/// Flutter Guard Agent
///
/// A small, self-contained "agent" that inspects Flutter/Dart source code
/// strings for a handful of common pitfalls and risky patterns. It is designed
/// to be simple, deterministic, and easy to reason about – ideal for
/// demonstration and evaluation inside Cursor.
///
/// The agent does not execute or compile code. Instead, it applies textual
/// heuristics to the provided source and returns a structured report.

/// A single potential issue or observation produced by the agent.
class GuardIssue {
  GuardIssue({
    required this.id,
    required this.severity,
    required this.message,
    this.lineHint,
    this.category,
  });

  /// Stable identifier for the rule that produced this issue.
  final String id;

  /// Coarse severity bucket: e.g. "info", "warning", "error".
  final String severity;

  /// Human-readable description of the issue.
  final String message;

  /// Optional line or line range hint for where the issue occurs.
  final String? lineHint;

  /// Optional high-level category, such as "lifecycle" or "performance".
  final String? category;
}

/// Aggregate metrics for an analysis run.
class GuardMetrics {
  GuardMetrics({
    required this.totalIssues,
    required this.errorCount,
    required this.warningCount,
    required this.infoCount,
    required this.score,
  });

  /// Total number of issues reported.
  final int totalIssues;

  /// Number of "error" severity issues.
  final int errorCount;

  /// Number of "warning" severity issues.
  final int warningCount;

  /// Number of "info" severity issues.
  final int infoCount;

  /// Normalised score on a 1–10 000 scale.
  ///
  /// This is computed deterministically from the issue counts so it can be
  /// easily referenced in documentation and benchmarks.
  final int score;
}

/// Full report for a single analysis run.
class GuardReport {
  GuardReport({
    required this.issues,
    required this.metrics,
  });

  final List<GuardIssue> issues;
  final GuardMetrics metrics;
}

/// Core "agent" responsible for analysing Flutter/Dart source text.
class FlutterGuardAgent {
  /// Analyse a single Dart/Flutter source string and produce a [GuardReport].
  ///
  /// The heuristics are intentionally conservative and easy to understand.
  GuardReport analyze(String source) {
    final issues = <GuardIssue>[];

    issues.addAll(_findMissingDisposeInStatefulWidget(source));
    issues.addAll(_findSetStateInAsyncGaps(source));
    issues.addAll(_findLongBuildMethods(source));

    final errorCount =
        issues.where((issue) => issue.severity == 'error').length;
    final warningCount =
        issues.where((issue) => issue.severity == 'warning').length;
    final infoCount = issues.where((issue) => issue.severity == 'info').length;
    final totalIssues = issues.length;

    final score = _scoreFromCounts(
      errorCount: errorCount,
      warningCount: warningCount,
      infoCount: infoCount,
    );

    return GuardReport(
      issues: issues,
      metrics: GuardMetrics(
        totalIssues: totalIssues,
        errorCount: errorCount,
        warningCount: warningCount,
        infoCount: infoCount,
        score: score,
      ),
    );
  }

  /// Deterministic scoring function on a 1–10 000 scale.
  ///
  /// Starts at 10 000 and subtracts weighted penalties for each issue type.
  int _scoreFromCounts({
    required int errorCount,
    required int warningCount,
    required int infoCount,
  }) {
    const base = 10000;
    const errorPenalty = 500;
    const warningPenalty = 200;
    const infoPenalty = 50;

    final penalty = (errorCount * errorPenalty) +
        (warningCount * warningPenalty) +
        (infoCount * infoPenalty);
    final raw = base - penalty;

    if (raw < 1) return 1;
    if (raw > base) return base;
    return raw;
  }

  List<GuardIssue> _findMissingDisposeInStatefulWidget(String source) {
    final issues = <GuardIssue>[];

    // Very small heuristic: if we see a StatefulWidget with a corresponding
    // State subclass that overrides initState but not dispose, we flag it.
    final statefulRegex = RegExp(r'class\s+(\w+)\s+extends\s+StatefulWidget');

    final matches = statefulRegex.allMatches(source);
    for (final match in matches) {
      final widgetName = match.group(1);
      if (widgetName == null) continue;

      // Match any State subclass for this widget (e.g. DemoWidgetState or
      // _DemoWidgetState), not just a specific naming pattern.
      final stateClassRegex = RegExp(
        r'class\s+[_\w]+\s+extends\s+State<' '${RegExp.escape(widgetName)}' r'>',
      );
      final stateMatch = stateClassRegex.firstMatch(source);
      if (stateMatch == null) continue;

      final stateBodyStart = stateMatch.start;
      final stateBodyEnd = source.indexOf('}', stateBodyStart);
      if (stateBodyEnd == -1) continue;

      final stateBody = source.substring(stateBodyStart, stateBodyEnd);
      final hasInitState = stateBody.contains('initState()');
      final hasDispose = stateBody.contains('dispose()');

      if (hasInitState && !hasDispose) {
        issues.add(
          GuardIssue(
            id: 'missing_dispose',
            severity: 'warning',
            category: 'lifecycle',
            message:
                'State class for $widgetName overrides initState but not dispose; '
                'this can easily lead to leaked resources.',
            lineHint: null,
          ),
        );
      }
    }

    return issues;
  }

  List<GuardIssue> _findSetStateInAsyncGaps(String source) {
    final issues = <GuardIssue>[];

    // Simple heuristic: "await" followed later in the same method body by
    // "setState(" without an obvious "mounted" guard.
    final methodRegex = RegExp(
      r'(Future<\w*>|Future|void)\s+\w+\s*\([^)]*\)\s*async\s*{',
    );

    final matches = methodRegex.allMatches(source);
    for (final match in matches) {
      final methodStart = match.start;
      final methodEnd = source.indexOf('}', methodStart);
      if (methodEnd == -1) continue;

      final body = source.substring(methodStart, methodEnd);
      final hasAwait = body.contains('await ');
      final hasSetState = body.contains('setState(');
      final hasMountedGuard = body.contains('if (mounted)') ||
          body.contains('if (!mounted)') ||
          body.contains('if (context.mounted)');

      if (hasAwait && hasSetState && !hasMountedGuard) {
        issues.add(
          GuardIssue(
            id: 'set_state_after_await',
            severity: 'warning',
            category: 'lifecycle',
            message:
                'setState is called after an await without an explicit mounted '
                'check; this can throw if the widget is disposed in the meantime.',
            lineHint: null,
          ),
        );
      }
    }

    return issues;
  }

  List<GuardIssue> _findLongBuildMethods(String source) {
    final issues = <GuardIssue>[];

    // Heuristic: flag build methods whose body spans more than N lines.
    final buildRegex =
        RegExp(r'Widget\s+build\(BuildContext\s+context\)\s*{', multiLine: true);

    final matches = buildRegex.allMatches(source);
    for (final match in matches) {
      final start = match.start;
      final end = source.indexOf('}', start);
      if (end == -1) continue;

      final body = source.substring(start, end);
      final lineCount = '\n'.allMatches(body).length + 1;
      const threshold = 40;
      if (lineCount > threshold) {
        issues.add(
          GuardIssue(
            id: 'long_build_method',
            severity: 'info',
            category: 'readability',
            message:
                'build method is very long (~$lineCount lines); consider '
                'extracting widgets for readability and testability.',
            lineHint: null,
          ),
        );
      }
    }

    return issues;
  }
}

/// Convenience top-level helper for quick, one-off analyses.
GuardReport analyzeSource(String source) => FlutterGuardAgent().analyze(source);

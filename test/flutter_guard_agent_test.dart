import 'package:flutter_guard_agent/flutter_guard_agent.dart';
import 'package:flutter_guard_agent/core/concurrency/safe_parser.dart';
import 'package:test/test.dart';

void main() {
  group('FlutterGuardAgent', () {
    test('produces no issues for empty source', () {
      final agent = FlutterGuardAgent();
      final report = agent.analyze('');

      expect(report.issues, isEmpty);
      expect(report.metrics.totalIssues, 0);
      expect(report.metrics.score, 10000);
    });

    test('flags missing dispose when initState is present', () {
      const source = '''
class DemoWidget extends StatefulWidget {
  const DemoWidget({super.key});

  @override
  State<DemoWidget> createState() => DemoWidgetState();
}

class DemoWidgetState extends State<DemoWidget> {
  @override
  void initState() {
    super.initState();
  }
}
''';
      final agent = FlutterGuardAgent();
      final report = agent.analyze(source);

      expect(
        report.issues.where((i) => i.id == 'missing_dispose'),
        isNotEmpty,
      );
    });

    test('flags setState after await without mounted guard', () {
      const source = '''
class DemoState extends State<StatefulWidget> {
  Future<void> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    setState(() {});
  }
}
''';
      final agent = FlutterGuardAgent();
      final report = agent.analyze(source);

      expect(
        report.issues.where((i) => i.id == 'set_state_after_await'),
        isNotEmpty,
      );
    });

    test('flags long build methods', () {
      final buffer = StringBuffer()
        ..writeln('class LongBuild extends StatelessWidget {')
        ..writeln('  const LongBuild({super.key});')
        ..writeln('  @override')
        ..writeln('  Widget build(BuildContext context) {')
        ..writeln('    return Column(')
        ..writeln('      children: [');
      // Add many lines to exceed the threshold.
      for (var i = 0; i < 45; i++) {
        buffer.writeln('        const SizedBox.shrink(),');
      }
      buffer
        ..writeln('      ],')
        ..writeln('    );')
        ..writeln('  }')
        ..writeln('}');

      final agent = FlutterGuardAgent();
      final report = agent.analyze(buffer.toString());

      expect(
        report.issues.where((i) => i.id == 'long_build_method'),
        isNotEmpty,
      );
    });

    test('rewards code with no issues via high score', () {
      const source = '''
class Simple extends StatelessWidget {
  const Simple({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
''';
      final report = analyzeSource(source);

      expect(report.issues, isEmpty);
      expect(report.metrics.score, 10000);
    });

    test('applies warning and info penalties to score', () {
      // One missing_dispose (warning) and one long_build_method (info).
      final buffer = StringBuffer()
        ..writeln('class DemoWidget extends StatefulWidget {')
        ..writeln('  const DemoWidget({super.key});')
        ..writeln('  @override')
        ..writeln('  State<DemoWidget> createState() => DemoWidgetState();')
        ..writeln('}')
        ..writeln('class DemoWidgetState extends State<DemoWidget> {')
        ..writeln('  @override')
        ..writeln('  void initState() {')
        ..writeln('    super.initState();')
        ..writeln('  }')
        ..writeln('  @override')
        ..writeln('  Widget build(BuildContext context) {')
        ..writeln('    return Column(children: [');
      for (var i = 0; i < 45; i++) {
        buffer.writeln('      const SizedBox.shrink(),');
      }
      buffer
        ..writeln('    ]);')
        ..writeln('  }')
        ..writeln('}');

      final agent = FlutterGuardAgent();
      final report = agent.analyze(buffer.toString());

      // 1 warning (200 penalty) + 1 info (50 penalty) → 10000 - 250 = 9750.
      expect(report.metrics.errorCount, 0);
      expect(report.metrics.warningCount, greaterThanOrEqualTo(1));
      expect(report.metrics.infoCount, greaterThanOrEqualTo(1));
      expect(report.metrics.score, 9750);
    });
  });

  group('SafeParser', () {
    test('parses JSON in background isolate and maps result', () async {
      const rawJson = '{"id": 1, "name": "Alice"}';

      final result = await SafeParser.parseInBackground<Map<String, dynamic>>(
        rawJson,
        (json) => json,
      );

      expect(result['id'], 1);
      expect(result['name'], 'Alice');
    });
  });
}

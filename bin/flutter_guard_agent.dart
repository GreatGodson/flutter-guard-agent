import 'dart:io';

import 'package:flutter_guard_agent/flutter_guard_agent.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty || arguments.contains('--help')) {
    _printUsage();
    exit(0);
  }

  final fileArgIndex = arguments.indexOf('--file');
  if (fileArgIndex == -1 || fileArgIndex == arguments.length - 1) {
    stderr.writeln(
      'Missing --file <path> argument.\n',
    );
    _printUsage();
    exit(64); // EX_USAGE
  }

  final path = arguments[fileArgIndex + 1];
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('File not found: $path');
    exit(66); // EX_NOINPUT
  }

  final source = file.readAsStringSync();
  final agent = FlutterGuardAgent();
  final report = agent.analyze(source);

  _printReport(path, report);
}

void _printUsage() {
  stdout.writeln(
    'Flutter Guard Agent\n'
    '\n'
    'Usage:\n'
    '  dart run flutter_guard_agent --file <path/to/file.dart>\n'
    '\n'
    'The agent will analyse the given Dart/Flutter source file for a small\n'
    'set of lifecycle and readability issues, then print a structured report\n'
    'including a 1–10 000 score.\n',
  );
}

void _printReport(String path, GuardReport report) {
  stdout.writeln('Analysed: $path');
  stdout.writeln('Score:   ${report.metrics.score} / 10000');
  stdout.writeln(
      'Issues:  ${report.metrics.totalIssues} (errors: ${report.metrics.errorCount}, '
      'warnings: ${report.metrics.warningCount}, info: ${report.metrics.infoCount})');
  stdout.writeln('');

  if (report.issues.isEmpty) {
    stdout.writeln('No issues detected by Flutter Guard Agent.');
    return;
  }

  stdout.writeln('Issues:');
  for (final issue in report.issues) {
    final category = issue.category ?? 'general';
    final hint = issue.lineHint != null ? ' @ ${issue.lineHint}' : '';
    stdout.writeln(
      '- [${issue.severity.toUpperCase()}] '
      '${issue.id} ($category)$hint: ${issue.message}',
    );
  }
}

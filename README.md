# Flutter Guard Agent

**Flutter Guard Agent** is a small, deterministic Dart agent designed for the
Cursor quest-based hiring process. It specialises in:

- Analysing Flutter/Dart UI code for high-signal lifecycle and readability
  issues.
- Encouraging **jank-free data layering** via background JSON parsing
  (`Isolate.run`) and clean separation of concerns.
- Reporting repeatable scores on a 1–10 000 scale that can be compared against
  default Cursor Claude.

The project is:

- **Cursor-ready** (includes `.cursorrules` and rule files under
  `.cursor/rules/`).
- **CLI + library** (usable from `dart run` or directly from Dart code).
- **Secret-free by design** (no API keys, no network calls in the agent core).

---

## 1. Problem Specialisation

- **Specialised problem**: Quickly assess Flutter widget and data-layer code for:
  - Missing `dispose` when `initState` is used in `State` classes.
  - `setState` usage after `await` without a `mounted` guard.
  - Extremely long `build` methods that hurt readability.
  - Heavy JSON parsing that should be moved off the main isolate.
- **Why this problem?**
  - These issues are **common**, **high-impact**, and **easy to encode** as
    deterministic heuristics.
  - They make for a great demonstration of how an “agent” can enforce a
    focused, opinionated standard inside Cursor.
- **Why #1 priority?**
  - They directly affect app stability (lifecycle leaks, crashes) and
    maintainability (giant `build` methods, blocking parsing on the UI thread).
  - They provide clear, testable behavior for benchmarking against
    default Cursor Claude.

---

## 2. Agent Capabilities & Design

The agent is implemented in `lib/flutter_guard_agent.dart` and exposed as:

- `class FlutterGuardAgent` – the core agent.
- `GuardIssue`, `GuardMetrics`, `GuardReport` – structured results.
- `GuardReport analyzeSource(String source)` – convenience top-level helper.

### 2.1. What the Agent Checks

The agent currently applies three heuristics to a source string:

- **Missing dispose in State classes**
  - Looks for `StatefulWidget` + associated `State<Widget>` subclasses that:
    - Override `initState`, but
    - Do not implement `dispose`.
  - Adds a `GuardIssue` with:
    - `id: 'missing_dispose'`
    - `severity: 'warning'`
    - `category: 'lifecycle'`

- **setState after await without mounted guard**
  - Scans `async` methods for:
    - At least one `await`.
    - A call to `setState(`.
    - No obvious `mounted` guard (`if (mounted)` / `if (!mounted)` /
      `if (context.mounted)`).
  - Adds a `GuardIssue` with:
    - `id: 'set_state_after_await'`
    - `severity: 'warning'`
    - `category: 'lifecycle'`

- **Very long build methods**
  - Detects `Widget build(BuildContext context)` bodies whose span exceeds a
    simple line threshold (default: 40 lines).
  - Adds a `GuardIssue` with:
    - `id: 'long_build_method'`
    - `severity: 'info'`
    - `category: 'readability'`

> The **concurrency / jank-free data layering** concern is represented in code
> by the `SafeParser` utility (see Section 2.3) and in the documentation and
> evaluation rules, rather than as an additional textual heuristic.

### 2.3. Jank-Free Data Layering Helper

Under `lib/core/concurrency/safe_parser.dart` you will find:

- `SafeParser.parseInBackground<T>(String rawJson, T Function(Map<String, dynamic>) mapper)`
  - Uses `Isolate.run` to offload JSON decoding and mapping to a background
    isolate.
  - Demonstrates the kind of “safe by default” helper the agent promotes.

### 2.2. File Analysis Score (1–10 000)

Each analysis run yields:

- **GuardMetrics**:
  - `totalIssues`
  - `errorCount`
  - `warningCount`
  - `infoCount`
  - `score` (1–10 000)

#### Scoring function

The per-file score is computed **deterministically** as:

- **Base score**: 10 000
- **Penalties**:
  - Each error: 500 points
  - Each warning: 200 points
  - Each info: 50 points
- **Final score**:

  \[
  \text{score} =
  \max\bigl(1, \min(10000,\ 10000 - 500 \cdot E - 200 \cdot W - 50 \cdot I)\bigr)
  \]

Where:

- \(E\) = errorCount
- \(W\) = warningCount
- \(I\) = infoCount

There are currently no `error`-severity rules implemented, but the rubric
is ready for future extension.

---

## 3. Using the Agent

### 3.1. As a CLI

From the project root:

```bash
dart run bin/flutter_guard_agent.dart --file path/to/file.dart
```

This will:

- Read the specified Dart file.
- Run `FlutterGuardAgent.analyze`.
- Print:
  - File path
  - Score (1–10 000)
  - Issue counts
  - A human-readable list of issues.

### 3.2. From Dart code

You can also call it directly from another Dart file or from tests:

```dart
import 'package:flutter_guard_agent/flutter_guard_agent.dart';

void main() {
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
  print('Score: ${report.metrics.score}');
  print('Issues: ${report.issues.length}');
}
```

---

## 4. Cursor-Based Setup

This repo is configured to be **Cursor-ready**:

- `.cursor/rules/flutter-guard-agent.mdc`:
  - Describes:
    - The agent’s specialisation.
    - Determinism requirements.
    - No-secrets policy.
    - How to invoke the CLI and library from Cursor.
  - Marked with `alwaysApply: true` for this project so Cursor always has
    the right context when working here.

You can open this repo in Cursor and immediately:

- Ask the agent (via Cursor) to:
  - Explain an issue the heuristics would find.
  - Suggest how to refactor a long `build` into smaller widgets.
  - Extend the heuristics with new rules.

---

## 5. Security Requirements

- **No secrets in git**:
  - The agent core has **no external API calls**.
  - There is no need to configure keys or tokens for normal usage.
- **If you extend it** (e.g. to call external services):
  - Use environment variables (e.g. `API_KEY`) or untracked config files.
  - Document new configuration in this README without committing any
    actual secret values.

---

## 6. Performance Metrics & Evaluation

This project includes:

- **A clear per-file scoring function** (see Section 2.2).
- **Unit tests** in `test/flutter_guard_agent_test.dart` that:
  - Verify no-issue scenarios get a high score (10 000).
  - Ensure known-bad patterns are flagged.

### 6.1. Measuring the Agent’s Performance

To evaluate performance in practice:

- **Determinism**:
  - Run `dart test` multiple times – results and scores should not change.
  - Feed the same source file multiple times to the CLI – identical scores.
- **Sensitivity**:
  - Use a small suite of Dart/Flutter snippets:
    - A “clean” widget with short `build` and no async state.
    - A widget with `initState` but no `dispose`.
    - A widget with `setState` after `await` and no `mounted` guard.
    - A long `build` method (>40 lines).
  - Confirm that:
    - Clean code scores close to 10 000.
    - Problematic code gets noticeably lower scores.
  - For data-layer code, confirm that examples using `SafeParser.parseInBackground`
    match your concurrency and jank-free expectations.

### 6.2. Example Scoring Table (Per-File Score)

| Scenario                                   | Issues (E/W/I) | Expected score (approx.) |
| ------------------------------------------ | -------------- | ------------------------ |
| Clean widget                               | 0/0/0          | 10 000                   |
| Missing `dispose`                          | 0/1/0          | 9 800                    |
| `setState` after `await` w/o mounted check | 0/1/0          | 9 800                    |
| Long `build` method                        | 0/0/1          | 9 950                    |
| Missing `dispose` + long `build`          | 0/1/1          | 9 750                    |

### 6.3. Agent Efficiency Score (AES, 1–10 000)

For Requirement #4, we also define a **meta-metric** called
**Agent Efficiency Score (AES)**, which rates the behaviour of this
Cursor agent (and default Cursor Claude) on a scale from 1 to 10 000.

We break it into three components, each expressed as a percentage from
0 to 100:

- **Architecture Compliance (A)** – up to 4 000 pts  
  How often the agent respects the architecture rules, e.g.:
  - Avoiding unnecessary `StatefulWidget` when a `StatelessWidget` with DI
    would work.
  - Keeping business logic out of UI widgets.
- **Concurrency Coverage (C)** – up to 4 000 pts  
  How often heavy JSON parsing or similar work is suggested to run via
  `Isolate.run` / `SafeParser` instead of on the main isolate.
- **Prompt-to-Code Ratio (R)** – up to 2 000 pts  

  \[
  R = 1 - \frac{\text{Manual Edits}}{\text{Lines Generated}}
  \]

  Measured over a test session: how much generated code needed manual edits.

Each percentage is then mapped to the 1–10 000 AES scale as:

\[
\text{AES} = (A \times 40) + (C \times 40) + (R \times 20)
\]

This keeps AES on the same 1–10 000 range and lets you compare:

- This specialised Flutter Guard Agent (using its docs/rules as the “desired”
  behaviour).
- Default Cursor Claude, using the same prompts and scenarios.

---

## 7. Benchmark vs Default Cursor Claude

To compare this agent with default Cursor Claude:

1. **Prepare test snippets**
   - Use the same set of snippet scenarios from Section 6.1.
2. **Ask both agents the same questions**
   - Example prompt to default Cursor Claude:
     - “Here is a Flutter widget. Identify lifecycle and state issues (like
       `setState` after `await` or missing `dispose`) and rate code quality
       from 1 to 10 000.”
   - Example for this agent (via CLI or directly via `analyzeSource`):
     - Run it on the exact same code and record:
       - Issues.
       - Score.
3. **Side-by-side comparison**
   - Where **this agent excels**:
     - **Repeatability**: given the same input, the score is identical every time.
     - **Focus**: only targets a few specific patterns; less likely to drift.
     - **Transparency**: you can see and modify the scoring function.
   - Where **default Cursor Claude excels**:
     - **Breadth**: understands a much wider set of Flutter/Dart problems.
     - **Contextual reasoning**: can consider cross-file context and higher-level
       architecture concerns.

### 7.1. Example Side-by-Side Scenario

Below is an example (illustrative) comparison for a widget that calls
`setState` after `await` without a `mounted` check:

| Aspect                      | Flutter Guard Agent                                  | Default Cursor Claude                                      |
| --------------------------- | ---------------------------------------------------- | ---------------------------------------------------------- |
| Detected issue             | Flags `set_state_after_await` warning               | Describes async `setState` risk in natural language       |
| File score (1–10 000)      | ~9 800                                               | Depends on prompt; no fixed numeric score                 |
| Suggested fix              | Add `if (!mounted) return;` before `setState`       | Typically suggests `if (!mounted) return;` or similar     |
| AES – Architecture (A)     | High: follows documented lifecycle rules            | High: usually agrees with recommended pattern             |
| AES – Concurrency (C)      | Neutral (no JSON parsing here)                      | Neutral                                                    |
| AES – Prompt-to-Code (R)   | High if little manual editing is required           | Depends on how much you tweak the suggested code          |

You can repeat this style of comparison for:

- A missing-`dispose` case.
- A long `build` method.
- A data-layer example where `SafeParser.parseInBackground` is preferred.

---

## 8. How to Run & Develop

### 8.1. Run tests

```bash
dart test
```

### 8.2. Run the CLI

```bash
dart run bin/flutter_guard_agent.dart --file path/to/file.dart
```

You can also try the built-in benchmark examples:

```bash
dart run bin/flutter_guard_agent.dart --file benchmarks/clean_widget.dart
dart run bin/flutter_guard_agent.dart --file benchmarks/bad_widget_missing_dispose.dart
dart run bin/flutter_guard_agent.dart --file benchmarks/bad_widget_set_state_after_await.dart
dart run bin/flutter_guard_agent.dart --file benchmarks/bad_widget_long_build.dart
```

### 8.3. Extend the Agent

- Add new heuristic methods in `FlutterGuardAgent`:
  - Return `List<GuardIssue>`.
  - Wire them into `analyze`.
- Update this README:
  - Document the new rule.
  - Update any examples or scoring expectations if needed.

---

## 9. Submission Checklist

This repository is ready to be shared as your quest submission:

- **Agent code**: Implemented in `lib/flutter_guard_agent.dart`.
- **Cursor config**: `.cursor/rules/flutter-guard-agent.mdc`.
- **No secrets**: No API keys or private tokens in version control.
- **Performance metrics**:
  - Clear scoring function and example scenarios.
- **Benchmark comparison plan**:
  - Instructions for comparing with default Cursor Claude.
- **Documentation**:
  - This README explains capabilities, design decisions, and usage examples.


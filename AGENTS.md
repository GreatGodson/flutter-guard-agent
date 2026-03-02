# Flutter Guard Agent – High-Level Design

## Purpose

Flutter Guard Agent is a small, deterministic analysis agent built for the
Cursor quest. Its mission is to:

- Spot high-signal Flutter pitfalls (lifecycle, async `setState`, long builds).
- Encourage **jank-free data layering** by pushing heavy JSON parsing work to
  background isolates.
- Provide a transparent 1–10 000 scoring mechanism that can be compared against
  default Cursor Claude.

## Specialisation

- **Domain**: Flutter UI and data-layer ergonomics.
- **Primary focus areas**:
  - Lifecycle safety (`initState` / `dispose`, `setState` after `await`).
  - Readability of `build` methods.
  - Concurrency hygiene for large JSON parsing using `Isolate.run`.

## How Cursor Should Use This Agent

- When editing Flutter widgets or screens:
  - Ask the agent to identify lifecycle risks and long `build` methods.
  - Use its findings as guardrails, not as absolute truth.
- When designing the data layer:
  - Prefer concurrency helpers in `lib/core/concurrency/` (e.g. `SafeParser`)
    for heavy JSON parsing.
- When discussing metrics or benchmarks:
  - Use the 1–10 000 file analysis score from the Dart agent.
  - Use the AES (Agent Efficiency Score) as the meta-metric for comparing this
    agent’s behaviour vs default Cursor Claude (see `README.md`).


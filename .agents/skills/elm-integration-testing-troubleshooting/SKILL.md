---
name: elm-integration-testing-troubleshooting
description: Use when Elm integration tests fail or behave flakily. Covers selector failures, rendering preconditions, async/timing issues, state mismatch debugging, and other elm-program-test diagnostics.
---

# Elm Integration Testing Troubleshooting

Use this skill when `ProgramTest` workflows fail unexpectedly.

- Check whether the target element actually exists in the current rendered state before clicking it.
- Prefer more specific selectors when multiple matches are possible.
- Validate intermediate states instead of asserting only the final state.
- For async flows, confirm the test drives the application into the state where the next UI element should appear.
- When state expectations diverge, inspect the full interaction chain rather than patching the last assertion.
- Keep using npm scripts for test execution rather than direct tool calls.

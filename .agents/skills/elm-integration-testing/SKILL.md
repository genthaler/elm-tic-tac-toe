---
name: elm-integration-testing
description: Use for Elm integration tests that exercise user workflows with elm-program-test. Covers interaction helpers, routing flows, model and view assertions, and end-to-end behavior checks.
---

# Elm Integration Testing

Use this skill for `ProgramTest`-based Elm tests.

- Test complete user workflows rather than internal helper calls.
- Assert both model state and rendered output when that improves confidence.
- Use helper modules such as `tests/TestUtils/ProgramTestHelpers.elm` when they match the flow.
- Cover navigation, async transitions, and state preservation when the feature requires them.
- Keep selectors specific and stable.
- `ProgramTest` files must end in `IntegrationTest.elm`.
- Ensure module names match filenames.

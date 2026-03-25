---
name: elm-testing
description: Use for Elm unit tests in this repository. Covers elm-test patterns for pure functions, fuzz tests, view tests, update tests, naming conventions, and behavior-first assertions.
---

# Elm Testing

Use this skill when writing or reviewing Elm unit tests.

- Prefer behavior-focused tests over implementation-detail tests.
- Start with pure functions, then add view and update tests where they carry their weight.
- Use fuzz tests for encoder/decoder round trips and stable invariants.
- Keep each test focused on one behavior.
- Use descriptive test names that explain the scenario and expected outcome.
- Files that do not use `ProgramTest` should end in `UnitTest.elm`.
- Ensure module names match filenames.

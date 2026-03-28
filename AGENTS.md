# AGENTS.md

This repository is set up for Codex-first development. Start with the repo-local skills under `.agents/skills/`, and use the feature-specific spec skills before changing behavior.

## Source Of Truth

- `docs/specs/**/requirements.md` is the canonical statement of expected behavior and acceptance criteria.
- `docs/specs/**/design.md` is the canonical statement of implementation intent and architecture.
- If code and retained docs diverge, call out the mismatch explicitly before changing behavior.

## Repo Workflow

- For substantial work, inspect `git status` first and call out unrelated local changes before mixing scopes.
- Do not create commits unless the user explicitly asks.
- When asked to commit a completed task, suggest a message in the style `Complete: ...` or `Implement: ...`.
- Use the repo's npm scripts as the supported interface for build, review, test, and formatting workflows.

## Project Conventions

- Preserve the established Elm Architecture, `elm-ui`, and shared-theme patterns; use the relevant repo-local skills for the detailed guidance.
- Tests that use `ProgramTest` must end in `IntegrationTest.elm`.
- Other Elm test files must end in `UnitTest.elm`.
- Elm module names must match file names.

# AGENTS.md

This repository is set up for Codex-first development. Prefer the repo-local skills under `.agents/skills/` and the retained feature documents under `docs/specs/`.

## Source Of Truth

- Treat `docs/specs/**/requirements.md` as the canonical statement of expected behavior and acceptance criteria.
- Treat `docs/specs/**/design.md` as the canonical statement of implementation intent and architecture.

## Git Hygiene

- Before starting substantial new work, check `git status` and summarize staged, unstaged, and untracked changes.
- Prefer a clean working tree before starting a new feature or bugfix.
- If the tree is dirty, warn about the risk of mixing unrelated work and suggest a commit or stash strategy.
- Do not create commits automatically.
- Only create commits when the user explicitly asks for one, even if task documents imply work is complete.
- When asked to commit work tied to a completed task, inspect the most recent completed task and propose a message in the style `Complete: ...` or `Implement: ...`.
- On request, provide a concise git status summary with suggested commit messages when useful.

## Command Policy

- Prefer the documented npm scripts over direct tool invocation.
- Do not run `elm` directly; use the repo scripts instead.
- Do not run `elm-review` directly; use `npm run review` or related scripts.
- Do not use `npx` for repo workflows when an npm script already exists.
- Prefer one command per step instead of chaining unrelated shell commands.
- For bulk text replacement, prefer `./scripts/find_replace.sh`.

## Elm Editing Expectations

- When editing Elm files, keep to the Elm Architecture patterns already used in the repo.
- Use `elm-ui` patterns already established in the codebase instead of introducing ad hoc HTML/CSS approaches.
- Use the shared theme infrastructure rather than duplicating theme logic.
- Format any touched Elm files before finishing unless the user explicitly asks otherwise or formatting is unavailable.

## Testing Expectations

- When creating or renaming Elm tests, files that use `ProgramTest` must end in `IntegrationTest.elm`.
- Other Elm test files must end in `UnitTest.elm`.
- Elm module names must match their file names.
- Before declaring a substantial implementation task complete, run the relevant verification scripts when the task changes behavior or code.

## Skills

- Start with the repo-local skills in `.agents/skills/` when the task matches them.
- Use the feature-specific spec skills to locate the correct requirements and design docs before changing feature behavior.

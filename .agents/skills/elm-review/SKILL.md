---
name: elm-review
description: Use for linting and code-quality work involving elm-review in this repository. Covers common review failures, configuration problems, performance issues, and the repo's expectation to use npm review scripts instead of direct tool invocation.
---

# Elm Review

Use this skill when the task involves `elm-review`.

- Run the repo review scripts instead of invoking `elm-review` directly.
- Treat configuration errors, missing packages, and slow rules as first-class debugging targets.
- Prefer meaningful fixes over blindly satisfying every suggestion.
- Use `npm run review:perf` when rule performance is the issue.
- Use `npm run review:fix` only when the autofix behavior is appropriate for the task.
- Preserve readability when a simplification suggestion makes the code worse.

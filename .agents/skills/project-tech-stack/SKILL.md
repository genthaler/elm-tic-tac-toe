---
name: project-tech-stack
description: Use when toolchain, commands, or build workflow matter in this repository. Covers Elm, Parcel, npm scripts, review and test commands, and repo-specific command constraints.
---

# Project Tech Stack

Use this skill whenever the task depends on how the repo is built or verified.

- The app is built with Elm, Parcel, and Node.js.
- Prefer the repo's npm scripts for build, test, and review workflows.
- Do not run `elm` or `elm-review` directly when an npm script exists.
- Avoid `npx` for routine repo tasks.
- For bulk text replacements, prefer `./scripts/find_replace.sh`.
- Treat build and verification commands as the supported interface to the toolchain.

---
name: project-architecture
description: Use when you need a codebase map for this Elm demo repository. Covers source layout, feature boundaries, test layout, and repo naming conventions.
---

# Project Architecture

Use this skill to orient before making changes.

- `src/App.elm` and `src/Route.elm` anchor application-level flow and routing.
- `src/TicTacToe/` contains the two-player tic-tac-toe game logic, view, worker integration, and model types.
- `src/RobotGame/` contains the robot movement demo and its animation-aware modules.
- `src/Theme/` holds shared theme infrastructure and style-guide surfaces.
- `tests/` mirrors the feature layout and uses `UnitTest` versus `IntegrationTest` suffixes intentionally.
- Keep new work aligned to existing feature boundaries instead of creating catch-all modules.

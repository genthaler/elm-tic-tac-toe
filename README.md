# Elm Tic-Tac-Toe

Live app: [https://genthaler.github.io/elm-tic-tac-toe/](https://genthaler.github.io/elm-tic-tac-toe/)

This repository contains a single-screen tic-tac-toe app built with Elm. It boots directly into the game, uses a shared theme module for light and dark color schemes, and runs AI move calculations in a web worker so the UI stays responsive. It also includes a search-inspection mode that visualizes Negamax and Alpha-Beta evaluation without changing the fast gameplay path.

## Project Guidance

This repository is set up for Codex-first development.

- Feature requirements and design documents live under `docs/specs/`.
- Repo-local Codex guidance lives under `.agents/skills/`.

## Features

- Human vs AI tic-tac-toe
- Negamax-based computer opponent
- Web worker-backed AI so the main thread stays responsive
- Search inspection mode for stepping through Negamax and Alpha-Beta traces
- Alpha-Beta bounds, pruning, and node values shown during inspection
- Shared light/dark theme support with persisted preference
- Responsive single-screen layout for desktop and mobile
- Reset flow that preserves theme state

## Tech Stack

- Elm 0.19.1
- Parcel 2
- `elm-ui`
- Web Workers
- `elm-test`
- `elm-review`

## Quick Start

### Prerequisites

- Node.js 20 or newer
- npm

### Installation

```bash
git clone https://github.com/genthaler/elm-tic-tac-toe.git
cd elm-tic-tac-toe
npm install
```

### Development Commands

```bash
npm run parcel
npm run build
npm run serve
npm run test
npm run test:unit
npm run test:integration
```

### Code Quality

```bash
npm run review
npm run review:fix
npm run review:perf
npm run review:ci
```

## Architecture

- `src/TicTacToe/Main.elm` is the Elm application entry point
- `src/TicTacToe/Model.elm` holds the game state and theme preference
- `src/TicTacToe/View.elm` renders the single-screen game UI
- `src/TicTacToe/GameWorker.elm` handles AI work off the main thread
- `src/TicTacToe/Search*.elm` holds the pure search-trace layer used by inspection mode
- `src/Theme/Theme.elm` centralizes theming, responsive helpers, and JSON persistence
- `src/TicTacToe/TicTacToe.elm` contains the core game logic

## Specs

- [Tic-tac-toe game requirements](docs/specs/tic-tac-toe-game/requirements.md)
- [Tic-tac-toe game design](docs/specs/tic-tac-toe-game/design.md)
- [Shared theme module requirements](docs/specs/shared-theme-module/requirements.md)
- [Shared theme module design](docs/specs/shared-theme-module/design.md)

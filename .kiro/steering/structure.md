# Project Structure

## Root Directory
- `elm.json`: Elm package configuration and dependencies
- `package.json`: Node.js dependencies and npm scripts
- `index.html`: Main entry point for the application

## Source Code (`src/`)
- `Main.elm`: Application entry point with ports and subscriptions
- `Model.elm`: Core data types, game state, and JSON encoding/decoding
- `View.elm`: UI rendering and visual components
- `GameWorker.elm`: Web worker for AI game logic
- `Book.elm`: Component style guide using elm-book
- `index.html`, `index.js`, `worker.js`: JavaScript integration files

### Game Logic (`src/TicTacToe/`)
- `TicTacToe.elm`: Core game rules, move validation, and AI integration

### Game Theory (`src/GameTheory/`)
- `AdversarialEager.elm`: Negamax algorithms
- `AdversarialLazy.elm`: Lazy evaluation variants
- `ExtendedOrder.elm`: Extended ordering utilities for game evaluation

## Tests (`tests/`)
- Mirror the `src/` structure with `*Test.elm` files
- `elm-verify-examples.json`: Configuration for documentation testing
- Test modules follow naming convention: `ModuleNameTest.elm`

## Generated/Build Artifacts
- `elm-stuff/`: Elm compiler cache and generated files
- `dist/`: Production build output
- `.parcel-cache/`: Parcel bundler cache
- `node_modules/`: Node.js dependencies

## Naming Conventions
- Elm modules use PascalCase: `TicTacToe.elm`
- Test files append `Test`: `TicTacToeTest.elm`
- Folders group related functionality by domain
- Game theory algorithms are separated into their own module hierarchy
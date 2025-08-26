# Project Structure

## Root Directory
- `elm.json`: Elm package configuration and dependencies
- `package.json`: Node.js dependencies and npm scripts
- `index.html`: Main entry point for the application

## Source Code (`src/`)
- `Book.elm`: Component style guide using elm-book
- `index.html`, `index.js`, `worker.js`: JavaScript integration files

### Landing Page (`src/Landing/`)
- `Landing.elm`: Landing page logic and state management
- `LandingView.elm`: Landing page UI components

### Main Application (`src/`)
- `App.elm`: Main application entry point with hash routing and ports
- `Route.elm`: Hash-based routing system with URL parsing and navigation

### Game Logic (`src/TicTacToe/`)
- `Main.elm`: Game application logic and subscriptions
- `Model.elm`: Core data types, game state, and JSON encoding/decoding
- `View.elm`: UI rendering and visual components
- `GameWorker.elm`: Web worker for AI game logic
- `TicTacToe.elm`: Core game rules, move validation, and AI integration

### Robot Game (`src/RobotGame/`)
- `Main.elm`: Robot game application logic and subscriptions
- `Model.elm`: Robot game state and data types
- `View.elm`: Robot game UI components
- `RobotGame.elm`: Core robot game logic and movement

### Game Theory (`src/GameTheory/`)
- `AdversarialEager.elm`: Negamax algorithms
- `AdversarialLazy.elm`: Lazy evaluation variants
- `ExtendedOrder.elm`: Extended ordering utilities for game evaluation

## Tests (`tests/`)
- Mirror the `src/` structure with `*Test.elm` files
- `Integration/`: Application-level integration tests
- `RouteUnitTest.elm`: Hash routing unit tests
- `HashRoutingIntegrationTest.elm`: Hash routing integration tests
- `ProductionHashRoutingTest.elm`: Production build routing verification
- `elm-verify-examples.json`: Configuration for documentation testing
- Unit test modules follow naming convention: `ModuleNameUnitTest.elm`
- Integration test modules follow naming convention: `ModuleNameIntegrationTest.elm`

## Generated/Build Artifacts
- `elm-stuff/`: Elm compiler cache and generated files
- `dist/`: Production build output
- `.parcel-cache/`: Parcel bundler cache
- `node_modules/`: Node.js dependencies

## Naming Conventions
- Elm modules use PascalCase: `TicTacToe.elm`
- Unit test files append `UnitTest`: `TicTacToeUnitTest.elm`
- Integration test files append `IntegrationTest`: `GameFlowIntegrationTest.elm`
- Folders group related functionality by domain
- Game theory algorithms are separated into their own module hierarchy
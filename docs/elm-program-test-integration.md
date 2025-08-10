# elm-program-test Integration Guide

This guide covers how to use elm-program-test for integration testing in this Elm project. elm-program-test allows you to test complete user workflows by simulating user interactions and verifying application behavior.

## Table of Contents

1. [Overview](#overview)
2. [Test Structure](#test-structure)
3. [Helper Modules](#helper-modules)
4. [Writing Integration Tests](#writing-integration-tests)
5. [Common Patterns](#common-patterns)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

## Overview

elm-program-test enables end-to-end testing of Elm applications by:
- Simulating user interactions (clicks, keyboard input, etc.)
- Testing complete workflows across multiple components
- Verifying application state changes
- Testing navigation and routing
- Validating UI rendering and behavior

### Test Categories

Our test suite is organized into two main categories:

- **Unit Tests** (745 tests): Test individual functions and modules in isolation
- **Integration Tests** (220 tests): Test complete user workflows and component interactions

## Test Structure

Integration tests are organized by feature area:

```
tests/
├── Integration/                    # Application-level integration tests
│   ├── NavigationFlowIntegrationTest.elm
│   ├── RoutingIntegrationTest.elm
│   └── StatePreservationIntegrationTest.elm
├── TicTacToe/                     # TicTacToe game integration tests
│   ├── AIInteractionProgramTest.elm
│   ├── CompleteGameFlowTest.elm
│   ├── GameFlowIntegrationTest.elm
│   └── ThemeProgramTest.elm
├── RobotGame/                     # Robot game integration tests
│   ├── AnimationIntegrationTest.elm
│   ├── NavigationIntegrationTest.elm
│   └── UserInputIntegrationTest.elm
└── TestUtils/                     # Shared test utilities
    └── ProgramTestHelpers.elm
```

## Helper Modules

### TestUtils.ProgramTestHelpers

Provides common utilities for setting up and interacting with ProgramTest instances:

```elm
-- Application startup helpers
startApp : () -> ProgramTest App.Model App.Msg (Cmd App.Msg)
startTicTacToe : () -> ProgramTest TicTacToe.Model TicTacToe.Msg (Cmd TicTacToe.Msg)
startRobotGame : () -> ProgramTest RobotGame.Model RobotGame.Msg (Cmd RobotGame.Msg)

-- Interaction helpers
simulateClick : String -> ProgramTest model msg effect -> ProgramTest model msg effect
simulateKeyPress : String -> ProgramTest model msg effect -> ProgramTest model msg effect
clickCell : Position -> ProgramTest model msg effect -> ProgramTest model msg effect

-- Assertion helpers
expectGameState : GameState -> ProgramTest model msg effect -> Expectation
expectRobotPosition : Position -> ProgramTest model msg effect -> Expectation
expectRoute : Route -> ProgramTest model msg effect -> Expectation
```

### Game-Specific Helpers

Each game has its own helper module with specialized functions:

- `TicTacToe.ProgramTestHelpers`: TicTacToe-specific test utilities
- `RobotGame.ProgramTestHelpers`: Robot game-specific test utilities

## Writing Integration Tests

### Basic Test Structure

```elm
module MyIntegrationTest exposing (suite)

import Expect
import ProgramTest
import Test exposing (Test, describe, test)
import TestUtils.ProgramTestHelpers exposing (startApp, simulateClick)

suite : Test
suite =
    describe "My Integration Tests"
        [ test "user can complete basic workflow" <|
            \() ->
                startApp ()
                    |> simulateClick "start-button"
                    |> ProgramTest.expectViewHas [ text "Started!" ]
        ]
```

### Testing User Interactions

#### Clicking Elements

```elm
test "user can click game cell" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.expectModel
                (\model ->
                    case getCellState model.board { row = 0, col = 0 } of
                        Just X ->
                            Expect.pass
                        _ ->
                            Expect.fail "Expected X in clicked cell"
                )
```

#### Keyboard Input

```elm
test "user can control robot with arrow keys" <|
    \() ->
        startRobotGame ()
            |> simulateKeyPress "ArrowUp"
            |> ProgramTest.expectModel
                (\model ->
                    Expect.equal North model.robot.facing
                )
```

### Testing Navigation

```elm
test "user can navigate between pages" <|
    \() ->
        startApp ()
            |> simulateClick "tic-tac-toe-link"
            |> expectRoute TicTacToeRoute
            |> ProgramTest.expectViewHas [ text "Tic-Tac-Toe" ]
```

### Testing Async Operations

For operations that involve web workers or other async behavior:

```elm
test "AI responds after human move" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.expectModel
                (\model ->
                    case model.gameState of
                        Thinking O ->
                            Expect.pass
                        _ ->
                            Expect.fail "Expected AI to be thinking"
                )
```

## Common Patterns

### 1. Complete Workflow Testing

Test entire user journeys from start to finish:

```elm
test "complete game from start to win" <|
    \() ->
        startTicTacToe ()
            -- Human moves
            |> clickCell { row = 0, col = 0 }  -- X
            |> clickCell { row = 1, col = 1 }  -- X  
            |> clickCell { row = 2, col = 2 }  -- X wins
            |> ProgramTest.expectModel
                (\model ->
                    case model.gameState of
                        Winner X ->
                            Expect.pass
                        _ ->
                            Expect.fail "Expected X to win"
                )
```

### 2. State Preservation Testing

Verify that state is maintained across different operations:

```elm
test "theme persists across game state changes" <|
    \() ->
        startTicTacToe ()
            |> simulateClick "dark-theme-button"
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.expectModel
                (\model ->
                    Expect.equal Dark model.colorScheme
                )
```

### 3. Error Handling Testing

Test how the application handles error conditions:

```elm
test "invalid move creates error state" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }  -- Valid move
            |> clickCell { row = 0, col = 0 }  -- Invalid move (same cell)
            |> ProgramTest.expectModel
                (\model ->
                    case model.gameState of
                        Error _ ->
                            Expect.pass
                        _ ->
                            Expect.fail "Expected error state"
                )
```

### 4. Multi-Component Integration

Test interactions between different parts of the application:

```elm
test "navigation preserves game state" <|
    \() ->
        startApp ()
            |> simulateClick "tic-tac-toe-link"
            |> clickCell { row = 0, col = 0 }
            |> simulateClick "landing-link"
            |> simulateClick "tic-tac-toe-link"
            |> ProgramTest.expectModel
                (\model ->
                    -- Verify game state was preserved
                    case getCellState model.board { row = 0, col = 0 } of
                        Just X ->
                            Expect.pass
                        _ ->
                            Expect.fail "Game state not preserved"
                )
```

## Best Practices

### 1. Use Descriptive Test Names

```elm
-- Good
test "AI responds within reasonable time for simple position"

-- Bad  
test "AI test"
```

### 2. Test One Thing at a Time

Focus each test on a single behavior or workflow:

```elm
-- Good - tests one specific interaction
test "theme toggle changes from light to dark"

-- Bad - tests multiple unrelated things
test "theme toggle and game reset and navigation"
```

### 3. Use Helper Functions

Create reusable helpers for common operations:

```elm
-- Helper function
makeWinningMoves : ProgramTest model msg effect -> ProgramTest model msg effect
makeWinningMoves programTest =
    programTest
        |> clickCell { row = 0, col = 0 }
        |> clickCell { row = 1, col = 1 }
        |> clickCell { row = 2, col = 2 }

-- Use in tests
test "winner state shows correct message" <|
    \() ->
        startTicTacToe ()
            |> makeWinningMoves
            |> ProgramTest.expectViewHas [ text "Player X wins!" ]
```

### 4. Verify Both Model and View

Test both the internal state and the UI representation:

```elm
test "move updates both model and view" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.expectModel
                (\model ->
                    case getCellState model.board { row = 0, col = 0 } of
                        Just X -> Expect.pass
                        _ -> Expect.fail "Model not updated"
                )
            |> ProgramTest.expectViewHas [ text "X" ]
```

### 5. Handle Timing-Sensitive Operations

For operations that involve delays or async behavior:

```elm
test "AI makes move after thinking" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            -- First verify thinking state
            |> ProgramTest.expectModel
                (\model ->
                    case model.gameState of
                        Thinking O -> Expect.pass
                        _ -> Expect.fail "Expected thinking state"
                )
            -- Then verify AI eventually makes a move
            |> ProgramTest.expectModel
                (\model ->
                    case model.gameState of
                        Waiting X -> Expect.pass
                        _ -> Expect.fail "Expected AI to complete move"
                )
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Element Not Found

**Error**: `ProgramTest.clickButton` fails with "element not found"

**Solution**: 
- Verify the element exists in the current view
- Check that the selector is correct
- Ensure the element is not conditionally hidden

```elm
-- Debug by checking what's in the view
|> ProgramTest.expectView
    (Test.Html.Query.has [ Test.Html.Selector.text "Expected Text" ])
```

#### 2. Model State Mismatch

**Error**: Model doesn't have expected state after interaction

**Solution**:
- Add intermediate assertions to track state changes
- Verify that the interaction actually triggers the expected message
- Check for race conditions in async operations

```elm
-- Add debugging assertions
|> ProgramTest.expectModel
    (\model ->
        let
            _ = Debug.log "Current model state" model
        in
        Expect.pass
    )
```

#### 3. Timing Issues with Async Operations

**Error**: Tests fail intermittently due to timing

**Solution**:
- Use `ProgramTest.expectModel` to wait for specific states
- Avoid hardcoded delays
- Test the intermediate states, not just the final result

```elm
-- Instead of assuming immediate completion
test "AI completes move" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            -- Test the thinking state first
            |> ProgramTest.expectModel
                (\model ->
                    case model.gameState of
                        Thinking O -> Expect.pass
                        _ -> Expect.fail "Should be thinking"
                )
```

#### 4. Web Worker Communication Issues

**Error**: Worker-related tests fail in development

**Solution**:
- Web workers require production builds to function properly
- Use `npm run build && npm run serve` for testing worker functionality
- Mock worker responses in tests when appropriate

### Debugging Tips

1. **Use Debug.log**: Add temporary logging to understand test flow
2. **Break down complex tests**: Split large tests into smaller, focused ones
3. **Check intermediate states**: Don't just test the final result
4. **Verify test setup**: Ensure the initial state is what you expect

### Performance Considerations

1. **Avoid unnecessary DOM queries**: Cache selectors when possible
2. **Use specific selectors**: More specific selectors are faster
3. **Minimize test setup**: Only set up what's needed for each test
4. **Group related tests**: Use `describe` blocks to organize tests logically

## Running Tests

### All Tests
```bash
npm run test
```

### Unit Tests Only
```bash
npm run test:unit
```

### Integration Tests Only
```bash
npm run test:integration
```

### Test Coverage Report
```bash
npm run test:coverage
```

### Watch Mode
```bash
npm run test:watch
```

## Further Reading

- [elm-program-test documentation](https://package.elm-lang.org/packages/avh4/elm-program-test/latest/)
- [elm-test documentation](https://package.elm-lang.org/packages/elm-explorations/test/latest/)
- [Testing best practices in Elm](https://guide.elm-lang.org/effects/testing.html)
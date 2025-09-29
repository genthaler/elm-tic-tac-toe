---
inclusion: fileMatch
fileMatchPattern: '*IntegrationTest.elm'
---

# elm-program-test Integration Testing Guide

This guide covers how to use elm-program-test for integration testing in this Elm project. elm-program-test allows you to test complete user workflows by simulating user interactions and verifying application behavior.

## Overview

elm-program-test enables end-to-end testing of Elm applications by:
- Simulating user interactions (clicks, keyboard input, etc.)
- Testing complete workflows across multiple components
- Verifying application state changes
- Testing navigation and routing
- Validating UI rendering and behavior

### Test Categories

Our test suite is organized into two main categories:

- **Unit Tests** (745 tests): Test individual functions and modules in isolation - files end with `UnitTest.elm`
- **Integration Tests** (220 tests): Test complete user workflows and component interactions - files end with `IntegrationTest.elm`

## Test Structure

Tests are organized by feature area with clear naming conventions:

```
tests/
├── Integration/                    # Application-level integration tests
│   ├── NavigationFlowIntegrationTest.elm
│   └── StatePreservationIntegrationTest.elm
├── TicTacToe/                     # TicTacToe game tests
│   ├── TicTacToeUnitTest.elm      # Unit tests for core logic
│   ├── ModelUnitTest.elm          # Unit tests for model functions
│   ├── ViewUnitTest.elm           # Unit tests for view functions
│   └── TicTacToeIntegrationTest.elm        # Consolidated integration tests
├── RobotGame/                     # Robot game tests
│   ├── RobotGameUnitTest.elm      # Unit tests for core logic
│   ├── ModelUnitTest.elm          # Unit tests for model functions
│   ├── ViewUnitTest.elm           # Unit tests for view functions
│   ├── AnimationIntegrationTest.elm        # Integration tests
│   ├── MovementIntegrationTest.elm         # Integration tests
│   └── UserInputIntegrationTest.elm        # Integration tests
├── GameTheory/                    # Algorithm unit tests
│   ├── AdversarialEagerUnitTest.elm
│   └── ExtendedOrderUnitTest.elm
├── Theme/                         # Theme system unit tests
│   ├── ThemeUnitTest.elm
│   └── ResponsiveUnitTest.elm
├── RouteUnitTest.elm              # Hash routing unit tests
├── NavigationFlowIntegrationTest.elm # Navigation flow and hash routing integration tests
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

## Best Practices

### 1. Test User Behavior, Not Implementation

**Good**: Test what the user experiences
```elm
test "user can complete a game and see the winner" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            |> clickCell { row = 1, col = 1 }
            |> clickCell { row = 2, col = 2 }
            |> ProgramTest.expectViewHas [ text "Player X wins!" ]
```

**Bad**: Test internal implementation details
```elm
test "updateGameState function is called with correct parameters" <|
    \() ->
        -- This tests implementation, not user experience
        startTicTacToe ()
            |> ProgramTest.expectModel
                (\model ->
                    Expect.equal 0 model.updateGameStateCallCount
                )
```

### 2. One Behavior Per Test

Focus each test on a single user behavior or workflow:

```elm
-- Good - tests one specific interaction
test "theme toggle changes from light to dark"

-- Bad - tests multiple unrelated things
test "theme toggle and game reset and navigation"
```

### 3. Use Descriptive Test Names

```elm
-- Good
test "AI responds within reasonable time for simple position"

-- Bad  
test "AI test"
```

### 4. Test Both Model and View

Verify that changes are reflected in both state and UI:

```elm
test "theme change updates both model and appearance" <|
    \() ->
        startApp ()
            |> ProgramTest.clickButton "theme-toggle"
            -- Test view rendering shows dark theme
            |> ProgramTest.expectViewHas 
                [ Test.Html.Selector.class "dark-theme" ]
            -- Test that dark theme elements are visible
            |> ProgramTest.expectView
                (Test.Html.Query.find [ Test.Html.Selector.class "theme-indicator" ]
                    >> Test.Html.Query.has [ Test.Html.Selector.text "Dark Mode" ]
                )
```

### 5. Handle Async Operations Properly

For operations involving web workers or other async behavior:

```elm
test "AI move completes after human move" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            -- First verify the thinking state is visible
            |> ProgramTest.expectViewHas [ text "Player O is thinking..." ]
```

## Common Test Patterns

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
            |> ProgramTest.expectViewHas [ text "Player X wins!" ]
```

### 2. Navigation Testing

```elm
test "user can navigate between pages" <|
    \() ->
        startApp ()
            |> simulateClick "tic-tac-toe-link"
            |> expectRoute TicTacToeRoute
            |> ProgramTest.expectViewHas [ text "Tic-Tac-Toe" ]
```

### 3. State Preservation Testing

Verify that state is maintained across different operations:

```elm
test "theme persists across game state changes" <|
    \() ->
        startTicTacToe ()
            |> simulateClick "dark-theme-button"
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.expectViewHas [ Test.Html.Selector.class "dark-theme" ]
```

### 4. Error Handling Testing

Test how the application handles error conditions:

```elm
test "invalid move creates error state" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }  -- Valid move
            |> clickCell { row = 0, col = 0 }  -- Invalid move (same cell)
            |> ProgramTest.expectViewHas [ text "Invalid move - cell already occupied" ]
```

### 5. Keyboard Input Testing

```elm
test "user can control robot with arrow keys" <|
    \() ->
        startRobotGame ()
            |> simulateKeyPress "ArrowUp"
            |> ProgramTest.expectView
                (Test.Html.Query.find [ Test.Html.Selector.class "robot" ]
                    >> Test.Html.Query.has [ Test.Html.Selector.class "facing-north" ]
                )
```

## Helper Function Examples

### Domain-Specific Helpers

Build helpers that match your domain language:

```elm
-- Game-specific helpers
expectPlayerTurn : Player -> ProgramTest model msg effect -> ProgramTest model msg effect
expectPlayerTurn player programTest =
    programTest
        |> ProgramTest.expectViewHas 
            [ text ("Player " ++ playerToString player ++ "'s turn") ]

expectGameWinner : Player -> ProgramTest model msg effect -> ProgramTest model msg effect
expectGameWinner winner programTest =
    programTest
        |> ProgramTest.expectViewHas 
            [ text ("Player " ++ playerToString winner ++ " wins!") ]

-- Robot game helpers
expectRobotAt : Position -> ProgramTest model msg effect -> ProgramTest model msg effect
expectRobotAt position programTest =
    programTest
        |> ProgramTest.expectView
            (Test.Html.Query.find [ Test.Html.Selector.class "robot" ]
                >> Test.Html.Query.has 
                    [ Test.Html.Selector.attribute "data-position" 
                        (String.fromInt position.row ++ "," ++ String.fromInt position.col)
                    ]
            )
```

### Workflow Helpers

```elm
-- Helper for setting up a near-win scenario
setupNearWin : Player -> ProgramTest model msg effect -> ProgramTest model msg effect
setupNearWin player programTest =
    case player of
        X ->
            programTest
                |> clickCell { row = 0, col = 0 }  -- X
                |> clickCell { row = 1, col = 1 }  -- X
                -- Now X can win with { row = 2, col = 2 }
        
        O ->
            programTest
                |> clickCell { row = 0, col = 1 }  -- Force AI to play
                |> clickCell { row = 1, col = 0 }  -- Force AI to play
                -- AI (O) should now be in near-win position

-- Usage
test "AI blocks human winning move" <|
    \() ->
        startTicTacToe ()
            |> setupNearWin X
            |> clickCell { row = 2, col = 2 }  -- Human tries to win
            |> ProgramTest.expectViewHas [ text "Player X wins!" ]
```

## Web Worker Considerations

### Production Build Required

Web worker functionality **cannot be tested** using development servers. Development mode compilation removes the DOM nodes and worker compilation needed for proper web worker functionality.

**Correct Testing Procedure:**

1. **Build for production**: `npm run build`
2. **Serve the built files**: `npm run serve`
3. **Test in browser**: Navigate to `http://localhost:3000`

### Mock Worker Responses in Tests

For deterministic testing, mock worker behavior:

```elm
-- Create test helper that mocks worker behavior
startTicTacToeWithMockWorker : () -> ProgramTest Model Msg (Cmd Msg)
startTicTacToeWithMockWorker _ =
    ProgramTest.createElement
        { init = init
        , update = updateWithMockWorker  -- Use mock update function
        , view = view
        }
        |> ProgramTest.start ()

updateWithMockWorker : Msg -> Model -> ( Model, Cmd Msg )
updateWithMockWorker msg model =
    case msg of
        HumanMove position ->
            -- Immediately simulate AI response instead of using worker
            let
                ( modelAfterHuman, _ ) = update msg model
                aiMove = findBestMove modelAfterHuman.board O
            in
            case aiMove of
                Just move ->
                    update (AIMove move) modelAfterHuman
                Nothing ->
                    ( modelAfterHuman, Cmd.none )
        
        _ ->
            update msg model
```

## Performance Considerations

### 1. Minimize Test Setup

Only set up what's necessary for each test:

```elm
-- Good: Minimal setup
test "theme toggle works" <|
    \() ->
        startApp ()  -- Simple startup
            |> ProgramTest.clickButton "theme-toggle"
            |> ProgramTest.expectViewHas [ Test.Html.Selector.class "dark-theme" ]
```

### 2. Use Efficient Selectors

Prefer specific selectors over broad searches:

```elm
-- Good: Specific selector
|> ProgramTest.expectView
    (Test.Html.Query.find [ Test.Html.Selector.id "game-status" ]
        >> Test.Html.Query.has [ Test.Html.Selector.text "Player X's turn" ]
    )

-- Bad: Broad search
|> ProgramTest.expectViewHas [ text "Player X's turn" ]  -- Searches entire DOM
```

### 3. Group Related Tests

Use `describe` blocks to share setup when appropriate:

```elm
describe "Theme persistence tests"
    (let
        appWithDarkTheme =
            startApp ()
                |> ProgramTest.clickButton "theme-toggle"
     in
     [ test "persists on tic-tac-toe page" <|
        \() ->
            appWithDarkTheme
                |> ProgramTest.clickLink "tic-tac-toe-link"
                |> ProgramTest.expectViewHas [ Test.Html.Selector.class "dark-theme" ]
     
     , test "persists on robot game page" <|
        \() ->
            appWithDarkTheme
                |> ProgramTest.clickLink "robot-game-link"
                |> ProgramTest.expectViewHas [ Test.Html.Selector.class "dark-theme" ]
     ]
    )
```

## Common Anti-Patterns to Avoid

### 1. Testing Implementation Details

**Avoid**: Testing internal function calls or data structures
```elm
-- Bad: Tests internal implementation
test "updateBoard function is called" <|
    \() ->
        startTicTacToe ()
            |> ProgramTest.expectModel
                (\model ->
                    Expect.equal 1 model.updateBoardCallCount
                )
```

**Instead**: Test user-observable behavior
```elm
-- Good: Tests user experience
test "clicking cell places player symbol" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.expectViewHas [ text "X" ]
```

### 2. Testing Multiple Behaviors in One Test

**Avoid**: Combining unrelated test scenarios
```elm
-- Bad: Multiple unrelated behaviors
test "game features work" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }  -- Test moves
            |> ProgramTest.clickButton "theme-toggle"  -- Test themes
            |> ProgramTest.clickButton "reset-game"  -- Test reset
```

**Instead**: One behavior per test
```elm
-- Good: Focused tests
test "user can make moves" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.expectViewHas [ text "X" ]

test "user can toggle theme" <|
    \() ->
        startTicTacToe ()
            |> ProgramTest.clickButton "theme-toggle"
            |> ProgramTest.expectViewHas [ Test.Html.Selector.class "dark-theme" ]
```

### 3. Ignoring Async Behavior

**Avoid**: Assuming immediate completion of async operations
```elm
-- Bad: Assumes AI move completes immediately
test "AI responds to human move" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.expectViewHas [ text "Player X's turn" ]  -- May not be true immediately
```

**Instead**: Test intermediate states and eventual outcomes
```elm
-- Good: Handles async properly
test "AI responds to human move" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.expectViewHas [ text "Player O is thinking..." ]  -- Immediate state
```

## Running Tests

### All Tests
```bash
npm run test
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

By following these patterns and best practices, your integration tests will be more reliable, maintainable, and valuable for ensuring your application works correctly from the user's perspective.
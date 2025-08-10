# elm-program-test Best Practices

This guide outlines best practices for writing maintainable, reliable, and effective integration tests using elm-program-test.

## Table of Contents

1. [Test Design Principles](#test-design-principles)
2. [Test Organization](#test-organization)
3. [Writing Effective Tests](#writing-effective-tests)
4. [Helper Functions and Utilities](#helper-functions-and-utilities)
5. [Performance Considerations](#performance-considerations)
6. [Maintenance and Debugging](#maintenance-and-debugging)
7. [Common Anti-Patterns](#common-anti-patterns)

## Test Design Principles

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

**Good**: Focus on a single user behavior
```elm
test "theme toggle changes from light to dark" <|
    \() ->
        startApp ()
            |> ProgramTest.clickButton "theme-toggle"
            |> ProgramTest.expectModel (\model -> Expect.equal Dark model.colorScheme)

test "theme persists across navigation" <|
    \() ->
        startApp ()
            |> ProgramTest.clickButton "theme-toggle"
            |> ProgramTest.clickLink "tic-tac-toe-link"
            |> ProgramTest.expectModel (\model -> Expect.equal Dark model.colorScheme)
```

**Bad**: Test multiple unrelated behaviors
```elm
test "theme and navigation and game logic all work" <|
    \() ->
        startApp ()
            |> ProgramTest.clickButton "theme-toggle"
            |> ProgramTest.clickLink "tic-tac-toe-link"
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.clickButton "reset-game"
            -- Too many different behaviors in one test
```

### 3. Test the Happy Path and Edge Cases

Always include both successful workflows and error conditions:

```elm
describe "Game move validation"
    [ test "valid move is accepted" <|
        \() ->
            startTicTacToe ()
                |> clickCell { row = 0, col = 0 }
                |> ProgramTest.expectModel
                    (\model ->
                        case getCellState model.board { row = 0, col = 0 } of
                            Just X -> Expect.pass
                            _ -> Expect.fail "Valid move should be accepted"
                    )
    
    , test "invalid move on occupied cell shows error" <|
        \() ->
            startTicTacToe ()
                |> clickCell { row = 0, col = 0 }  -- Valid move
                |> clickCell { row = 0, col = 0 }  -- Invalid move
                |> ProgramTest.expectViewHas [ text "Cell already occupied" ]
    ]
```

## Test Organization

### 1. Logical Grouping

Organize tests by feature area and user workflow:

```elm
-- Good structure
describe "TicTacToe Game Flow"
    [ describe "Basic gameplay"
        [ test "human can make first move"
        , test "AI responds to human move"
        , test "game alternates between players"
        ]
    
    , describe "Game ending scenarios"
        [ test "human wins with three in a row"
        , test "AI wins when human makes mistake"
        , test "game ends in draw when board is full"
        ]
    
    , describe "Error handling"
        [ test "invalid move shows error message"
        , test "error recovery allows continued play"
        ]
    ]
```

### 2. Consistent Naming Conventions

Use descriptive, consistent test names:

```elm
-- Good: Describes user action and expected outcome
test "clicking reset button clears game board"
test "pressing arrow key rotates robot to face direction"
test "navigating to game page preserves theme setting"

-- Bad: Vague or implementation-focused
test "reset works"
test "arrow key test"
test "navigation test"
```

### 3. Shared Setup and Helpers

Create reusable setup functions for common scenarios:

```elm
-- Helper for common game states
startGameWithMoves : List Position -> ProgramTest Model Msg (Cmd Msg)
startGameWithMoves moves =
    List.foldl clickCell (startTicTacToe ()) moves

-- Helper for near-win scenarios
setupNearWinScenario : Player -> ProgramTest Model Msg (Cmd Msg)
setupNearWinScenario player =
    case player of
        X ->
            startTicTacToe ()
                |> clickCell { row = 0, col = 0 }
                |> clickCell { row = 1, col = 1 }
        O ->
            -- Setup where O is about to win
            startGameWithMoves 
                [ { row = 0, col = 1 }
                , { row = 1, col = 0 }
                ]
```

## Writing Effective Tests

### 1. Use Descriptive Assertions

Make test failures informative:

```elm
-- Good: Clear failure message
|> ProgramTest.expectModel
    (\model ->
        case model.gameState of
            Winner X ->
                Expect.pass
            other ->
                Expect.fail ("Expected Winner X, but got " ++ Debug.toString other)
    )

-- Bad: Unclear failure
|> ProgramTest.expectModel
    (\model ->
        Expect.equal (Winner X) model.gameState
    )
```

### 2. Test Both Model and View

Verify that changes are reflected in both state and UI:

```elm
test "theme change updates both model and appearance" <|
    \() ->
        startApp ()
            |> ProgramTest.clickButton "theme-toggle"
            -- Test model state
            |> ProgramTest.expectModel
                (\model ->
                    Expect.equal Dark model.colorScheme
                )
            -- Test view rendering
            |> ProgramTest.expectViewHas 
                [ Test.Html.Selector.class "dark-theme" ]
```

### 3. Handle Async Operations Properly

For operations involving web workers or other async behavior:

```elm
test "AI move completes after human move" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            -- First verify the thinking state
            |> ProgramTest.expectModel
                (\model ->
                    case model.gameState of
                        Thinking O ->
                            Expect.pass
                        other ->
                            Expect.fail ("Expected Thinking O, got " ++ Debug.toString other)
                )
            -- Don't assume immediate completion - test the eventual state
            |> ProgramTest.expectModel
                (\model ->
                    case model.gameState of
                        Waiting X ->
                            Expect.pass
                        Thinking O ->
                            Expect.pass  -- Still processing is acceptable
                        other ->
                            Expect.fail ("Unexpected state: " ++ Debug.toString other)
                )
```

### 4. Use Intermediate Assertions

For complex workflows, verify intermediate states:

```elm
test "complete navigation workflow" <|
    \() ->
        startApp ()
            -- Step 1: Navigate to game
            |> ProgramTest.clickLink "tic-tac-toe-link"
            |> expectRoute TicTacToeRoute
            |> ProgramTest.expectViewHas [ text "Tic-Tac-Toe" ]
            
            -- Step 2: Make a move
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.expectModel
                (\model ->
                    case getCellState model.board { row = 0, col = 0 } of
                        Just X -> Expect.pass
                        _ -> Expect.fail "Move should be recorded"
                )
            
            -- Step 3: Navigate away and back
            |> ProgramTest.clickLink "landing-link"
            |> expectRoute LandingRoute
            |> ProgramTest.clickLink "tic-tac-toe-link"
            
            -- Step 4: Verify state persistence
            |> ProgramTest.expectModel
                (\model ->
                    case getCellState model.board { row = 0, col = 0 } of
                        Just X -> Expect.pass
                        _ -> Expect.fail "State should persist across navigation"
                )
```

## Helper Functions and Utilities

### 1. Create Domain-Specific Helpers

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
        |> ProgramTest.expectModel
            (\model ->
                case model.gameState of
                    Winner w ->
                        if w == winner then
                            Expect.pass
                        else
                            Expect.fail ("Expected " ++ playerToString winner ++ " to win")
                    other ->
                        Expect.fail ("Expected winner, got " ++ Debug.toString other)
            )

-- Robot game helpers
expectRobotAt : Position -> ProgramTest model msg effect -> ProgramTest model msg effect
expectRobotAt position programTest =
    programTest
        |> ProgramTest.expectModel
            (\model ->
                Expect.equal position model.robot.position
            )

expectRobotFacing : Direction -> ProgramTest model msg effect -> ProgramTest model msg effect
expectRobotFacing direction programTest =
    programTest
        |> ProgramTest.expectModel
            (\model ->
                Expect.equal direction model.robot.facing
            )
```

### 2. Compose Helpers for Complex Scenarios

```elm
-- Compose simple helpers into complex scenarios
makeWinningSequence : Player -> ProgramTest model msg effect -> ProgramTest model msg effect
makeWinningSequence player programTest =
    case player of
        X ->
            programTest
                |> clickCell { row = 0, col = 0 }
                |> clickCell { row = 1, col = 1 }
                |> clickCell { row = 2, col = 2 }
                |> expectGameWinner X
        
        O ->
            -- Let AI win by setting up the right scenario
            programTest
                |> clickCell { row = 0, col = 1 }  -- Force specific AI response
                |> clickCell { row = 1, col = 0 }  -- Continue pattern
                |> expectGameWinner O

-- Usage
test "human can win with diagonal" <|
    \() ->
        startTicTacToe ()
            |> makeWinningSequence X
```

### 3. Error-Specific Helpers

```elm
expectErrorState : String -> ProgramTest model msg effect -> ProgramTest model msg effect
expectErrorState expectedMessage programTest =
    programTest
        |> ProgramTest.expectModel
            (\model ->
                case model.gameState of
                    Error errorInfo ->
                        if String.contains expectedMessage errorInfo.message then
                            Expect.pass
                        else
                            Expect.fail ("Expected error containing '" ++ expectedMessage ++ "', got: " ++ errorInfo.message)
                    other ->
                        Expect.fail ("Expected error state, got " ++ Debug.toString other)
            )

expectErrorRecovery : ProgramTest model msg effect -> ProgramTest model msg effect
expectErrorRecovery programTest =
    programTest
        |> ProgramTest.clickButton "dismiss-error"
        |> ProgramTest.expectModel
            (\model ->
                case model.gameState of
                    Error _ ->
                        Expect.fail "Error should be dismissed"
                    _ ->
                        Expect.pass
            )
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
            |> ProgramTest.expectModel (\model -> Expect.equal Dark model.colorScheme)

-- Bad: Unnecessary complex setup
test "theme toggle works" <|
    \() ->
        startApp ()
            |> ProgramTest.clickLink "tic-tac-toe-link"
            |> clickCell { row = 0, col = 0 }
            |> clickCell { row = 1, col = 1 }
            |> ProgramTest.clickLink "landing-link"
            |> ProgramTest.clickButton "theme-toggle"  -- Finally test what we care about
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
                |> ProgramTest.expectModel (\model -> Expect.equal Dark model.colorScheme)
     
     , test "persists on robot game page" <|
        \() ->
            appWithDarkTheme
                |> ProgramTest.clickLink "robot-game-link"
                |> ProgramTest.expectModel (\model -> Expect.equal Dark model.colorScheme)
     ]
    )
```

## Maintenance and Debugging

### 1. Write Self-Documenting Tests

Tests should be readable without additional documentation:

```elm
-- Good: Self-explanatory
test "user can recover from invalid move error by clicking dismiss button" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }  -- Valid move
            |> clickCell { row = 0, col = 0 }  -- Invalid move (same cell)
            |> ProgramTest.expectViewHas [ text "Invalid move" ]
            |> ProgramTest.clickButton "dismiss-error"
            |> ProgramTest.expectModel
                (\model ->
                    case model.gameState of
                        Waiting X -> Expect.pass
                        _ -> Expect.fail "Should return to waiting state"
                )
```

### 2. Add Debug Information to Failures

Include context in failure messages:

```elm
expectBoardState : List (Position, Maybe Player) -> ProgramTest model msg effect -> ProgramTest model msg effect
expectBoardState expectedCells programTest =
    programTest
        |> ProgramTest.expectModel
            (\model ->
                let
                    failures =
                        expectedCells
                            |> List.filterMap (\(pos, expectedPlayer) ->
                                let
                                    actualPlayer = getCellState model.board pos
                                in
                                if actualPlayer == expectedPlayer then
                                    Nothing
                                else
                                    Just ("Position " ++ Debug.toString pos ++ 
                                          ": expected " ++ Debug.toString expectedPlayer ++ 
                                          ", got " ++ Debug.toString actualPlayer)
                            )
                in
                if List.isEmpty failures then
                    Expect.pass
                else
                    Expect.fail ("Board state mismatch: " ++ String.join "; " failures)
            )
```

### 3. Use Consistent Error Handling

Establish patterns for handling different types of test failures:

```elm
-- Standard pattern for state assertions
expectGameState : GameState -> String -> ProgramTest model msg effect -> ProgramTest model msg effect
expectGameState expectedState context programTest =
    programTest
        |> ProgramTest.expectModel
            (\model ->
                if model.gameState == expectedState then
                    Expect.pass
                else
                    Expect.fail (context ++ ": expected " ++ Debug.toString expectedState ++ 
                                ", got " ++ Debug.toString model.gameState)
            )

-- Usage with context
test "AI responds after human move" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            |> expectGameState (Thinking O) "After human move"
```

## Common Anti-Patterns

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

### 2. Overly Complex Test Setup

**Avoid**: Complex setup that obscures the test purpose
```elm
-- Bad: Complex, unclear setup
test "theme works" <|
    \() ->
        startApp ()
            |> ProgramTest.clickLink "tic-tac-toe-link"
            |> clickCell { row = 0, col = 0 }
            |> clickCell { row = 1, col = 1 }
            |> ProgramTest.clickLink "robot-game-link"
            |> simulateKeyPress "ArrowUp"
            |> ProgramTest.clickLink "landing-link"
            |> ProgramTest.clickButton "theme-toggle"  -- Finally the actual test
```

**Instead**: Minimal, focused setup
```elm
-- Good: Clear, minimal setup
test "theme toggle changes color scheme" <|
    \() ->
        startApp ()
            |> ProgramTest.clickButton "theme-toggle"
            |> ProgramTest.expectModel (\model -> Expect.equal Dark model.colorScheme)
```

### 3. Testing Multiple Behaviors in One Test

**Avoid**: Combining unrelated test scenarios
```elm
-- Bad: Multiple unrelated behaviors
test "game features work" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }  -- Test moves
            |> ProgramTest.clickButton "theme-toggle"  -- Test themes
            |> ProgramTest.clickButton "reset-game"  -- Test reset
            |> simulateKeyPress "Escape"  -- Test keyboard
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
            |> ProgramTest.expectModel (\model -> Expect.equal Dark model.colorScheme)
```

### 4. Ignoring Async Behavior

**Avoid**: Assuming immediate completion of async operations
```elm
-- Bad: Assumes AI move completes immediately
test "AI responds to human move" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.expectModel
                (\model ->
                    case model.gameState of
                        Waiting X -> Expect.pass  -- May not be true immediately
                        _ -> Expect.fail "AI should have responded"
                )
```

**Instead**: Test intermediate states and eventual outcomes
```elm
-- Good: Handles async properly
test "AI responds to human move" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.expectModel
                (\model ->
                    case model.gameState of
                        Thinking O -> Expect.pass  -- Immediate state
                        _ -> Expect.fail "AI should start thinking"
                )
            -- Test eventual completion separately if needed
```

By following these best practices, your integration tests will be more reliable, maintainable, and valuable for ensuring your application works correctly from the user's perspective.
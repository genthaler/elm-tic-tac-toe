# elm-program-test Examples

This document provides practical examples of common integration test patterns using elm-program-test. Each example includes explanations and best practices.

## Table of Contents

1. [Basic Test Structure](#basic-test-structure)
2. [User Interaction Testing](#user-interaction-testing)
3. [Navigation and Routing](#navigation-and-routing)
4. [State Management](#state-management)
5. [Async Operations](#async-operations)
6. [Error Handling](#error-handling)
7. [Theme and UI Testing](#theme-and-ui-testing)
8. [Complete Workflow Testing](#complete-workflow-testing)

## Basic Test Structure

### Simple Click Test

```elm
module Examples.BasicClickTest exposing (suite)

import Expect
import ProgramTest
import Test exposing (Test, describe, test)
import TestUtils.ProgramTestHelpers exposing (startTicTacToe, clickCell)
import TicTacToe.Model exposing (GameState(..), Player(..))

suite : Test
suite =
    describe "Basic Click Tests"
        [ test "clicking empty cell places X" <|
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
        ]
```

### View Assertion Test

```elm
test "game status displays current player" <|
    \() ->
        startTicTacToe ()
            |> ProgramTest.expectViewHas [ text "Player X's turn" ]
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.expectViewHas [ text "Player O is thinking..." ]
```

## User Interaction Testing

### Keyboard Input

```elm
module Examples.KeyboardTest exposing (suite)

import Test exposing (Test, describe, test)
import TestUtils.ProgramTestHelpers exposing (startRobotGame, simulateKeyPress)
import RobotGame.Model exposing (Direction(..))

suite : Test
suite =
    describe "Keyboard Input Tests"
        [ test "arrow up rotates robot to face north" <|
            \() ->
                startRobotGame ()
                    |> simulateKeyPress "ArrowUp"
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.equal North model.robot.facing
                        )
        
        , test "arrow down rotates robot to face south" <|
            \() ->
                startRobotGame ()
                    |> simulateKeyPress "ArrowDown"
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.equal South model.robot.facing
                        )
        
        , test "space key moves robot forward" <|
            \() ->
                startRobotGame ()
                    |> simulateKeyPress "ArrowUp"  -- Face north first
                    |> simulateKeyPress " "        -- Move forward
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.equal { row = 1, col = 2 } model.robot.position
                        )
        ]
```

### Button Interactions

```elm
test "reset button clears game state" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }  -- Make a move
            |> clickCell { row = 1, col = 1 }  -- Make another move
            |> ProgramTest.clickButton "reset-game"
            |> ProgramTest.expectModel
                (\model ->
                    Expect.equal (createEmptyBoard ()) model.board
                )
            |> ProgramTest.expectViewHas [ text "Player X's turn" ]
```

### Form Input

```elm
test "theme selector changes color scheme" <|
    \() ->
        startApp ()
            |> ProgramTest.fillIn "theme-selector" "Dark"
            |> ProgramTest.expectModel
                (\model ->
                    Expect.equal Dark model.colorScheme
                )
```

## Navigation and Routing

### Page Navigation

```elm
module Examples.NavigationTest exposing (suite)

import Test exposing (Test, describe, test)
import TestUtils.ProgramTestHelpers exposing (startApp, expectRoute)
import Route exposing (Route(..))

suite : Test
suite =
    describe "Navigation Tests"
        [ test "clicking tic-tac-toe link navigates to game" <|
            \() ->
                startApp ()
                    |> ProgramTest.clickLink "tic-tac-toe-link"
                    |> expectRoute TicTacToeRoute
                    |> ProgramTest.expectViewHas [ text "Tic-Tac-Toe Game" ]
        
        , test "browser back button returns to previous page" <|
            \() ->
                startApp ()
                    |> ProgramTest.clickLink "tic-tac-toe-link"
                    |> expectRoute TicTacToeRoute
                    |> ProgramTest.clickLink "robot-game-link"
                    |> expectRoute RobotGameRoute
                    |> ProgramTest.simulateBrowserBack
                    |> expectRoute TicTacToeRoute
        
        , test "direct URL navigation works" <|
            \() ->
                startApp ()
                    |> ProgramTest.routeChange "/robot-game"
                    |> expectRoute RobotGameRoute
                    |> ProgramTest.expectViewHas [ text "Robot Game" ]
        ]
```

### Deep Linking

```elm
test "deep link to game preserves URL structure" <|
    \() ->
        startApp ()
            |> ProgramTest.routeChange "/tic-tac-toe"
            |> expectRoute TicTacToeRoute
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.expectUrl "/tic-tac-toe"  -- URL should remain consistent
```

## State Management

### State Persistence

```elm
module Examples.StatePersistenceTest exposing (suite)

import Test exposing (Test, describe, test)

suite : Test
suite =
    describe "State Persistence Tests"
        [ test "game state persists across navigation" <|
            \() ->
                startApp ()
                    |> ProgramTest.clickLink "tic-tac-toe-link"
                    |> clickCell { row = 0, col = 0 }  -- Make a move
                    |> ProgramTest.clickLink "landing-link"  -- Navigate away
                    |> ProgramTest.clickLink "tic-tac-toe-link"  -- Navigate back
                    |> ProgramTest.expectModel
                        (\model ->
                            case getCellState model.board { row = 0, col = 0 } of
                                Just X ->
                                    Expect.pass
                                _ ->
                                    Expect.fail "Game state should persist"
                        )
        
        , test "theme preference persists across pages" <|
            \() ->
                startApp ()
                    |> ProgramTest.clickButton "dark-theme-toggle"
                    |> ProgramTest.clickLink "tic-tac-toe-link"
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.equal Dark model.colorScheme
                        )
                    |> ProgramTest.clickLink "robot-game-link"
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.equal Dark model.colorScheme
                        )
        ]
```

### State Transitions

```elm
test "game state transitions correctly" <|
    \() ->
        startTicTacToe ()
            -- Initial state
            |> ProgramTest.expectModel
                (\model ->
                    Expect.equal (Waiting X) model.gameState
                )
            -- After human move
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.expectModel
                (\model ->
                    Expect.equal (Thinking O) model.gameState
                )
            -- After AI move (eventually)
            |> ProgramTest.expectModel
                (\model ->
                    case model.gameState of
                        Waiting X ->
                            Expect.pass
                        Thinking O ->
                            Expect.pass  -- Still thinking is OK
                        _ ->
                            Expect.fail "Unexpected game state"
                )
```

## Async Operations

### Web Worker Communication

```elm
module Examples.AsyncTest exposing (suite)

import Test exposing (Test, describe, test)

suite : Test
suite =
    describe "Async Operation Tests"
        [ test "AI responds after human move" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 0, col = 0 }
                    -- First verify thinking state
                    |> ProgramTest.expectModel
                        (\model ->
                            case model.gameState of
                                Thinking O ->
                                    Expect.pass
                                _ ->
                                    Expect.fail "AI should be thinking"
                        )
                    -- Then verify AI eventually responds
                    |> ProgramTest.expectModel
                        (\model ->
                            case model.gameState of
                                Waiting X ->
                                    Expect.pass
                                Thinking O ->
                                    Expect.pass  -- Still processing is OK
                                _ ->
                                    Expect.fail "Unexpected state after AI move"
                        )
        ]
```

### Timeout Handling

```elm
test "timeout triggers auto-play" <|
    \() ->
        startTicTacToe ()
            |> ProgramTest.advanceTime 5000  -- Advance past timeout threshold
            |> ProgramTest.expectModel
                (\model ->
                    -- Should have made an auto-play move
                    let
                        occupiedCells = countOccupiedCells model.board
                    in
                    if occupiedCells > 0 then
                        Expect.pass
                    else
                        Expect.fail "Auto-play should have made a move"
                )
```

### Animation States

```elm
test "robot animation completes before next move" <|
    \() ->
        startRobotGame ()
            |> simulateKeyPress " "  -- Move forward
            |> ProgramTest.expectModel
                (\model ->
                    case model.animationState of
                        Moving _ ->
                            Expect.pass
                        _ ->
                            Expect.fail "Should be animating"
                )
            |> ProgramTest.advanceTime 500  -- Wait for animation
            |> ProgramTest.expectModel
                (\model ->
                    case model.animationState of
                        Idle ->
                            Expect.pass
                        _ ->
                            Expect.fail "Animation should complete"
                )
```

## Error Handling

### Invalid Input Handling

```elm
module Examples.ErrorHandlingTest exposing (suite)

import Test exposing (Test, describe, test)

suite : Test
suite =
    describe "Error Handling Tests"
        [ test "clicking occupied cell creates error" <|
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
                                    Expect.fail "Should create error state"
                        )
        
        , test "error recovery works correctly" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 0, col = 0 }
                    |> clickCell { row = 0, col = 0 }  -- Create error
                    |> ProgramTest.clickButton "reset-game"  -- Recover
                    |> ProgramTest.expectModel
                        (\model ->
                            case model.gameState of
                                Waiting X ->
                                    Expect.pass
                                _ ->
                                    Expect.fail "Should recover to initial state"
                        )
        ]
```

### Boundary Conditions

```elm
test "robot cannot move beyond grid boundaries" <|
    \() ->
        startRobotGame ()
            |> simulateKeyPress "ArrowUp"    -- Face north
            |> simulateKeyPress " "          -- Move to edge
            |> simulateKeyPress " "          -- Try to move beyond
            |> ProgramTest.expectModel
                (\model ->
                    -- Should still be at edge, not beyond
                    Expect.equal { row = 0, col = 2 } model.robot.position
                )
            |> ProgramTest.expectViewHas [ text "Cannot move further north" ]
```

### Network/Worker Failures

```elm
test "worker communication failure handling" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            -- Simulate worker failure
            |> ProgramTest.update (WorkerError "Communication failed")
            |> ProgramTest.expectModel
                (\model ->
                    case model.gameState of
                        Error errorInfo ->
                            if String.contains "Communication failed" errorInfo.message then
                                Expect.pass
                            else
                                Expect.fail "Should contain error message"
                        _ ->
                            Expect.fail "Should be in error state"
                )
```

## Theme and UI Testing

### Theme Switching

```elm
module Examples.ThemeTest exposing (suite)

import Test exposing (Test, describe, test)

suite : Test
suite =
    describe "Theme and UI Tests"
        [ test "theme toggle changes appearance" <|
            \() ->
                startTicTacToe ()
                    |> ProgramTest.expectViewHas [ Test.Html.Selector.class "light-theme" ]
                    |> ProgramTest.clickButton "theme-toggle"
                    |> ProgramTest.expectViewHas [ Test.Html.Selector.class "dark-theme" ]
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.equal Dark model.colorScheme
                        )
        
        , test "theme persists during gameplay" <|
            \() ->
                startTicTacToe ()
                    |> ProgramTest.clickButton "theme-toggle"  -- Switch to dark
                    |> clickCell { row = 0, col = 0 }          -- Make move
                    |> ProgramTest.expectViewHas [ Test.Html.Selector.class "dark-theme" ]
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.equal Dark model.colorScheme
                        )
        ]
```

### Responsive Design

```elm
test "mobile layout adapts correctly" <|
    \() ->
        startTicTacToe ()
            |> ProgramTest.update (WindowResize { width = 400, height = 600 })
            |> ProgramTest.expectViewHas [ Test.Html.Selector.class "mobile-layout" ]
            |> ProgramTest.expectModel
                (\model ->
                    case model.windowSize of
                        Just { width } ->
                            if width < 768 then
                                Expect.pass
                            else
                                Expect.fail "Should detect mobile width"
                        Nothing ->
                            Expect.fail "Window size should be set"
                )
```

### Accessibility

```elm
test "keyboard navigation works" <|
    \() ->
        startTicTacToe ()
            |> ProgramTest.simulateKeyDown "Tab"  -- Focus first cell
            |> ProgramTest.simulateKeyDown "Enter"  -- Activate cell
            |> ProgramTest.expectModel
                (\model ->
                    case getCellState model.board { row = 0, col = 0 } of
                        Just X ->
                            Expect.pass
                        _ ->
                            Expect.fail "Keyboard activation should work"
                )
```

## Complete Workflow Testing

### Full Game Scenarios

```elm
module Examples.WorkflowTest exposing (suite)

import Test exposing (Test, describe, test)

suite : Test
suite =
    describe "Complete Workflow Tests"
        [ test "complete tic-tac-toe game ending in human win" <|
            \() ->
                startTicTacToe ()
                    -- Human wins with diagonal
                    |> clickCell { row = 0, col = 0 }  -- X
                    -- AI will respond automatically
                    |> clickCell { row = 1, col = 1 }  -- X
                    -- AI will respond automatically  
                    |> clickCell { row = 2, col = 2 }  -- X wins
                    |> ProgramTest.expectModel
                        (\model ->
                            case model.gameState of
                                Winner X ->
                                    Expect.pass
                                _ ->
                                    Expect.fail "X should win"
                        )
                    |> ProgramTest.expectViewHas [ text "Player X wins!" ]
        
        , test "complete robot navigation sequence" <|
            \() ->
                startRobotGame ()
                    -- Navigate to top-right corner
                    |> simulateKeyPress "ArrowUp"     -- Face north
                    |> simulateKeyPress " "           -- Move north
                    |> simulateKeyPress " "           -- Move to top edge
                    |> simulateKeyPress "ArrowRight"  -- Face east
                    |> simulateKeyPress " "           -- Move east
                    |> simulateKeyPress " "           -- Move to corner
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.equal { row = 0, col = 4 } model.robot.position
                        )
                    |> ProgramTest.expectViewHas [ text "Reached corner!" ]
        ]
```

### Multi-Page Workflows

```elm
test "user journey across multiple pages" <|
    \() ->
        startApp ()
            -- Start at landing page
            |> ProgramTest.expectViewHas [ text "Welcome" ]
            -- Go to tic-tac-toe
            |> ProgramTest.clickLink "tic-tac-toe-link"
            |> clickCell { row = 0, col = 0 }
            -- Switch to robot game
            |> ProgramTest.clickLink "robot-game-link"
            |> simulateKeyPress "ArrowUp"
            -- Return to tic-tac-toe (state should persist)
            |> ProgramTest.clickLink "tic-tac-toe-link"
            |> ProgramTest.expectModel
                (\model ->
                    case getCellState model.board { row = 0, col = 0 } of
                        Just X ->
                            Expect.pass
                        _ ->
                            Expect.fail "Tic-tac-toe state should persist"
                )
```

### Error Recovery Workflows

```elm
test "complete error recovery workflow" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            |> clickCell { row = 0, col = 0 }  -- Create error
            |> ProgramTest.expectViewHas [ text "Invalid move" ]
            |> ProgramTest.clickButton "dismiss-error"
            |> ProgramTest.expectModel
                (\model ->
                    case model.gameState of
                        Waiting X ->
                            Expect.pass
                        _ ->
                            Expect.fail "Should recover to waiting state"
                )
            |> clickCell { row = 1, col = 1 }  -- Valid move should work
            |> ProgramTest.expectModel
                (\model ->
                    case getCellState model.board { row = 1, col = 1 } of
                        Just X ->
                            Expect.pass
                        _ ->
                            Expect.fail "Should accept valid move after recovery"
                )
```

## Helper Function Examples

### Custom Assertion Helpers

```elm
-- Custom helper for checking game board state
expectBoardState : List (Position, Player) -> ProgramTest model msg effect -> ProgramTest model msg effect
expectBoardState expectedPieces programTest =
    programTest
        |> ProgramTest.expectModel
            (\model ->
                let
                    actualPieces = 
                        expectedPieces
                            |> List.map (\(pos, expectedPlayer) ->
                                case getCellState model.board pos of
                                    Just actualPlayer ->
                                        if actualPlayer == expectedPlayer then
                                            Ok ()
                                        else
                                            Err ("Expected " ++ Debug.toString expectedPlayer ++ " at " ++ Debug.toString pos)
                                    Nothing ->
                                        Err ("Expected " ++ Debug.toString expectedPlayer ++ " at " ++ Debug.toString pos ++ " but cell was empty")
                            )
                    
                    errors = List.filterMap Result.toMaybe actualPieces
                in
                if List.isEmpty errors then
                    Expect.pass
                else
                    Expect.fail (String.join ", " errors)
            )

-- Usage
test "board has expected pieces" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            |> clickCell { row = 1, col = 1 }
            |> expectBoardState
                [ ({ row = 0, col = 0 }, X)
                , ({ row = 1, col = 1 }, X)
                ]
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
            |> ProgramTest.expectModel
                (\model ->
                    case model.gameState of
                        Winner X ->
                            Expect.pass
                        _ ->
                            Expect.fail "Human should win"
                )
```

These examples demonstrate the key patterns for writing effective integration tests with elm-program-test. Remember to:

1. **Test user workflows, not implementation details**
2. **Use descriptive test names that explain the behavior**
3. **Break complex workflows into logical steps**
4. **Handle async operations appropriately**
5. **Test both success and error scenarios**
6. **Create reusable helpers for common operations**
7. **Verify both model state and view rendering**
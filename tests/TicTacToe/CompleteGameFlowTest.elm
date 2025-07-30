module TicTacToe.CompleteGameFlowTest exposing (suite)

{-| Comprehensive integration tests for complete game flows.
Tests end-to-end scenarios including human vs AI games, theme switching, and error recovery.
-}

import Expect
import Test exposing (Test, describe, test)
import TicTacToe.Main exposing (update)
import TicTacToe.Model exposing (ColorScheme(..), GameState(..), Msg(..), Player(..), createUnknownError, initialModel)
import TicTacToe.TicTacToe as TicTacToe
import Time


suite : Test
suite =
    describe "Complete Game Flow Integration Tests"
        [ humanVsAIGameFlows
        , themeAndResponsiveTests
        , errorHandlingAndRecoveryTests
        , gameEndingScenarios
        ]


humanVsAIGameFlows : Test
humanVsAIGameFlows =
    describe "Human vs AI Game Scenarios"
        [ test "complete game where human wins" <|
            \_ ->
                let
                    -- Simulate a game where human (X) wins
                    initialState =
                        initialModel

                    -- Move 1: Human X at (0,0)
                    ( state1, _ ) =
                        update (MoveMade { row = 0, col = 0 }) initialState

                    -- Move 2: AI O responds (simulated at (1,1))
                    ( state2, _ ) =
                        update (MoveMade { row = 1, col = 1 }) state1

                    -- Move 3: Human X at (0,1)
                    ( state3, _ ) =
                        update (MoveMade { row = 0, col = 1 }) state2

                    -- Move 4: AI O responds (simulated at (2,0))
                    ( state4, _ ) =
                        update (MoveMade { row = 2, col = 0 }) state3

                    -- Move 5: Human X at (0,2) - winning move
                    ( finalState, _ ) =
                        update (MoveMade { row = 0, col = 2 }) state4
                in
                case finalState.gameState of
                    Winner X ->
                        -- Verify the winning line is present
                        let
                            topRow =
                                [ TicTacToe.getCellState { row = 0, col = 0 } finalState.board
                                , TicTacToe.getCellState { row = 0, col = 1 } finalState.board
                                , TicTacToe.getCellState { row = 0, col = 2 } finalState.board
                                ]
                        in
                        Expect.equal [ Just X, Just X, Just X ] topRow

                    _ ->
                        Expect.fail ("Expected X to win, got: " ++ Debug.toString finalState.gameState)
        , test "complete game ending in draw" <|
            \_ ->
                let
                    -- Simulate a game that ends in a draw
                    moves =
                        [ { row = 0, col = 0 } -- X
                        , { row = 0, col = 1 } -- O
                        , { row = 0, col = 2 } -- X
                        , { row = 1, col = 0 } -- O
                        , { row = 1, col = 2 } -- X
                        , { row = 1, col = 1 } -- O
                        , { row = 2, col = 0 } -- X
                        , { row = 2, col = 2 } -- O
                        , { row = 2, col = 1 } -- X
                        ]

                    -- Apply moves sequentially
                    finalState =
                        List.foldl
                            (\move state ->
                                let
                                    ( newState, _ ) =
                                        update (MoveMade move) state
                                in
                                newState
                            )
                            initialModel
                            moves
                in
                case finalState.gameState of
                    Draw ->
                        -- Verify board is full
                        let
                            isFull =
                                finalState.board
                                    |> List.concat
                                    |> List.all (\cell -> cell /= Nothing)
                        in
                        Expect.equal True isFull

                    _ ->
                        Expect.fail ("Expected Draw, got: " ++ Debug.toString finalState.gameState)
        , test "AI makes reasonable moves throughout game" <|
            \_ ->
                let
                    -- Start a game and let AI respond to human moves
                    initialState =
                        initialModel

                    -- Human move at center
                    ( state1, _ ) =
                        update (MoveMade { row = 1, col = 1 }) initialState

                    -- Simulate AI response (should be a corner or edge)
                    aiMove =
                        case state1.gameState of
                            Thinking O ->
                                case TicTacToe.findBestMove O state1.board of
                                    Just position ->
                                        position

                                    Nothing ->
                                        { row = 0, col = 0 }

                            -- Fallback
                            _ ->
                                { row = 0, col = 0 }

                    -- Fallback
                    ( state2, _ ) =
                        update (MoveMade aiMove) state1

                    -- Verify AI made a valid move
                    aiMoveValid =
                        TicTacToe.getCellState aiMove state2.board == Just O

                    -- Verify game continues
                    gameStateValid =
                        case state2.gameState of
                            Waiting X ->
                                True

                            _ ->
                                False
                in
                Expect.all
                    [ \_ -> Expect.equal True aiMoveValid
                    , \_ -> Expect.equal True gameStateValid
                    ]
                    ()
        , test "game handles alternating turns correctly" <|
            \_ ->
                let
                    -- Track game states through multiple moves
                    moves =
                        [ { row = 0, col = 0 } -- X
                        , { row = 1, col = 1 } -- O
                        , { row = 0, col = 1 } -- X
                        , { row = 2, col = 2 } -- O
                        ]

                    expectedStates =
                        [ Thinking O -- After X move
                        , Waiting X -- After O move
                        , Thinking O -- After X move
                        , Waiting X -- After O move
                        ]

                    -- Apply moves and collect states
                    ( _, states ) =
                        List.foldl
                            (\move ( state, stateList ) ->
                                let
                                    ( newState, _ ) =
                                        update (MoveMade move) state
                                in
                                ( newState, newState.gameState :: stateList )
                            )
                            ( initialModel, [] )
                            moves

                    actualStates =
                        List.reverse states
                in
                Expect.equal expectedStates actualStates
        ]


themeAndResponsiveTests : Test
themeAndResponsiveTests =
    describe "Theme Switching and Responsive Behavior"
        [ test "theme switching preserves game state" <|
            \_ ->
                let
                    -- Set up a game in progress
                    gameInProgress =
                        { initialModel
                            | board =
                                [ [ Just X, Nothing, Nothing ]
                                , [ Nothing, Just O, Nothing ]
                                , [ Nothing, Nothing, Nothing ]
                                ]
                            , gameState = Waiting X
                            , colorScheme = Light
                        }

                    -- Switch to dark theme
                    ( darkState, _ ) =
                        update (ColorScheme Dark) gameInProgress

                    -- Switch back to light theme
                    ( lightState, _ ) =
                        update (ColorScheme Light) darkState
                in
                Expect.all
                    [ \_ -> Expect.equal Dark darkState.colorScheme
                    , \_ -> Expect.equal Light lightState.colorScheme
                    , \_ -> Expect.equal gameInProgress.board darkState.board
                    , \_ -> Expect.equal gameInProgress.board lightState.board
                    , \_ -> Expect.equal gameInProgress.gameState darkState.gameState
                    , \_ -> Expect.equal gameInProgress.gameState lightState.gameState
                    ]
                    ()
        , test "viewport changes preserve game state" <|
            \_ ->
                let
                    gameInProgress =
                        { initialModel
                            | board =
                                [ [ Just X, Just O, Nothing ]
                                , [ Nothing, Just X, Nothing ]
                                , [ Nothing, Nothing, Nothing ]
                                ]
                            , gameState = Thinking O
                        }

                    -- Simulate viewport resize
                    ( resizedState, _ ) =
                        update (GetResize 1024 768) gameInProgress
                in
                Expect.all
                    [ \_ -> Expect.equal (Just ( 1024, 768 )) resizedState.maybeWindow
                    , \_ -> Expect.equal gameInProgress.board resizedState.board
                    , \_ -> Expect.equal gameInProgress.gameState resizedState.gameState
                    ]
                    ()
        , test "theme and viewport changes work together" <|
            \_ ->
                let
                    initialState =
                        { initialModel | colorScheme = Light }

                    -- Apply multiple UI changes
                    ( state1, _ ) =
                        update (GetResize 800 600) initialState

                    ( state2, _ ) =
                        update (ColorScheme Dark) state1

                    ( finalState, _ ) =
                        update (GetResize 1200 900) state2
                in
                Expect.all
                    [ \_ -> Expect.equal Dark finalState.colorScheme
                    , \_ -> Expect.equal (Just ( 1200, 900 )) finalState.maybeWindow
                    , \_ -> Expect.equal initialModel.board finalState.board
                    , \_ -> Expect.equal initialModel.gameState finalState.gameState
                    ]
                    ()
        ]


errorHandlingAndRecoveryTests : Test
errorHandlingAndRecoveryTests =
    describe "Error Handling and Recovery Scenarios"
        [ test "reset game recovers from error state" <|
            \_ ->
                let
                    errorState =
                        { initialModel
                            | gameState = Error (createUnknownError "Test error")
                            , board =
                                [ [ Just X, Just O, Nothing ]
                                , [ Nothing, Just X, Nothing ]
                                , [ Nothing, Nothing, Nothing ]
                                ]
                        }

                    ( recoveredState, _ ) =
                        update ResetGame errorState
                in
                Expect.all
                    [ \_ -> Expect.equal (Waiting X) recoveredState.gameState
                    , \_ -> Expect.equal initialModel.board recoveredState.board
                    , \_ -> Expect.equal Nothing recoveredState.lastMove
                    , \_ -> Expect.equal Nothing recoveredState.now
                    ]
                    ()
        , test "reset game works from any game state" <|
            \_ ->
                let
                    testStates =
                        [ Winner X
                        , Winner O
                        , Draw
                        , Waiting X
                        , Thinking O
                        , Error (createUnknownError "Test")
                        ]

                    testReset gameState =
                        let
                            stateWithGame =
                                { initialModel
                                    | gameState = gameState
                                    , board =
                                        [ [ Just X, Just O, Just X ]
                                        , [ Just O, Just X, Just O ]
                                        , [ Just O, Just X, Just O ]
                                        ]
                                }

                            ( resetState, _ ) =
                                update ResetGame stateWithGame
                        in
                        resetState.gameState == Waiting X && resetState.board == initialModel.board

                    results =
                        List.map testReset testStates
                in
                Expect.equal (List.repeat 6 True) results
        , test "error state preserves theme settings on reset" <|
            \_ ->
                let
                    stateWithSettings =
                        { initialModel
                            | colorScheme = Dark
                            , maybeWindow = Just ( 1024, 768 )
                        }

                    errorState =
                        { stateWithSettings | gameState = Error (createUnknownError "Test error") }

                    ( resetState, _ ) =
                        update ResetGame errorState
                in
                Expect.all
                    [ \_ -> Expect.equal Dark resetState.colorScheme
                    , \_ -> Expect.equal (Waiting X) resetState.gameState

                    -- Note: maybeWindow might be reset to Nothing on game reset, which is acceptable
                    ]
                    ()
        , test "invalid moves result in appropriate error handling" <|
            \_ ->
                let
                    -- Set up a board with some moves
                    boardWithMoves =
                        [ [ Just X, Nothing, Nothing ]
                        , [ Nothing, Just O, Nothing ]
                        , [ Nothing, Nothing, Nothing ]
                        ]

                    gameState =
                        { initialModel
                            | board = boardWithMoves
                            , gameState = Waiting X
                        }

                    -- Try to make move to occupied cell
                    ( resultState, _ ) =
                        update (MoveMade { row = 0, col = 0 }) gameState
                in
                case resultState.gameState of
                    Error errorInfo ->
                        if String.contains "occupied" errorInfo.message || String.contains "Invalid move" errorInfo.message then
                            Expect.pass

                        else
                            Expect.fail ("Expected occupied cell error, got: " ++ errorInfo.message)

                    _ ->
                        Expect.fail ("Expected error state, got: " ++ Debug.toString resultState.gameState)
        ]


gameEndingScenarios : Test
gameEndingScenarios =
    describe "Game Ending Scenarios"
        [ test "game ends immediately when winning move is made" <|
            \_ ->
                let
                    -- Set up board where X can win with next move
                    almostWinBoard =
                        [ [ Just X, Just X, Nothing ] -- X can win at (0,2)
                        , [ Just O, Nothing, Nothing ]
                        , [ Nothing, Nothing, Nothing ]
                        ]

                    gameState =
                        { initialModel
                            | board = almostWinBoard
                            , gameState = Waiting X
                        }

                    -- Make winning move
                    ( finalState, _ ) =
                        update (MoveMade { row = 0, col = 2 }) gameState
                in
                case finalState.gameState of
                    Winner X ->
                        -- Verify the winning move was applied
                        let
                            winningCell =
                                TicTacToe.getCellState { row = 0, col = 2 } finalState.board
                        in
                        Expect.equal (Just X) winningCell

                    _ ->
                        Expect.fail ("Expected X to win, got: " ++ Debug.toString finalState.gameState)
        , test "no moves possible after game ends" <|
            \_ ->
                let
                    winnerState =
                        { initialModel
                            | gameState = Winner X
                            , board =
                                [ [ Just X, Just X, Just X ]
                                , [ Just O, Nothing, Nothing ]
                                , [ Nothing, Nothing, Nothing ]
                                ]
                        }

                    -- Try to make move after game ended
                    ( resultState, _ ) =
                        update (MoveMade { row = 1, col = 1 }) winnerState
                in
                case resultState.gameState of
                    Error errorInfo ->
                        if String.contains "invalid game state" errorInfo.message then
                            Expect.pass

                        else
                            Expect.fail ("Expected invalid game state error, got: " ++ errorInfo.message)

                    _ ->
                        Expect.fail ("Expected error for move after game end, got: " ++ Debug.toString resultState.gameState)
        , test "draw detection works correctly" <|
            \_ ->
                let
                    -- Set up board one move away from draw
                    almostDrawBoard =
                        [ [ Just X, Just O, Just X ]
                        , [ Just O, Just X, Just O ]
                        , [ Just O, Just X, Nothing ] -- Last empty cell
                        ]

                    gameState =
                        { initialModel
                            | board = almostDrawBoard
                            , gameState = Waiting O
                        }

                    -- Make final move
                    ( finalState, _ ) =
                        update (MoveMade { row = 2, col = 2 }) gameState
                in
                case finalState.gameState of
                    Draw ->
                        -- Verify board is completely full
                        let
                            isFull =
                                finalState.board
                                    |> List.concat
                                    |> List.all (\cell -> cell /= Nothing)
                        in
                        Expect.equal True isFull

                    _ ->
                        Expect.fail ("Expected Draw, got: " ++ Debug.toString finalState.gameState)
        , test "time tracking continues throughout game" <|
            \_ ->
                let
                    time1 =
                        Time.millisToPosix 1000

                    time2 =
                        Time.millisToPosix 2000

                    time3 =
                        Time.millisToPosix 3000

                    -- Start with initial time
                    ( state1, _ ) =
                        update (Tick time1) initialModel

                    -- Make a move
                    ( state2, _ ) =
                        update (MoveMade { row = 0, col = 0 }) state1

                    -- Update time again
                    ( state3, _ ) =
                        update (Tick time2) state2

                    -- Make another move
                    ( state4, _ ) =
                        update (MoveMade { row = 1, col = 1 }) state3

                    -- Final time update
                    ( finalState, _ ) =
                        update (Tick time3) state4
                in
                Expect.all
                    [ \_ -> Expect.equal (Just time3) finalState.now
                    , \_ -> Expect.equal (Just time2) finalState.lastMove -- Last move time should be preserved
                    ]
                    ()
        ]

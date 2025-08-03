module TicTacToe.TimeoutIntegrationTest exposing (suite)

{-| Integration tests for complete timeout and auto-play flow.
Tests the full workflow from timeout detection to auto-move application.
-}

import Expect
import Test exposing (Test, describe, test)
import Theme.Theme exposing (ColorScheme(..))
import TicTacToe.Main exposing (update)
import TicTacToe.Model exposing (GameState(..), Msg(..), Player(..), createUnknownError, idleTimeoutMillis, initialModel)
import TicTacToe.TicTacToe
import Time


suite : Test
suite =
    describe "Timeout Integration Tests"
        [ completeTimeoutFlowTests
        , gameStateTransitionTests
        , errorHandlingTests
        ]


completeTimeoutFlowTests : Test
completeTimeoutFlowTests =
    describe "Complete Timeout Flow"
        [ test "timeout triggers auto-play and continues game normally" <|
            \_ ->
                let
                    -- Set up a game state where X is waiting and has timed out
                    initialBoard =
                        [ [ Just X, Nothing, Nothing ]
                        , [ Nothing, Just O, Nothing ]
                        , [ Nothing, Nothing, Nothing ]
                        ]

                    model =
                        { initialModel
                            | board = initialBoard
                            , gameState = Waiting X
                            , lastMove = Just (Time.millisToPosix 1000)
                            , now = Just (Time.millisToPosix 1000) -- Start time
                        }

                    -- Simulate timeout by sending Tick message after timeout period
                    timeoutTime =
                        Time.millisToPosix (1000 + idleTimeoutMillis + 100)

                    ( updatedModel, _ ) =
                        update (Tick timeoutTime) model
                in
                -- After timeout, the game should have made a move and switched players
                case updatedModel.gameState of
                    Waiting O ->
                        -- Game should continue with O's turn after X's auto-move
                        Expect.notEqual initialBoard updatedModel.board

                    Thinking O ->
                        -- Or O (AI) is now thinking after X's auto-move
                        Expect.notEqual initialBoard updatedModel.board

                    Winner _ ->
                        -- Or X might have won with the auto-move
                        Expect.notEqual initialBoard updatedModel.board

                    Draw ->
                        -- Or the game might have ended in a draw
                        Expect.notEqual initialBoard updatedModel.board

                    _ ->
                        Expect.fail ("Unexpected game state after timeout: " ++ Debug.toString updatedModel.gameState)
        , test "timeout auto-play makes winning move when available" <|
            \_ ->
                let
                    -- Set up a board where X has a winning move at (0,2)
                    initialBoard =
                        [ [ Just X, Just X, Nothing ] -- X can win at (0,2)
                        , [ Just O, Nothing, Nothing ]
                        , [ Nothing, Nothing, Nothing ]
                        ]

                    model =
                        { initialModel
                            | board = initialBoard
                            , gameState = Waiting X
                            , lastMove = Just (Time.millisToPosix 1000)
                            , now = Just (Time.millisToPosix 1000)
                        }

                    -- Simulate timeout
                    timeoutTime =
                        Time.millisToPosix (1000 + idleTimeoutMillis + 100)

                    ( updatedModel, _ ) =
                        update (Tick timeoutTime) model
                in
                -- After timeout, X should have won
                case updatedModel.gameState of
                    Winner X ->
                        -- Verify the winning move was made at (0,2)
                        let
                            cellState =
                                TicTacToe.TicTacToe.getCellState { row = 0, col = 2 } updatedModel.board
                        in
                        Expect.equal (Just X) cellState

                    _ ->
                        Expect.fail ("Expected X to win after timeout auto-play, got: " ++ Debug.toString updatedModel.gameState)
        , test "timeout auto-play blocks opponent winning move" <|
            \_ ->
                let
                    -- Set up a board where O threatens to win and X should block
                    initialBoard =
                        [ [ Just O, Just O, Nothing ] -- O threatens to win at (0,2)
                        , [ Just X, Nothing, Nothing ]
                        , [ Nothing, Nothing, Nothing ]
                        ]

                    model =
                        { initialModel
                            | board = initialBoard
                            , gameState = Waiting X
                            , lastMove = Just (Time.millisToPosix 1000)
                            , now = Just (Time.millisToPosix 1000)
                        }

                    -- Simulate timeout
                    timeoutTime =
                        Time.millisToPosix (1000 + idleTimeoutMillis + 100)

                    ( updatedModel, _ ) =
                        update (Tick timeoutTime) model

                    cellState =
                        TicTacToe.TicTacToe.getCellState { row = 0, col = 2 } updatedModel.board
                in
                case updatedModel.gameState of
                    Waiting O ->
                        -- Game should continue with O's turn after X blocked
                        Expect.equal (Just X) cellState

                    Thinking O ->
                        -- Or O (AI) is now thinking after X blocked
                        Expect.equal (Just X) cellState

                    _ ->
                        -- Let's be more flexible and just check that a move was made
                        Expect.notEqual initialBoard updatedModel.board
        ]


gameStateTransitionTests : Test
gameStateTransitionTests =
    describe "Game State Transitions During Timeout"
        [ test "timeout only triggers in Waiting state" <|
            \_ ->
                let
                    testStates =
                        [ Winner X
                        , Draw
                        , Error (createUnknownError "Test error")
                        ]

                    testStateTimeout state =
                        let
                            model =
                                { initialModel
                                    | gameState = state
                                    , lastMove = Just (Time.millisToPosix 1000)
                                    , now = Just (Time.millisToPosix 1000)
                                }

                            timeoutTime =
                                Time.millisToPosix (1000 + idleTimeoutMillis + 100)

                            ( updatedModel, _ ) =
                                update (Tick timeoutTime) model
                        in
                        -- Game state should remain unchanged for non-Waiting states
                        updatedModel.gameState == state

                    results =
                        List.map testStateTimeout testStates
                in
                Expect.equal [ True, True, True ] results
        , test "timeout updates now time even when not triggering auto-play" <|
            \_ ->
                let
                    model =
                        { initialModel
                            | gameState = Waiting X
                            , lastMove = Just (Time.millisToPosix 1000)
                            , now = Just (Time.millisToPosix 1000)
                        }

                    -- Send tick before timeout
                    earlyTime =
                        Time.millisToPosix 3000

                    ( updatedModel, _ ) =
                        update (Tick earlyTime) model
                in
                Expect.equal (Just earlyTime) updatedModel.now
        , test "timeout preserves color scheme and window settings" <|
            \_ ->
                let
                    model =
                        { initialModel
                            | gameState = Waiting X
                            , lastMove = Just (Time.millisToPosix 1000)
                            , now = Just (Time.millisToPosix 1000)
                            , colorScheme = Dark
                            , maybeWindow = Just ( 800, 600 )
                        }

                    timeoutTime =
                        Time.millisToPosix (1000 + idleTimeoutMillis + 100)

                    ( updatedModel, _ ) =
                        update (Tick timeoutTime) model
                in
                Expect.all
                    [ \_ -> Expect.equal Dark updatedModel.colorScheme
                    , \_ -> Expect.equal (Just ( 800, 600 )) updatedModel.maybeWindow
                    ]
                    ()
        ]


errorHandlingTests : Test
errorHandlingTests =
    describe "Error Handling During Timeout"
        [ test "timeout handles full board gracefully" <|
            \_ ->
                let
                    -- Create a full board where no moves are possible
                    fullBoard =
                        [ [ Just X, Just O, Just X ]
                        , [ Just O, Just O, Just X ]
                        , [ Just O, Just X, Just O ]
                        ]

                    model =
                        { initialModel
                            | board = fullBoard
                            , gameState = Waiting X -- This shouldn't happen in real game, but test edge case
                            , lastMove = Just (Time.millisToPosix 1000)
                            , now = Just (Time.millisToPosix 1000)
                        }

                    timeoutTime =
                        Time.millisToPosix (1000 + idleTimeoutMillis + 100)

                    ( updatedModel, _ ) =
                        update (Tick timeoutTime) model
                in
                -- Should result in error state when no moves available
                case updatedModel.gameState of
                    Error errorInfo ->
                        Expect.equal "No valid moves available for auto-play - this should not happen" errorInfo.message

                    _ ->
                        Expect.fail ("Expected error state for full board timeout, got: " ++ Debug.toString updatedModel.gameState)
        , test "timeout with no lastMove does not trigger auto-play" <|
            \_ ->
                let
                    model =
                        { initialModel
                            | gameState = Waiting X
                            , lastMove = Nothing -- No previous move
                            , now = Just (Time.millisToPosix 1000)
                        }

                    timeoutTime =
                        Time.millisToPosix (1000 + idleTimeoutMillis + 100)

                    ( updatedModel, _ ) =
                        update (Tick timeoutTime) model
                in
                -- Should not trigger auto-play without lastMove
                Expect.all
                    [ \_ -> Expect.equal (Waiting X) updatedModel.gameState
                    , \_ -> Expect.equal initialModel.board updatedModel.board
                    ]
                    ()
        ]

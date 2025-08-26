module TicTacToe.TimeoutUnitTest exposing (suite)

{-| Test suite for timeout and auto-play functionality.
Tests time calculations, timeout detection, and auto-play behavior.
-}

import Expect
import Test exposing (Test, describe, test)
import TicTacToe.Model exposing (Player(..), idleTimeoutMillis, initialModel, timeSpent)
import TicTacToe.TicTacToe
import Time


suite : Test
suite =
    describe "Timeout Functionality"
        [ timeCalculationTests
        , timeoutDetectionTests
        , autoPlayTests
        ]


timeCalculationTests : Test
timeCalculationTests =
    describe "Time Calculations"
        [ test "timeSpent returns full timeout when no move has been made" <|
            \_ ->
                let
                    model =
                        { initialModel
                            | lastMove = Nothing
                            , now = Just (Time.millisToPosix 5000)
                        }
                in
                Expect.equal (toFloat idleTimeoutMillis) (timeSpent model)
        , test "timeSpent returns full timeout when now is Nothing" <|
            \_ ->
                let
                    model =
                        { initialModel
                            | lastMove = Just (Time.millisToPosix 1000)
                            , now = Nothing
                        }
                in
                Expect.equal (toFloat idleTimeoutMillis) (timeSpent model)
        , test "timeSpent calculates correct elapsed time" <|
            \_ ->
                let
                    model =
                        { initialModel
                            | lastMove = Just (Time.millisToPosix 1000)
                            , now = Just (Time.millisToPosix 3500)
                        }
                in
                Expect.equal 2500.0 (timeSpent model)
        , test "timeSpent returns zero when lastMove equals now" <|
            \_ ->
                let
                    model =
                        { initialModel
                            | lastMove = Just (Time.millisToPosix 1000)
                            , now = Just (Time.millisToPosix 1000)
                        }
                in
                Expect.equal 0.0 (timeSpent model)
        , test "timeSpent handles large time differences" <|
            \_ ->
                let
                    model =
                        { initialModel
                            | lastMove = Just (Time.millisToPosix 1000)
                            , now = Just (Time.millisToPosix 61000)
                        }
                in
                Expect.equal 60000.0 (timeSpent model)
        ]


timeoutDetectionTests : Test
timeoutDetectionTests =
    describe "Timeout Detection Logic"
        [ test "idleTimeoutMillis is set to 5 seconds" <|
            \_ ->
                Expect.equal 5000 idleTimeoutMillis
        , test "timeout threshold is correctly defined" <|
            \_ ->
                let
                    fiveSecondsInMillis =
                        5 * 1000
                in
                Expect.equal fiveSecondsInMillis idleTimeoutMillis
        , test "timeSpent correctly identifies timeout condition" <|
            \_ ->
                let
                    timeoutModel =
                        { initialModel
                            | lastMove = Just (Time.millisToPosix 1000)
                            , now = Just (Time.millisToPosix 7000)
                        }

                    noTimeoutModel =
                        { initialModel
                            | lastMove = Just (Time.millisToPosix 1000)
                            , now = Just (Time.millisToPosix 4000)
                        }

                    timeoutCondition =
                        timeSpent timeoutModel >= toFloat idleTimeoutMillis

                    noTimeoutCondition =
                        timeSpent noTimeoutModel < toFloat idleTimeoutMillis
                in
                Expect.all
                    [ \_ -> Expect.equal True timeoutCondition
                    , \_ -> Expect.equal True noTimeoutCondition
                    ]
                    ()
        , test "timeout detection works at exact threshold" <|
            \_ ->
                let
                    exactTimeoutModel =
                        { initialModel
                            | lastMove = Just (Time.millisToPosix 1000)
                            , now = Just (Time.millisToPosix (1000 + idleTimeoutMillis))
                        }

                    timeoutCondition =
                        timeSpent exactTimeoutModel >= toFloat idleTimeoutMillis
                in
                Expect.equal True timeoutCondition
        , test "timeout detection works just before threshold" <|
            \_ ->
                let
                    almostTimeoutModel =
                        { initialModel
                            | lastMove = Just (Time.millisToPosix 1000)
                            , now = Just (Time.millisToPosix (1000 + idleTimeoutMillis - 1))
                        }

                    noTimeoutCondition =
                        timeSpent almostTimeoutModel < toFloat idleTimeoutMillis
                in
                Expect.equal True noTimeoutCondition
        ]


autoPlayTests : Test
autoPlayTests =
    describe "Auto-Play Functionality"
        [ test "auto-play should select best move for human player" <|
            \_ ->
                let
                    -- Create a board where X (human) has a winning move
                    board =
                        [ [ Just X, Just X, Nothing ] -- X can win by playing (0,2)
                        , [ Just O, Nothing, Nothing ]
                        , [ Nothing, Nothing, Nothing ]
                        ]
                in
                -- The auto-play should find the winning move at (0,2)
                case TicTacToe.TicTacToe.findBestMove X board of
                    Just bestMove ->
                        Expect.equal { row = 0, col = 2 } bestMove

                    Nothing ->
                        Expect.fail "Auto-play should find a valid move"
        , test "auto-play should block opponent winning move" <|
            \_ ->
                let
                    -- Create a board where O has a winning threat that X should block
                    board =
                        [ [ Just O, Just O, Nothing ] -- O threatens to win at (0,2)
                        , [ Just X, Nothing, Nothing ]
                        , [ Nothing, Nothing, Nothing ]
                        ]
                in
                -- The auto-play should block the winning move at (0,2)
                case TicTacToe.TicTacToe.findBestMove X board of
                    Just bestMove ->
                        Expect.equal { row = 0, col = 2 } bestMove

                    Nothing ->
                        Expect.fail "Auto-play should find a blocking move"
        , test "auto-play should make reasonable move when no immediate threats" <|
            \_ ->
                let
                    -- Create a board with no immediate winning or blocking moves
                    board =
                        [ [ Just X, Nothing, Nothing ]
                        , [ Nothing, Just O, Nothing ]
                        , [ Nothing, Nothing, Nothing ]
                        ]
                in
                -- The auto-play should find some valid move
                case TicTacToe.TicTacToe.findBestMove X board of
                    Just bestMove ->
                        -- Verify it's a valid position
                        Expect.all
                            [ \_ -> Expect.atLeast 0 bestMove.row
                            , \_ -> Expect.atMost 2 bestMove.row
                            , \_ -> Expect.atLeast 0 bestMove.col
                            , \_ -> Expect.atMost 2 bestMove.col
                            ]
                            ()

                    Nothing ->
                        Expect.fail "Auto-play should find a valid move"
        , test "auto-play should handle full board gracefully" <|
            \_ ->
                let
                    -- Create a full board (draw scenario)
                    board =
                        [ [ Just X, Just O, Just X ]
                        , [ Just O, Just O, Just X ]
                        , [ Just O, Just X, Just O ]
                        ]
                in
                -- The auto-play should return Nothing for full board
                case TicTacToe.TicTacToe.findBestMove X board of
                    Just _ ->
                        Expect.fail "Auto-play should not find moves on full board"

                    Nothing ->
                        Expect.pass
        , test "auto-play works for both X and O players" <|
            \_ ->
                let
                    -- Create a board where O (AI) could also timeout and need auto-play
                    board =
                        [ [ Just X, Nothing, Nothing ]
                        , [ Nothing, Nothing, Nothing ]
                        , [ Nothing, Nothing, Nothing ]
                        ]

                    testForPlayer player =
                        case TicTacToe.TicTacToe.findBestMove player board of
                            Just bestMove ->
                                -- Verify it's a valid position and the cell is empty
                                let
                                    isValidPosition =
                                        bestMove.row
                                            >= 0
                                            && bestMove.row
                                            <= 2
                                            && bestMove.col
                                            >= 0
                                            && bestMove.col
                                            <= 2

                                    cellState =
                                        TicTacToe.TicTacToe.getCellState bestMove board
                                in
                                isValidPosition && cellState == Nothing

                            Nothing ->
                                False
                in
                Expect.all
                    [ \_ -> Expect.equal True (testForPlayer X)
                    , \_ -> Expect.equal True (testForPlayer O)
                    ]
                    ()
        ]

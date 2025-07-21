module TicTacToe.TicTacToeTest exposing (all)

-- import Fuzz exposing (Fuzzer, int, list, string)

import Expect
import GameTheory.ExtendedOrder exposing (ExtendedOrder(..))
import Model exposing (Board, ColorScheme(..), Player(..), Position, initialModel)
import Test exposing (Test, describe, only, test)
import TicTacToe.TicTacToe exposing (..)


all : Test
all =
    let
        ( n, x, o ) =
            ( Nothing, Just X, Just O )
    in
    describe "Tic Tac Toe"
        [ describe "nextPlayer"
            [ test "X becomes O" <|
                \_ ->
                    nextPlayer X
                        |> Expect.equal O
            , test "O becomes X" <|
                \_ ->
                    nextPlayer O
                        |> Expect.equal X
            ]
        , describe "makeMove"
            [ test "places X correctly" <|
                \_ ->
                    makeMove
                        X
                        [ [ n, n, n ]
                        , [ n, n, n ]
                        , [ n, n, n ]
                        ]
                        { row = 1, col = 1 }
                        |> Expect.equal
                            [ [ n, n, n ]
                            , [ n, x, n ]
                            , [ n, n, n ]
                            ]
            ]
        , describe "scoreBoard"
            [ test "should return positive score for X winning 1*10^3 + 1*10^1 - 1*10^2" <|
                \_ ->
                    let
                        board : Board
                        board =
                            [ [ x, x, x ]
                            , [ o, o, n ]
                            , [ n, n, n ]
                            ]
                    in
                    scoreBoard X board
                        |> Expect.equal 910
            , test "should return negative score for O winning" <|
                \_ ->
                    let
                        board : Board
                        board =
                            [ [ o, o, o ]
                            , [ x, x, n ]
                            , [ n, n, n ]
                            ]
                    in
                    scoreBoard X board
                        |> Expect.equal -910
            , test "should return 0 for a draw" <|
                \_ ->
                    let
                        board : Board
                        board =
                            [ [ x, o, x ]
                            , [ x, o, o ]
                            , [ o, x, x ]
                            ]
                    in
                    scoreBoard X board
                        |> Expect.equal 0
            , test "should return score for ongoing game 3*10^1 - 2*10^1" <|
                \_ ->
                    let
                        board : Board
                        board =
                            [ [ x, o, n ]
                            , [ n, x, n ]
                            , [ n, n, o ]
                            ]
                    in
                    scoreBoard X board
                        |> Expect.equal 10
            ]
        , describe "checkWinner"
            [ test "horizontal win for X" <|
                \_ ->
                    [ [ x, x, x ]
                    , [ n, o, n ]
                    , [ o, n, n ]
                    ]
                        |> checkWinner
                        |> Expect.equal (Just (Won X))
            , test "vertical win for O" <|
                \_ ->
                    [ [ x, o, n ]
                    , [ n, o, x ]
                    , [ n, o, n ]
                    ]
                        |> checkWinner
                        |> Expect.equal (Just (Won O))
            , test "diagonal win for X" <|
                \_ ->
                    [ [ x, o, n ]
                    , [ n, x, o ]
                    , [ n, n, x ]
                    ]
                        |> checkWinner
                        |> Expect.equal (Just (Won X))
            , test "no winner yet" <|
                \_ ->
                    [ [ x, o, n ]
                    , [ n, x, o ]
                    , [ n, n, o ]
                    ]
                        |> checkWinner
                        |> Expect.equal Nothing
            , test "draw when board is full" <|
                \_ ->
                    [ [ x, o, x ]
                    , [ x, o, o ]
                    , [ o, x, x ]
                    ]
                        |> checkWinner
                        |> Expect.equal (Just Drew)
            ]
        , describe "scoreLine"
            [ test "empty line scores 0" <|
                \_ ->
                    [ n, n, n ]
                        |> scoreLine X
                        |> Expect.equal 0
            , test "single X scores 10" <|
                \_ ->
                    [ x, n, n ]
                        |> scoreLine X
                        |> Expect.equal 10
            , test "two X scores 100" <|
                \_ ->
                    [ x, x, n ]
                        |> scoreLine X
                        |> Expect.equal 100
            , test "three X scores 1000" <|
                \_ ->
                    [ x, x, x ]
                        |> scoreLine X
                        |> Expect.equal 1000
            , test "blocked line scores 0" <|
                \_ ->
                    [ x, o, n ]
                        |> scoreLine X
                        |> Expect.equal 0
            , test "single O scores 10" <|
                \_ ->
                    [ o, n, n ]
                        |> scoreLine X
                        |> Expect.equal -10
            , test "two O scores 100" <|
                \_ ->
                    [ o, o, n ]
                        |> scoreLine X
                        |> Expect.equal -100
            , test "three O scores 1000" <|
                \_ ->
                    [ o, o, o ]
                        |> scoreLine X
                        |> Expect.equal -1000
            ]
        , describe "possibleMoves"
            [ test "empty board has 9 moves" <|
                \_ ->
                    [ [ n, n, n ]
                    , [ n, n, n ]
                    , [ n, n, n ]
                    ]
                        |> possibleMoves X
                        |> List.length
                        |> Expect.equal 9
            , test "partially filled board" <|
                \_ ->
                    [ [ x, n, o ]
                    , [ n, x, n ]
                    , [ o, n, n ]
                    ]
                        |> possibleMoves X
                        |> List.length
                        |> Expect.equal 5
            , test "should return all positions for empty board" <|
                \_ ->
                    initialModel
                        |> .board
                        |> possibleMoves X
                        |> List.length
                        |> Expect.equal 9
            , test "should exclude occupied positions" <|
                \_ ->
                    [ [ x, n, n ]
                    , [ n, o, n ]
                    , [ n, n, n ]
                    ]
                        |> possibleMoves X
                        |> List.length
                        |> Expect.equal 7
            , test "should return correct positions" <|
                \_ ->
                    let
                        board : Board
                        board =
                            [ [ x, n, n ]
                            , [ n, o, n ]
                            , [ n, n, n ]
                            ]

                        expected : List Position
                        expected =
                            [ Position 0 1
                            , Position 0 2
                            , Position 1 0
                            , Position 1 2
                            , Position 2 0
                            , Position 2 1
                            , Position 2 2
                            ]
                    in
                    possibleMoves X board
                        |> List.sortBy (\pos -> pos.row * 3 + pos.col)
                        |> Expect.equal expected
            ]
        , describe "findBestMove"
            [ test "should choose winning move when available" <|
                \_ ->
                    let
                        board =
                            [ [ x, x, n ]
                            , [ o, o, n ]
                            , [ n, n, n ]
                            ]

                        currentPlayer =
                            X

                        expectedMove : Maybe Position
                        expectedMove =
                            Just (Position 0 2)
                    in
                    findBestMove currentPlayer board
                        |> Expect.equal expectedMove
            , test "should block opponent's winning move" <|
                \_ ->
                    let
                        board =
                            [ [ o, o, n ]
                            , [ x, n, n ]
                            , [ n, n, n ]
                            ]

                        currentPlayer =
                            X

                        expectedMove : Maybe Position
                        expectedMove =
                            Just (Position 0 2)
                    in
                    findBestMove currentPlayer board
                        |> Expect.equal expectedMove
            ]
        ]

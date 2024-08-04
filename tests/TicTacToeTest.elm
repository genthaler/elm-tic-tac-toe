module TicTacToeTest exposing (all)

-- import Fuzz exposing (Fuzzer, int, list, string)

import AdversarialEager exposing (alphabetaMove, minimaxMove)
import Array exposing (fromList, toIndexedList)
import Expect
import Test exposing (Test, describe, test)
import TicTacToe exposing (..)


all : Test
all =
    let
        ( n, x, o ) =
            ( Nothing, Just X, Just O )
    in
    describe "Tic Tac Toe"
        [ describe "scoreLine"
            [ test "empty" <|
                \_ ->
                    let
                        emptyLine : List ( Int, Maybe Player )
                        emptyLine =
                            [ n, n, n ] |> fromList |> toIndexedList
                    in
                    scoreLine X emptyLine
                        |> Expect.equal 0
            , test "just me" <|
                \_ ->
                    let
                        emptyLine : List ( Int, Maybe Player )
                        emptyLine =
                            [ n, x, n ] |> fromList |> toIndexedList
                    in
                    scoreLine X emptyLine
                        |> Expect.equal 1
            ]
        , describe "initGame"
            [ test "setup" <|
                \_ ->
                    initGame
                        |> Expect.equal { board = List.repeat 9 n |> Array.fromList, gameState = InProgress X }
            ]
        , let
            g =
                restoreGame O
                    [ [ o, n, x ]
                    , [ n, x, n ]
                    , [ n, n, n ]
                    ]

            -- [ [ o, n, x ]
            -- , [ x, x, o ]
            -- , [ o, x, n ]
            -- ]
            -- [ [ 0, 1, 2 ]
            -- , [ 3, 4, 5 ]
            -- , [ 6, 7, 8 ]
            -- ]
          in
          describe "midgame"
            [ test "moves" <|
                \_ ->
                    g
                        |> moves
                        |> Expect.equalLists [ 6, 3, 5, 7, 8, 1 ]
            , test "moves and scores" <|
                \_ ->
                    g
                        |> moves
                        |> List.map (\m -> try g m |> score |> Tuple.pair m)
                        |> Expect.equalLists
                            [ ( 6, 1078 )
                            , ( 3, -22 )
                            , ( 5, -1100 )
                            , ( 7, -1100 )
                            , ( 8, -1100 )
                            , ( 1, -1111 )
                            ]
            , test "minimax" <|
                \_ ->
                    g
                        |> minimaxMove 9 heuristic moves play
                        |> Expect.equal (Just 6)
            , test "alphabeta" <|
                \_ ->
                    g
                        |> alphabetaMove 9 heuristic moves play
                        |> Expect.equal (Just 6)
            ]
        , let
            g =
                restoreGame O
                    [ [ o, n, x ]
                    , [ x, x, o ]
                    , [ o, x, n ]
                    ]

            -- [ [ 0, 1, 2 ]
            -- , [ 3, 4, 5 ]
            -- , [ 6, 7, 8 ]
            -- ]
          in
          describe "lategame"
            [ test "moves" <|
                \_ ->
                    g
                        |> moves
                        |> Expect.equalLists [ 1, 8 ]
            , test "moves and scores" <|
                \_ ->
                    g
                        |> moves
                        |> List.map (\m -> try g m |> score |> Tuple.pair m)
                        |> Expect.equalLists
                            [ ( 1, 0 )
                            , ( 8, -1100 )
                            ]
            ]
        , let
            initialState =
                restoreGame X
                    [ [ x, n, n ]
                    , [ x, x, o ]
                    , [ o, o, n ]
                    ]
          in
          describe "endgame"
            [ test "moves" <|
                \_ ->
                    initialState
                        |> moves
                        |> Expect.equalLists [ 8, 2, 1 ]
            , test "score" <|
                \_ ->
                    initialState
                        |> score
                        |> Expect.equal 0
            , test "moves and scores" <|
                \_ ->
                    initialState
                        |> moves
                        |> List.map (\m -> try initialState m |> score |> Tuple.pair m)
                        |> Expect.equalLists [ ( 8, 1010 ), ( 2, 100 ), ( 1, 90 ) ]
            , test "alphabeta" <|
                \_ ->
                    initialState
                        |> alphabetaMove 9 heuristic moves play
                        |> Expect.equal (Just 8)
            ]
        , describe "Full game"
            [ test "Lets play a game out (moves only)" <|
                \_ ->
                    initGame
                        |> alphabetaFullGame
                        |> List.map (Tuple.mapSecond .gameState)
                        |> Expect.equalLists
                            [ ( 4, InProgress O )
                            , ( 0, InProgress X )
                            , ( 2, InProgress O )
                            , ( 6, InProgress X )
                            , ( 3, InProgress O )
                            , ( 5, InProgress X )
                            , ( 1, InProgress O )
                            , ( 7, InProgress X )
                            , ( 8, Stalemate )
                            ]
            , test "Lets play a game out full" <|
                \_ ->
                    initGame
                        |> alphabetaFullGame
                        |> Expect.equalLists
                            [ ( 4
                              , restoreGame O
                                    [ [ n, n, n ]
                                    , [ n, x, n ]
                                    , [ n, n, n ]
                                    ]
                              )
                            , ( 0
                              , restoreGame X
                                    [ [ o, n, n ]
                                    , [ n, x, n ]
                                    , [ n, n, n ]
                                    ]
                              )
                            , ( 2
                              , restoreGame O
                                    [ [ o, n, x ]
                                    , [ n, x, n ]
                                    , [ n, n, n ]
                                    ]
                              )
                            , ( 6
                              , restoreGame X
                                    [ [ o, n, x ]
                                    , [ n, x, n ]
                                    , [ o, n, n ]
                                    ]
                              )
                            , ( 3
                              , restoreGame O
                                    [ [ o, n, x ]
                                    , [ x, x, n ]
                                    , [ o, n, n ]
                                    ]
                              )
                            , ( 5
                              , restoreGame X
                                    [ [ o, n, x ]
                                    , [ x, x, o ]
                                    , [ o, n, n ]
                                    ]
                              )
                            , ( 1
                              , restoreGame O
                                    [ [ o, x, x ]
                                    , [ x, x, o ]
                                    , [ o, n, n ]
                                    ]
                              )
                            , ( 7
                              , restoreGame X
                                    [ [ o, x, x ]
                                    , [ x, x, o ]
                                    , [ o, o, n ]
                                    ]
                              )
                            , ( 8
                              , restoreGame O
                                    [ [ o, x, x ]
                                    , [ x, x, o ]
                                    , [ o, o, x ]
                                    ]
                              )
                            ]
            ]
        ]

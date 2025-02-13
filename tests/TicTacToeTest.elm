module TicTacToeTest exposing (all)

-- import Fuzz exposing (Fuzzer, int, list, string)

import AdversarialEager exposing (alphabetaMove, minimaxMove)
import Array
import Basics.Extra exposing (flip)
import Expect
import Test exposing (Test, describe, only, test)
import TicTacToe exposing (..)


all : Test
all =
    let
        ( n, x, o ) =
            ( Nothing, Just X, Just O )
    in
    describe "Tic Tac Toe"
        [ describe "Unit tests"
            [ describe "initGame"
                [ test "setup" <|
                    \_ ->
                        initGame
                            |> Expect.equal { board = List.repeat 9 n |> Array.fromList, gameState = InProgress X }
                , test "play" <|
                    \_ ->
                        let
                            -- state1: Result
                            state1 =
                                play initGame 4

                            state2 =
                                restoreGame O
                                    [ [ n, n, n ]
                                    , [ n, x, n ]
                                    , [ n, n, n ]
                                    ]
                        in
                        state1 |> Expect.equal state2
                , test "moves" <|
                    \_ ->
                        moves initGame
                            |> Expect.equalLists [ 4, 0, 2, 6, 8, 1, 3, 5, 7 ]
                , test "score (1 point for each position)" <|
                    \_ ->
                        initGame
                            |> score
                            |> Expect.equal 0
                ]
            , let
                g =
                    restoreGame O
                        [ [ o, n, x ]
                        , [ n, x, n ]
                        , [ n, n, n ]
                        ]
              in
              describe "midgame"
                [ test "moves" <|
                    \_ ->
                        g
                            |> moves
                            |> Expect.equalLists [ 1, 3, 5, 6, 7, 8 ]
                , only <|
                    test "moves and scores" <|
                        \_ ->
                            g
                                |> moves
                                |> List.map (\m -> try g m |> score |> Tuple.pair m)
                                |> Expect.equalLists
                                    [ ( 6, 80 )
                                    , ( 3, -20 )
                                    , ( 5, -100 )
                                    , ( 7, -100 )
                                    , ( 8, -100 )
                                    , ( 1, -110 )
                                    ]
                , test "minimax" <|
                    \_ ->
                        g
                            |> minimaxMove 9 heuristic moves play
                            |> Debug.log "Minimax midgame"
                            |> Expect.equal (Just 6)
                , test "alphabeta" <|
                    \_ ->
                        g
                            |> alphabetaMove 9 heuristic moves play
                            |> Expect.equal (Just 6)
                ]
            , let
                g =
                    restoreGame X
                        [ [ x, n, n ]
                        , [ x, x, o ]
                        , [ o, o, n ]
                        ]
              in
              describe "endgame"
                [ test "moves" <|
                    \_ ->
                        g
                            |> moves
                            |> Expect.equalLists [ 8, 2, 1 ]
                , test "score" <|
                    \_ ->
                        g
                            |> score
                            |> Expect.equal 0
                , test "moves and scores" <|
                    \_ ->
                        g
                            |> moves
                            |> List.map (\m -> try g m |> score |> Tuple.pair m)
                            |> Expect.equalLists [ ( 8, 1010 ), ( 2, 100 ), ( 1, 90 ) ]
                , test "alphabeta" <|
                    \_ ->
                        g
                            |> alphabetaMove 9 heuristic moves play
                            |> Expect.equal (Just 8)
                ]
            ]
        , describe "Full game"
            [ test "Lets play a game out" <|
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

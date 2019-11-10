module GameTest exposing (all)

import AdversarialPure exposing (alphabeta, minimax)
import Basics.Extra
import Dict
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Game exposing (..)
import Test exposing (..)


n =
    Nothing


j =
    Just


all : Test
all =
    describe "Game test"
        [ describe "Minimax no pruning"
            [ test "The best possible result is to win with 2 lines" <|
                \_ ->
                    Expect.equal 2000 <| minimax 9 True heuristic getChildren initGame
            , Test.only <|
                test "Best move from start is in the middle of the board, everyone knows that" <|
                    \_ ->
                        Expect.equal (Just ( 1, 1 )) <| getBestMove initGame
            , test "End game" <|
                \_ ->
                    Expect.equal (Just ( 2, 0 )) <|
                        Maybe.andThen getBestMove <|
                            restoreGame X
                                [ [ j X, n, n ]
                                , [ j X, n, n ]
                                , [ n, n, n ]
                                ]
            ]
        , describe "Game mechanics"
            [ test "If there's a winning move, then the game is over" <|
                \_ ->
                    Expect.equal (Just True) <|
                        (restoreGame X
                            [ [ j X, n, n ]
                            , [ j X, n, n ]
                            , [ j X, n, n ]
                            ]
                            |> Maybe.map (updateGame 2 0)
                            |> Maybe.map (getWinningPositions >> List.isEmpty >> not)
                        )
            , test "score game" <|
                \_ ->
                    Expect.equal
                        [ ( 0
                          , [ [ ( 0, 1 ), ( 1, 1 ), ( 2, 1 ) ]
                            , [ ( 0, 2 ), ( 1, 2 ), ( 2, 2 ) ]
                            ]
                          )
                        , ( 1
                          , [ [ ( 0, 0 ), ( 0, 1 ), ( 0, 2 ) ]
                            , [ ( 1, 0 ), ( 1, 1 ), ( 1, 2 ) ]
                            , [ ( 2, 0 ), ( 2, 1 ), ( 2, 2 ) ]
                            , [ ( 0, 0 ), ( 1, 1 ), ( 2, 2 ) ]
                            , [ ( 0, 2 ), ( 1, 1 ), ( 2, 0 ) ]
                            ]
                          )
                        , ( 3
                          , [ [ ( 0, 0 ), ( 1, 0 ), ( 2, 0 ) ]
                            ]
                          )
                        ]
                    <|
                        (restoreGame X
                            [ [ j X, n, n ]
                            , [ j X, n, n ]
                            , [ n, n, n ]
                            ]
                            |> Maybe.map (updateGame 2 0)
                            |> Maybe.map Game.scoreGame
                            |> Maybe.map Dict.toList
                            |> Maybe.withDefault []
                        )
            ]
        ]

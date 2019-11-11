module GameTest exposing (all)

-- import Fuzz exposing (Fuzzer, int, list, string)

import AdversarialPure exposing (minimax)
import Dict
import Expect
import Game exposing (Player(..), getBestMove, getChildren, getWinningPositions, heuristic, initGame, restoreGame, updateGame)
import Test exposing (Test, describe, test)


all : Test
all =
    let
        n =
            Nothing

        j =
            Just
    in
    describe "Game test"
        [ describe "Minimax no pruning"
            [ test "The best possible result is to win with 2 lines" <|
                \_ ->
                    Expect.equal 2000 <| minimax 9 True heuristic getChildren initGame
            , -- anywhere but the middle; this is because I currently rank doing a double row win as higher than a single row win
              test "Best move from start - anywhere but the middle!" <|
                \_ ->
                    Expect.equal (Just ( 2, 2 )) <| getBestMove initGame
            , test "End game" <|
                \_ ->
                    Expect.equal (Just ( 2, 0 )) <|
                        (restoreGame X
                            [ [ j X, n, n ]
                            , [ j X, n, n ]
                            , [ n, n, n ]
                            ]
                            |> Maybe.andThen getBestMove
                        )
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

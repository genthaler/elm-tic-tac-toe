module NimTest exposing (..)

import AdversarialEager exposing (..)
import Array exposing (Array)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)


{-| At any time, it's someone's turn to play on the board
Nim is played with an arbitrary number of 'heaps' containing an arbitrary initial number of objects, lets call them 'stones'
-}
type alias Game =
    Array Int


{-| A possible move a player can make.
-}
type alias Move =
    { heap : Int
    , stones : Int
    }


{-| Let's play an initial board of 1 heap with 5 stones
-}
initGame : Game
initGame =
    Array.fromList [ 5 ]


{-| super simple heuristic; if I win, then 1, else 0
-}
heuristic : Game -> Move -> Int
heuristic game move =
    case applyMove game move |> Array.toList |> List.filter (\h -> h > 0) |> List.length of
        0 ->
            1

        _ ->
            0


{-| All possible moves from the given game

To avoid having to do an Array.get, define a move as what the heap will look like after the move, rather than what is taken.

-}
getMoves : Game -> List Move
getMoves game =
    game |> Array.toIndexedList |> List.filter (\( _, heap ) -> heap > 0) |> List.map (\( i, heap ) -> List.range 0 (heap - 1) |> List.map (Move i)) |> List.concat


applyMove : Game -> Move -> Game
applyMove game move =
    Array.set move.heap move.stones game


suite : Test
suite =
    describe "Nim"
        [ describe "getMoves"
            [ test "1 heap 5 stones" <|
                \() ->
                    getMoves (Array.fromList [ 5 ])
                        |> Expect.equal [ { heap = 0, stones = 0 }, { heap = 0, stones = 1 }, { heap = 0, stones = 2 }, { heap = 0, stones = 3 }, { heap = 0, stones = 4 } ]
            , test "2 heaps 5 stones each" <|
                \() ->
                    getMoves (Array.fromList [ 5, 5 ])
                        |> Expect.equal [ { heap = 0, stones = 0 }, { heap = 0, stones = 1 }, { heap = 0, stones = 2 }, { heap = 0, stones = 3 }, { heap = 0, stones = 4 }, { heap = 1, stones = 0 }, { heap = 1, stones = 1 }, { heap = 1, stones = 2 }, { heap = 1, stones = 3 }, { heap = 1, stones = 4 } ]
            ]
        , describe "heuristic"
            [ test "1 heap 5 stones - take 5" <|
                \() ->
                    heuristic (Array.fromList [ 5 ]) (Move 0 0)
                        |> Expect.equal 1
            , test "1 heap 5 stones - take 3" <|
                \() ->
                    heuristic (Array.fromList [ 5 ]) (Move 0 0)
                        |> Expect.equal 0
            , test "2 heaps 5 stones each" <|
                \() ->
                    heuristic (Array.fromList [ 5, 5 ]) (Move 0 1)
                        |> Expect.equal 0
            ]
        , describe "minimax"
            [ test "1 heap 5 stones" <|
                \() ->
                    minimax 9 heuristic getMoves applyMove (Array.fromList [ 5 ])
                        |> Expect.equal (Just (Move 0 0))
            , test "2 heaps 5 stones each" <|
                \() ->
                    minimax 9 heuristic getMoves applyMove (Array.fromList [ 5, 5 ])
                        |> Expect.equal (Just (Move 0 4))
            ]
        ]

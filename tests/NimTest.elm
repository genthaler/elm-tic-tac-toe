module NimTest exposing (..)

import AdversarialEager exposing (..)
import Array exposing (Array)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Nim exposing (..)
import Test exposing (..)


suite : Test
suite =
    describe "Nim"
        [ describe "getMoves"
            [ test "1 heap 5 stones" <|
                \() ->
                    getMoves (initGame 1 5)
                        |> Expect.equal [ { heap = 0, stones = 0 }, { heap = 0, stones = 1 }, { heap = 0, stones = 2 }, { heap = 0, stones = 3 }, { heap = 0, stones = 4 } ]
            , test "2 heaps 1 stones each" <|
                \() ->
                    getMoves (initGame 2 1)
                        |> Expect.equal [ { heap = 0, stones = 0 }, { heap = 1, stones = 0 } ]
            ]
        , describe "heuristic"
            [ test "1 heap 5 stones - take 5" <|
                \() ->
                    heuristic (initGame 1 5) (Move 0 0)
                        |> Expect.equal 1
            , test "1 heap 5 stones - take everything" <|
                \() ->
                    heuristic (initGame 1 5) (Move 0 0)
                        |> Expect.equal 1
            , test "2 heaps 5 stones each" <|
                \() ->
                    heuristic (initGame 2 5) (Move 0 1)
                        |> Expect.equal 0
            ]
        , describe "minimax"
            [ test "1 heap 5 stones" <|
                \() ->
                    minimaxMove 9 heuristic getMoves applyMove (initGame 1 5)
                        |> Expect.equal (Just (Move 0 0))
            , test "2 heaps 5 stones each" <|
                \() ->
                    minimaxMove 50 heuristic getMoves applyMove (initGame 2 5)
                        |> Expect.equal (Just (Move 0 0))
            ]
        , describe "alphabeta"
            [ test "1 heap 5 stones" <|
                \() ->
                    alphabetaMove 9 heuristic getMoves applyMove (initGame 1 5)
                        |> Expect.equal (Just (Move 0 0))
            , test "2 heaps 5 stones each" <|
                \() ->
                    alphabetaMove 10 heuristic getMoves applyMove (initGame 2 5)
                        |> Expect.equal (Just (Move 0 0))
            ]
        ]

module GameTheory.AdversarialEagerTest exposing (all)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import GameTheory.AdversarialEager exposing (..)
import Test exposing (..)



-- import TicTacToe exposing (..)
{-
   I need to have a minimal game board,
-}


all : Test
all =
    let
        heuristic node move =
            1.0

        applyMove node move =
            node
    in
    describe "AdversarialEager"
        [ describe "Minimax no pruning"
            [ test "Game over" <|
                \_ ->
                    Expect.equal Nothing <| minimax 4 heuristic (always []) applyMove ()
            , test "Bottom of the search tree" <|
                \_ ->
                    Expect.equal (Just ()) <| minimax 0 heuristic (always [ () ]) applyMove ()
            ]
        , describe "Alpha-beta no pruning"
            [ test "Game over" <|
                \_ ->
                    Expect.equal Nothing <| minimaxAlphabeta 4 heuristic (always []) applyMove ()
            , test "Bottom of the search tree" <|
                \_ ->
                    Expect.equal (Just ()) <| minimaxAlphabeta 0 heuristic (always [ () ]) applyMove ()
            ]
        ]

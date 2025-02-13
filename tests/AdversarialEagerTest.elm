module AdversarialEagerTest exposing (all)

import AdversarialEager exposing (..)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
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

        getMoves =
            always []

        applyMove node move =
            node
    in
    describe "AdversarialEager"
        [ describe "Minimax no pruning"
            [ test "Game over" <|
                \_ ->
                    Expect.equal Nothing <| minimaxMove 4 heuristic (always []) applyMove ()
            , test "Bottom of the search tree" <|
                \_ ->
                    Expect.equal (Just ()) <| minimaxMove 0 heuristic (always [ () ]) applyMove ()
            ]
        , describe "Alpha-beta no pruning"
            [ test "Game over" <|
                \_ ->
                    Expect.equal Nothing <| alphabetaMove 4 heuristic (always []) applyMove ()
            , test "Bottom of the search tree" <|
                \_ ->
                    Expect.equal (Just ()) <| alphabetaMove 0 heuristic (always [ () ]) applyMove ()
            ]
        ]

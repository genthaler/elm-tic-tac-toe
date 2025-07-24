module GameTheory.AdversarialEagerTest exposing (all)

import Expect
import GameTheory.AdversarialEager exposing (..)
import Test exposing (..)


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
                    Expect.equal Nothing <| minimax heuristic (always []) applyMove 4 ()
            , test "Bottom of the search tree" <|
                \_ ->
                    Expect.equal (Just ()) <| minimax heuristic (always [ () ]) applyMove 0 ()
            ]
        , describe "Minimax alpha-beta no pruning"
            [ test "Game over" <|
                \_ ->
                    Expect.equal Nothing <| minimaxAlphabeta heuristic (always []) applyMove 4 ()
            , test "Bottom of the search tree" <|
                \_ ->
                    Expect.equal (Just ()) <| minimaxAlphabeta heuristic (always [ () ]) applyMove 0 ()
            ]
        ]

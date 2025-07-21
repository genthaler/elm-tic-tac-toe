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
        , describe "Alpha-beta no pruning"
            [ test "Game over" <|
                \_ ->
                    Expect.equal Nothing <| minimaxAlphabeta heuristic (always []) applyMove 4 ()
            , test "Bottom of the search tree" <|
                \_ ->
                    Expect.equal (Just ()) <| minimaxAlphabeta heuristic (always [ () ]) applyMove 0 ()
            ]
        , let
            foo =
                1
          in
          describe "negamaxNoColor"
            [ test "returns Nothing for a node with no moves" <|
                \_ ->
                    let
                        node =
                            { value = 5, children = [] }
                    in
                    negamaxNoColor getMoves makeMove scoreNode 3 node
                        |> Expect.equal Nothing
            , test "finds best move in a simple tree" <|
                \_ ->
                    let
                        node =
                            { value = 0
                            , children = [ 3, -2, 4, -1 ] -- Child indices/values
                            }
                    in
                    negamaxNoColor getMoves makeMove scoreNode 1 node
                        |> Expect.equal (Just 4)

            -- Should pick the highest value child
            , test "considers opponent's best responses" <|
                \_ ->
                    let
                        -- Tree where:
                        -- Root (0) has children [1, 2]
                        -- Child 1 has value -2 (opponent's perspective)
                        -- Child 2 has value -4 (opponent's perspective)
                        node =
                            { value = 0
                            , children = [ 1, 2 ]
                            }

                        makeMove_ parent childIndex =
                            case childIndex of
                                1 ->
                                    { value = -2, children = [] }

                                2 ->
                                    { value = -4, children = [] }

                                _ ->
                                    { value = 0, children = [] }
                    in
                    negamaxNoColor getMoves makeMove_ scoreNode 2 node
                        |> Expect.equal (Just 1)

            -- Should pick move 1 since it leads to -2 vs -4
            ]
        ]

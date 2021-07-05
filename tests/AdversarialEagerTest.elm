module AdversarialEagerTest exposing (all)

import AdversarialEager exposing (..)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import TicTacToe exposing (..)



{-
   I need to have a minimal game board,
-}


all : Test
all =
    describe "Minimax"
        [--     describe "Minimax no pruning"
         --     [ test "Already there" <|
         --         \_ ->
         --             Expect.equal 1.0 <| minimax 0 True (always 1.0) (always []) ()
         --     , test "At the bottom with nowhere to go" <|
         --         \_ ->
         --             Expect.equal 1.0 <| minimax 1 True (always 1.0) (always []) ()
         --     ]
         -- , describe "Alpha-beta pruning"
         --     [ test "Already there" <|
         --         \_ ->
         --             Expect.equal 1.0 <| alphabeta 2 -2 0 True (always 1.0) (always []) ()
         --     , test "At the bottom with nowhere to go" <|
         --         \_ ->
         --             Expect.equal 1.0 <| alphabeta 2 -2 1 True (always 1.0) (always []) ()
         --     ]
        ]

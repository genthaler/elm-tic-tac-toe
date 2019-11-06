module GameTest exposing (all)

import AdversarialPure exposing (alphabeta, minimax)
import Basics.Extra
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Game exposing (..)
import Test exposing (..)


all : Test
all =
    describe "Minimax"
        [ describe "Minimax no pruning"
            [ test "You can win!" <|
                \_ ->
                    Expect.equal Basics.Extra.maxSafeInteger <| minimax 9 True heuristic getChildren initGame
            , test "Best move from start" <|
                \_ ->
                    Expect.equal (Just ( 0, 0 )) <| getBestMove initGame
            ]
        ]

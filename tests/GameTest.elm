module GameTest exposing (all)

import AdversarialPure exposing (..)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Game exposing (..)
import Test exposing (..)


{-| For minimax, here are the required parameters

  - ´depth´ -- how deep to search from this node;
  - `maximizingPlayer` -- whose point of view we're searching from;
  - `heuristic` -- a function that returns an approximate value of the current position;
  - `getChildren` -- a function that generates valid positions from the current position;
  - `node` -- the current position.

For tic-tac-toe, these correspond to

  - depth - 9; that's as long as the game can go
  - heuristic - in rank, the best is a winning position, followed by number of open winning positions, followed by postions on an empty line, else 0
  - getChildren - if it's your go, you can go anywhere

-}
getChildren : Board -> List Board
getChildren board =
    board
        |> Matrix.indexedMap
            (\i j a ->
                if Maybe.Extra.isNothing a then
                    Just ( i, j )

                else
                    Nothing
            )


heuristic : Board -> Int
heuristic board =
    0


all : Test
all =
    describe "Minimax"
        [ describe "Minimax no pruning"
            [ test "Already there" <|
                \_ ->
                    Expect.equal 1.0 <| minimax 0 True (always 1.0) (always []) ()
            , test "At the bottom with nowhere to go" <|
                \_ ->
                    Expect.equal 1.0 <| minimax 1 True (always 1.0) (always []) ()
            ]
        , describe "Alpha-beta pruning"
            [ test "Already there" <|
                \_ ->
                    Expect.equal 1.0 <| alphabeta 2 -2 0 True (always 1.0) (always []) ()
            , test "At the bottom with nowhere to go" <|
                \_ ->
                    Expect.equal 1.0 <| alphabeta 2 -2 1 True (always 1.0) (always []) ()
            ]
        ]

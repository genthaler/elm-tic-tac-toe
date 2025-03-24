module Nim.Nim exposing (..)

import Array exposing (Array)


{-| Nim is a mathematical game of strategy in which two players take turns removing (or "nimming") objects from distinct heaps or piles.
On each turn, a player must remove at least one object, and may remove any number of objects provided they all come from the same heap or pile.
Depending on the version being played, the goal of the game is either to avoid taking the last object or to take the last object.

Here we're playing to take the last object.

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

    import Array

    (==) (initGame 1 5) (Array.fromList [ 5 ]) --> True

-}
initGame : Int -> Int -> Game
initGame heaps stones =
    Array.repeat heaps stones


{-| super simple heuristic; if I win, then 1, else 0
-}
heuristic : Game -> Move -> Int
heuristic game move =
    case
        applyMove game move
            |> Array.filter (\stones -> stones > 0)
            |> Array.length
    of
        0 ->
            1

        _ ->
            0


{-| All possible moves from the given game

To avoid having to do an Array.get, define a move as what the heap will look like after the move, rather than what is taken.

-}
getMoves : Game -> List Move
getMoves game =
    game
        |> Array.toIndexedList
        |> List.filter
            (\( _, stones ) ->
                stones > 0
            )
        |> List.map
            (\( heap, stones ) ->
                List.range 0 (stones - 1)
                    |> List.map (Move heap)
            )
        |> List.concat


applyMove : Game -> Move -> Game
applyMove game move =
    Array.set move.heap move.stones game

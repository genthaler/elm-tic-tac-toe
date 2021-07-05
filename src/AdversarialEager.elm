module AdversarialEager exposing (alphabeta, minimax)

import NumberExtended exposing (..)
import Tuple exposing (..)


{-| This module implements some classic adversarial search algorithms.

<https://www.freecodecamp.org/news/playing-strategy-games-with-minimax-4ecb83b39b4b>


# Adversarial search strategies

@docs minimax, alphabeta

This function implements the [minimax algorithm](https://en.wikipedia.org/wiki/Minimax).

  - ´depth´ -- how deep to search from this node;

  - `maximizingPlayer` -- whose point of view we're searching from;

  - `heuristic` -- a function that returns an approximate value of the current position;

  - `getChildren` -- a function that generates valid positions from the current position;

  - `node` -- the current position.

Following is the pseudocode from that page:

        function minimax(node, depth, maximizingPlayer) is
            if depth = 0 or node is a terminal node then
                return the heuristic value of node
            if maximizingPlayer then
                value := −∞
                for each child of node do
                    value := max(value, minimax(child, depth − 1, FALSE))
                return value
            else (* minimizing player *)
                value := +∞
                for each child of node do
                    value := min(value, minimax(child, depth − 1, TRUE))
                return value

        minimax(origin, depth, TRUE)

This algorithm calculates the heuristic value of a given 'node' or game state.
We need to wrap this in some code that generates available moves, calculates the minimax of each move, sorts, and picks the top one.
This looks a lot like some of the code inside the algorithm, which (probably) results in some refactoring.

There is a lot that could be done to reduce the amount of code here, but I think there's value in having the implementation mirror the Wikipedia pseudocode as closely as possible.

-}
minimax : Int -> (node -> move -> comparable) -> (node -> List move) -> (node -> move -> node) -> node -> Maybe move
minimax depth heuristic getMoves applyMove node0 =
    let
        {-
           Below is the actual implementation of the pseudocode above.
           Compared to the pseudocode, we make node_ the last argument to make it easier to partially apply
        -}
        minimax_ : Int -> Bool -> node -> move -> NumberExtended comparable
        minimax_ depth_ maximizingPlayer node1 move =
            if depth_ == 0 then
                heuristic node1 move |> Number

            else
                let
                    node2 : node
                    node2 =
                        applyMove node1 move

                    moves =
                        getMoves node2
                in
                if List.isEmpty moves then
                    -- this is a terminal node
                    heuristic node1 move |> Number

                else if maximizingPlayer then
                    List.foldl NumberExtended.max NegativeInfinity <| List.map (minimax_ (depth_ - 1) False node2) moves

                else
                    List.foldl NumberExtended.min PositiveInfinity <| List.map (minimax_ (depth_ - 1) True node2) moves

        score : node -> move -> ( move, NumberExtended comparable )
        score node move =
            ( move, minimax_ depth True node move )

        sort : ( move, NumberExtended comparable ) -> ( move, NumberExtended comparable ) -> Order
        sort ( move1, score1 ) ( move2, score2 ) =
            NumberExtended.sort score1 score2
    in
    node0 |> getMoves |> List.map (score node0) |> List.sortWith sort |> List.map Tuple.first |> List.head


{-| This function implements the [minimax algorithm with alpha-beta pruning](https://en.wikipedia.org/wiki/Alpha%E2%80%93beta_pruning).

    ```
    function alphabeta(node, depth, α, β, maximizingPlayer) is
        if depth = 0 or node is a terminal node then
            return the heuristic value of node
        if maximizingPlayer then
            value := −∞
            for each child of node do
                value := max(value, alphabeta(child, depth − 1, α, β, FALSE))
                α := max(α, value)
                if α ≥ β then
                    break (* β cut-off *)
            return value
        else
            value := +∞
            for each child of node do
                value := min(value, alphabeta(child, depth − 1, α, β, TRUE))
                β := min(β, value)
                if α ≥ β then
                    break (* α cut-off *)
            return value

    alphabeta(origin, depth, −∞, +∞, TRUE)
    ```

    There is a lot that could be done to reduce the amount of code here,
    but I think there's value in having the implementation mirror the Wikipedia pseudocode closely.

-}
alphabeta : Int -> (node -> move -> comparable) -> (node -> List move) -> (node -> move -> node) -> node -> Maybe move
alphabeta depth heuristic getMoves applyMove node =
    let
        {-
           Below is the actual implementation of the pseudocode above.
           Compared to the pseudocode, we make node_ the last argument to make it easier to partially apply
        -}
        alphabeta1 : Int -> NumberExtended comparable -> NumberExtended comparable -> Bool -> node -> move -> NumberExtended comparable
        alphabeta1 depth1 alpha1 beta1 maximizingPlayer node1 move1 =
            if depth1 == 0 then
                heuristic node1 move1 |> Number

            else
                let
                    node2 =
                        applyMove node1 move1

                    moves =
                        getMoves node2

                    --    The cutoff code would work so much better with a lazy generator
                in
                if List.isEmpty moves then
                    -- this is a terminal node
                    heuristic node1 move1 |> Number

                else if maximizingPlayer then
                    let
                        cutoff : NumberExtended comparable -> NumberExtended comparable -> NumberExtended comparable -> List move -> NumberExtended comparable
                        cutoff value2 alpha2 beta2 moves2 =
                            case moves2 of
                                [] ->
                                    value2

                                move :: moves3 ->
                                    let
                                        value3 =
                                            NumberExtended.max value2 (alphabeta1 (depth1 - 1) alpha2 beta2 (not maximizingPlayer) node2 move)

                                        alpha3 =
                                            NumberExtended.max value3 alpha2
                                    in
                                    if NumberExtended.ge alpha3 beta2 then
                                        -- beta cut-off
                                        value3

                                    else
                                        cutoff value3 alpha3 beta2 moves3
                    in
                    cutoff NegativeInfinity alpha1 beta1 (getMoves node2)

                else
                    let
                        cutoff : NumberExtended comparable -> NumberExtended comparable -> NumberExtended comparable -> List move -> NumberExtended comparable
                        cutoff value2 alpha2 beta2 moves2 =
                            case moves2 of
                                [] ->
                                    value2

                                move :: moves3 ->
                                    let
                                        value3 =
                                            NumberExtended.min value2 (alphabeta1 (depth1 - 1) alpha2 beta2 (not maximizingPlayer) node2 move)

                                        beta3 =
                                            NumberExtended.min value3 beta2
                                    in
                                    if NumberExtended.ge alpha2 beta3 then
                                        -- alpha cut-off
                                        value3

                                    else
                                        cutoff value3 alpha2 beta3 moves3
                    in
                    cutoff PositiveInfinity alpha1 beta1 (getMoves node2)

        score : node -> move -> ( move, NumberExtended comparable )
        score node1 move1 =
            ( move1, alphabeta1 depth NegativeInfinity PositiveInfinity True node1 move1 )

        sort : ( b, NumberExtended comparable ) -> ( b, NumberExtended comparable ) -> Order
        sort ( move1, score1 ) ( move2, score2 ) =
            NumberExtended.sort score1 score2
    in
    node |> getMoves |> List.map (score node) |> List.sortWith sort |> List.map Tuple.first |> List.head
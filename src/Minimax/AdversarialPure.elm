module AdversarialPure exposing (minimax, alphabeta)

{-| This module implements some classic adversarial search algorithms.


# Adversarial search strategies

@docs minimax, alphabeta

-}


{-| This function implements the [minimax algorithm](https://en.wikipedia.org/wiki/Minimax).

  - ´depth´ -- how deep to search from this node;

  - `maximizingPlayer` -- whose point of view we're searching from;

  - `heuristic` -- a function that returns an approximate value of the current position;

  - `getChildren` -- a function that generates valid positions from the current position;

  - `node` -- the current position.

    minimax depth maximizingPlayer heuristic getChildren node

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

    There is a lot that could be done to reduce the amount of code here, but I think there's value in having the implementation mirror the Wikipedia pseudocode closely.

-}
minimax : Int -> Bool -> (a -> comparable) -> (a -> List a) -> a -> comparable
minimax depth maximizingPlayer heuristic getChildren node =
    if depth == 0 then
        heuristic node

    else if maximizingPlayer then
        case List.maximum <| List.map (minimax (depth - 1) (not maximizingPlayer) heuristic getChildren) (getChildren node) of
            Nothing ->
                heuristic node

            Just max ->
                max

    else
        case List.minimum <| List.map (minimax (depth - 1) (not maximizingPlayer) heuristic getChildren) (getChildren node) of
            Nothing ->
                heuristic node

            Just max ->
                max


{-| This function implements the [minimax algorithm with alpha-beta pruning](https://en.wikipedia.org/wiki/Alpha%E2%80%93beta_pruning).

    alphabeta depth positiveInfinity negativeInfinity maximizingPlayer heuristic getChildren node =

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
    ```
    `alphabeta(origin, depth, −∞, +∞, TRUE)`

    There is a lot that could be done to reduce the amount of code here, but I think there's value in having the implementation mirror the Wikipedia pseudocode closely.

-}
alphabeta : Int -> comparable -> comparable -> Bool -> (a -> comparable) -> (a -> List a) -> a -> comparable
alphabeta depth positiveInfinity negativeInfinity maximizingPlayer heuristic getChildren node =
    let
        alphabeta0 depth0 alpha0 beta0 maximizingPlayer0 node0 =
            if depth0 == 0 then
                heuristic node0

            else
                case getChildren node0 of
                    [] ->
                        heuristic node0

                    children0 ->
                        if maximizingPlayer0 then
                            let
                                cutoff value alpha1 beta1 children1 =
                                    case children1 of
                                        [] ->
                                            value

                                        child :: children2 ->
                                            let
                                                value2 =
                                                    Basics.max value (alphabeta0 (depth - 1) alpha1 beta1 (not maximizingPlayer0) child)

                                                alpha2 =
                                                    Basics.max value2 alpha1
                                            in
                                            if alpha2 >= beta1 then
                                                value2

                                            else
                                                cutoff value2 alpha2 beta1 children2
                            in
                            cutoff negativeInfinity alpha0 beta0 children0

                        else
                            let
                                cutoff value alpha1 beta1 children1 =
                                    case children1 of
                                        [] ->
                                            value

                                        child :: children2 ->
                                            let
                                                value2 =
                                                    Basics.max value (alphabeta0 (depth - 1) alpha1 beta1 (not maximizingPlayer) child)

                                                beta2 =
                                                    Basics.max value2 beta1
                                            in
                                            if alpha1 >= beta2 then
                                                value2

                                            else
                                                cutoff value2 alpha1 beta2 children2
                            in
                            cutoff positiveInfinity alpha0 beta0 children0
    in
    alphabeta0 depth positiveInfinity negativeInfinity maximizingPlayer node

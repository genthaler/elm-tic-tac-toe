module GameTheory.AdversarialEager exposing (minimax, minimaxAlphabeta, negamaxAlphaBeta, negamaxNoColor)

import Compare exposing (by, compose, maximum, reverse)
import GameTheory.ExtendedOrder as ExtendedOrder exposing (..)
import Html exposing (node)
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

Having said that, here are some efficiency refinements:

  - ´depth´ -- how deep to search from this node;
  - `maximizingPlayer` -- We assume we're the maximising player
  - `heuristic` -- a function that returns an approximate value of a move applied to the current position;
  - `getMoves` -- a function that generates valid moves from the current position;
  - `applyMove` -- a function that applies a move to a position and returns a new position;
  - `node` -- the current position.

`getMoves` and `applyMove` can't change for either side, they are the "game rules".

Instead of returning the calculated heuristic, return the best move, or `Nothing` if none.

Note that it's the game engine's responsibility to check whether the game is over (victory or stalemate), though `getMoves` might well be a way to implement that.

-}
minimax : Int -> (node -> move -> comparable) -> (node -> List move) -> (node -> move -> node) -> node -> Maybe move
minimax depth heuristic getMoves applyMove node0 =
    let
        {-
           Below is the actual implementation of the pseudocode above.
           Compared to the pseudocode, we make node_ the last argument to make it easier to partially apply
        -}
        minimax_ : Int -> Bool -> node -> move -> ExtendedOrder comparable
        minimax_ depth_ maximizingPlayer node1 move =
            if depth_ == 0 then
                Debug.log ("At depth " ++ String.fromInt depth_ ++ " and move " ++ Debug.toString move ++ " the heuristic value is ")
                    (heuristic node1 move |> Comparable)

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
                    Debug.log ("At depth " ++ String.fromInt depth_ ++ " and move " ++ Debug.toString move ++ " the heuristic value is ")
                        (heuristic node1 move |> Comparable)

                else if maximizingPlayer then
                    List.foldl ExtendedOrder.max NegativeInfinity <| List.map (minimax_ (depth_ - 1) False node2) moves

                else
                    List.foldl ExtendedOrder.min PositiveInfinity <| List.map (minimax_ (depth_ - 1) True node2) moves

        score : node -> move -> ( move, ExtendedOrder comparable )
        score node move =
            ( move, minimax_ depth True node move )

        -- note that sorting in this context means getting the highest score first, i.e. descending order, so the comparison is backwards compared to the usual.
        sort : ( move, ExtendedOrder comparable ) -> ( move, ExtendedOrder comparable ) -> Order
        sort ( move1, score1 ) ( move2, score2 ) =
            ExtendedOrder.compare score2 score1
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
minimaxAlphabeta : Int -> (node -> move -> comparable) -> (node -> List move) -> (node -> move -> node) -> node -> Maybe move
minimaxAlphabeta depth heuristic getMoves applyMove node =
    let
        {-
           Below is the actual implementation of the pseudocode above.
           Compared to the pseudocode, we make node_ the last argument to make it easier to partially apply
        -}
        alphabeta1 : Int -> ExtendedOrder comparable -> ExtendedOrder comparable -> Bool -> node -> move -> ExtendedOrder comparable
        alphabeta1 depth1 alpha1 beta1 maximizingPlayer node1 move1 =
            if depth1 == 0 then
                heuristic node1 move1 |> Comparable

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
                    heuristic node1 move1 |> Comparable

                else if maximizingPlayer then
                    let
                        cutoff : ExtendedOrder comparable -> ExtendedOrder comparable -> ExtendedOrder comparable -> List move -> ExtendedOrder comparable
                        cutoff value2 alpha2 beta2 moves2 =
                            case moves2 of
                                [] ->
                                    value2

                                move :: moves3 ->
                                    let
                                        value3 =
                                            ExtendedOrder.max value2 (alphabeta1 (depth1 - 1) alpha2 beta2 (not maximizingPlayer) node2 move)

                                        alpha3 =
                                            ExtendedOrder.max value3 alpha2
                                    in
                                    if ge alpha3 beta2 then
                                        -- beta cut-off
                                        value3

                                    else
                                        cutoff value3 alpha3 beta2 moves3
                    in
                    cutoff NegativeInfinity alpha1 beta1 (getMoves node2)

                else
                    let
                        cutoff : ExtendedOrder comparable -> ExtendedOrder comparable -> ExtendedOrder comparable -> List move -> ExtendedOrder comparable
                        cutoff value2 alpha2 beta2 moves2 =
                            case moves2 of
                                [] ->
                                    value2

                                move :: moves3 ->
                                    let
                                        value3 =
                                            ExtendedOrder.min value2 (alphabeta1 (depth1 - 1) alpha2 beta2 (not maximizingPlayer) node2 move)

                                        beta3 =
                                            ExtendedOrder.min value3 beta2
                                    in
                                    if ge alpha2 beta3 then
                                        -- alpha cut-off
                                        value3

                                    else
                                        cutoff value3 alpha2 beta3 moves3
                    in
                    cutoff PositiveInfinity alpha1 beta1 (getMoves node2)

        score : node -> move -> ( move, ExtendedOrder comparable )
        score node1 move1 =
            ( move1, alphabeta1 depth NegativeInfinity PositiveInfinity True node1 move1 )
    in
    node
        |> getMoves
        |> List.map (score node)
        |> maximum (compose Tuple.second ExtendedOrder.compare)
        |> Maybe.map Tuple.first



{- Negamax variant with no color parameter

    Negamax can be implemented without the color parameter.
    In this case, the heuristic evaluation function must return values from the point of view of the node's current player
    (Ex: In a chess game, if it is white's turn and white is winning, it should return a positive value. However if it is black's turn, it should return a negative value).


   function negamax(node, depth) is
       if depth = 0 or node is a terminal node then
           return evaluatePosition() // From current player's perspective
       value := −∞
       for each child of node do
           value := max(value, −negamax(child, depth − 1))
       return value

   // Example picking best move in a chess game using negamax function above
   function think(boardState) is
       allMoves := generateLegalMoves(boardState)
       bestMove := null
       bestEvaluation := -∞

       for each move in allMoves
           board.apply(move)
           evaluateMove := -negamax(boardState, depth=3)
           board.undo(move)
           if evaluateMove > bestEvaluation
               bestMove := move
               bestEvaluation := evaluateMove

       return bestMove

       The value of a position to player A in such a game is the negation of the value to player B
       i.e.
       evaluate
-}


negamaxNoColor : (node -> List move) -> (node -> move -> node) -> (node -> number) -> Int -> node -> Maybe move
negamaxNoColor getMoves makeMove scoreNode depth node =
    let
        negamaxNoColor_ : Int -> node -> number
        negamaxNoColor_ depth_ node_ =
            let
                children : List node
                children =
                    node_
                        |> getMoves
                        |> List.map (makeMove node_)
            in
            if depth_ == 0 then
                scoreNode node_

            else
                children
                    |> List.map (negamaxNoColor_ (depth_ - 1) >> Basics.negate)
                    |> List.maximum
                    |> Maybe.withDefault (scoreNode node_)
    in
    node
        |> getMoves
        |> List.map (\child -> ( child, child |> makeMove node |> negamaxNoColor_ depth ))
        |> maximum (by Tuple.second)
        |> Maybe.map Tuple.first



{- Negamax with alpha beta pruning

   An animated pedagogical example showing the negamax algorithm with alpha–beta pruning. The person performing the game tree search is considered to be the one that has to move first from the current state of the game (player in this case)
   Algorithm optimizations for minimax are also equally applicable for Negamax. Alpha–beta pruning can decrease the number of nodes the negamax algorithm evaluates in a search tree in a manner similar with its use with the minimax algorithm.

   The pseudocode for depth-limited negamax search with alpha–beta pruning follows:[1]

   function negamax(node, depth, α, β, color) is
       if depth = 0 or node is a terminal node then
           return color × the heuristic value of node

       childNodes := generateMoves(node)
       childNodes := orderMoves(childNodes)
       value := −∞
       foreach child in childNodes do
           value := max(value, −negamax(child, depth − 1, −β, −α, −color))
           α := max(α, value)
           if α ≥ β then
               break (* cut-off *)
       return value
   (* Initial call for Player A's root node *)
   negamax(rootNode, depth, −∞, +∞, 1)
-}


negamaxAlphaBeta : (node -> List move) -> (node -> move -> node) -> (node -> number) -> Int -> node -> Maybe move
negamaxAlphaBeta getMoves makeMove scoreNode depth node =
    let
        negamaxAlphaBeta_ : Int -> ExtendedOrder number -> ExtendedOrder number -> node -> ExtendedOrder number
        negamaxAlphaBeta_ depth_ alpha_ beta_ node_ =
            if depth_ == 0 then
                scoreNode node_ |> Comparable

            else
                let
                    sortedChildren : List node
                    sortedChildren =
                        node_
                            |> getMoves
                            |> List.map (makeMove node_)
                            |> List.map (\child -> ( child, scoreNode child ))
                            |> List.sortWith (by Tuple.second |> reverse)
                            |> List.map Tuple.first

                    foreach : List node -> ExtendedOrder number -> ExtendedOrder number -> ( ExtendedOrder number, ExtendedOrder number )
                    foreach children currentValue currentAlpha =
                        case children of
                            [] ->
                                ( currentValue, currentAlpha )

                            child :: rest ->
                                let
                                    newValue : ExtendedOrder number
                                    newValue =
                                        ExtendedOrder.max currentValue (ExtendedOrder.negate (negamaxAlphaBeta_ (depth_ - 1) (ExtendedOrder.negate beta_) (ExtendedOrder.negate currentAlpha) child))

                                    newAlpha : ExtendedOrder number
                                    newAlpha =
                                        ExtendedOrder.max currentAlpha newValue
                                in
                                if isPositive newAlpha then
                                    ( newValue, newAlpha )

                                else
                                    foreach rest newValue newAlpha

                    result : ( ExtendedOrder number, ExtendedOrder number )
                    result =
                        foreach sortedChildren NegativeInfinity alpha_
                in
                Tuple.first result
    in
    node
        |> getMoves
        |> List.map
            (\child ->
                ( child
                , child
                    |> makeMove node
                    |> negamaxAlphaBeta_ depth NegativeInfinity PositiveInfinity
                )
            )
        |> maximum (compose Tuple.second ExtendedOrder.compare)
        |> Maybe.map Tuple.first

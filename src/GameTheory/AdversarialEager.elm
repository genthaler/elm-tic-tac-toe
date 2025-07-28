module GameTheory.AdversarialEager exposing (negamax, negamaxWithPruning)

{-| This module implements adversarial search algorithms for game theory.

It provides eager evaluation variants of negamax algorithms with performance optimizations
including alpha-beta pruning and move ordering for efficient game tree search.


# Algorithms

  - **Negamax**: Game tree search using the negation property
  - **Negamax with Pruning**: Optimized version with alpha-beta pruning


# Performance Features

  - **Alpha-beta pruning**: Eliminates branches that cannot improve the result
  - **Move ordering**: Processes better moves first for more effective pruning
  - **Configurable depth**: Allows depth-limited search for time constraints
  - **Extended order support**: Handles infinite values for terminal positions


# Usage

The algorithms are generic and work with any two-player zero-sum game that provides:

  - Position evaluation function
  - Move generation function
  - Move application function
  - Terminal state detection
  - Move ordering function (for pruning version)

-}

import GameTheory.ExtendedOrder as ExtendedOrder exposing (ExtendedOrder(..))


{-| Negamax algorithm implementation for finding the best move in a two-player zero-sum game.
The negamax algorithm simplifies game tree search implementation by using
the fact that max(a, b) = -min(-a, -b).

Parameters:

  - evaluate: Function to evaluate a position for the current player
  - generateMoves: Function to generate all possible moves from a position
  - applyMove: Function to apply a move to a position
  - isTerminal: Function to check if a position is terminal (game over)
  - depth: Maximum search depth
  - position: Current game position

Returns the best score for the current player as an ExtendedOrder Int.

-}
negamax :
    (position -> Int)
    -> (position -> List move)
    -> (move -> position -> position)
    -> (position -> Bool)
    -> Int
    -> position
    -> ExtendedOrder Int
negamax evaluate generateMoves applyMove isTerminal depth position =
    if depth == 0 || isTerminal position then
        Comparable (evaluate position)

    else
        let
            moves =
                generateMoves position

            evaluateMove move =
                let
                    newPosition =
                        applyMove move position

                    score =
                        negamax
                            (\pos -> -(evaluate pos))
                            -- Negate for opponent
                            generateMoves
                            applyMove
                            isTerminal
                            (depth - 1)
                            newPosition
                in
                ExtendedOrder.negate score

            scores =
                List.map evaluateMove moves
        in
        case scores of
            [] ->
                -- No moves available, return current evaluation
                Comparable (evaluate position)

            _ ->
                List.foldl ExtendedOrder.max NegativeInfinity scores


{-| Optimized negamax algorithm with alpha-beta pruning for better performance.
This version includes move ordering and pruning to reduce the search space significantly.

Parameters:

  - evaluate: Function to evaluate a position for the current player
  - generateMoves: Function to generate all possible moves from a position
  - applyMove: Function to apply a move to a position
  - isTerminal: Function to check if a position is terminal (game over)
  - orderMoves: Function to order moves for better pruning (best moves first)
  - depth: Maximum search depth
  - alpha: Alpha value for pruning (best value for maximizing player)
  - beta: Beta value for pruning (best value for minimizing player)
  - position: Current game position

Returns the best score for the current player as an ExtendedOrder Int.

-}
negamaxWithPruning :
    (position -> Int)
    -> (position -> List move)
    -> (move -> position -> position)
    -> (position -> Bool)
    -> (position -> List move -> List move)
    -> Int
    -> Int
    -> Int
    -> position
    -> ExtendedOrder Int
negamaxWithPruning evaluate generateMoves applyMove isTerminal orderMoves depth alpha beta position =
    if depth == 0 || isTerminal position then
        Comparable (evaluate position)

    else
        let
            moves =
                generateMoves position
                    |> orderMoves position

            searchMoves currentAlpha remainingMoves bestScore =
                case remainingMoves of
                    [] ->
                        bestScore

                    move :: restMoves ->
                        let
                            newPosition =
                                applyMove move position

                            score =
                                negamaxWithPruning
                                    (\pos -> -(evaluate pos))
                                    generateMoves
                                    applyMove
                                    isTerminal
                                    orderMoves
                                    (depth - 1)
                                    -beta
                                    -currentAlpha
                                    newPosition
                                    |> ExtendedOrder.negate

                            newBestScore =
                                ExtendedOrder.max bestScore score

                            newAlpha =
                                case score of
                                    Comparable value ->
                                        max currentAlpha value

                                    _ ->
                                        currentAlpha
                        in
                        -- Alpha-beta pruning: if alpha >= beta, we can stop searching
                        if newAlpha >= beta then
                            newBestScore

                        else
                            searchMoves newAlpha restMoves newBestScore
        in
        case moves of
            [] ->
                -- No moves available, return current evaluation
                Comparable (evaluate position)

            _ ->
                searchMoves alpha moves NegativeInfinity

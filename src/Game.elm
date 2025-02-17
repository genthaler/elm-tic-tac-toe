module Game exposing (evaluateMove, findBestMove, moveMade, possibleMoves, scoreBoard)

{-| This module contains the game logic for Tic-tac-toe.
It implements the game rules, move validation, and AI opponent using the minimax algorithm.
-}

import ExtendedOrder exposing (..)
import List.Extra as ListExtra
import Maybe
import Model exposing (Board, Line, Model, Player(..), Position)



-- Game Logic


negate : ExtendedOrder number -> ExtendedOrder number
negate =
    ExtendedOrder.map ((*) -1)


{-| Returns the opposite player (X -> O, O -> X)
-}
nextPlayer : Player -> Player
nextPlayer player =
    case player of
        X ->
            O

        O ->
            X


{-| Checks if there is a winner on the board by examining all possible lines.
Returns Maybe Player, where Nothing means no winner yet.
-}
checkWinner : Board -> Maybe Player
checkWinner board =
    let
        lines : List Line
        lines =
            getLines board
    in
    List.head (List.filterMap checkLine lines)


{-| Checks a single line for a winner.
Returns Maybe Player if all positions in the line are occupied by the same player.
-}
checkLine : Line -> Maybe Player
checkLine line =
    case line of
        [ Just p1, Just p2, Just p3 ] ->
            if p1 == p2 && p2 == p3 then
                Just p1

            else
                Nothing

        _ ->
            Nothing


{-| Calculates a score for a single line based on the player's perspective.
Returns:

  - 0 if line is empty or blocked
  - 10^n where n is number of player's pieces (if no opponent pieces)
  - -10^n where n is number of opponent's pieces (if no player pieces)

-}
scoreLine : Player -> Line -> Int
scoreLine player line =
    let
        count : Player -> Int
        count player_ =
            line
                |> List.filter (\p -> p == Just player_)
                |> List.length

        playerCount : Int
        playerCount =
            count player

        nextPlayerCount : Int
        nextPlayerCount =
            count (nextPlayer player)
    in
    case ( playerCount, nextPlayerCount ) of
        ( 0, 0 ) ->
            0

        ( c, 0 ) ->
            10 ^ c

        ( 0, c ) ->
            -(10 ^ c)

        _ ->
            0


{-| Scores a board position for a given player.

Returns an integer score representing how favorable the position is for the player.
Positive scores favor the player, negative scores favor the opponent.
The magnitude of the score indicates the strength of the position.

Note that this isn't a perfect scoring function. It should for example score higher for forks or potential forks.

-}
scoreBoard : Player -> Board -> Int
scoreBoard player =
    getLines >> List.map (scoreLine player) >> List.sum


{-| Returns all possible winning lines on the board, including:

  - Rows (horizontal)
  - Columns (vertical)
  - Both diagonals

-}
getLines : Board -> List Line
getLines board =
    getDiagonal board :: getAntiDiagonal board :: board ++ ListExtra.transpose board


{-| Returns the main diagonal of the board (top-left to bottom-right)
-}
getDiagonal : Board -> Line
getDiagonal board =
    List.indexedMap (\i row -> ListExtra.getAt i row) board
        |> List.filterMap identity


{-| Returns the anti-diagonal of the board (top-right to bottom-left)
-}
getAntiDiagonal : Board -> Line
getAntiDiagonal board =
    List.indexedMap (\i row -> ListExtra.getAt (List.length row - 1 - i) row) board
        |> List.filterMap identity


{-| Places a player's piece on the board at the specified position.
Returns the new board state after the move.
-}
makeMove : Board -> Position -> Player -> Board
makeMove board { row, col } player =
    List.indexedMap
        (\rIdx rowList ->
            if rIdx == row then
                List.indexedMap
                    (\cIdx cell ->
                        if cIdx == col && cell == Nothing then
                            Just player

                        else
                            cell
                    )
                    rowList

            else
                rowList
        )
        board


{-| Processes a move made by a player at the given position.
Returns an updated Model with the new board state and possibly a winner.
-}
moveMade : Model -> Position -> Model
moveMade model position =
    let
        newBoard : List Line
        newBoard =
            makeMove model.board position model.currentPlayer

        winner : Maybe Player
        winner =
            checkWinner newBoard

        newPlayer : Player
        newPlayer =
            case winner of
                Just player ->
                    player

                Nothing ->
                    nextPlayer model.currentPlayer
    in
    { model
        | board = newBoard
        , winner = winner
        , currentPlayer = newPlayer
    }


{-| Returns a list of available positions on the board where moves can be made.
-}
possibleMoves : Board -> List Position
possibleMoves board =
    List.concatMap
        (\( rowIdx, row ) ->
            List.indexedMap
                (\colIdx cell ->
                    if cell == Nothing then
                        Just (Position rowIdx colIdx)

                    else
                        Nothing
                )
                row
                |> List.filterMap identity
        )
        (List.indexedMap Tuple.pair board)



-- Negamax with Alpha-Beta Pruning (no depth check)


{-| Implements the negamax algorithm with alpha-beta pruning for move evaluation.
Returns a score representing how good the position is for the current player.
Higher scores are better for the current player.
-}
negamaxAlphaBeta : Model -> ExtendedOrder Int -> ExtendedOrder Int -> ExtendedOrder Int
negamaxAlphaBeta model alpha beta =
    case model.winner of
        Just player ->
            Comparable (scoreBoard player model.board)

        Nothing ->
            let
                possibleChildren : List Model
                possibleChildren =
                    possibleMoves model.board
                        |> List.map (moveMade model)

                orderedChildren : List Model
                orderedChildren =
                    possibleChildren
                        |> List.sortBy (\child -> scoreBoard child.currentPlayer child.board)

                foreach : List Model -> ExtendedOrder Int -> ExtendedOrder Int -> ( ExtendedOrder Int, ExtendedOrder Int )
                foreach children currentValue currentAlpha =
                    case children of
                        [] ->
                            ( currentValue, currentAlpha )

                        child :: rest ->
                            let
                                newValue : ExtendedOrder Int
                                newValue =
                                    ExtendedOrder.max currentValue (negate (negamaxAlphaBeta child (negate beta) (negate currentAlpha)))

                                newAlpha : ExtendedOrder Int
                                newAlpha =
                                    ExtendedOrder.max currentAlpha newValue
                            in
                            if ge newAlpha beta then
                                ( newValue, newAlpha )

                            else
                                foreach rest newValue newAlpha

                result : ( ExtendedOrder Int, ExtendedOrder Int )
                result =
                    foreach orderedChildren ExtendedOrder.NegativeInfinity alpha
            in
            Tuple.first result


{-| Evaluates a potential move by simulating it and using the minimax algorithm.
Returns an integer score representing how good the move is.
-}
evaluateMove : Model -> Position -> ExtendedOrder Int
evaluateMove model position =
    negamaxAlphaBeta (moveMade model position) ExtendedOrder.NegativeInfinity ExtendedOrder.PositiveInfinity


{-| Finds the best possible move for the current player using the minimax algorithm.
Returns a Maybe Position representing the optimal move.
-}
findBestMove : Model -> Maybe Position
findBestMove model =
    possibleMoves model.board
        |> List.map (\position -> ( evaluateMove model position |> negate, position ))
        |> List.sortWith (\( a, _ ) ( b, _ ) -> ExtendedOrder.compare a b)
        |> List.map (Debug.log "candidates")
        |> List.head
        |> Maybe.map Tuple.second

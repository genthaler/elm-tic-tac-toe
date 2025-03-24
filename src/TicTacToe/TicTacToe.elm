module TicTacToe.TicTacToe exposing (checkWinner, findBestMove, makeMove, moveMade, nextPlayer, possibleMoves, scoreBoard, scoreLine)

{-| This module contains the game logic for Tic-tac-toe.
It implements the game rules, move validation, and AI opponent using the minimax algorithm.
-}

import GameTheory.AdversarialEager exposing (negamaxAlphaBeta)
import GameTheory.ExtendedOrder exposing (..)
import List.Extra as ListExtra
import Model exposing (Board, Line, Model, Player(..), Position)



-- Game Logic


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
            (10 ^ c) * -1

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
        , lastMove = model.now
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


{-| Finds the best possible move for the current player using the negamax algorithm.
Returns a Maybe Position representing the optimal move.
-}
findBestMove : Model -> Maybe Position
findBestMove model =
    -- this is almost certainly incorrect, the application of current player is probably incorrect
    negamaxAlphaBeta (.board >> possibleMoves) moveMade (\model_ -> scoreBoard (nextPlayer model_.currentPlayer) model_.board) 9 model

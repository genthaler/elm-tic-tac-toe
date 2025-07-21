module TicTacToe.TicTacToe exposing (GameWon(..), checkWinner, findBestMove, makeMove, moveMade, nextPlayer, possibleMoves, scoreBoard, scoreLine, scoreModel)

{-| This module contains the game logic for Tic-tac-toe.
It implements the game rules, move validation, and AI opponent using the minimax algorithm.
-}

import GameTheory.AdversarialEager exposing (negamax, negamaxAlphaBeta)
import GameTheory.ExtendedOrder exposing (..)
import List.Extra as ListExtra
import Maybe.Extra
import Model exposing (Board, GameState(..), Line, Model, Player(..), Position)



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


type GameWon
    = Won Player
    | Drew


{-| Checks if there is a winner on the board by examining all possible lines.
Returns Maybe GameWon, where Nothing means no winner yet.
-}
checkWinner : Board -> Maybe GameWon
checkWinner board =
    let
        lines : List Line
        lines =
            getLines board
    in
    lines
        |> List.filterMap checkLine
        |> List.head
        |> Maybe.map Won
        |> Maybe.Extra.orElseLazy
            (\() ->
                if List.concat lines |> List.filter Maybe.Extra.isNothing |> List.isEmpty then
                    Just Drew

                else
                    Nothing
            )


{-| Checks a single line for a winner.
Returns Maybe Player if all positions in the line are occupied by the same player.
-}
checkLine : Line -> Maybe Player
checkLine line =
    case line of
        [ Just X, Just X, Just X ] ->
            Just X

        [ Just O, Just O, Just O ] ->
            Just O

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
makeMove : Player -> Board -> Position -> Board
makeMove player board { row, col } =
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
            case model.gameState of
                Waiting player ->
                    makeMove player model.board position

                Thinking player ->
                    makeMove player model.board position

                _ ->
                    model.board

        newGameState : GameState
        newGameState =
            case ( model.gameState, checkWinner newBoard ) of
                ( Error error, _ ) ->
                    Error error

                ( Winner _, _ ) ->
                    Error "Game was already won"

                ( Draw, _ ) ->
                    Error "Game was already drawn"

                ( Thinking _, Just (Won winner) ) ->
                    Winner winner

                ( Waiting _, Just (Won winner) ) ->
                    Winner winner

                ( Thinking _, Just Drew ) ->
                    Draw

                ( Waiting _, Just Drew ) ->
                    Draw

                ( Thinking player, Nothing ) ->
                    Waiting (nextPlayer player)

                ( Waiting player, Nothing ) ->
                    Waiting (nextPlayer player)
    in
    { model
        | board = newBoard
        , gameState = newGameState
        , lastMove = model.now
    }


{-| Returns a list of available positions on the board where moves can be made.
-}
possibleMoves : Player -> Board -> List Position
possibleMoves _ board =
    case checkWinner board of
        Nothing ->
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

        _ ->
            []


{-| Scores the board from the point of view of the player that put the board in its current position.
-}
scoreModel : Model -> Int
scoreModel model =
    case model.gameState of
        Winner winner ->
            scoreBoard winner model.board

        Waiting player ->
            scoreBoard (nextPlayer player) model.board

        Thinking player ->
            scoreBoard (nextPlayer player) model.board

        Draw ->
            0

        Error _ ->
            0


isTerminal : Board -> Bool
isTerminal node =
    checkWinner node /= Nothing


{-| Finds the best possible move for the current player using the negamax algorithm.
Returns a Maybe Position representing the optimal move.
-}
findBestMove : Player -> Board -> Maybe Position
findBestMove player board =
    negamax possibleMoves makeMove scoreBoard isTerminal nextPlayer 9 player board

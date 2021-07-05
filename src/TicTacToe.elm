module TicTacToe exposing
    ( Board
    , Game
    , Move
    , Player(..)
    , alphabetaGame
    , getMoves
    , getWinningPositions
    , indexToPosition
    , initGame
    , minimaxGame
    , positionToIndex
    , restoreGame
    , scoreGame
    , scoreLine
    , updateGame
    )

import AdversarialEager exposing (alphabeta, minimax)
import Array exposing (Array)
import List.Extra


{-| TicTacToe has 2 players
-}
type Player
    = O
    | X


{-| TicTacToe is usually played on a 3x3 grid
-}
type alias Board =
    Array (Maybe Player)


{-| At any time, it's someone's turn to play on the board
-}
type alias Game =
    { player : Player
    , board : Board
    }


{-| (x,y) position / coordinates
-}
type alias Position =
    ( Int, Int )


{-| A possible move a player can make
-}
type alias Move =
    { player : Player
    , position : Position
    }


{-| TicTacToe is usually played on a 3x3 grid, starting with no pieces laid.
for such a simple case, don't worry about a Matrix data structure,
we can manage manually with a list of 3\*3 length
-}
initBoard : Board
initBoard =
    Array.repeat 9 Nothing


{-| Let's assume for now that X goes first

    Ok TicTacToe.initGame --> restoreGame X [[Nothing, Nothing, Nothing], [Nothing, Nothing, Nothing], [Nothing, Nothing, Nothing]]

-}
initGame : Game
initGame =
    Game X initBoard


{-| convert from index to coordinates

    TicTacToe.indexToPosition 0 --> (0, 0)

    TicTacToe.indexToPosition 8 --> (2, 2)

-}
indexToPosition : Int -> ( Int, Int )
indexToPosition i =
    ( i // 3, remainderBy 3 i )


{-| convert from coordinates to index

    TicTacToe.positionToIndex ( 0, 0 ) --> 0

    TicTacToe.positionToIndex ( 2, 1 ) --> 7

-}
positionToIndex : ( Int, Int ) -> Int
positionToIndex ( x, y ) =
    x * 3 + y


{-| Sometimes we want to create a board from lists; especially for testing
-}
restoreGame : Player -> List (List (Maybe Player)) -> Result String Game
restoreGame player lists =
    let
        board =
            lists |> List.concat |> Array.fromList
    in
    case Array.length board of
        9 ->
            Result.Ok { player = player, board = board }

        len ->
            Result.Err ("Invalid board length: " ++ String.fromInt len)


{-| get the other player
-}
swapPlayer : Player -> Player
swapPlayer currentPlayer =
    case currentPlayer of
        X ->
            O

        O ->
            X


{-| get the other player
-}
swapMaybePlayer : Maybe Player -> Maybe Player
swapMaybePlayer currentPlayer =
    case currentPlayer of
        Just X ->
            Just O

        Just O ->
            Just X

        _ ->
            Nothing


{-| Update the game based on the clicked position
-}
updateGame : ( Int, Int ) -> Game -> Game
updateGame coordinates game =
    let
        game_ =
            { game | board = Array.set (positionToIndex coordinates) (Just game.player) game.board }
    in
    if game_ |> getWinningPositions |> List.isEmpty then
        { game_ | player = swapPlayer game_.player }

    else
        game_


getMoves : Game -> List Move
getMoves game =
    let
        getEmpty ( i, a ) =
            case a of
                Nothing ->
                    Just (Move game.player (indexToPosition i))

                _ ->
                    Nothing
    in
    game.board
        |> Array.toIndexedList
        |> List.filterMap getEmpty
        |> List.sortBy (applyMove game >> scoreGame)



-- create a list of each row, column and diagonal, to be used to score a board
-- there's almost certainly a clever, succinct mathematical way to do this, but cbf
-- I did give it a go using a matrix library, but there was much more code than below


lines : Game -> List (List ( Int, Maybe Player ))
lines game =
    case Array.toIndexedList game.board of
        [ p0, p1, p2, p3, p4, p5, p6, p7, p8 ] ->
            -- rows
            [ [ p0, p1, p2 ]
            , [ p3, p4, p5 ]
            , [ p6, p7, p8 ]

            -- columns
            , [ p0, p3, p6 ]
            , [ p1, p4, p7 ]
            , [ p2, p5, p8 ]

            -- diagonals
            , [ p0, p4, p8 ]
            , [ p2, p4, p6 ]
            ]

        _ ->
            -- ideally return a Result.Err, but no real need
            []



{--
    Score
    1 for each line with 1 of mine and none of theirs
    10 for each line with 2 of mine and none of theirs
    100 for each line with 3 of mine
    Scored from the perspective of the current player `game.board`
-}


scoreLine : Player -> List ( Int, Maybe Player ) -> Int
scoreLine player line =
    let
        line_ =
            List.map Tuple.second line
    in
    if List.member (swapMaybePlayer (Just player)) line_ then
        0

    else
        line_ |> List.filterMap identity |> List.length


scoreGame : Game -> Int
scoreGame game =
    let
        us =
            game.player

        them =
            swapPlayer us

        lines_ : List (List ( Int, Maybe Player ))
        lines_ =
            lines game

        scoreGame_ : Player -> Int
        scoreGame_ player =
            lines_ |> List.map (scoreLine player) |> List.map ((^) 10) |> List.sum
    in
    scoreGame_ us - scoreGame_ them


{-| To display a winning game nicely, we need to
get the lines with 3 of the current player,
then flatten that,
then get the unique positions of that (there could have been some overlap)
-}
getWinningPositions : Game -> List ( Int, Int )
getWinningPositions game =
    let
        -- a winning line has 3 of current player
        hasThree =
            List.filterMap Tuple.second >> List.filter ((==) game.player) >> List.length >> (==) 3
    in
    game |> lines |> List.filter hasThree |> List.concat |> List.map Tuple.first |> List.Extra.unique |> List.sort |> List.map indexToPosition


{-| in highest first order,

  - count of 3 on a line
  - count of 2 on a line + 1 blank
  - count of 1 on a line + 2 blank
  - count of alone on an empty line
  - 0

implemented as 10^n \* (number of lines with n) which is to say that e.g. 3 on a line is an order of magnitude better than 2 on a line

-}
heuristic : Game -> Move -> Int
heuristic game move =
    applyMove game move |> scoreGame


applyMove : Game -> Move -> Game
applyMove game move =
    { game | board = Array.set (positionToIndex move.position) (Just move.player) game.board }


{-| For minimax/alphabeta, here are the required parameters

  - ´depth´ -- how deep to search from this node;
  - `heuristic` -- a function that returns an approximate value of the current position;
  - `getMoves` -- a function that generates valid moves from the current position;
  - \`applyMoves -- a function that applies a move to the current position
  - `node` -- the current game.

For tic-tac-toe, these correspond to

  - depth - 9; that's as long as the game can go
  - heuristic - in rank, the best is a winning position, followed by number of open winning positions, followed by postions on an empty line, else 0
  - getMoves - any open position
  - applyMove - overwrite the given position with the given player. Maybe do some validation to be sure it isn't take due to a logic bug.

-}
minimaxGame : Game -> Maybe Move
minimaxGame =
    minimax 9 heuristic getMoves applyMove


alphabetaGame : Game -> Maybe Move
alphabetaGame =
    alphabeta 9 heuristic getMoves applyMove

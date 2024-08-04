module TicTacToe exposing
    ( Board
    , Game
    , GameState(..)
    , Player(..)
    , alphabetaFullGame
    , alphabetaFullGamePrinted
    , alphabetaGame
    , gameStateToString
    , gameToString
    , getWinningPositions
    , heuristic
    , initGame
    , minimaxGame
    , moves
    , play
    , playerToString
    , restoreGame
    , score
    , scoreLine
    , try
    )

import AdversarialEager exposing (alphabetaMove, minimaxMove)
import Array exposing (Array)
import List exposing (sort)
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


{-| Game can be in progress, over, or in some error state
-}
type GameState
    = InProgress Player
    | GameWon Player
    | Stalemate
    | GameError String


{-| At any time, it's someone's turn to play on the board
-}
type alias Game =
    { board : Board
    , gameState : GameState
    }


{-| Let's assume for now that X goes first

TicTacToe is usually played on a 3x3 grid, starting with no pieces laid.
for such a simple case, don't worry about a Matrix data structure,
we can manage manually with a list of 3\*3 length

    TicTacToe.initGame --> restoreGame X [[Nothing, Nothing, Nothing], [Nothing, Nothing, Nothing], [Nothing, Nothing, Nothing]]

-}
initGame : Game
initGame =
    Game (Array.repeat 9 Nothing) (InProgress X)


positionToString : Int -> String
positionToString position =
    "( " ++ String.fromInt (position // 3) ++ ", " ++ String.fromInt (remainderBy 3 position) ++ " )"


{-| Sometimes we want to create a board from lists; especially for testing
-}
restoreGame : Player -> List (List (Maybe Player)) -> Game
restoreGame player lists =
    let
        board =
            lists |> List.concat |> Array.fromList

        gameState =
            case Array.length board of
                9 ->
                    InProgress player

                len ->
                    GameError ("Invalid board length: " ++ String.fromInt len)
    in
    Game board gameState |> updateGameState


playerToString : Maybe Player -> String
playerToString player =
    case player of
        Nothing ->
            " "

        Just X ->
            "X"

        Just O ->
            "O"


gameStateToString : GameState -> String
gameStateToString gameState =
    case gameState of
        GameWon player ->
            "Winner, Player " ++ playerToString (Just player)

        Stalemate ->
            "It's a tie!"

        InProgress player ->
            "In Progress, Player " ++ playerToString (Just player) ++ "'s turn"

        GameError err ->
            "Error " ++ err


gameToString : Game -> String
gameToString game =
    let
        newLine i =
            if modBy 3 i == 0 then
                "\n"
                -- ""

            else
                ""

        boardToString : Board -> String
        boardToString =
            Array.toIndexedList >> List.map (\( i, mp ) -> playerToString mp ++ newLine i) >> List.foldl (++) ""
    in
    gameStateToString game.gameState ++ "\n" ++ boardToString game.board


{-| get the other player
-}
otherPlayer : Player -> Player
otherPlayer currentPlayer =
    case currentPlayer of
        X ->
            O

        O ->
            X


updateGameState : Game -> Game
updateGameState game =
    { game
        | gameState =
            case game.gameState of
                InProgress player ->
                    if game |> getWinningPositions |> List.isEmpty |> not then
                        GameWon player

                    else if game |> moves |> List.isEmpty then
                        Stalemate

                    else
                        InProgress player

                other ->
                    other
    }


{-| Play a move, but don't swap players yet
-}
try : Game -> Int -> Game
try game position =
    case Array.get position game.board of
        Nothing ->
            { game | gameState = GameError ("Position " ++ String.fromInt position ++ " is invalid") }

        Just piece ->
            case piece of
                Just _ ->
                    { game | gameState = GameError ("Position " ++ positionToString position ++ " is already occupied") }

                Nothing ->
                    case game.gameState of
                        InProgress player ->
                            { game | board = Array.set position (Just player) game.board }

                        _ ->
                            { game | gameState = GameError "Expected game to be in InProgress " }


{-| Play the move, and swap players if appropriate
-}
play : Game -> Int -> Game
play game position =
    let
        game_ =
            try game position |> updateGameState
    in
    case game_.gameState of
        InProgress player ->
            { game_ | gameState = InProgress (otherPlayer player) }

        _ ->
            game_


moves : Game -> List Int
moves game =
    let
        getEmpty : ( Int, Maybe Player ) -> Maybe Int
        getEmpty ( i, a ) =
            case a of
                Nothing ->
                    Just i

                _ ->
                    Nothing

        -- get a stable sort order for testing
        sortable : Int -> ( Int, Int )
        sortable position =
            try game position
                |> score
                |> (\r -> ( r, position ))

        sort : ( Int, Int ) -> ( Int, Int ) -> Order
        sort ( r1, p1 ) ( r2, p2 ) =
            case compare r1 r2 of
                EQ ->
                    compare p1 p2

                cr ->
                    reverse cr

        reverse : Order -> Order
        reverse order =
            case order of
                EQ ->
                    EQ

                GT ->
                    LT

                LT ->
                    GT
    in
    game.board
        |> Array.toIndexedList
        |> List.filterMap getEmpty
        |> List.map sortable
        |> List.sortWith sort
        |> List.map Tuple.second



-- (play game >> score)


{-| Create a list of each row, column and diagonal, to be used to score a board

There's almost certainly a clever, succinct mathematical way to do this, but cbf
I did give it a go using a matrix library, but there was much more code than below

-}
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
    We're scoring as though the given player had just moved, so they have priority

    -100000 if three of theirs
    orelse
    10000 if three of ours
    orelse
    -1000 if two of theirs and none of ours
    orelse
    100 if two of ours and none of theirs
    -10 if one of theirs and none of ours
    orelse
    1 for one of ours and none of theirs
    orelse 
    0
    Scored from the perspective of the current player `game.board`

-}


scoreLine : Player -> List ( Int, Maybe Player ) -> Int
scoreLine us line =
    let
        line_ =
            line |> List.map Tuple.second |> List.filterMap identity

        usCount =
            line_ |> List.filter ((==) us) |> List.length

        themCount =
            line_ |> List.filter ((==) (otherPlayer us)) |> List.length
    in
    if usCount > 0 && themCount > 0 then
        0

    else if themCount == 3 then
        -100000

    else if themCount == 2 then
        -1000

    else if themCount == 1 then
        -10

    else if usCount == 3 then
        10000

    else if usCount == 2 then
        100

    else if usCount == 1 then
        1

    else
        0


{-| Score the game.

Note that this from the point of view of the current player in the game.

-}
score : Game -> Int
score game =
    let
        lines_ : List (List ( Int, Maybe Player ))
        lines_ =
            lines game

        scoreGame_ : Player -> Int
        scoreGame_ player =
            lines_
                |> List.map (scoreLine player)
                |> List.sum
    in
    case game.gameState of
        InProgress player ->
            scoreGame_ player - scoreGame_ (otherPlayer player)

        _ ->
            0


{-| To display a winning game nicely, we need to
get the lines with 3 of the current player,
then flatten that,
then get the unique positions of that (there could have been some overlap)
-}
getWinningPositions : Game -> List Int
getWinningPositions game =
    let
        -- a winning line has 3 of current player
        hasThree player =
            List.filterMap Tuple.second
                >> List.filter ((==) player)
                >> List.length
                >> (==) 3

        winningPositions player =
            game
                |> lines
                |> List.filter (hasThree player)
                |> List.concat
                |> List.map Tuple.first
                |> List.Extra.unique
                |> List.sort
    in
    case game.gameState of
        GameWon player ->
            winningPositions player

        InProgress player ->
            winningPositions player

        _ ->
            []


{-| in highest first order,

  - count of 3 on a line
  - count of 2 on a line + 1 blank
  - count of 1 on a line + 2 blank
  - count of alone on an empty line
  - 0

implemented as 10^n \* (number of lines with n) which is to say that e.g. 3 on a line is an order of magnitude better than 2 on a line

Note that

-}
heuristic : Game -> Int -> Int
heuristic game position =
    let
        game_ =
            try game position
    in
    case game.gameState of
        InProgress _ ->
            score game_

        GameWon _ ->
            1000000

        Stalemate ->
            0

        GameError _ ->
            -1000000


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
minimaxGame : Game -> Maybe Int
minimaxGame =
    minimaxMove 9 heuristic moves play


alphabetaGame : Game -> Maybe Int
alphabetaGame =
    alphabetaMove 9 heuristic moves play


alphabetaFullGame : Game -> List ( Int, Game )
alphabetaFullGame game =
    let
        maybeMove =
            alphabetaMove 9 heuristic moves play game
    in
    case maybeMove of
        Nothing ->
            []

        Just move ->
            let
                game_ =
                    play game move
            in
            case game_.gameState of
                GameError _ ->
                    [ ( move, game_ ) ]

                GameWon _ ->
                    [ ( move, game_ ) ]

                Stalemate ->
                    [ ( move, game_ ) ]

                InProgress _ ->
                    ( move, game_ )
                        :: alphabetaFullGame game_


alphabetaFullGamePrinted : String
alphabetaFullGamePrinted =
    alphabetaFullGame initGame
        |> List.map (Tuple.mapBoth positionToString gameToString)
        |> List.map (\( p, g ) -> p ++ "\n" ++ g)
        |> String.join "\n"

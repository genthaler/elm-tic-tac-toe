module Game exposing
    ( Board
    , Game
    , Player(..)
    , getBestMove
    , getChildren
    , getOpenPositions
    , heuristic
    , initGame
    , isGameOver
    , restoreGame
    , updateGame
    )

import AdversarialPure exposing (alphabeta, minimax)
import Basics.Extra
import Bool.Extra
import Dict.Extra
import Matrix
import Maybe
import Maybe.Extra


type Player
    = O
    | X


type alias Board =
    Matrix.Matrix (Maybe Player)


type alias Game =
    { player : Player
    , board : Board
    }


initBoard : Board
initBoard =
    Matrix.repeat 3 3 Nothing


initGame : Game
initGame =
    { board = initBoard, player = X }


restoreGame : Player -> List (List (Maybe Player)) -> Maybe Game
restoreGame player lists =
    lists
        |> Matrix.fromLists
        |> Maybe.map (Game player)


lines : List (List ( Int, Int ))
lines =
    let
        r : List Int
        r =
            List.range 0 2

        rows : List (List ( Int, Int ))
        rows =
            r |> List.map (\i -> r |> List.map (Tuple.pair i))

        columns : List (List ( Int, Int ))
        columns =
            r |> List.map (\i -> r |> List.map (Basics.Extra.flip Tuple.pair i))

        diagonals : List (List ( Int, Int ))
        diagonals =
            [ List.map (\i -> ( i, i )) r
            , List.map (\i -> ( i, 2 - i )) r
            ]
    in
    rows ++ columns ++ diagonals


updatePlayer : Player -> Player
updatePlayer currentPlayer =
    case currentPlayer of
        X ->
            O

        O ->
            X


updateGame : Int -> Int -> Game -> Game
updateGame x y { board, player } =
    { board = Matrix.set x y (Just player) board
    , player = updatePlayer player
    }


getOpenPositions : Game -> List ( Int, Int )
getOpenPositions =
    .board
        >> Matrix.indexedMap
            (\i j a ->
                if a == Nothing then
                    Just ( i, j )

                else
                    Nothing
            )
        >> Matrix.toList
        >> List.filterMap Basics.identity


getChildren : Game -> List Game
getChildren game =
    game
        |> getOpenPositions
        |> List.map (\( i, j ) -> updateGame i j game)


isGameOver : Game -> Bool
isGameOver game =
    heuristic game > 1000000 || getBestMove game == Nothing


getWinningLines : Game -> List (List ( Int, Int ))
getWinningLines game =
    let
        getPlayer : ( Int, Int ) -> Maybe Player
        getPlayer ( i, j ) =
            Matrix.get i j game.board |> Maybe.Extra.join

        -- fill out lines with current players at those positions
        linesWithPlayers : List (List ( ( Int, Int ), Maybe Player ))
        linesWithPlayers =
            lines |> List.map (List.map (\ij -> ( ij, getPlayer ij )))

        enemy =
            updatePlayer game.player

        noEnemyHere ( ij, maybePlayer ) =
            maybePlayer /= Just enemy

        -- get lines that have no enemy on them
        availableLinesWithPlayers =
            linesWithPlayers
                |> List.filter (List.foldl (noEnemyHere >> (&&)) True)

        -- only have to count not Nothing
        dict =
            availableLinesWithPlayers |> Dict.Extra.groupBy (\l -> List.) 
    in
    lines


{-| in highest first order,

  - count of 3 on a line
  - count of 2 on a line + 1 blank
  - count of 1 on a line + 2 blank
  - count of alone on an empty line
  - 0

-}
heuristic : Game -> Int
heuristic { player, board } =
    let
        enemy =
            updatePlayer player

        z : List (List (Maybe Player))
        z =
            lines |> List.map (List.map (\( i, j ) -> Matrix.get i j board |> Maybe.withDefault Nothing))
    in
    0



-- z |> List.filter (List.)


{-| For minimax, here are the required parameters

  - ´depth´ -- how deep to search from this node;
  - `maximizingPlayer` -- whose point of view we're searching from;
  - `heuristic` -- a function that returns an approximate value of the current position;
  - `getChildren` -- a function that generates valid positions from the current position;
  - `node` -- the current position.

For tic-tac-toe, these correspond to

  - depth - 9; that's as long as the game can go
  - heuristic - in rank, the best is a winning position, followed by number of open winning positions, followed by postions on an empty line, else 0
  - getChildren - if it's your go, you can go anywhere

-}
getBestMove : Game -> Maybe ( Int, Int )
getBestMove game =
    game |> getOpenPositions |> List.sortBy (\( i, j ) -> game |> updateGame i j |> minimax 9 True heuristic getChildren) |> List.head

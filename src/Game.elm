module Game exposing
    ( Board
    , Game
    , Player(..)
    , getBestMove
    , getChildren
    , getOpenPositions
    , getWinningPositions
    , heuristic
    , initGame
    , restoreGame
    , scoreGame
    , updateGame
    )

import AdversarialPure exposing (minimax)
import Basics.Extra
import Dict
import Dict.Extra
import List.Extra
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
    let
        board =
            Matrix.fromLists lists
    in
    board |> Maybe.map (Game player)


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
updateGame x y game =
    let
        game_ =
            { game | board = Matrix.set x y (Just game.player) game.board }
    in
    if game_ |> getWinningPositions |> List.isEmpty then
        { game_ | player = updatePlayer game_.player }

    else
        game_


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


scoreGame : Game -> Dict.Dict Int (List (List ( Int, Int )))
scoreGame game =
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

        noEnemyHere ( _, maybePlayer ) =
            maybePlayer /= Just enemy

        -- only care about lines that have no enemy on them. lines with an enemy are dead ends
        availableLinesWithPlayers =
            linesWithPlayers
                |> List.filter (List.foldl (noEnemyHere >> (&&)) True)
    in
    -- only have to count not Nothing
    availableLinesWithPlayers
        |> Dict.Extra.groupBy (List.Extra.count (Tuple.second >> (/=) Nothing))
        |> Dict.map (Basics.always (List.map (List.map Tuple.first)))


{-| score the game, get the lines with 3 of the current player, then flatten that and get the unique positions of that (there could have been some overlap)
-}
getWinningPositions : Game -> List ( Int, Int )
getWinningPositions =
    scoreGame >> Dict.get 3 >> Maybe.withDefault [] >> List.concat >> List.Extra.unique


{-| in highest first order,

  - count of 3 on a line
  - count of 2 on a line + 1 blank
  - count of 1 on a line + 2 blank
  - count of alone on an empty line
  - 0

implemented as 10^n \* (number of lines with n) which is to say that e.g. 3 on a line is an order of magnitude better than 2 on a line

-}
heuristic : Game -> Int
heuristic =
    scoreGame >> Dict.foldl (\k v acc -> 10 ^ k * List.length v + acc) 0


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
    game |> getOpenPositions |> List.sortBy (\( i, j ) -> game |> updateGame i j |> minimax 9 True heuristic getChildren) |> List.reverse |> List.head

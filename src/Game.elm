module Game exposing
    ( Board
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
import Matrix
import Maybe
import Maybe.Extra


type Player
    = O
    | X


type alias Board =
    Matrix.Matrix (Maybe ( Player, Bool ))


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
        |> Maybe.map (Matrix.map (Maybe.map Tuple (\p -> ( p, False ))))
        |> Maybe.map (Game player)


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


lines : List (List ( Int, Int ))
lines =
    rows ++ columns ++ diagonals


checkHasWon : Player -> Board -> Board
checkHasWon player board =
    let
        winningLines : List (List ( Int, Int ))
        winningLines =
            lines |> List.filter (checkAll checkCell)

        equalPlayer : Maybe ( Player, Bool ) -> Bool
        equalPlayer =
            Maybe.map (Tuple.first >> (==) player)
                >> Maybe.withDefault False

        checkCell : ( Int, Int ) -> Bool
        checkCell ( p, q ) =
            Matrix.get p q board |> Maybe.map equalPlayer |> Maybe.withDefault False

        checkAll : (( Int, Int ) -> Bool) -> List ( Int, Int ) -> Bool
        checkAll f =
            List.map f >> Bool.Extra.all

        checkHasWon_ =
            not (List.isEmpty winningLines)

        updateCellWinning : Bool -> Maybe ( Player, Bool ) -> Maybe ( Player, Bool )
        updateCellWinning winning =
            Maybe.map (Tuple.mapSecond (always winning))

        updateAll : Board -> Board
        updateAll =
            let
                winningPoints =
                    List.concat winningLines
            in
            Matrix.indexedMap (\i j -> List.member ( i, j ) winningPoints |> updateCellWinning)
    in
    if checkHasWon_ then
        updateAll board

    else
        board


updatePlayer : Player -> Player
updatePlayer currentPlayer =
    case currentPlayer of
        X ->
            O

        O ->
            X


updateGame : Int -> Int -> Game -> Game
updateGame x y { board, player } =
    { board =
        board
            |> Matrix.set x y (Just ( player, False ))
            |> checkHasWon player
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
    (game.board |> Matrix.toList |> List.filterMap (Maybe.map Tuple.second) |> Bool.Extra.any)
        || (game.board |> Matrix.toList |> List.map Maybe.Extra.isNothing |> Bool.Extra.none)


{-| in highest first order,

  - winning position,
  - count of open winning positions,
  - count of alone on intersecting lines
  - count of alone on an empty line
  - 0

-}
heuristic : Game -> Int
heuristic game =
    if isGameOver game then
        Basics.Extra.maxSafeInteger

    else
        0


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

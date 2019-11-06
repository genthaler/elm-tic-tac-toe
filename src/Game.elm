module Game exposing (Board, Player(..), initBoard, isGameOver, updateBoard, updatePlayer)

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


initBoard : Board
initBoard =
    Matrix.repeat 3 3 Nothing


updatePlayer : Player -> Player
updatePlayer currentPlayer =
    case currentPlayer of
        X ->
            O

        O ->
            X


isGameOver : Board -> Bool
isGameOver board =
    let
        list : List (Maybe ( Player, Bool ))
        list =
            board |> Matrix.toList
    in
    (list |> List.filterMap (Maybe.map Tuple.second) |> Bool.Extra.any)
        || (list |> List.map Maybe.Extra.isNothing |> Bool.Extra.none)


checkHasWon : Player -> Board -> Board
checkHasWon player board =
    let
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


updateBoard : Int -> Int -> Player -> Board -> Board
updateBoard x y player =
    Matrix.set x y (Just ( player, False ))
        >> checkHasWon player

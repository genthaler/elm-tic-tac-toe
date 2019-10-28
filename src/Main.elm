module Main exposing (main)

import Array exposing (Array)
import Browser
import Browser.Events
import Debug exposing (todo)
import Element exposing (Element, alignRight, centerX, centerY, column, el, explain, fill, height, layout, none, padding, paddingXY, px, rgb, rgb255, row, spaceEvenly, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Grid exposing (Grid)
import Html exposing (Html)
import List
import Maybe exposing (Maybe)


type Player
    = O
    | X


type alias Model =
    { board : Grid (Maybe Player)
    , currentPlayer : Player
    }


type Msg
    = Window Int Int
    | Click Int Int


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model (Grid.repeat 3 3 Nothing) X
    , Cmd.none
    )


viewCell : Int -> Int -> Maybe Player -> Element Msg
viewCell x y player =
    let
        handler =
            case player of
                Nothing ->
                    Just <| Click x y

                _ ->
                    Nothing

        tile =
            case player of
                Just X ->
                    text "X"

                Just O ->
                    text "O"

                Nothing ->
                    none
    in
    Input.button
        [ width fill
        , height fill
        , Background.color (rgb255 100 100 100)
        , Border.color (rgb 0 0.7 0)
        , Border.solid
        , Border.rounded 4
        , Border.shadow
            { offset = ( 4.0, 4.0 )
            , size = 3
            , blur = 1.0
            , color = rgb255 150 150 150
            }
        ]
        { onPress = handler
        , label = el [ centerX, centerY, Font.size 128 ] <| tile
        }


view : Model -> Html Msg
view { board, currentPlayer } =
    let
        viewBoard =
            layout [ Background.color (rgb255 200 200 200), width fill, height fill, padding 10, spacing 10 ]
                << column [ width fill, height fill ]
                << Array.toList
                << Array.map (row [ width fill, height fill, padding 10, spacing 10 ] << Array.toList)
                << Grid.rows
                << Grid.indexedMap viewCell
    in
    viewBoard board


update msg ({ board, currentPlayer } as model) =
    let
        otherPlayer =
            case currentPlayer of
                X ->
                    O

                O ->
                    X
    in
    case msg of
        Click x y ->
            let
                model_ =
                    Model (Grid.set ( x, y ) (Just currentPlayer) board) otherPlayer
            in
            ( model_, Cmd.none )

        _ ->
            ( model, Cmd.none )


subscriptions _ =
    Browser.Events.onResize Window


main : Program () Model Msg
main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }

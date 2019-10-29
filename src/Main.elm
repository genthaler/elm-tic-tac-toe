module Main exposing (main)

import Array
import Browser
import Browser.Events
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Grid exposing (Grid)
import Html exposing (Html)
import Maybe exposing (Maybe)
import Task
import Browser.Dom

type Player
    = O
    | X


type alias Model =
    { board : Grid (Maybe Player, Bool)
    , currentPlayer : Player
    , gameOver:Bool
    , window : Maybe (Int, Int)
    }


type Msg
    = GetViewPort Browser.Dom.Viewport
    | GetResize Int Int
    | Click Int Int


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model (Grid.repeat 3 3 (Nothing, False)) X False Nothing
    , Task.perform GetViewPort Browser.Dom.getViewport  
    )


viewPlayer : Maybe Player -> Element msg
viewPlayer player =
    case player of
        Just X ->
            Element.text "X"

        Just O ->
            Element.text "O"

        Nothing ->
            Element.none


viewCell : Bool -> Int -> Int -> (Maybe Player, Bool) -> Element Msg
viewCell gameOver  x y (maybePlayer, winningPosition) =
    let
        handler =
            if gameOver then
                Nothing
            else
                case maybePlayer of
                    Nothing ->
                        Just <| Click x y

                    _ ->
                        Nothing
        fontColor = 
            if winningPosition then
                Element.rgb255 255 255 255
            else 
                Element.rgb255 0 0 0
    in                        
    Input.button
        [ Element.width Element.fill
        , Element.height Element.fill
        , Background.color (Element.rgb255 100 100 100)
        , Border.color (Element.rgb 0 0.7 0)
        , Border.solid
        , Border.rounded 4
        , Border.shadow { offset = ( 4.0, 4.0 ), size = 3, blur = 1.0, color = Element.rgb255 150 150 150 }
        ]
        { onPress = handler
        , label = Element.el [ Element.centerX, Element.centerY, Font.size 128 , Font.color fontColor] <| viewPlayer maybePlayer
        }


view : Model -> Html Msg
view { board, currentPlayer , gameOver} =
    let
        viewBoard =
            Element.column [ Region.mainContent, Element.width Element.fill, Element.height Element.fill ]
                << Array.toList
                << Array.map (Element.row [ Element.width Element.fill, Element.height Element.fill, Element.padding 10, Element.spacing 10 ] << Array.toList)
                << Grid.rows
                << Grid.indexedMap (viewCell gameOver)

        viewHeader player =
            Element.row [ Region.announce, Region.heading 1, Font.size 128, Element.centerX ] [ Element.text "Ready, Player ", viewPlayer <| Just player ]
    in
    Element.layout [ Background.color (Element.rgb255 200 200 200), Element.width Element.fill, Element.height Element.fill, Element.padding 10, Element.spacing 10 ] <|
        Element.column [ Element.width Element.fill, Element.height Element.fill ]
            [ viewHeader <| currentPlayer, viewBoard board ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg ({ board, currentPlayer, gameOver , window} as model) =
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
                    Model (Grid.set ( x, y ) (Just currentPlayer, False) board) otherPlayer gameOver window
            in
            ( model_, Cmd.none )

        _ ->
            ( model, Cmd.none )

subscriptions : Model -> Sub Msg
subscriptions _ =
    Browser.Events.onResize GetResize


main : Program () Model Msg
main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }

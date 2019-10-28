module Main exposing (main)

import Browser
import Debug exposing (todo)
import Element exposing (Element, alignRight, centerX, centerY, column, el, explain, fill, height, layout, none, padding, paddingXY, px, rgb255, rgb, row, spaceEvenly, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import List

type alias Model =
    List (List String)


type alias Msg =
    ()


init : () -> ( Model, Cmd Msg )
init _ =
    ( [ [ "X", "X", "X" ], [ "X", "X", "X" ], [ "X", "X", "X" ] ], Cmd.none )
    -- ( [ [ "X" ] ], Cmd.none )


debug =
    Element.explain Debug.todo


myCell : String -> Element msg
myCell s =
    column [ width fill, height fill ] [ row [ width fill, height fill ] [ none, none ], row [ width fill, height fill ] [ none, Input.button [width fill, height fill, Border.color (rgb 0 0.7 0), Border.solid] {onPress=Nothing, label= el [centerX, centerY] <|text s} ] ]


myRow : List String -> Element Msg
myRow =
    row [ width fill, height fill ]
        << List.map (el [ width fill, height fill ] << myCell)


view : Model -> Html Msg
view =
    layout [ Background.color (rgb255 200 200 200), width fill, height fill ]
        << column [ width fill, height fill ]
        << List.map myRow


update _ model =
    ( model, Cmd.none )


subscriptions _ =
    Sub.none


main : Program () Model Msg
main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }

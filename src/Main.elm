module Main exposing (main)

import Browser
import Element exposing (Element, alignRight, centerX,centerY, column, el, fill, layout, padding, rgb255, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import List
import Html exposing (Html)

type alias Model = List String
type alias Msg = ()

init _ =
    ( ["X","X","X","X","X","X","X","X","X"], Cmd.none )

view : Model -> Html Msg
view model =
    layout [ Background.color (rgb255 200 200 200),centerX, centerY ] <|
        column [centerX, centerY] [
            row [centerX, centerY] [
                text "X",
                text "X",
                text "X"
            ],
            row [centerX, centerY] [
                text "X",
                text "X",
                text "X"
            ],
            row [centerX, centerY] [
                text "X",
                text "X",
                text "X"
            ]
        ]




update _ model =
    ( model, Cmd.none )


subscriptions _ =
    Sub.none


main : Program () Model Msg
main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }

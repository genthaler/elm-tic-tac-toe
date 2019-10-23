module Main exposing (main)

import Browser
import Debug exposing (todo)
import Element exposing (Element, alignRight, centerX, centerY, column, el, explain, fill, height, layout, padding, rgb255, row, spaceEvenly, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html exposing (Html)
import List


type alias Model =
    List (List String)


type alias Msg =
    ()


init : () -> ( Model, Cmd Msg )
init _ =
    ( [ [ "X", "X", "X" ], [ "X", "X", "X" ], [ "X", "X", "X" ] ], Cmd.none )


debug =
    Element.explain Debug.todo


view : Model -> Html Msg
view model =
    let
        myRow : List String -> Element Msg
        myRow =
            row [ spacing 20, debug, width fill, height fill, spaceEvenly ]
                << List.map (el [] << text)

        myCol : List (List String) -> Element Msg
        myCol =
            column [ padding 100, spacing 20, debug, width fill, height fill, spaceEvenly ]
                << List.map myRow
    in
    layout [ Background.color (rgb255 200 200 200), centerX, centerY ]
        << column [ padding 100, spacing 20, debug, width fill, height fill, spaceEvenly ]
        << List.map
            row
            [ spacing 20, debug, width fill, height fill, spaceEvenly ]
        << List.map (el [] << text)



-- myCol model


update _ model =
    ( model, Cmd.none )


subscriptions _ =
    Sub.none


main : Program () Model Msg
main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }

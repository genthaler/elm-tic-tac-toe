module Main exposing (main)

import Browser
import Element exposing (Element, alignRight, centerY, column, el, fill, layout, padding, rgb255, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font


init _ =
    ( (), Cmd.none )


view _ =
    layout [ Background.color (rgb255 111 111 111) ] <|
        el
            [ Background.color (rgb255 111 111 111)
            , Font.color (rgb255 255 255 255)
            , Border.rounded 3
            , padding 30
            ]
        <|
            text "stylish!"


update _ _ =
    ( (), Cmd.none )


subscriptions _ =
    Sub.none


main : Program () () msg
main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }

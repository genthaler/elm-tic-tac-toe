module Book exposing (main)

{-| This module provides a storybook-like interface for showcasing and testing
the Tic-tac-toe game components using elm-book.
-}

import Element
import Element.Background as Background
import Element.HexColor
import ElmBook exposing (withChapters)
import ElmBook.Actions exposing (mapUpdate, updateStateWith)
import ElmBook.Chapter exposing (chapter, render, withComponentList, withStatefulComponent, withStatefulComponentList)
import ElmBook.ElmUI exposing (Book, Chapter, book)
import ElmBook.StatefulOptions
import Model exposing (ColorScheme(..), Model, Msg(..), Player(..), initialModel)
import TicTacToe.TicTacToe exposing (moveMade, nextPlayer)
import Time
import View exposing (Theme, currentTheme, viewCell, viewModel, viewPlayerAsString, viewPlayerAsSvg)


{-| Maps the game's update function to work with elm-book
-}
mapUpdater =
    mapUpdate
        { toState = \_ model_ -> model_
        , fromState = \state -> state
        , update = update
        }


{-| Updates the game state based on the given message
-}
update : Msg -> Model -> Model
update msg model =
    case msg of
        MoveMade position ->
            let
                newModel : Model
                newModel =
                    moveMade model position
            in
            { newModel | currentPlayer = nextPlayer model.currentPlayer, lastMove = model.now }

        ResetGame ->
            initialModel

        GameError string ->
            { model | errorMessage = Just string }

        ColorScheme colorScheme ->
            { model | colorScheme = colorScheme }

        GetViewPort _ ->
            Debug.todo "branch 'GetViewPort _' not implemented"

        GetResize _ _ ->
            Debug.todo "branch 'GetResize _ _' not implemented"

        Tick _ ->
            Debug.todo "branch 'Tick _' not implemented"


{-| A chapter for showcasing the player as SVG
-}
viewPlayerAsSvgChapter : Chapter Model
viewPlayerAsSvgChapter =
    chapter "Player as SVG"
        |> withStatefulComponentList
            [ ( "X", \state -> viewPlayerAsSvg state X |> Element.el [ Element.width (Element.px 200) ] )
            , ( "O", \state -> viewPlayerAsSvg state O |> Element.el [ Element.width (Element.px 200) ] )
            ]
        |> render """
<component-list  />
"""


{-| A chapter for showcasing the player as string
-}
viewPlayerAsStringChapter : Chapter Model
viewPlayerAsStringChapter =
    chapter "Player as String"
        |> withComponentList
            [ ( "X", viewPlayerAsString X |> Element.text )
            , ( "O", viewPlayerAsString O |> Element.text )
            ]
        |> render """
<component-list  />
"""


{-| A chapter for showcasing the cell view
-}
viewCellChapter : Chapter Model
viewCellChapter =
    chapter "Cell View"
        |> withStatefulComponent (\model -> viewCell model 0 0 (Just X) |> Element.map mapUpdater)
        |> render "<component />"


{-| A chapter for showcasing the full game view
-}
viewModelChapter : Chapter Model
viewModelChapter =
    chapter "Full Game View"
        |> withStatefulComponent (\model -> viewModel model |> Element.map mapUpdater)
        |> render "<component />"


{-| A chapter for showcasing the theme elements
-}
themeChapter : Chapter Model
themeChapter =
    chapter "Theme Elements"
        |> withStatefulComponent
            (\model ->
                let
                    theme : Theme
                    theme =
                        currentTheme model.colorScheme

                    themeElement : String -> Element.Color -> Element.Element msg
                    themeElement label color =
                        Element.row
                            [ Element.spacing 40
                            , Element.width Element.fill
                            ]
                            [ Element.el [ Element.width (Element.px 150) ] (Element.text label)
                            , Element.el [ Background.color color, Element.width (Element.px 100), Element.height (Element.px 50) ] Element.none
                            ]

                    themeElements : Element.Element msg
                    themeElements =
                        Element.column
                            [ Element.spacing 20
                            , Element.padding 20
                            , Element.width Element.fill
                            ]
                            [ Element.text
                                ("Current Theme: "
                                    ++ (case model.colorScheme of
                                            Light ->
                                                "Light"

                                            Dark ->
                                                "Dark"
                                       )
                                )
                            , themeElement "Background Color" theme.backgroundColor
                            , themeElement "Border Color" theme.borderColor
                            , themeElement "Font Color" theme.fontColor
                            , themeElement "Piece Color" (Element.HexColor.rgbCSSHex theme.pieceColorHex)
                            ]
                in
                themeElements |> Element.map mapUpdater
            )
        |> render "<component />"


{-| Main program that runs the elm-book interface
-}
main : Book Model
main =
    book "Elm Tic-Tac-Toe"
        |> ElmBook.withStatefulOptions
            [ ElmBook.StatefulOptions.initialState initialModel
            , ElmBook.StatefulOptions.subscriptions
                [ Time.every 100 (updateStateWith updateNow)
                ]
            , ElmBook.StatefulOptions.onDarkModeChange
                (\darkMode state ->
                    { state
                        | colorScheme =
                            if darkMode then
                                Dark

                            else
                                Light
                    }
                )
            ]
        |> withChapters
            [ viewPlayerAsStringChapter
            , viewPlayerAsSvgChapter
            , viewCellChapter
            , viewModelChapter
            , themeChapter
            ]


updateNow : Time.Posix -> Model -> Model
updateNow posix state =
    { state | now = Just posix }

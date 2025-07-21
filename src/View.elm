module View exposing (Theme, currentTheme, view, viewCell, viewModel, viewPlayerAsString, viewPlayerAsSvg)

{-| This module handles the UI rendering for the Tic-tac-toe game.
It provides functions to render the game board, cells, and player symbols using elm-ui.
-}

import Element exposing (Color)
import Element.Background as Background
import Element.Events
import Element.Font as Font
import FlatColors.AussiePalette as AussiePalette
import Html exposing (Html)
import Model exposing (ColorScheme(..), GameState(..), Line, Model, Msg(..), Player(..), Position)
import Svg exposing (..)
import Svg.Attributes as SvgAttr exposing (..)


{-| Styles for the main layout
-}
type alias Theme =
    { backgroundColor : Color
    , borderColor : Color
    , fontColor : Color
    , pieceColorHex : String
    }


darkTheme : Theme
darkTheme =
    { backgroundColor = AussiePalette.pureApple
    , borderColor = AussiePalette.blurple
    , fontColor = AussiePalette.soaringEagle
    , pieceColorHex = AussiePalette.coastalBreezeHex
    }


lightTheme : Theme
lightTheme =
    { backgroundColor = AussiePalette.beekeeper
    , borderColor = AussiePalette.quinceJelly
    , fontColor = AussiePalette.deepCove
    , pieceColorHex = AussiePalette.carminePinkHex
    }


currentTheme : ColorScheme -> Theme
currentTheme colorScheme =
    case colorScheme of
        Light ->
            lightTheme

        Dark ->
            darkTheme


{-| Main view function that renders the entire game UI
-}
view : Model -> Html Msg
view model =
    let
        theme : Theme
        theme =
            currentTheme model.colorScheme
    in
    Element.layout
        [ Background.color theme.backgroundColor
        , Font.color theme.fontColor
        ]
    <|
        viewModel model


{-| The main view model that contains the game board and the winner text
-}
viewModel : Model -> Element.Element Msg
viewModel model =
    let
        theme : Theme
        theme =
            currentTheme model.colorScheme
    in
    Element.el
        [ Element.centerX
        , Element.centerY
        , Background.color theme.borderColor
        , Font.color theme.fontColor
        , Font.bold
        , Font.size 32
        ]
        (Element.column [ Element.spacing 10 ]
            [ Element.row
                [ Element.width Element.fill
                , Element.height (Element.px 70)
                , Element.spacing 10
                , Element.padding 10
                ]
                [ Element.el [ Element.alignLeft ] (Element.text "Tic-Tac-Toe")
                , Element.el [ Element.alignRight ] <|
                    Element.row
                        [ Element.spacing 10
                        , Element.padding 10
                        ]
                        [ case ( model.gameState, model.lastMove ) of
                            ( Waiting _, Just _ ) ->
                                viewTimer model

                            _ ->
                                Element.none
                        , resetIcon model
                        , colorSchemeToggleIcon model
                        ]
                ]
            , Element.el []
                (Element.column [ Element.spacing 10 ]
                    (List.indexedMap (viewRow model) model.board)
                )
            , Element.row
                [ Element.padding 10
                , Element.spacing 10
                , Element.centerX
                ]
                [ case model.gameState of
                    Winner player ->
                        Element.text ("Player " ++ viewPlayerAsString player ++ " wins!")

                    Waiting player ->
                        Element.text ("Player " ++ viewPlayerAsString player ++ "'s turn")

                    Thinking player ->
                        Element.text ("Player " ++ viewPlayerAsString player ++ "'s thinking")

                    Draw ->
                        Element.text "Game ended in a draw!"

                    Error error ->
                        Element.text error
                ]
            ]
        )


viewRow : Model -> Int -> Line -> Element.Element Msg
viewRow model rowIndex row =
    Element.row [ Element.spacing 10 ]
        (List.indexedMap (viewCell model rowIndex) row)


{-| Renders a single cell on the game board
-}
viewCell : Model -> Int -> Int -> Maybe Player -> Element.Element Msg
viewCell model rowIndex colIndex maybePlayer =
    let
        theme : Theme
        theme =
            currentTheme model.colorScheme

        boardCellAttributes : List (Element.Attr () msg)
        boardCellAttributes =
            [ Background.color theme.backgroundColor
            , Element.height (Element.px 200)
            , Element.width (Element.px 200)
            , Element.padding 20
            ]
    in
    case maybePlayer of
        Just player ->
            player
                |> viewPlayerAsSvg model
                |> Element.el boardCellAttributes

        Nothing ->
            let
                clickAttributes : List (Element.Attribute Msg)
                clickAttributes =
                    case model.gameState of
                        Waiting _ ->
                            [ Element.Events.onClick (MoveMade (Position rowIndex colIndex)) ]

                        _ ->
                            []
            in
            Element.el
                (boardCellAttributes ++ clickAttributes)
                (Element.text " ")


{-| Renders a player as a string ("X" or "O")
-}
viewPlayerAsString : Player -> String
viewPlayerAsString player =
    case player of
        X ->
            "X"

        O ->
            "O"


{-| Renders a player as an SVG symbol
-}
viewPlayerAsSvg : Model -> Player -> Element.Element msg
viewPlayerAsSvg model player =
    case player of
        X ->
            crossIcon model

        O ->
            circleIcon model


circleIcon : Model -> Element.Element msg
circleIcon model =
    let
        theme : Theme
        theme =
            currentTheme model.colorScheme
    in
    Element.html <|
        Svg.svg
            [ SvgAttr.viewBox "0 0 24 24"
            , SvgAttr.fill "none"
            ]
            [ Svg.path
                [ SvgAttr.d "M21 12C21 16.9706 16.9706 21 12 21C7.02944 21 3 16.9706 3 12C3 7.02944 7.02944 3 12 3C16.9706 3 21 7.02944 21 12Z"
                , SvgAttr.stroke theme.pieceColorHex
                , SvgAttr.strokeWidth "2"
                , SvgAttr.strokeLinecap "round"
                , SvgAttr.strokeLinejoin "round"
                ]
                []
            ]


crossIcon : Model -> Element.Element msg
crossIcon model =
    let
        theme : Theme
        theme =
            currentTheme model.colorScheme
    in
    Element.html <|
        Svg.svg
            [ SvgAttr.viewBox "0 0 25 25"
            , SvgAttr.version "1.1"
            ]
            [ Svg.g
                [ SvgAttr.stroke "none"
                , SvgAttr.strokeWidth "1"
                , SvgAttr.fill "none"
                , SvgAttr.fillRule "evenodd"
                ]
                [ Svg.g
                    [ SvgAttr.transform "translate(-467.000000, -1039.000000)"
                    , SvgAttr.fill theme.pieceColorHex
                    ]
                    [ Svg.path
                        [ SvgAttr.d "M489.396,1061.4 C488.614,1062.18 487.347,1062.18 486.564,1061.4 L479.484,1054.32 L472.404,1061.4 C471.622,1062.18 470.354,1062.18 469.572,1061.4 C468.79,1060.61 468.79,1059.35 469.572,1058.56 L476.652,1051.48 L469.572,1044.4 C468.79,1043.62 468.79,1042.35 469.572,1041.57 C470.354,1040.79 471.622,1040.79 472.404,1041.57 L479.484,1048.65 L486.564,1041.57 C487.347,1040.79 488.614,1040.79 489.396,1041.57 C490.179,1042.35 490.179,1043.62 489.396,1044.4 L482.316,1051.48 L489.396,1058.56 C490.179,1059.35 490.179,1060.61 489.396,1061.4 L489.396,1061.4 Z M485.148,1051.48 L490.813,1045.82 C492.376,1044.26 492.376,1041.72 490.813,1040.16 C489.248,1038.59 486.712,1038.59 485.148,1040.16 L479.484,1045.82 L473.82,1040.16 C472.257,1038.59 469.721,1038.59 468.156,1040.16 C466.593,1041.72 466.593,1044.26 468.156,1045.82 L473.82,1051.48 L468.156,1057.15 C466.593,1058.71 466.593,1061.25 468.156,1062.81 C469.721,1064.38 472.257,1064.38 473.82,1062.81 L479.484,1057.15 L485.148,1062.81 C486.712,1064.38 489.248,1064.38 490.813,1062.81 C492.376,1061.25 492.376,1058.71 490.813,1057.15 L485.148,1051.48 L485.148,1051.48 Z"
                        ]
                        []
                    ]
                ]
            ]


resetIcon : Model -> Element.Element Msg
resetIcon model =
    let
        theme : Theme
        theme =
            currentTheme model.colorScheme
    in
    Element.el
        [ Element.Events.onClick ResetGame
        , Element.pointer
        ]
    <|
        Element.html <|
            Svg.svg
                [ SvgAttr.viewBox "0 0 1024 1024"
                , SvgAttr.version "1.1"
                , SvgAttr.width "1em"
                , SvgAttr.height "1em"
                ]
                [ Svg.path
                    [ SvgAttr.d "M903.424 199.424l-142.88-142.848c-31.104-31.104-92.576-56.576-136.576-56.576l-480 0c-44 0-80 36-80 80l0 864c0 44 36 80 80 80l736 0c44 0 80-36 80-80l0-608c0-44-25.472-105.472-56.576-136.576zM858.176 244.672c3.136 3.136 6.24 6.976 9.28 11.328l-163.456 0 0-163.456c4.352 3.04 8.192 6.144 11.328 9.28l142.88 142.848zM896 944c0 8.672-7.328 16-16 16l-736 0c-8.672 0-16-7.328-16-16l0-864c0-8.672 7.328-16 16-16l480 0c4.832 0 10.24 0.608 16 1.696l0 254.304 254.304 0c1.088 5.76 1.696 11.168 1.696 16l0 608z"
                    , SvgAttr.fill theme.pieceColorHex
                    ]
                    []
                ]


colorSchemeToggleIcon : Model -> Element.Element Msg
colorSchemeToggleIcon model =
    let
        theme : Theme
        theme =
            currentTheme model.colorScheme
    in
    Element.el
        [ Element.Events.onClick
            (ColorScheme
                (case model.colorScheme of
                    Light ->
                        Dark

                    Dark ->
                        Light
                )
            )
        , Element.pointer
        ]
    <|
        Element.html <|
            Svg.svg
                [ SvgAttr.viewBox "0 0 1024 1024"
                , SvgAttr.version "1.1"
                , SvgAttr.width "1em"
                , SvgAttr.height "1em"
                ]
                [ Svg.path
                    [ SvgAttr.d """
                    M320 85.333333c-76.373333 49.066667-128 135.68-128 234.666667s51.626667 185.6 129.28 234.666667C190.293333 554.666667 85.333333 449.706667 85.333333 320A234.666667 234.666667 0 0 1 320 85.333333m493.653333 64l61.013334 61.013334L210.346667 874.666667 149.333333 813.653333 813.653333 149.333333m-263.68 103.68L486.826667 213.333333 425.386667 256l17.92-72.533333L384 138.24l74.666667-5.12 24.746666-70.4L512 132.266667l73.813333 1.28-57.6 48.213333 21.76 71.253333m-140.8 154.026667l-49.493333-31.146667-47.786667 33.28 14.506667-56.32-46.506667-35.413333 58.026667-3.84 19.2-55.04 21.76 54.186667 58.026667 1.28-44.8 37.12 17.066666 55.893333M810.666667 576a234.666667 234.666667 0 0 1-234.666667 234.666667c-52.053333 0-100.266667-17.066667-139.093333-45.653334l328.106666-328.106666c28.586667 38.826667 45.653333 87.04 45.653334 139.093333m-187.733334 280.746667l118.186667-49.066667-10.24 142.933333-107.946667-93.866666m184.746667-115.2l49.066667-118.186667 93.866666 108.373333-142.933333 9.813334m49.066667-211.626667l-48.64-118.613333 142.506666 10.24-93.866666 108.373333M410.88 807.68l118.186667 49.066667-107.946667 93.44-10.24-142.506667z
                    """
                    , SvgAttr.fill theme.pieceColorHex
                    ]
                    []
                ]


type alias TimerConfig =
    { radius : Float
    , strokeWidth : Float
    }


viewTimer : Model -> Element.Element msg
viewTimer model =
    let
        theme =
            currentTheme model.colorScheme

        config : TimerConfig
        config =
            { radius = 15
            , strokeWidth = 3
            }

        timeSpent =
            Model.timeSpent model

        progress =
            timeSpent / toFloat Model.idleTimeoutMillis

        circumference =
            2 * pi * config.radius

        dashOffset =
            circumference * (1 - progress)
    in
    Element.html <|
        Svg.svg
            [ SvgAttr.width "40"
            , SvgAttr.height "40"
            , SvgAttr.viewBox "0 0 40 40"
            ]
            [ Svg.circle
                [ SvgAttr.cx "20"
                , SvgAttr.cy "20"
                , SvgAttr.r (String.fromFloat config.radius)
                , SvgAttr.fill "none"
                , SvgAttr.stroke theme.pieceColorHex
                , SvgAttr.strokeWidth (String.fromFloat config.strokeWidth)
                , SvgAttr.opacity "0.3"
                ]
                []
            , Svg.circle
                [ SvgAttr.cx "20"
                , SvgAttr.cy "20"
                , SvgAttr.r (String.fromFloat config.radius)
                , SvgAttr.fill "none"
                , SvgAttr.stroke theme.pieceColorHex
                , SvgAttr.strokeWidth (String.fromFloat config.strokeWidth)
                , SvgAttr.strokeDasharray (String.fromFloat circumference)
                , SvgAttr.strokeDashoffset (String.fromFloat dashOffset)
                , SvgAttr.transform "rotate(-90 20 20)"
                ]
                []
            ]

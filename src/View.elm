module View exposing (ScreenSize(..), Theme, calculateResponsiveCellSize, currentTheme, getResponsiveFontSize, getResponsivePadding, getResponsiveSpacing, getScreenSize, view, viewCell, viewModel, viewPlayerAsString, viewPlayerAsSvg)

{-| This module handles the UI rendering for the Tic-tac-toe game.
It provides functions to render the game board, cells, and player symbols using elm-ui.
-}

import Element exposing (Color)
import Element.Background as Background
import Element.Border
import Element.Events
import Element.Font as Font
import FlatColors.AussiePalette as AussiePalette
import Html exposing (Html)
import Model exposing (ColorScheme(..), ErrorInfo, ErrorType(..), GameState(..), Line, Model, Msg(..), Player(..), Position)
import Svg
import Svg.Attributes as SvgAttr


{-| Comprehensive theme definition with all UI colors
-}
type alias Theme =
    { -- Background colors
      backgroundColor : Color
    , boardBackgroundColor : Color
    , cellBackgroundColor : Color
    , headerBackgroundColor : Color

    -- Border and accent colors
    , borderColor : Color
    , accentColor : Color

    -- Text colors
    , fontColor : Color
    , secondaryFontColor : Color
    , errorColor : Color
    , successColor : Color

    -- Interactive element colors
    , buttonColor : Color
    , buttonHoverColor : Color
    , iconColor : String
    , pieceColorHex : String

    -- Timer colors
    , timerBackgroundColor : String
    , timerProgressColor : String
    }


{-| Dark theme with carefully selected colors for good contrast and accessibility
-}
darkTheme : Theme
darkTheme =
    { backgroundColor = AussiePalette.deepCove
    , boardBackgroundColor = AussiePalette.blurple
    , cellBackgroundColor = AussiePalette.pureApple
    , headerBackgroundColor = AussiePalette.blurple
    , borderColor = AussiePalette.soaringEagle
    , accentColor = AussiePalette.coastalBreeze
    , fontColor = Element.rgb255 236 240 241
    , secondaryFontColor = AussiePalette.soaringEagle
    , errorColor = Element.rgb255 231 76 60
    , successColor = Element.rgb255 46 204 113
    , buttonColor = Element.rgb255 52 152 219
    , buttonHoverColor = Element.rgb255 41 128 185
    , iconColor = "#ecf0f1"
    , pieceColorHex = "#1abc9c"
    , timerBackgroundColor = "#34495e"
    , timerProgressColor = "#e74c3c"
    }


{-| Light theme with warm, accessible colors
-}
lightTheme : Theme
lightTheme =
    { backgroundColor = Element.rgb255 248 249 250
    , boardBackgroundColor = AussiePalette.quinceJelly
    , cellBackgroundColor = AussiePalette.beekeeper
    , headerBackgroundColor = AussiePalette.quinceJelly
    , borderColor = Element.rgb255 189 195 199
    , accentColor = AussiePalette.coastalBreeze
    , fontColor = AussiePalette.deepCove
    , secondaryFontColor = Element.rgb255 127 140 141
    , errorColor = Element.rgb255 231 76 60
    , successColor = Element.rgb255 39 174 96
    , buttonColor = Element.rgb255 52 152 219
    , buttonHoverColor = Element.rgb255 41 128 185
    , iconColor = "#2c3e50"
    , pieceColorHex = "#e67e22"
    , timerBackgroundColor = "#bdc3c7"
    , timerProgressColor = "#e74c3c"
    }


currentTheme : ColorScheme -> Theme
currentTheme colorScheme =
    case colorScheme of
        Light ->
            lightTheme

        Dark ->
            darkTheme


{-| Responsive breakpoints for different screen sizes
-}
type ScreenSize
    = Mobile
    | Tablet
    | Desktop


{-| Determine screen size based on viewport dimensions
-}
getScreenSize : Maybe ( Int, Int ) -> ScreenSize
getScreenSize maybeWindow =
    case maybeWindow of
        Just ( width, _ ) ->
            if width < 768 then
                Mobile

            else if width < 1024 then
                Tablet

            else
                Desktop

        Nothing ->
            Desktop


{-| Calculate responsive cell size based on viewport and screen size
-}
calculateResponsiveCellSize : Maybe ( Int, Int ) -> Int
calculateResponsiveCellSize maybeWindow =
    case maybeWindow of
        Just ( width, height ) ->
            let
                screenSize =
                    getScreenSize maybeWindow

                minDimension =
                    Basics.min width height

                baseSize =
                    case screenSize of
                        Mobile ->
                            minDimension // 5

                        Tablet ->
                            minDimension // 4

                        Desktop ->
                            minDimension // 4

                minSize =
                    case screenSize of
                        Mobile ->
                            80

                        Tablet ->
                            120

                        Desktop ->
                            150

                maxSize =
                    case screenSize of
                        Mobile ->
                            120

                        Tablet ->
                            180

                        Desktop ->
                            200
            in
            Basics.max minSize (Basics.min maxSize baseSize)

        Nothing ->
            200


{-| Calculate responsive font size based on screen size
-}
getResponsiveFontSize : Maybe ( Int, Int ) -> Int -> Int
getResponsiveFontSize maybeWindow baseSize =
    case getScreenSize maybeWindow of
        Mobile ->
            Basics.max 16 (baseSize - 8)

        Tablet ->
            Basics.max 18 (baseSize - 4)

        Desktop ->
            baseSize


{-| Calculate responsive spacing based on screen size
-}
getResponsiveSpacing : Maybe ( Int, Int ) -> Int -> Int
getResponsiveSpacing maybeWindow baseSpacing =
    case getScreenSize maybeWindow of
        Mobile ->
            Basics.max 5 (baseSpacing - 5)

        Tablet ->
            Basics.max 8 (baseSpacing - 2)

        Desktop ->
            baseSpacing


{-| Calculate responsive padding based on screen size
-}
getResponsivePadding : Maybe ( Int, Int ) -> Int -> Int
getResponsivePadding maybeWindow basePadding =
    case getScreenSize maybeWindow of
        Mobile ->
            Basics.max 8 (basePadding - 7)

        Tablet ->
            Basics.max 12 (basePadding - 3)

        Desktop ->
            basePadding


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
        , Background.color theme.boardBackgroundColor
        , Font.color theme.fontColor
        , Font.bold
        , Font.size (getResponsiveFontSize model.maybeWindow 32)
        , Element.padding (getResponsivePadding model.maybeWindow 20)
        , Element.spacing (getResponsiveSpacing model.maybeWindow 15)
        ]
        (Element.column [ Element.spacing (getResponsiveSpacing model.maybeWindow 15) ]
            [ -- Header section with title and controls
              Element.row
                [ Element.width Element.fill
                , Element.height (Element.px (getResponsiveFontSize model.maybeWindow 70))
                , Element.spacing (getResponsiveSpacing model.maybeWindow 15)
                , Element.padding (getResponsivePadding model.maybeWindow 15)
                , Background.color theme.headerBackgroundColor
                , Element.centerX
                ]
                [ Element.el
                    [ Element.alignLeft
                    , Font.color theme.fontColor
                    , Font.size (getResponsiveFontSize model.maybeWindow 28)
                    ]
                    (Element.text "Tic-Tac-Toe")
                , Element.el [ Element.alignRight ] <|
                    Element.row
                        [ Element.spacing (getResponsiveSpacing model.maybeWindow 15)
                        , Element.padding (getResponsivePadding model.maybeWindow 5)
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

            -- Game board section
            , Element.el
                [ Element.centerX
                , Background.color theme.borderColor
                , Element.padding (getResponsivePadding model.maybeWindow 10)
                ]
                (Element.column [ Element.spacing (getResponsiveSpacing model.maybeWindow 10) ]
                    (List.indexedMap (viewRow model) model.board)
                )

            -- Status message section
            , Element.el
                [ Element.padding (getResponsivePadding model.maybeWindow 15)
                , Element.centerX
                , Background.color theme.headerBackgroundColor
                , Element.width Element.fill
                ]
                (Element.el
                    [ Element.centerX
                    , Font.color (getStatusColor model theme)
                    , Font.size (getResponsiveFontSize model.maybeWindow 24)
                    ]
                    (Element.text (getStatusMessage model))
                )
            ]
        )


{-| Get the appropriate color for status messages based on game state
-}
getStatusColor : Model -> Theme -> Color
getStatusColor model theme =
    case model.gameState of
        Winner _ ->
            theme.successColor

        Error errorInfo ->
            case errorInfo.errorType of
                TimeoutError ->
                    theme.secondaryFontColor

                _ ->
                    theme.errorColor

        _ ->
            theme.fontColor


{-| Get the status message text
-}
getStatusMessage : Model -> String
getStatusMessage model =
    case model.gameState of
        Winner player ->
            "Player " ++ viewPlayerAsString player ++ " wins!"

        Waiting player ->
            "Player " ++ viewPlayerAsString player ++ "'s turn"

        Thinking player ->
            "Player " ++ viewPlayerAsString player ++ "'s thinking"

        Draw ->
            "Game ended in a draw!"

        Error errorInfo ->
            formatErrorMessage errorInfo


{-| Format error messages with additional context based on error type
-}
formatErrorMessage : ErrorInfo -> String
formatErrorMessage errorInfo =
    let
        baseMessage =
            errorInfo.message

        contextualMessage =
            case errorInfo.errorType of
                InvalidMove ->
                    baseMessage ++ " (Try clicking an empty cell)"

                GameLogicError ->
                    baseMessage ++ " (Please reset the game)"

                WorkerCommunicationError ->
                    baseMessage ++ " (Please reset the game)"

                JsonError ->
                    baseMessage ++ " (Communication error - please reset)"

                TimeoutError ->
                    baseMessage ++ " (Click reset to continue)"

                UnknownError ->
                    baseMessage ++ " (Please reset the game)"
    in
    if errorInfo.recoverable then
        contextualMessage

    else
        contextualMessage ++ " (Game cannot continue)"


viewRow : Model -> Int -> Line -> Element.Element Msg
viewRow model rowIndex row =
    Element.row [ Element.spacing (getResponsiveSpacing model.maybeWindow 10) ]
        (List.indexedMap (viewCell model rowIndex) row)


{-| Renders a single cell on the game board with responsive sizing
-}
viewCell : Model -> Int -> Int -> Maybe Player -> Element.Element Msg
viewCell model rowIndex colIndex maybePlayer =
    let
        theme : Theme
        theme =
            currentTheme model.colorScheme

        -- Calculate responsive cell size based on viewport
        cellSize : Int
        cellSize =
            calculateResponsiveCellSize model.maybeWindow

        boardCellAttributes : List (Element.Attr () msg)
        boardCellAttributes =
            [ Background.color theme.cellBackgroundColor
            , Element.height (Element.px cellSize)
            , Element.width (Element.px cellSize)
            , Element.padding (getResponsivePadding model.maybeWindow 20)
            , Element.Border.width 2
            , Element.Border.color theme.borderColor
            ]

        hoverAttributes : List (Element.Attribute Msg)
        hoverAttributes =
            case model.gameState of
                Waiting _ ->
                    [ Element.mouseOver [ Background.color theme.accentColor ]
                    , Element.pointer
                    ]

                _ ->
                    []
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
                (boardCellAttributes ++ clickAttributes ++ hoverAttributes)
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
            , SvgAttr.width "100%"
            , SvgAttr.height "100%"
            ]
            [ Svg.path
                [ SvgAttr.d "M21 12C21 16.9706 16.9706 21 12 21C7.02944 21 3 16.9706 3 12C3 7.02944 7.02944 3 12 3C16.9706 3 21 7.02944 21 12Z"
                , SvgAttr.stroke theme.pieceColorHex
                , SvgAttr.strokeWidth "3"
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
            , SvgAttr.width "100%"
            , SvgAttr.height "100%"
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
        , Element.mouseOver [ Background.color theme.buttonHoverColor ]
        , Element.padding 8
        , Background.color theme.buttonColor
        , Element.Border.rounded 4
        ]
    <|
        Element.html <|
            Svg.svg
                [ SvgAttr.viewBox "0 0 24 24"
                , SvgAttr.version "1.1"
                , SvgAttr.width "24"
                , SvgAttr.height "24"
                ]
                [ Svg.path
                    [ SvgAttr.d "M17.65,6.35C16.2,4.9 14.21,4 12,4A8,8 0 0,0 4,12A8,8 0 0,0 12,20C15.73,20 18.84,17.45 19.73,14H17.65C16.83,16.33 14.61,18 12,18A6,6 0 0,1 6,12A6,6 0 0,1 12,6C13.66,6 15.14,6.69 16.22,7.78L13,11H20V4L17.65,6.35Z"
                    , SvgAttr.fill theme.iconColor
                    ]
                    []
                ]


colorSchemeToggleIcon : Model -> Element.Element Msg
colorSchemeToggleIcon model =
    let
        theme : Theme
        theme =
            currentTheme model.colorScheme

        iconPath =
            case model.colorScheme of
                Light ->
                    -- Moon icon for switching to dark mode
                    "M17.75,4.09L15.22,6.03L16.13,9.09L13.5,7.28L10.87,9.09L11.78,6.03L9.25,4.09L12.44,4L13.5,1L14.56,4L17.75,4.09M21.25,11L19.61,12.25L20.2,14.23L18.5,13.06L16.8,14.23L17.39,12.25L15.75,11L17.81,10.95L18.5,9L19.19,10.95L21.25,11M18.97,15.95C19.8,15.87 20.69,17.05 20.16,17.8C19.84,18.25 19.5,18.67 19.08,19.07C15.17,23 8.84,23 4.94,19.07C1.03,15.17 1.03,8.83 4.94,4.93C5.34,4.53 5.76,4.17 6.21,3.85C6.96,3.32 8.14,4.21 8.06,5.04C7.79,7.9 8.75,10.87 10.95,13.06C13.14,15.26 16.1,16.22 18.97,15.95M17.33,17.97C14.5,17.81 11.7,16.64 9.53,14.5C7.36,12.31 6.2,9.5 6.04,6.68C3.23,9.82 3.34,14.4 6.35,17.41C9.37,20.43 14,20.54 17.33,17.97Z"

                Dark ->
                    -- Sun icon for switching to light mode
                    "M12,7A5,5 0 0,1 17,12A5,5 0 0,1 12,17A5,5 0 0,1 7,12A5,5 0 0,1 12,7M12,9A3,3 0 0,0 9,12A3,3 0 0,0 12,15A3,3 0 0,0 15,12A3,3 0 0,0 12,9M12,2L14.39,5.42C13.65,5.15 12.84,5 12,5C11.16,5 10.35,5.15 9.61,5.42L12,2M3.34,7L7.5,6.65C6.9,7.16 6.36,7.78 5.94,8.5C5.5,9.24 5.25,10 5.11,10.79L3.34,7M3.36,17L5.12,13.23C5.26,14 5.53,14.78 5.95,15.5C6.37,16.24 6.91,16.86 7.5,17.37L3.36,17M20.65,7L18.88,10.79C18.74,10 18.47,9.23 18.05,8.5C17.63,7.78 17.1,7.15 16.5,6.64L20.65,7M20.64,17L16.5,17.36C17.09,16.85 17.62,16.22 18.04,15.5C18.46,14.77 18.73,14 18.87,13.21L20.64,17M12,22L9.59,18.56C10.33,18.83 11.14,19 12,19C12.82,19 13.63,18.83 14.37,18.56L12,22Z"
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
        , Element.mouseOver [ Background.color theme.buttonHoverColor ]
        , Element.padding 8
        , Background.color theme.buttonColor
        , Element.Border.rounded 4
        ]
    <|
        Element.html <|
            Svg.svg
                [ SvgAttr.viewBox "0 0 24 24"
                , SvgAttr.version "1.1"
                , SvgAttr.width "24"
                , SvgAttr.height "24"
                ]
                [ Svg.path
                    [ SvgAttr.d iconPath
                    , SvgAttr.fill theme.iconColor
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
    Element.el
        [ Element.padding 4
        , Background.color theme.headerBackgroundColor
        , Element.Border.rounded 20
        ]
    <|
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
                    , SvgAttr.stroke theme.timerBackgroundColor
                    , SvgAttr.strokeWidth (String.fromFloat config.strokeWidth)
                    ]
                    []
                , Svg.circle
                    [ SvgAttr.cx "20"
                    , SvgAttr.cy "20"
                    , SvgAttr.r (String.fromFloat config.radius)
                    , SvgAttr.fill "none"
                    , SvgAttr.stroke theme.timerProgressColor
                    , SvgAttr.strokeWidth (String.fromFloat config.strokeWidth)
                    , SvgAttr.strokeDasharray (String.fromFloat circumference)
                    , SvgAttr.strokeDashoffset (String.fromFloat dashOffset)
                    , SvgAttr.transform "rotate(-90 20 20)"
                    , SvgAttr.strokeLinecap "round"
                    ]
                    []
                ]

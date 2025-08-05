module Landing.LandingView exposing (view)

{-| Landing page view components for the Tic-Tac-Toe application.

This module provides the UI components for the landing page, including
navigation buttons, theme toggle, and responsive layout using the existing
theme system from View.elm.

-}

import Element exposing (Element)
import Element.Background as Background
import Element.Border
import Element.Events
import Element.Font as Font
import Html exposing (Html)
import Landing.Landing as Landing
import Route
import Svg
import Svg.Attributes as SvgAttr
import Theme.Responsive exposing (ScreenSize(..), getResponsiveFontSize, getResponsivePadding, getResponsiveSpacing, getScreenSize)
import Theme.Theme exposing (BaseTheme, ColorScheme(..), getBaseTheme)


{-| Main view function for the landing page
-}
view : Landing.Model -> (Landing.Msg -> msg) -> Html msg
view model toMsg =
    let
        theme : BaseTheme
        theme =
            getBaseTheme model.colorScheme
    in
    Element.layout
        [ Background.color theme.backgroundColor
        , Font.color theme.fontColor
        ]
    <|
        viewLandingPage model toMsg


{-| Main landing page content with responsive layout
-}
viewLandingPage : Landing.Model -> (Landing.Msg -> msg) -> Element msg
viewLandingPage model toMsg =
    let
        theme : BaseTheme
        theme =
            getBaseTheme model.colorScheme

        screenSize : ScreenSize
        screenSize =
            getScreenSize model.maybeWindow
    in
    Element.column
        [ Element.centerX
        , Element.centerY
        , Element.spacing (getResponsiveSpacing model.maybeWindow 30)
        , Element.padding (getResponsivePadding model.maybeWindow 20)
        , Element.width Element.fill
        , Element.height Element.fill
        ]
        [ -- Header with title and theme toggle
          viewHeader model toMsg theme

        -- Main content area
        , viewMainContent model toMsg theme screenSize
        ]


{-| Header section with title and theme toggle button
-}
viewHeader : Landing.Model -> (Landing.Msg -> msg) -> BaseTheme -> Element msg
viewHeader model toMsg theme =
    Element.row
        [ Element.width Element.fill
        , Element.padding (getResponsivePadding model.maybeWindow 20)
        , Background.color theme.headerBackgroundColor
        , Element.Border.rounded 8
        ]
        [ -- Application title
          Element.el
            [ Element.alignLeft
            , Font.size (getResponsiveFontSize model.maybeWindow 32)
            , Font.bold
            , Font.color theme.fontColor
            ]
            (Element.text "Elm Tic-Tac-Toe")

        -- Theme toggle button
        , Element.el
            [ Element.alignRight ]
            (viewThemeToggle model toMsg theme)
        ]


{-| Main content area with navigation options
-}
viewMainContent : Landing.Model -> (Landing.Msg -> msg) -> BaseTheme -> ScreenSize -> Element msg
viewMainContent model toMsg theme screenSize =
    let
        contentLayout =
            case screenSize of
                Mobile ->
                    Element.column

                _ ->
                    Element.column
    in
    Element.el
        [ Element.centerX
        , Element.centerY
        , Background.color theme.backgroundColor
        , Element.padding (getResponsivePadding model.maybeWindow 40)
        , Element.Border.rounded 12
        , Element.width (Element.maximum 600 Element.fill)
        ]
    <|
        contentLayout
            [ Element.centerX
            , Element.spacing (getResponsiveSpacing model.maybeWindow 30)
            , Element.width Element.fill
            ]
            [ -- Welcome message
              viewWelcomeMessage model theme

            -- Navigation buttons
            , viewNavigationButtons model toMsg theme screenSize
            ]


{-| Welcome message section
-}
viewWelcomeMessage : Landing.Model -> BaseTheme -> Element msg
viewWelcomeMessage model theme =
    Element.column
        [ Element.centerX
        , Element.spacing (getResponsiveSpacing model.maybeWindow 15)
        ]
        [ Element.el
            [ Element.centerX
            , Font.size (getResponsiveFontSize model.maybeWindow 28)
            , Font.bold
            , Font.color theme.fontColor
            ]
            (Element.text "Welcome!")
        , Element.paragraph
            [ Element.centerX
            , Font.size (getResponsiveFontSize model.maybeWindow 18)
            , Font.color theme.secondaryFontColor
            , Font.center
            , Element.width (Element.maximum 400 Element.fill)
            ]
            [ Element.text "Choose your adventure: play games or explore our component style guide." ]
        ]


{-| Navigation buttons section
-}
viewNavigationButtons : Landing.Model -> (Landing.Msg -> msg) -> BaseTheme -> ScreenSize -> Element msg
viewNavigationButtons model toMsg theme screenSize =
    let
        buttonLayout =
            case screenSize of
                Mobile ->
                    Element.column

                _ ->
                    Element.row
    in
    buttonLayout
        [ Element.centerX
        , Element.spacing (getResponsiveSpacing model.maybeWindow 20)
        , Element.width Element.fill
        ]
        [ -- Play Tic-Tac-Toe Game button
          viewNavigationButton
            { label = "Tic-Tac-Toe"
            , description = "Classic strategy game"
            , icon = gameIcon theme
            , onClick = toMsg (Landing.NavigateToRoute Route.TicTacToe)
            , isPrimary = True
            , model = model
            , theme = theme
            }

        -- Play Robot Game button
        , viewNavigationButton
            { label = "Robot Grid Game"
            , description = "Control a robot on a grid"
            , icon = robotIcon theme
            , onClick = toMsg (Landing.NavigateToRoute Route.RobotGame)
            , isPrimary = True
            , model = model
            , theme = theme
            }

        -- View Style Guide button
        , viewNavigationButton
            { label = "View Style Guide"
            , description = "Explore components"
            , icon = styleGuideIcon theme
            , onClick = toMsg (Landing.NavigateToRoute Route.StyleGuide)
            , isPrimary = False
            , model = model
            , theme = theme
            }
        ]


{-| Configuration for navigation buttons
-}
type alias NavigationButtonConfig msg =
    { label : String
    , description : String
    , icon : Element msg
    , onClick : msg
    , isPrimary : Bool
    , model : Landing.Model
    , theme : BaseTheme
    }


{-| Reusable navigation button component
-}
viewNavigationButton : NavigationButtonConfig msg -> Element msg
viewNavigationButton config =
    let
        buttonColor =
            if config.isPrimary then
                config.theme.buttonColor

            else
                config.theme.cellBackgroundColor

        hoverColor =
            if config.isPrimary then
                config.theme.buttonHoverColor

            else
                config.theme.accentColor
    in
    Element.el
        [ Element.Events.onClick config.onClick
        , Element.pointer
        , Element.mouseOver [ Background.color hoverColor ]
        , Background.color buttonColor
        , Element.padding (getResponsivePadding config.model.maybeWindow 20)
        , Element.Border.rounded 8
        , Element.width Element.fill
        , Element.Border.width 2
        , Element.Border.color config.theme.borderColor
        ]
    <|
        Element.column
            [ Element.centerX
            , Element.spacing (getResponsiveSpacing config.model.maybeWindow 10)
            ]
            [ -- Icon
              Element.el
                [ Element.centerX
                , Element.width (Element.px 48)
                , Element.height (Element.px 48)
                ]
                config.icon

            -- Label
            , Element.el
                [ Element.centerX
                , Font.size (getResponsiveFontSize config.model.maybeWindow 20)
                , Font.bold
                , Font.color config.theme.fontColor
                ]
                (Element.text config.label)

            -- Description
            , Element.el
                [ Element.centerX
                , Font.size (getResponsiveFontSize config.model.maybeWindow 14)
                , Font.color config.theme.secondaryFontColor
                ]
                (Element.text config.description)
            ]


{-| Theme toggle button component
-}
viewThemeToggle : Landing.Model -> (Landing.Msg -> msg) -> BaseTheme -> Element msg
viewThemeToggle model toMsg theme =
    let
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
        [ Element.Events.onClick (toMsg Landing.ColorSchemeToggled)
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
                    , SvgAttr.fill theme.iconColorHex
                    ]
                    []
                ]


{-| Game icon for the Play Game button
-}
gameIcon : BaseTheme -> Element msg
gameIcon theme =
    Element.html <|
        Svg.svg
            [ SvgAttr.viewBox "0 0 24 24"
            , SvgAttr.width "100%"
            , SvgAttr.height "100%"
            ]
            [ -- Tic-tac-toe grid
              Svg.g
                [ SvgAttr.stroke theme.iconColorHex
                , SvgAttr.strokeWidth "2"
                , SvgAttr.fill "none"
                ]
                [ -- Grid lines
                  Svg.line [ SvgAttr.x1 "8", SvgAttr.y1 "4", SvgAttr.x2 "8", SvgAttr.y2 "20" ] []
                , Svg.line [ SvgAttr.x1 "16", SvgAttr.y1 "4", SvgAttr.x2 "16", SvgAttr.y2 "20" ] []
                , Svg.line [ SvgAttr.x1 "4", SvgAttr.y1 "8", SvgAttr.x2 "20", SvgAttr.y2 "8" ] []
                , Svg.line [ SvgAttr.x1 "4", SvgAttr.y1 "16", SvgAttr.x2 "20", SvgAttr.y2 "16" ] []

                -- X in top-left
                , Svg.line [ SvgAttr.x1 "5", SvgAttr.y1 "5", SvgAttr.x2 "7", SvgAttr.y2 "7" ] []
                , Svg.line [ SvgAttr.x1 "7", SvgAttr.y1 "5", SvgAttr.x2 "5", SvgAttr.y2 "7" ] []

                -- O in center
                , Svg.circle [ SvgAttr.cx "12", SvgAttr.cy "12", SvgAttr.r "1.5" ] []
                ]
            ]


{-| Robot icon for the Robot Grid Game button
-}
robotIcon : BaseTheme -> Element msg
robotIcon theme =
    Element.html <|
        Svg.svg
            [ SvgAttr.viewBox "0 0 24 24"
            , SvgAttr.width "100%"
            , SvgAttr.height "100%"
            ]
            [ Svg.g
                [ SvgAttr.stroke theme.iconColorHex
                , SvgAttr.strokeWidth "2"
                , SvgAttr.fill "none"
                ]
                [ -- Robot head (rectangle)
                  Svg.rect [ SvgAttr.x "8", SvgAttr.y "4", SvgAttr.width "8", SvgAttr.height "6", SvgAttr.rx "1" ] []

                -- Robot body (rectangle)
                , Svg.rect [ SvgAttr.x "6", SvgAttr.y "10", SvgAttr.width "12", SvgAttr.height "8", SvgAttr.rx "1" ] []

                -- Robot eyes (circles)
                , Svg.circle [ SvgAttr.cx "10", SvgAttr.cy "7", SvgAttr.r "1", SvgAttr.fill theme.iconColorHex ] []
                , Svg.circle [ SvgAttr.cx "14", SvgAttr.cy "7", SvgAttr.r "1", SvgAttr.fill theme.iconColorHex ] []

                -- Robot arms
                , Svg.line [ SvgAttr.x1 "6", SvgAttr.y1 "12", SvgAttr.x2 "4", SvgAttr.y2 "14" ] []
                , Svg.line [ SvgAttr.x1 "18", SvgAttr.y1 "12", SvgAttr.x2 "20", SvgAttr.y2 "14" ] []

                -- Robot legs
                , Svg.line [ SvgAttr.x1 "9", SvgAttr.y1 "18", SvgAttr.x2 "9", SvgAttr.y2 "21" ] []
                , Svg.line [ SvgAttr.x1 "15", SvgAttr.y1 "18", SvgAttr.x2 "15", SvgAttr.y2 "21" ] []

                -- Direction arrow (pointing up to show robot facing direction)
                , Svg.path [ SvgAttr.d "M12 13 L10 15 L14 15 Z", SvgAttr.fill theme.iconColorHex ] []
                ]
            ]


{-| Style guide icon for the View Style Guide button
-}
styleGuideIcon : BaseTheme -> Element msg
styleGuideIcon theme =
    Element.html <|
        Svg.svg
            [ SvgAttr.viewBox "0 0 24 24"
            , SvgAttr.width "100%"
            , SvgAttr.height "100%"
            ]
            [ Svg.g
                [ SvgAttr.stroke theme.iconColorHex
                , SvgAttr.strokeWidth "2"
                , SvgAttr.fill "none"
                ]
                [ -- Book/document outline
                  Svg.path [ SvgAttr.d "M4 19.5A2.5 2.5 0 0 1 6.5 17H20" ] []
                , Svg.path [ SvgAttr.d "M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" ] []

                -- Content lines
                , Svg.line [ SvgAttr.x1 "10", SvgAttr.y1 "6", SvgAttr.x2 "16", SvgAttr.y2 "6" ] []
                , Svg.line [ SvgAttr.x1 "10", SvgAttr.y1 "10", SvgAttr.x2 "16", SvgAttr.y2 "10" ] []
                , Svg.line [ SvgAttr.x1 "10", SvgAttr.y1 "14", SvgAttr.x2 "16", SvgAttr.y2 "14" ] []
                ]
            ]

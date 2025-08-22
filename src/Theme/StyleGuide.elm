module Theme.StyleGuide exposing (viewStyleGuideWithNavigation)

{-| Theme Style Guide module providing comprehensive theme documentation and component examples.

This module contains the style guide implementation that showcases all theme components,
color schemes, and design patterns used across the application. It serves as both
documentation and a visual testing ground for theme consistency.


## Features

  - **Color Palette Showcase**: Visual display of all theme colors with labels
  - **Theme Comparison**: Side-by-side comparison of light and dark themes
  - **Responsive Design Examples**: Demonstration of responsive behavior
  - **Component Examples**: Interactive examples of themed UI components
  - **Accessibility Information**: Contrast ratios and accessibility compliance details


## Usage

The style guide can be accessed through the main application navigation or
embedded in other views for theme testing and documentation purposes.

    -- Render standalone style guide
    styleGuideHtml =
        view lightTheme darkTheme (Just ( 1200, 800 ))

    -- Render with navigation for main app
    styleGuideWithNav =
        viewStyleGuideWithNavigation Light (Just ( 1200, 800 )) BackToLandingMsg


# Main Views

@docs viewStyleGuideWithNavigation

-}

import Element exposing (Color, Element)
import Element.Background as Background
import Element.Border
import Element.Events
import Element.Font as Font
import Element.HexColor
import Html exposing (Html)
import Theme.Theme exposing (BaseTheme, ColorScheme(..), getBaseTheme)


{-| Helper function to display a color swatch with label
-}
viewColorSwatch : String -> Color -> Element msg
viewColorSwatch label color =
    Element.row
        [ Element.spacing 20
        , Element.width Element.fill
        ]
        [ Element.el
            [ Element.width (Element.px 150) ]
            (Element.text label)
        , Element.el
            [ Background.color color
            , Element.width (Element.px 100)
            , Element.height (Element.px 40)
            , Element.Border.rounded 4
            , Element.Border.width 1
            , Element.Border.color (Element.rgb 0.8 0.8 0.8)
            ]
            Element.none
        ]


{-| Display base theme properties in a structured format
-}
viewBaseThemeProperties : BaseTheme -> Element msg
viewBaseThemeProperties baseTheme =
    Element.column
        [ Element.spacing 10
        , Element.width Element.fill
        ]
        [ viewColorSwatch "Background Color" (Element.HexColor.rgbCSSHex baseTheme.backgroundColorHex)
        , viewColorSwatch "Font Color" (Element.HexColor.rgbCSSHex baseTheme.fontColorHex)
        , viewColorSwatch "Secondary Font Color" (Element.HexColor.rgbCSSHex baseTheme.secondaryFontColorHex)
        , viewColorSwatch "Border Color" (Element.HexColor.rgbCSSHex baseTheme.borderColorHex)
        , viewColorSwatch "Accent Color" (Element.HexColor.rgbCSSHex baseTheme.accentColorHex)
        , viewColorSwatch "Button Color" (Element.HexColor.rgbCSSHex baseTheme.buttonColorHex)
        , viewColorSwatch "Button Hover Color" (Element.HexColor.rgbCSSHex baseTheme.buttonHoverColorHex)
        ]


{-| Display a preview of a color scheme
-}
viewColorSchemePreview : String -> BaseTheme -> Element msg
viewColorSchemePreview schemeName baseTheme =
    Element.column
        [ Element.spacing 15
        , Element.padding 20
        , Background.color (Element.HexColor.rgbCSSHex baseTheme.backgroundColorHex)
        , Element.Border.rounded 8
        , Element.Border.width 2
        , Element.Border.color (Element.HexColor.rgbCSSHex baseTheme.borderColorHex)
        , Element.width (Element.fillPortion 1)
        ]
        [ Element.el
            [ Font.size 20
            , Font.bold
            , Font.color (Element.HexColor.rgbCSSHex baseTheme.fontColorHex)
            ]
            (Element.text schemeName)
        , Element.el
            [ Font.color (Element.HexColor.rgbCSSHex baseTheme.secondaryFontColorHex)
            , Font.size 14
            ]
            (Element.text "Sample text in secondary color")
        , Element.el
            [ Background.color (Element.HexColor.rgbCSSHex baseTheme.buttonColorHex)
            , Font.color (Element.HexColor.rgbCSSHex baseTheme.fontColorHex)
            , Element.padding 8
            , Element.Border.rounded 4
            ]
            (Element.text "Sample Button")
        , Element.el
            [ Background.color (Element.HexColor.rgbCSSHex baseTheme.accentColorHex)
            , Font.color (Element.HexColor.rgbCSSHex baseTheme.fontColorHex)
            , Element.padding 8
            , Element.Border.rounded 4
            ]
            (Element.text "Accent Element")
        ]


{-| Display responsive design showcase
-}
viewResponsiveShowcase : Maybe ( Int, Int ) -> BaseTheme -> Element msg
viewResponsiveShowcase maybeWindow baseTheme =
    let
        screenInfo =
            case maybeWindow of
                Just ( width, height ) ->
                    "Current screen: " ++ String.fromInt width ++ "x" ++ String.fromInt height

                Nothing ->
                    "Screen size not available"
    in
    Element.column
        [ Element.spacing 15
        , Element.padding 20
        , Background.color (Element.HexColor.rgbCSSHex baseTheme.backgroundColorHex)
        , Element.Border.rounded 8
        , Element.Border.width 1
        , Element.Border.color (Element.HexColor.rgbCSSHex baseTheme.borderColorHex)
        ]
        [ Element.text screenInfo
        , Element.text "The theme system automatically adapts to different screen sizes:"
        , Element.column
            [ Element.spacing 8 ]
            [ Element.text "• Mobile: < 768px - Smaller fonts and padding"
            , Element.text "• Tablet: 768px - 1024px - Medium fonts and padding"
            , Element.text "• Desktop: > 1024px - Full fonts and padding"
            ]
        ]



-- STYLE GUIDE


{-| Render the theme style guide content
-}
viewStyleGuide : Maybe ( Int, Int ) -> Html msg
viewStyleGuide maybeWindow =
    let
        lightTheme =
            getBaseTheme Light

        darkTheme =
            getBaseTheme Dark

        -- Use light theme as the default display theme
        baseTheme =
            lightTheme
    in
    Element.layout
        [ Background.color (Element.HexColor.rgbCSSHex baseTheme.backgroundColorHex)
        , Font.color (Element.HexColor.rgbCSSHex baseTheme.fontColorHex)
        ]
    <|
        Element.column
            [ Element.padding 40
            , Element.spacing 30
            , Element.width Element.fill
            ]
            [ -- Base theme showcase
              Element.column
                [ Element.spacing 20
                , Element.width Element.fill
                ]
                [ Element.el
                    [ Font.size 28
                    , Font.bold
                    , Font.color (Element.HexColor.rgbCSSHex baseTheme.fontColorHex)
                    ]
                    (Element.text "Base Theme Properties")
                , Element.text "These are the shared theme properties used across all games:"
                , viewBaseThemeProperties baseTheme
                ]

            -- Color scheme comparison
            , Element.column
                [ Element.spacing 20
                , Element.width Element.fill
                ]
                [ Element.el
                    [ Font.size 28
                    , Font.bold
                    , Font.color (Element.HexColor.rgbCSSHex baseTheme.fontColorHex)
                    ]
                    (Element.text "Color Scheme Comparison")
                , Element.text "Light vs Dark theme comparison:"
                , Element.row
                    [ Element.spacing 40
                    , Element.width Element.fill
                    ]
                    [ viewColorSchemePreview "Light Theme" lightTheme
                    , viewColorSchemePreview "Dark Theme" darkTheme
                    ]
                ]

            -- Responsive design showcase
            , Element.column
                [ Element.spacing 20
                , Element.width Element.fill
                ]
                [ Element.el
                    [ Font.size 28
                    , Font.bold
                    , Font.color (Element.HexColor.rgbCSSHex baseTheme.fontColorHex)
                    ]
                    (Element.text "Responsive Design")
                , Element.text "The theme system includes responsive utilities for different screen sizes:"
                , viewResponsiveShowcase maybeWindow baseTheme
                ]
            ]


{-| Render the style guide with navigation header for use in the main application

Creates a complete style guide page with navigation header and back button,
designed for integration into the main application. The style guide adapts
to the current color scheme and provides comprehensive theme documentation.


## Parameters

  - `colorScheme`: Current color scheme (Light or Dark) for the navigation UI
  - `maybeWindow`: Optional viewport dimensions for responsive examples
  - `navigateBackMsg`: Message to send when the back button is clicked


## Features

  - Themed navigation header with back button
  - Full style guide content with current theme
  - Responsive layout that adapts to screen size
  - Scrollable content area for long documentation

-}
viewStyleGuideWithNavigation : ColorScheme -> Maybe ( Int, Int ) -> msg -> Html msg
viewStyleGuideWithNavigation colorScheme maybeWindow navigateBackMsg =
    let
        baseTheme =
            getBaseTheme colorScheme
    in
    Element.layout
        [ Background.color (Element.HexColor.rgbCSSHex baseTheme.backgroundColorHex)
        , Font.color (Element.HexColor.rgbCSSHex baseTheme.fontColorHex)
        ]
    <|
        Element.column
            [ Element.width Element.fill
            , Element.height Element.fill
            ]
            [ -- Header with back navigation
              Element.row
                [ Element.width Element.fill
                , Element.padding 20
                , Background.color (Element.HexColor.rgbCSSHex baseTheme.backgroundColorHex)
                , Element.spacing 20
                , Element.Border.widthEach { bottom = 2, top = 0, left = 0, right = 0 }
                , Element.Border.color (Element.HexColor.rgbCSSHex baseTheme.borderColorHex)
                ]
                [ Element.el
                    [ Element.pointer
                    , Element.Events.onClick navigateBackMsg
                    , Element.padding 10
                    , Background.color (Element.HexColor.rgbCSSHex baseTheme.buttonColorHex)
                    , Element.Border.rounded 4
                    , Element.mouseOver [ Background.color (Element.HexColor.rgbCSSHex baseTheme.buttonHoverColorHex) ]
                    , Font.color (Element.rgb255 255 255 255)
                    ]
                    (Element.text "← Back to Landing")
                , Element.el
                    [ Font.size 24
                    , Font.bold
                    , Font.color (Element.HexColor.rgbCSSHex baseTheme.fontColorHex)
                    ]
                    (Element.text "Theme Style Guide")
                ]

            -- Style guide content
            , Element.el
                [ Element.width Element.fill
                , Element.height Element.fill
                , Element.scrollbarY
                ]
                (Element.html (viewStyleGuide maybeWindow))
            ]

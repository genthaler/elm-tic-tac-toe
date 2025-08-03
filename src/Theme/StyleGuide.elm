module Theme.StyleGuide exposing (BaseTheme, view)

{-| Theme Style Guide module providing comprehensive theme documentation and component examples.

This module contains the style guide implementation that showcases all theme components,
color schemes, and design patterns used across the application.

-}

import Element exposing (Color, Element)
import Element.Background as Background
import Element.Border
import Element.Font as Font
import Html exposing (Html)


{-| Base theme record type (duplicated to avoid circular import)
-}
type alias BaseTheme =
    { backgroundColor : Color
    , fontColor : Color
    , secondaryFontColor : Color
    , borderColor : Color
    , accentColor : Color
    , buttonColor : Color
    , buttonHoverColor : Color
    }


{-| Main style guide view function that renders the complete theme documentation
-}
view : BaseTheme -> BaseTheme -> Maybe ( Int, Int ) -> Html msg
view lightTheme darkTheme maybeWindow =
    let
        -- Use light theme as the default display theme
        baseTheme =
            lightTheme
    in
    Element.layout
        [ Background.color baseTheme.backgroundColor
        , Font.color baseTheme.fontColor
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
                    , Font.color baseTheme.fontColor
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
                    , Font.color baseTheme.fontColor
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
                    , Font.color baseTheme.fontColor
                    ]
                    (Element.text "Responsive Design")
                , Element.text "The theme system includes responsive utilities for different screen sizes:"
                , viewResponsiveShowcase maybeWindow baseTheme
                ]
            ]


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
        [ viewColorSwatch "Background Color" baseTheme.backgroundColor
        , viewColorSwatch "Font Color" baseTheme.fontColor
        , viewColorSwatch "Secondary Font Color" baseTheme.secondaryFontColor
        , viewColorSwatch "Border Color" baseTheme.borderColor
        , viewColorSwatch "Accent Color" baseTheme.accentColor
        , viewColorSwatch "Button Color" baseTheme.buttonColor
        , viewColorSwatch "Button Hover Color" baseTheme.buttonHoverColor
        ]


{-| Display a preview of a color scheme
-}
viewColorSchemePreview : String -> BaseTheme -> Element msg
viewColorSchemePreview schemeName baseTheme =
    Element.column
        [ Element.spacing 15
        , Element.padding 20
        , Background.color baseTheme.backgroundColor
        , Element.Border.rounded 8
        , Element.Border.width 2
        , Element.Border.color baseTheme.borderColor
        , Element.width (Element.fillPortion 1)
        ]
        [ Element.el
            [ Font.size 20
            , Font.bold
            , Font.color baseTheme.fontColor
            ]
            (Element.text schemeName)
        , Element.el
            [ Font.color baseTheme.secondaryFontColor
            , Font.size 14
            ]
            (Element.text "Sample text in secondary color")
        , Element.el
            [ Background.color baseTheme.buttonColor
            , Font.color baseTheme.fontColor
            , Element.padding 8
            , Element.Border.rounded 4
            ]
            (Element.text "Sample Button")
        , Element.el
            [ Background.color baseTheme.accentColor
            , Font.color baseTheme.fontColor
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
        , Background.color baseTheme.backgroundColor
        , Element.Border.rounded 8
        , Element.Border.width 1
        , Element.Border.color baseTheme.borderColor
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

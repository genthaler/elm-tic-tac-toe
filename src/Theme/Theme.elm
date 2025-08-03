module Theme.Theme exposing
    ( ColorScheme(..), ScreenSize(..), BaseTheme, ResponsiveConfig, ColorPalette, RobotGameTheme
    , encodeColorScheme, decodeColorScheme
    , getScreenSize, calculateResponsiveCellSize, getResponsiveFontSize, getResponsiveSpacing, getResponsivePadding
    , getBaseTheme, lightColorPalette, darkColorPalette, defaultResponsiveConfig, getRobotGameTheme
    , viewStyleGuideWithNavigation
    , validateResponsiveConfig, safeGetBaseTheme, safeGetColorPalette
    )

{-| Shared theme module providing centralized theming system for all games.

This module contains common theme infrastructure including ColorScheme types,
responsive design utilities, and base theme configurations that can be used
across all games in the project.


# Types

@docs ColorScheme, ScreenSize, BaseTheme, ResponsiveConfig, ColorPalette, RobotGameTheme


# JSON Encoding/Decoding

@docs encodeColorScheme, decodeColorScheme


# Responsive Design Utilities

@docs getScreenSize, calculateResponsiveCellSize, getResponsiveFontSize, getResponsiveSpacing, getResponsivePadding


# Theme Configuration

@docs getBaseTheme, lightColorPalette, darkColorPalette, defaultResponsiveConfig, getRobotGameTheme


# Style Guide

@docs viewStyleGuideWithNavigation


# Validation and Error Handling

@docs validateResponsiveConfig, safeGetBaseTheme, safeGetColorPalette

-}

import Element exposing (Color)
import Element.Background as Background
import Element.Border
import Element.Events
import Element.Font as Font
import FlatColors.AussiePalette as AussiePalette
import Html exposing (Html)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Theme.StyleGuide



-- TYPES


{-| Color scheme variants for theme switching
-}
type ColorScheme
    = Light
    | Dark


{-| Screen size categories for responsive design
-}
type ScreenSize
    = Mobile
    | Tablet
    | Desktop


{-| Base theme properties shared across all games
-}
type alias BaseTheme =
    { -- Background colors
      backgroundColor : Color
    , fontColor : Color
    , secondaryFontColor : Color

    -- Border and accent colors
    , borderColor : Color
    , accentColor : Color

    -- Interactive element colors
    , buttonColor : Color
    , buttonHoverColor : Color
    }


{-| Color palette for consistent color usage
-}
type alias ColorPalette =
    { primary : Color
    , secondary : Color
    , background : Color
    , surface : Color
    , onPrimary : Color
    , onSecondary : Color
    , onBackground : Color
    , onSurface : Color
    , accent : Color
    , border : Color
    }


{-| Configuration for responsive design calculations
-}
type alias ResponsiveConfig =
    { mobileBreakpoint : Int
    , tabletBreakpoint : Int
    , minCellSize : Int
    , maxCellSize : Int
    , baseFontSize : Int
    }


{-| RobotGame-specific theme definition with comprehensive UI colors
-}
type alias RobotGameTheme =
    { -- Background colors
      backgroundColor : Color
    , gridBackgroundColor : Color
    , cellBackgroundColor : Color
    , robotCellBackgroundColor : Color
    , headerBackgroundColor : Color

    -- Border and accent colors
    , borderColor : Color
    , accentColor : Color

    -- Text colors
    , fontColor : Color
    , secondaryFontColor : Color

    -- Robot colors
    , robotBodyColor : String
    , robotDirectionColor : String
    , iconColor : String
    , borderColorHex : String

    -- Button colors
    , buttonBackgroundColor : Color
    , buttonHoverColor : Color
    , buttonPressedColor : Color
    , buttonDisabledColor : Color
    , buttonTextColor : Color
    , buttonDisabledTextColor : Color
    , buttonBlockedColor : Color
    , buttonBlockedTextColor : Color

    -- Blocked movement feedback colors
    , blockedMovementColor : Color
    , blockedMovementBorderColor : Color
    }



-- JSON ENCODING/DECODING


{-| Encode ColorScheme to JSON
-}
encodeColorScheme : ColorScheme -> Value
encodeColorScheme colorScheme =
    case colorScheme of
        Light ->
            Encode.string "Light"

        Dark ->
            Encode.string "Dark"


{-| Decode ColorScheme from JSON with fallback to Light
-}
decodeColorScheme : Decoder ColorScheme
decodeColorScheme =
    Decode.string
        |> Decode.map
            (\colorSchemeStr ->
                case colorSchemeStr of
                    "Light" ->
                        Light

                    "Dark" ->
                        Dark

                    _ ->
                        -- Fallback to Light for invalid values
                        Light
            )



-- RESPONSIVE DESIGN UTILITIES


{-| Determine screen size based on viewport dimensions
-}
getScreenSize : Maybe ( Int, Int ) -> ScreenSize
getScreenSize maybeWindow =
    case maybeWindow of
        Just ( width, _ ) ->
            let
                config =
                    defaultResponsiveConfig
            in
            if width < config.mobileBreakpoint then
                Mobile

            else if width < config.tabletBreakpoint then
                Tablet

            else
                Desktop

        Nothing ->
            Desktop


{-| Calculate responsive cell size based on viewport and screen size
-}
calculateResponsiveCellSize : Maybe ( Int, Int ) -> Int -> Int -> Int
calculateResponsiveCellSize maybeWindow gridDivisor fallbackSize =
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
                            minDimension // gridDivisor

                        Tablet ->
                            minDimension // (gridDivisor - 1)

                        Desktop ->
                            minDimension // (gridDivisor - 1)

                minSize =
                    case screenSize of
                        Mobile ->
                            60

                        Tablet ->
                            80

                        Desktop ->
                            100

                maxSize =
                    case screenSize of
                        Mobile ->
                            100

                        Tablet ->
                            140

                        Desktop ->
                            160
            in
            Basics.max minSize (Basics.min maxSize baseSize)

        Nothing ->
            fallbackSize


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



-- THEME CONFIGURATION


{-| Get base theme configuration for the given color scheme
-}
getBaseTheme : ColorScheme -> BaseTheme
getBaseTheme colorScheme =
    case colorScheme of
        Light ->
            { backgroundColor = Element.rgb255 248 249 250
            , fontColor = Element.rgb255 44 62 80 -- deepCove equivalent
            , secondaryFontColor = Element.rgb255 127 140 141
            , borderColor = Element.rgb255 189 195 199
            , accentColor = Element.rgb255 26 188 156 -- coastalBreeze equivalent
            , buttonColor = Element.rgb255 52 152 219
            , buttonHoverColor = Element.rgb255 41 128 185
            }

        Dark ->
            { backgroundColor = Element.rgb255 44 62 80 -- deepCove
            , fontColor = Element.rgb255 236 240 241
            , secondaryFontColor = Element.rgb255 149 165 166 -- soaringEagle equivalent
            , borderColor = Element.rgb255 149 165 166
            , accentColor = Element.rgb255 26 188 156 -- coastalBreeze
            , buttonColor = Element.rgb255 52 152 219
            , buttonHoverColor = Element.rgb255 41 128 185
            }


{-| Light color palette for consistent theming
-}
lightColorPalette : ColorPalette
lightColorPalette =
    { primary = Element.rgb255 52 152 219
    , secondary = Element.rgb255 26 188 156
    , background = Element.rgb255 248 249 250
    , surface = Element.rgb255 255 255 255
    , onPrimary = Element.rgb255 255 255 255
    , onSecondary = Element.rgb255 255 255 255
    , onBackground = Element.rgb255 44 62 80
    , onSurface = Element.rgb255 44 62 80
    , accent = Element.rgb255 26 188 156
    , border = Element.rgb255 189 195 199
    }


{-| Dark color palette for consistent theming
-}
darkColorPalette : ColorPalette
darkColorPalette =
    { primary = Element.rgb255 52 152 219
    , secondary = Element.rgb255 26 188 156
    , background = Element.rgb255 44 62 80
    , surface = Element.rgb255 52 73 94
    , onPrimary = Element.rgb255 255 255 255
    , onSecondary = Element.rgb255 255 255 255
    , onBackground = Element.rgb255 236 240 241
    , onSurface = Element.rgb255 236 240 241
    , accent = Element.rgb255 26 188 156
    , border = Element.rgb255 149 165 166
    }


{-| Default responsive configuration
-}
defaultResponsiveConfig : ResponsiveConfig
defaultResponsiveConfig =
    { mobileBreakpoint = 768
    , tabletBreakpoint = 1024
    , minCellSize = 60
    , maxCellSize = 160
    , baseFontSize = 16
    }


{-| Get RobotGame theme configuration for the given color scheme
-}
getRobotGameTheme : ColorScheme -> RobotGameTheme
getRobotGameTheme colorScheme =
    case colorScheme of
        Light ->
            robotGameLightTheme

        Dark ->
            robotGameDarkTheme


{-| RobotGame dark theme with carefully selected colors for good contrast and accessibility
-}
robotGameDarkTheme : RobotGameTheme
robotGameDarkTheme =
    { backgroundColor = AussiePalette.deepCove
    , gridBackgroundColor = AussiePalette.blurple
    , cellBackgroundColor = AussiePalette.pureApple
    , robotCellBackgroundColor = AussiePalette.coastalBreeze
    , headerBackgroundColor = AussiePalette.blurple
    , borderColor = AussiePalette.soaringEagle
    , accentColor = AussiePalette.coastalBreeze
    , fontColor = Element.rgb255 236 240 241
    , secondaryFontColor = AussiePalette.soaringEagle
    , robotBodyColor = "#1abc9c"
    , robotDirectionColor = "#e74c3c"
    , iconColor = "#ecf0f1"
    , borderColorHex = "#95a5a6"
    , buttonBackgroundColor = AussiePalette.coastalBreeze
    , buttonHoverColor = Element.rgb255 52 152 219
    , buttonPressedColor = Element.rgb255 41 128 185
    , buttonDisabledColor = Element.rgb255 127 140 141
    , buttonTextColor = Element.rgb255 236 240 241
    , buttonDisabledTextColor = Element.rgb255 189 195 199
    , buttonBlockedColor = Element.rgb255 231 76 60
    , buttonBlockedTextColor = Element.rgb255 236 240 241
    , blockedMovementColor = Element.rgb255 231 76 60
    , blockedMovementBorderColor = Element.rgb255 192 57 43
    }


{-| RobotGame light theme with warm, accessible colors
-}
robotGameLightTheme : RobotGameTheme
robotGameLightTheme =
    { backgroundColor = Element.rgb255 248 249 250
    , gridBackgroundColor = AussiePalette.quinceJelly
    , cellBackgroundColor = AussiePalette.beekeeper
    , robotCellBackgroundColor = AussiePalette.coastalBreeze
    , headerBackgroundColor = AussiePalette.quinceJelly
    , borderColor = Element.rgb255 189 195 199
    , accentColor = AussiePalette.coastalBreeze
    , fontColor = AussiePalette.deepCove
    , secondaryFontColor = Element.rgb255 127 140 141
    , robotBodyColor = "#e67e22"
    , robotDirectionColor = "#c0392b"
    , iconColor = "#2c3e50"
    , borderColorHex = "#bdc3c7"
    , buttonBackgroundColor = AussiePalette.coastalBreeze
    , buttonHoverColor = Element.rgb255 52 152 219
    , buttonPressedColor = Element.rgb255 41 128 185
    , buttonDisabledColor = Element.rgb255 189 195 199
    , buttonTextColor = Element.rgb255 236 240 241
    , buttonDisabledTextColor = Element.rgb255 127 140 141
    , buttonBlockedColor = Element.rgb255 231 76 60
    , buttonBlockedTextColor = Element.rgb255 236 240 241
    , blockedMovementColor = Element.rgb255 231 76 60
    , blockedMovementBorderColor = Element.rgb255 192 57 43
    }



-- VALIDATION AND ERROR HANDLING


{-| Validate a BaseTheme configuration and return a corrected version with fallbacks
-}
validateBaseTheme : BaseTheme -> BaseTheme
validateBaseTheme theme =
    -- For now, we trust that Element.Color values are always valid
    -- In a more complex scenario, we might validate color ranges or formats
    -- This function serves as a placeholder for future validation logic
    theme


{-| Validate a ColorPalette configuration and return a corrected version with fallbacks
-}
validateColorPalette : ColorPalette -> ColorPalette
validateColorPalette palette =
    -- Similar to validateBaseTheme, Element.Color values are inherently valid
    -- This function provides a hook for future validation requirements
    palette


{-| Validate ResponsiveConfig and ensure all values are within reasonable bounds
-}
validateResponsiveConfig : ResponsiveConfig -> ResponsiveConfig
validateResponsiveConfig config =
    { mobileBreakpoint = Basics.max 320 (Basics.min 1024 config.mobileBreakpoint)
    , tabletBreakpoint = Basics.max config.mobileBreakpoint (Basics.min 1920 config.tabletBreakpoint)
    , minCellSize = Basics.max 20 (Basics.min 200 config.minCellSize)
    , maxCellSize = Basics.max config.minCellSize (Basics.min 400 config.maxCellSize)
    , baseFontSize = Basics.max 10 (Basics.min 32 config.baseFontSize)
    }


{-| Safely get base theme with validation and error handling
-}
safeGetBaseTheme : ColorScheme -> BaseTheme
safeGetBaseTheme colorScheme =
    getBaseTheme colorScheme
        |> validateBaseTheme


{-| Safely get color palette with validation and error handling
-}
safeGetColorPalette : ColorScheme -> ColorPalette
safeGetColorPalette colorScheme =
    let
        palette =
            case colorScheme of
                Light ->
                    lightColorPalette

                Dark ->
                    darkColorPalette
    in
    validateColorPalette palette



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
    in
    Theme.StyleGuide.view lightTheme darkTheme maybeWindow


{-| Render the style guide with navigation header for use in the main application
-}
viewStyleGuideWithNavigation : ColorScheme -> Maybe ( Int, Int ) -> msg -> Html msg
viewStyleGuideWithNavigation colorScheme maybeWindow navigateBackMsg =
    let
        baseTheme =
            getBaseTheme colorScheme
    in
    Element.layout
        [ Background.color baseTheme.backgroundColor
        , Font.color baseTheme.fontColor
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
                , Background.color baseTheme.backgroundColor
                , Element.spacing 20
                , Element.Border.widthEach { bottom = 2, top = 0, left = 0, right = 0 }
                , Element.Border.color baseTheme.borderColor
                ]
                [ Element.el
                    [ Element.pointer
                    , Element.Events.onClick navigateBackMsg
                    , Element.padding 10
                    , Background.color baseTheme.buttonColor
                    , Element.Border.rounded 4
                    , Element.mouseOver [ Background.color baseTheme.buttonHoverColor ]
                    , Font.color baseTheme.fontColor
                    ]
                    (Element.text "← Back to Home")
                , Element.el
                    [ Font.size 24
                    , Font.bold
                    , Font.color baseTheme.fontColor
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

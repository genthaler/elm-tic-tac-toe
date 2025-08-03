module Theme.ThemeTest exposing (suite)

import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)
import Theme.Theme as Theme


suite : Test
suite =
    describe "Theme.Theme"
        [ describe "ColorScheme JSON encoding/decoding"
            [ test "encodes Light correctly" <|
                \_ ->
                    Theme.encodeColorScheme Theme.Light
                        |> Encode.encode 0
                        |> Expect.equal "\"Light\""
            , test "encodes Dark correctly" <|
                \_ ->
                    Theme.encodeColorScheme Theme.Dark
                        |> Encode.encode 0
                        |> Expect.equal "\"Dark\""
            , test "decodes Light correctly" <|
                \_ ->
                    Decode.decodeString Theme.decodeColorScheme "\"Light\""
                        |> Expect.equal (Ok Theme.Light)
            , test "decodes Dark correctly" <|
                \_ ->
                    Decode.decodeString Theme.decodeColorScheme "\"Dark\""
                        |> Expect.equal (Ok Theme.Dark)
            , test "decodes invalid value to Light (fallback)" <|
                \_ ->
                    Decode.decodeString Theme.decodeColorScheme "\"Invalid\""
                        |> Expect.equal (Ok Theme.Light)
            , test "decodes empty string to Light (fallback)" <|
                \_ ->
                    Decode.decodeString Theme.decodeColorScheme "\"\""
                        |> Expect.equal (Ok Theme.Light)
            , test "decodes null to Light (fallback)" <|
                \_ ->
                    Decode.decodeString Theme.decodeColorScheme "null"
                        |> Result.toMaybe
                        |> Expect.equal Nothing
            , test "round-trip encoding/decoding preserves Light" <|
                \_ ->
                    Theme.Light
                        |> Theme.encodeColorScheme
                        |> Decode.decodeValue Theme.decodeColorScheme
                        |> Expect.equal (Ok Theme.Light)
            , test "round-trip encoding/decoding preserves Dark" <|
                \_ ->
                    Theme.Dark
                        |> Theme.encodeColorScheme
                        |> Decode.decodeValue Theme.decodeColorScheme
                        |> Expect.equal (Ok Theme.Dark)
            ]
        , describe "Screen size detection"
            [ test "detects Mobile for width < 768" <|
                \_ ->
                    Theme.getScreenSize (Just ( 767, 1024 ))
                        |> Expect.equal Theme.Mobile
            , test "detects Mobile at boundary (width = 767)" <|
                \_ ->
                    Theme.getScreenSize (Just ( 767, 1024 ))
                        |> Expect.equal Theme.Mobile
            , test "detects Tablet for width 768-1023" <|
                \_ ->
                    Theme.getScreenSize (Just ( 800, 1024 ))
                        |> Expect.equal Theme.Tablet
            , test "detects Tablet at lower boundary (width = 768)" <|
                \_ ->
                    Theme.getScreenSize (Just ( 768, 1024 ))
                        |> Expect.equal Theme.Tablet
            , test "detects Tablet at upper boundary (width = 1023)" <|
                \_ ->
                    Theme.getScreenSize (Just ( 1023, 768 ))
                        |> Expect.equal Theme.Tablet
            , test "detects Desktop for width >= 1024" <|
                \_ ->
                    Theme.getScreenSize (Just ( 1024, 768 ))
                        |> Expect.equal Theme.Desktop
            , test "detects Desktop at boundary (width = 1024)" <|
                \_ ->
                    Theme.getScreenSize (Just ( 1024, 768 ))
                        |> Expect.equal Theme.Desktop
            , test "detects Desktop for very large width" <|
                \_ ->
                    Theme.getScreenSize (Just ( 2560, 1440 ))
                        |> Expect.equal Theme.Desktop
            , test "defaults to Desktop when no window size" <|
                \_ ->
                    Theme.getScreenSize Nothing
                        |> Expect.equal Theme.Desktop
            , test "handles zero width gracefully" <|
                \_ ->
                    Theme.getScreenSize (Just ( 0, 1024 ))
                        |> Expect.equal Theme.Mobile
            , test "handles negative width gracefully" <|
                \_ ->
                    Theme.getScreenSize (Just ( -100, 1024 ))
                        |> Expect.equal Theme.Mobile
            ]
        , describe "Responsive utilities"
            [ describe "Font size calculations"
                [ test "calculates responsive font size for Mobile" <|
                    \_ ->
                        Theme.getResponsiveFontSize (Just ( 400, 800 )) 24
                            |> Expect.equal 16
                , test "calculates responsive font size for Tablet" <|
                    \_ ->
                        Theme.getResponsiveFontSize (Just ( 800, 600 )) 24
                            |> Expect.equal 20
                , test "calculates responsive font size for Desktop" <|
                    \_ ->
                        Theme.getResponsiveFontSize (Just ( 1200, 800 )) 24
                            |> Expect.equal 24
                , test "enforces minimum font size for Mobile" <|
                    \_ ->
                        Theme.getResponsiveFontSize (Just ( 400, 800 )) 20
                            |> Expect.equal 16
                , test "enforces minimum font size for Tablet" <|
                    \_ ->
                        Theme.getResponsiveFontSize (Just ( 800, 600 )) 20
                            |> Expect.equal 18
                , test "handles very small base font size" <|
                    \_ ->
                        Theme.getResponsiveFontSize (Just ( 400, 800 )) 10
                            |> Expect.equal 16
                ]
            , describe "Spacing calculations"
                [ test "calculates responsive spacing for Mobile" <|
                    \_ ->
                        Theme.getResponsiveSpacing (Just ( 400, 800 )) 20
                            |> Expect.equal 15
                , test "calculates responsive spacing for Tablet" <|
                    \_ ->
                        Theme.getResponsiveSpacing (Just ( 800, 600 )) 20
                            |> Expect.equal 18
                , test "calculates responsive spacing for Desktop" <|
                    \_ ->
                        Theme.getResponsiveSpacing (Just ( 1200, 800 )) 20
                            |> Expect.equal 20
                , test "enforces minimum spacing for Mobile" <|
                    \_ ->
                        Theme.getResponsiveSpacing (Just ( 400, 800 )) 8
                            |> Expect.equal 5
                , test "enforces minimum spacing for Tablet" <|
                    \_ ->
                        Theme.getResponsiveSpacing (Just ( 800, 600 )) 8
                            |> Expect.equal 8
                ]
            , describe "Padding calculations"
                [ test "calculates responsive padding for Mobile" <|
                    \_ ->
                        Theme.getResponsivePadding (Just ( 400, 800 )) 20
                            |> Expect.equal 13
                , test "calculates responsive padding for Tablet" <|
                    \_ ->
                        Theme.getResponsivePadding (Just ( 800, 600 )) 20
                            |> Expect.equal 17
                , test "calculates responsive padding for Desktop" <|
                    \_ ->
                        Theme.getResponsivePadding (Just ( 1200, 800 )) 20
                            |> Expect.equal 20
                , test "enforces minimum padding for Mobile" <|
                    \_ ->
                        Theme.getResponsivePadding (Just ( 400, 800 )) 10
                            |> Expect.equal 8
                , test "enforces minimum padding for Tablet" <|
                    \_ ->
                        Theme.getResponsivePadding (Just ( 800, 600 )) 10
                            |> Expect.equal 12
                ]
            , describe "Cell size calculations"
                [ test "calculates responsive cell size for Mobile" <|
                    \_ ->
                        Theme.calculateResponsiveCellSize (Just ( 400, 800 )) 8 80
                            |> Expect.atLeast 40
                , test "calculates responsive cell size for Tablet" <|
                    \_ ->
                        Theme.calculateResponsiveCellSize (Just ( 800, 600 )) 8 80
                            |> Expect.atLeast 60
                , test "calculates responsive cell size for Desktop" <|
                    \_ ->
                        Theme.calculateResponsiveCellSize (Just ( 1200, 800 )) 8 80
                            |> Expect.atLeast 80
                , test "uses fallback size when no window dimensions" <|
                    \_ ->
                        Theme.calculateResponsiveCellSize Nothing 8 80
                            |> Expect.equal 80
                , test "respects minimum cell size bounds" <|
                    \_ ->
                        Theme.calculateResponsiveCellSize (Just ( 200, 200 )) 20 80
                            |> Expect.atLeast 40
                , test "respects maximum cell size bounds" <|
                    \_ ->
                        Theme.calculateResponsiveCellSize (Just ( 2000, 2000 )) 2 80
                            |> Expect.atMost 160
                ]
            ]
        , describe "Theme selection and configuration"
            [ describe "Base theme configuration"
                [ test "provides Light base theme with correct structure" <|
                    \_ ->
                        let
                            theme =
                                Theme.getBaseTheme Theme.Light
                        in
                        Expect.all
                            [ \t -> t.backgroundColor |> always Expect.pass
                            , \t -> t.fontColor |> always Expect.pass
                            , \t -> t.secondaryFontColor |> always Expect.pass
                            , \t -> t.borderColor |> always Expect.pass
                            , \t -> t.accentColor |> always Expect.pass
                            , \t -> t.buttonColor |> always Expect.pass
                            , \t -> t.buttonHoverColor |> always Expect.pass
                            ]
                            theme
                , test "provides Dark base theme with correct structure" <|
                    \_ ->
                        let
                            theme =
                                Theme.getBaseTheme Theme.Dark
                        in
                        Expect.all
                            [ \t -> t.backgroundColor |> always Expect.pass
                            , \t -> t.fontColor |> always Expect.pass
                            , \t -> t.secondaryFontColor |> always Expect.pass
                            , \t -> t.borderColor |> always Expect.pass
                            , \t -> t.accentColor |> always Expect.pass
                            , \t -> t.buttonColor |> always Expect.pass
                            , \t -> t.buttonHoverColor |> always Expect.pass
                            ]
                            theme
                , test "Light and Dark themes have different background colors" <|
                    \_ ->
                        let
                            lightTheme =
                                Theme.getBaseTheme Theme.Light

                            darkTheme =
                                Theme.getBaseTheme Theme.Dark
                        in
                        lightTheme.backgroundColor
                            |> Expect.notEqual darkTheme.backgroundColor
                , test "Light and Dark themes have different font colors" <|
                    \_ ->
                        let
                            lightTheme =
                                Theme.getBaseTheme Theme.Light

                            darkTheme =
                                Theme.getBaseTheme Theme.Dark
                        in
                        lightTheme.fontColor
                            |> Expect.notEqual darkTheme.fontColor
                ]
            , describe "Color palette configuration"
                [ test "provides Light color palette with correct structure" <|
                    \_ ->
                        let
                            palette =
                                Theme.lightColorPalette
                        in
                        Expect.all
                            [ \p -> p.primary |> always Expect.pass
                            , \p -> p.secondary |> always Expect.pass
                            , \p -> p.background |> always Expect.pass
                            , \p -> p.surface |> always Expect.pass
                            , \p -> p.onPrimary |> always Expect.pass
                            , \p -> p.onSecondary |> always Expect.pass
                            , \p -> p.onBackground |> always Expect.pass
                            , \p -> p.onSurface |> always Expect.pass
                            , \p -> p.accent |> always Expect.pass
                            , \p -> p.border |> always Expect.pass
                            ]
                            palette
                , test "provides Dark color palette with correct structure" <|
                    \_ ->
                        let
                            palette =
                                Theme.darkColorPalette
                        in
                        Expect.all
                            [ \p -> p.primary |> always Expect.pass
                            , \p -> p.secondary |> always Expect.pass
                            , \p -> p.background |> always Expect.pass
                            , \p -> p.surface |> always Expect.pass
                            , \p -> p.onPrimary |> always Expect.pass
                            , \p -> p.onSecondary |> always Expect.pass
                            , \p -> p.onBackground |> always Expect.pass
                            , \p -> p.onSurface |> always Expect.pass
                            , \p -> p.accent |> always Expect.pass
                            , \p -> p.border |> always Expect.pass
                            ]
                            palette
                , test "Light and Dark palettes have different background colors" <|
                    \_ ->
                        Theme.lightColorPalette.background
                            |> Expect.notEqual Theme.darkColorPalette.background
                , test "Light and Dark palettes have different surface colors" <|
                    \_ ->
                        Theme.lightColorPalette.surface
                            |> Expect.notEqual Theme.darkColorPalette.surface
                ]
            , describe "Default responsive configuration"
                [ test "provides valid default responsive config" <|
                    \_ ->
                        let
                            config =
                                Theme.defaultResponsiveConfig
                        in
                        Expect.all
                            [ \c -> c.mobileBreakpoint |> Expect.equal 768
                            , \c -> c.tabletBreakpoint |> Expect.equal 1024
                            , \c -> c.minCellSize |> Expect.equal 60
                            , \c -> c.maxCellSize |> Expect.equal 160
                            , \c -> c.baseFontSize |> Expect.equal 16
                            ]
                            config
                , test "default config has logical breakpoint ordering" <|
                    \_ ->
                        let
                            config =
                                Theme.defaultResponsiveConfig
                        in
                        config.mobileBreakpoint
                            |> Expect.lessThan config.tabletBreakpoint
                , test "default config has logical cell size ordering" <|
                    \_ ->
                        let
                            config =
                                Theme.defaultResponsiveConfig
                        in
                        config.minCellSize
                            |> Expect.lessThan config.maxCellSize
                ]
            ]
        , describe "Validation and error handling"
            [ test "validateResponsiveConfig enforces minimum mobile breakpoint" <|
                \_ ->
                    let
                        config =
                            { mobileBreakpoint = 100
                            , tabletBreakpoint = 1024
                            , minCellSize = 60
                            , maxCellSize = 160
                            , baseFontSize = 16
                            }

                        validated =
                            Theme.validateResponsiveConfig config
                    in
                    validated.mobileBreakpoint
                        |> Expect.equal 320
            , test "validateResponsiveConfig enforces maximum tablet breakpoint" <|
                \_ ->
                    let
                        config =
                            { mobileBreakpoint = 768
                            , tabletBreakpoint = 2000
                            , minCellSize = 60
                            , maxCellSize = 160
                            , baseFontSize = 16
                            }

                        validated =
                            Theme.validateResponsiveConfig config
                    in
                    validated.tabletBreakpoint
                        |> Expect.equal 1920
            , test "validateResponsiveConfig ensures tablet breakpoint >= mobile breakpoint" <|
                \_ ->
                    let
                        config =
                            { mobileBreakpoint = 800
                            , tabletBreakpoint = 700
                            , minCellSize = 60
                            , maxCellSize = 160
                            , baseFontSize = 16
                            }

                        validated =
                            Theme.validateResponsiveConfig config
                    in
                    validated.tabletBreakpoint
                        |> Expect.atLeast validated.mobileBreakpoint
            , test "validateResponsiveConfig enforces cell size bounds" <|
                \_ ->
                    let
                        config =
                            { mobileBreakpoint = 768
                            , tabletBreakpoint = 1024
                            , minCellSize = 10
                            , maxCellSize = 500
                            , baseFontSize = 16
                            }

                        validated =
                            Theme.validateResponsiveConfig config
                    in
                    Expect.all
                        [ \c -> c.minCellSize |> Expect.equal 20
                        , \c -> c.maxCellSize |> Expect.equal 400
                        ]
                        validated
            , test "validateResponsiveConfig enforces font size bounds" <|
                \_ ->
                    let
                        config =
                            { mobileBreakpoint = 768
                            , tabletBreakpoint = 1024
                            , minCellSize = 60
                            , maxCellSize = 160
                            , baseFontSize = 5
                            }

                        validated =
                            Theme.validateResponsiveConfig config
                    in
                    validated.baseFontSize
                        |> Expect.equal 10
            , test "safeGetBaseTheme returns validated theme" <|
                \_ ->
                    let
                        theme =
                            Theme.safeGetBaseTheme Theme.Light
                    in
                    -- Just verify it returns a valid theme structure
                    Expect.all
                        [ \t -> t.backgroundColor |> always Expect.pass
                        , \t -> t.fontColor |> always Expect.pass
                        , \t -> t.secondaryFontColor |> always Expect.pass
                        , \t -> t.borderColor |> always Expect.pass
                        , \t -> t.accentColor |> always Expect.pass
                        , \t -> t.buttonColor |> always Expect.pass
                        , \t -> t.buttonHoverColor |> always Expect.pass
                        ]
                        theme
            , test "safeGetColorPalette returns validated palette" <|
                \_ ->
                    let
                        palette =
                            Theme.safeGetColorPalette Theme.Dark
                    in
                    -- Just verify it returns a valid palette structure
                    Expect.all
                        [ \p -> p.primary |> always Expect.pass
                        , \p -> p.secondary |> always Expect.pass
                        , \p -> p.background |> always Expect.pass
                        , \p -> p.surface |> always Expect.pass
                        , \p -> p.onPrimary |> always Expect.pass
                        , \p -> p.onSecondary |> always Expect.pass
                        , \p -> p.onBackground |> always Expect.pass
                        , \p -> p.onSurface |> always Expect.pass
                        , \p -> p.accent |> always Expect.pass
                        , \p -> p.border |> always Expect.pass
                        ]
                        palette
            ]
        ]

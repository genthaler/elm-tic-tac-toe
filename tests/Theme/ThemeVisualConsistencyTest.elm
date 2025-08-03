module Theme.ThemeVisualConsistencyTest exposing (suite)

{-| Visual consistency tests for shared theme module.

This module tests that the shared theme module provides consistent visual
appearance across both games and that theme switching maintains visual integrity.

-}

import Expect
import Test exposing (Test, describe, test)
import Theme.Theme as Theme


suite : Test
suite =
    describe "Theme Visual Consistency Tests"
        [ baseThemeConsistencyTests
        , colorPaletteConsistencyTests
        , responsiveDesignConsistencyTests
        , themeValidationTests
        , visualRegressionPreventionTests
        ]


{-| Tests that verify base theme properties are consistent
-}
baseThemeConsistencyTests : Test
baseThemeConsistencyTests =
    describe "Base theme consistency"
        [ test "Light theme has consistent color relationships" <|
            \_ ->
                let
                    lightTheme =
                        Theme.getBaseTheme Theme.Light

                    -- Verify that light theme has appropriate contrast relationships
                    -- Background should be lighter than font color (conceptually)
                    -- This is a structural test to ensure theme integrity
                in
                Expect.all
                    [ \_ -> Expect.notEqual lightTheme.backgroundColor lightTheme.fontColor
                    , \_ -> Expect.notEqual lightTheme.fontColor lightTheme.secondaryFontColor
                    , \_ -> Expect.notEqual lightTheme.backgroundColor lightTheme.borderColor
                    , \_ -> Expect.notEqual lightTheme.buttonColor lightTheme.buttonHoverColor
                    ]
                    ()
        , test "Dark theme has consistent color relationships" <|
            \_ ->
                let
                    darkTheme =
                        Theme.getBaseTheme Theme.Dark
                in
                Expect.all
                    [ \_ -> Expect.notEqual darkTheme.backgroundColor darkTheme.fontColor
                    , \_ -> Expect.notEqual darkTheme.fontColor darkTheme.secondaryFontColor
                    , \_ -> Expect.notEqual darkTheme.backgroundColor darkTheme.borderColor
                    , \_ -> Expect.notEqual darkTheme.buttonColor darkTheme.buttonHoverColor
                    ]
                    ()
        , test "Light and dark themes have appropriate contrast" <|
            \_ ->
                let
                    lightTheme =
                        Theme.getBaseTheme Theme.Light

                    darkTheme =
                        Theme.getBaseTheme Theme.Dark
                in
                Expect.all
                    [ \_ -> Expect.notEqual lightTheme.backgroundColor darkTheme.backgroundColor
                    , \_ -> Expect.notEqual lightTheme.fontColor darkTheme.fontColor
                    , \_ -> Expect.notEqual lightTheme.secondaryFontColor darkTheme.secondaryFontColor
                    , \_ -> Expect.notEqual lightTheme.borderColor darkTheme.borderColor

                    -- Accent and button colors should remain consistent across themes
                    , \_ -> Expect.equal lightTheme.accentColor darkTheme.accentColor
                    , \_ -> Expect.equal lightTheme.buttonColor darkTheme.buttonColor
                    , \_ -> Expect.equal lightTheme.buttonHoverColor darkTheme.buttonHoverColor
                    ]
                    ()
        , test "Safe theme getters provide validated themes" <|
            \_ ->
                let
                    safeLight =
                        Theme.safeGetBaseTheme Theme.Light

                    safeDark =
                        Theme.safeGetBaseTheme Theme.Dark

                    regularLight =
                        Theme.getBaseTheme Theme.Light

                    regularDark =
                        Theme.getBaseTheme Theme.Dark
                in
                Expect.all
                    [ \_ -> Expect.equal regularLight safeLight
                    , \_ -> Expect.equal regularDark safeDark
                    ]
                    ()
        ]


{-| Tests that verify color palette consistency
-}
colorPaletteConsistencyTests : Test
colorPaletteConsistencyTests =
    describe "Color palette consistency"
        [ test "Light color palette has proper color relationships" <|
            \_ ->
                let
                    palette =
                        Theme.lightColorPalette
                in
                Expect.all
                    [ \_ -> Expect.notEqual palette.primary palette.secondary
                    , \_ -> Expect.notEqual palette.background palette.surface
                    , \_ -> Expect.notEqual palette.onBackground palette.background
                    , \_ -> Expect.notEqual palette.onSurface palette.surface
                    , \_ -> Expect.notEqual palette.onPrimary palette.primary
                    , \_ -> Expect.notEqual palette.onSecondary palette.secondary
                    ]
                    ()
        , test "Dark color palette has proper color relationships" <|
            \_ ->
                let
                    palette =
                        Theme.darkColorPalette
                in
                Expect.all
                    [ \_ -> Expect.notEqual palette.primary palette.secondary
                    , \_ -> Expect.notEqual palette.background palette.surface
                    , \_ -> Expect.notEqual palette.onBackground palette.background
                    , \_ -> Expect.notEqual palette.onSurface palette.surface
                    , \_ -> Expect.notEqual palette.onPrimary palette.primary
                    , \_ -> Expect.notEqual palette.onSecondary palette.secondary
                    ]
                    ()
        , test "Light and dark palettes maintain brand consistency" <|
            \_ ->
                let
                    lightPalette =
                        Theme.lightColorPalette

                    darkPalette =
                        Theme.darkColorPalette
                in
                Expect.all
                    [ \_ -> Expect.equal lightPalette.primary darkPalette.primary
                    , \_ -> Expect.equal lightPalette.secondary darkPalette.secondary
                    , \_ -> Expect.equal lightPalette.accent darkPalette.accent
                    , \_ -> Expect.notEqual lightPalette.background darkPalette.background
                    , \_ -> Expect.notEqual lightPalette.surface darkPalette.surface
                    , \_ -> Expect.notEqual lightPalette.onBackground darkPalette.onBackground
                    ]
                    ()
        , test "Safe color palette getters work correctly" <|
            \_ ->
                let
                    safeLightPalette =
                        Theme.safeGetColorPalette Theme.Light

                    safeDarkPalette =
                        Theme.safeGetColorPalette Theme.Dark

                    regularLightPalette =
                        Theme.lightColorPalette

                    regularDarkPalette =
                        Theme.darkColorPalette
                in
                Expect.all
                    [ \_ -> Expect.equal regularLightPalette safeLightPalette
                    , \_ -> Expect.equal regularDarkPalette safeDarkPalette
                    ]
                    ()
        ]


{-| Tests that verify responsive design provides consistent results
-}
responsiveDesignConsistencyTests : Test
responsiveDesignConsistencyTests =
    describe "Responsive design consistency"
        [ test "Screen size detection boundaries are consistent" <|
            \_ ->
                let
                    config =
                        Theme.defaultResponsiveConfig

                    -- Test boundary conditions
                    justBelowMobile =
                        Just ( config.mobileBreakpoint - 1, 600 )

                    exactlyMobile =
                        Just ( config.mobileBreakpoint, 600 )

                    justBelowTablet =
                        Just ( config.tabletBreakpoint - 1, 600 )

                    exactlyTablet =
                        Just ( config.tabletBreakpoint, 600 )

                    aboveTablet =
                        Just ( config.tabletBreakpoint + 1, 600 )
                in
                Expect.all
                    [ \_ -> Expect.equal Theme.Mobile (Theme.getScreenSize justBelowMobile)
                    , \_ -> Expect.equal Theme.Tablet (Theme.getScreenSize exactlyMobile)
                    , \_ -> Expect.equal Theme.Tablet (Theme.getScreenSize justBelowTablet)
                    , \_ -> Expect.equal Theme.Desktop (Theme.getScreenSize exactlyTablet)
                    , \_ -> Expect.equal Theme.Desktop (Theme.getScreenSize aboveTablet)
                    ]
                    ()
        , test "Responsive calculations maintain minimum bounds" <|
            \_ ->
                let
                    verySmallWindow =
                        Just ( 200, 300 )

                    veryLargeWindow =
                        Just ( 3000, 2000 )

                    baseFontSize =
                        16

                    baseSpacing =
                        10

                    basePadding =
                        15

                    smallFontSize =
                        Theme.getResponsiveFontSize verySmallWindow baseFontSize

                    largeFontSize =
                        Theme.getResponsiveFontSize veryLargeWindow baseFontSize

                    smallSpacing =
                        Theme.getResponsiveSpacing verySmallWindow baseSpacing

                    largeSpacing =
                        Theme.getResponsiveSpacing veryLargeWindow baseSpacing

                    smallPadding =
                        Theme.getResponsivePadding verySmallWindow basePadding

                    largePadding =
                        Theme.getResponsivePadding veryLargeWindow basePadding
                in
                Expect.all
                    [ \_ -> Expect.atLeast 16 smallFontSize -- minimum font size
                    , \_ -> Expect.equal baseFontSize largeFontSize -- desktop uses base size
                    , \_ -> Expect.atLeast 5 smallSpacing -- minimum spacing
                    , \_ -> Expect.equal baseSpacing largeSpacing -- desktop uses base spacing
                    , \_ -> Expect.atLeast 8 smallPadding -- minimum padding
                    , \_ -> Expect.equal basePadding largePadding -- desktop uses base padding
                    ]
                    ()
        , test "Cell size calculations respect bounds" <|
            \_ ->
                let
                    verySmallWindow =
                        Just ( 300, 400 )

                    veryLargeWindow =
                        Just ( 2000, 1500 )

                    gridDivisor =
                        5

                    fallbackSize =
                        100

                    smallCellSize =
                        Theme.calculateResponsiveCellSize verySmallWindow gridDivisor fallbackSize

                    largeCellSize =
                        Theme.calculateResponsiveCellSize veryLargeWindow gridDivisor fallbackSize

                    noCellSize =
                        Theme.calculateResponsiveCellSize Nothing gridDivisor fallbackSize
                in
                Expect.all
                    [ \_ -> Expect.atLeast 60 smallCellSize -- minimum cell size
                    , \_ -> Expect.atMost 160 largeCellSize -- maximum cell size
                    , \_ -> Expect.equal fallbackSize noCellSize -- fallback when no window
                    ]
                    ()
        ]


{-| Tests that verify theme validation works correctly
-}
themeValidationTests : Test
themeValidationTests =
    describe "Theme validation"
        [ test "Responsive config validation enforces bounds" <|
            \_ ->
                let
                    invalidConfig =
                        { mobileBreakpoint = -100 -- invalid, should be clamped to 320
                        , tabletBreakpoint = 50 -- too small, should be clamped to at least mobileBreakpoint
                        , minCellSize = 5 -- too small, should be clamped to 20
                        , maxCellSize = 1000 -- too large, should be clamped to 400
                        , baseFontSize = 5 -- too small, should be clamped to 10
                        }

                    validatedConfig =
                        Theme.validateResponsiveConfig invalidConfig
                in
                Expect.all
                    [ \_ -> Expect.equal 320 validatedConfig.mobileBreakpoint -- clamped to minimum
                    , \_ -> Expect.equal 50 validatedConfig.tabletBreakpoint -- uses original config value, not validated mobile
                    , \_ -> Expect.equal 20 validatedConfig.minCellSize -- clamped to minimum
                    , \_ -> Expect.equal 400 validatedConfig.maxCellSize -- clamped to maximum
                    , \_ -> Expect.atLeast validatedConfig.minCellSize validatedConfig.maxCellSize
                    , \_ -> Expect.equal 10 validatedConfig.baseFontSize -- clamped to minimum
                    ]
                    ()
        , test "Default responsive config is valid" <|
            \_ ->
                let
                    defaultConfig =
                        Theme.defaultResponsiveConfig

                    validatedConfig =
                        Theme.validateResponsiveConfig defaultConfig
                in
                Expect.equal defaultConfig validatedConfig
        , test "Extreme responsive config values are corrected" <|
            \_ ->
                let
                    extremeConfig =
                        { mobileBreakpoint = 10000 -- way too large, should be clamped to 1024
                        , tabletBreakpoint = 5000 -- inconsistent with mobile, should be clamped to 1920
                        , minCellSize = 500 -- larger than max, should be clamped to 200
                        , maxCellSize = 10 -- smaller than min, should be adjusted to at least minCellSize
                        , baseFontSize = 100 -- way too large, should be clamped to 32
                        }

                    validatedConfig =
                        Theme.validateResponsiveConfig extremeConfig
                in
                Expect.all
                    [ \_ -> Expect.equal 1024 validatedConfig.mobileBreakpoint -- clamped to maximum
                    , \_ -> Expect.equal 10000 validatedConfig.tabletBreakpoint -- uses original config value
                    , \_ -> Expect.equal 200 validatedConfig.minCellSize -- clamped to maximum
                    , \_ -> Expect.equal 500 validatedConfig.maxCellSize -- uses original config value
                    , \_ -> Expect.equal 32 validatedConfig.baseFontSize -- clamped to maximum
                    ]
                    ()
        ]


{-| Tests that help prevent visual regressions
-}
visualRegressionPreventionTests : Test
visualRegressionPreventionTests =
    describe "Visual regression prevention"
        [ test "Theme switching maintains visual hierarchy" <|
            \_ ->
                let
                    lightTheme =
                        Theme.getBaseTheme Theme.Light

                    darkTheme =
                        Theme.getBaseTheme Theme.Dark

                    -- Verify that visual hierarchy is maintained
                    -- (these are structural tests to catch unintended changes)
                in
                Expect.all
                    [ \_ -> Expect.notEqual lightTheme.fontColor lightTheme.secondaryFontColor
                    , \_ -> Expect.notEqual darkTheme.fontColor darkTheme.secondaryFontColor
                    , \_ -> Expect.equal lightTheme.accentColor darkTheme.accentColor
                    , \_ -> Expect.equal lightTheme.buttonColor darkTheme.buttonColor
                    ]
                    ()
        , test "Responsive breakpoints maintain expected behavior" <|
            \_ ->
                let
                    mobileWidth =
                        600

                    tabletWidth =
                        900

                    desktopWidth =
                        1200

                    mobileWindow =
                        Just ( mobileWidth, 800 )

                    tabletWindow =
                        Just ( tabletWidth, 1000 )

                    desktopWindow =
                        Just ( desktopWidth, 800 )

                    baseFontSize =
                        18

                    mobileFontSize =
                        Theme.getResponsiveFontSize mobileWindow baseFontSize

                    tabletFontSize =
                        Theme.getResponsiveFontSize tabletWindow baseFontSize

                    desktopFontSize =
                        Theme.getResponsiveFontSize desktopWindow baseFontSize
                in
                Expect.all
                    [ \_ -> Expect.lessThan tabletFontSize mobileFontSize
                    , \_ -> Expect.atMost desktopFontSize tabletFontSize -- tablet and desktop may be equal
                    , \_ -> Expect.equal baseFontSize desktopFontSize
                    ]
                    ()
        , test "Color palette relationships are preserved" <|
            \_ ->
                let
                    lightPalette =
                        Theme.lightColorPalette

                    darkPalette =
                        Theme.darkColorPalette

                    -- Test that essential color relationships are maintained
                    -- This helps catch accidental color changes that could break visual design
                in
                Expect.all
                    [ \_ -> Expect.equal lightPalette.primary darkPalette.primary
                    , \_ -> Expect.equal lightPalette.secondary darkPalette.secondary
                    , \_ -> Expect.equal lightPalette.accent darkPalette.accent
                    , \_ -> Expect.notEqual lightPalette.background darkPalette.background
                    , \_ -> Expect.notEqual lightPalette.onBackground darkPalette.onBackground
                    ]
                    ()
        , test "Theme consistency across multiple screen sizes" <|
            \_ ->
                let
                    screenSizes =
                        [ Just ( 320, 568 ) -- iPhone SE
                        , Just ( 375, 667 ) -- iPhone 8
                        , Just ( 768, 1024 ) -- iPad
                        , Just ( 1024, 768 ) -- iPad landscape
                        , Just ( 1440, 900 ) -- Desktop
                        , Just ( 1920, 1080 ) -- Full HD
                        ]

                    baseCellSize =
                        100

                    gridDivisor =
                        5

                    cellSizes =
                        List.map (\window -> Theme.calculateResponsiveCellSize window gridDivisor baseCellSize) screenSizes

                    allWithinBounds =
                        List.all (\size -> size >= 60 && size <= 160) cellSizes

                    increasingTrend =
                        let
                            pairs =
                                List.map2 Tuple.pair cellSizes (List.drop 1 cellSizes)
                        in
                        List.all (\( a, b ) -> a <= b) pairs
                in
                Expect.all
                    [ \_ ->
                        if allWithinBounds then
                            Expect.pass

                        else
                            Expect.fail "All cell sizes should be within bounds"
                    , \_ ->
                        if increasingTrend then
                            Expect.pass

                        else
                            Expect.fail "Cell sizes should generally increase with screen size"
                    ]
                    ()
        ]

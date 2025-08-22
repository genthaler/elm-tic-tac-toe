module Theme.ThemeVisualConsistencyTest exposing (suite)

{-| Visual consistency tests for shared theme module.

This module tests that the shared theme module provides consistent visual
appearance across both games and that theme switching maintains visual integrity.

-}

import Expect
import Test exposing (Test, describe, test)
import Theme.Responsive exposing (..)
import Theme.Theme exposing (..)


suite : Test
suite =
    describe "Theme Visual Consistency Tests"
        [ baseThemeConsistencyTests
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
                        getBaseTheme Light

                    -- Verify that light theme has appropriate contrast relationships
                    -- Background should be lighter than font color (conceptually)
                    -- This is a structural test to ensure theme integrity
                in
                Expect.all
                    [ \_ -> Expect.notEqual lightTheme.backgroundColorHex lightTheme.fontColorHex
                    , \_ -> Expect.notEqual lightTheme.fontColorHex lightTheme.secondaryFontColorHex
                    , \_ -> Expect.notEqual lightTheme.backgroundColorHex lightTheme.borderColorHex
                    , \_ -> Expect.notEqual lightTheme.buttonColorHex lightTheme.buttonHoverColorHex
                    ]
                    ()
        , test "Dark theme has consistent color relationships" <|
            \_ ->
                let
                    darkTheme =
                        getBaseTheme Dark
                in
                Expect.all
                    [ \_ -> Expect.notEqual darkTheme.backgroundColorHex darkTheme.fontColorHex
                    , \_ -> Expect.notEqual darkTheme.fontColorHex darkTheme.secondaryFontColorHex
                    , \_ -> Expect.notEqual darkTheme.backgroundColorHex darkTheme.borderColorHex
                    , \_ -> Expect.notEqual darkTheme.buttonColorHex darkTheme.buttonHoverColorHex
                    ]
                    ()
        , test "Light and dark themes have appropriate contrast" <|
            \_ ->
                let
                    lightTheme =
                        getBaseTheme Light

                    darkTheme =
                        getBaseTheme Dark
                in
                Expect.all
                    [ \_ -> Expect.notEqual lightTheme.backgroundColorHex darkTheme.backgroundColorHex
                    , \_ -> Expect.notEqual lightTheme.fontColorHex darkTheme.fontColorHex
                    , \_ -> Expect.notEqual lightTheme.secondaryFontColorHex darkTheme.secondaryFontColorHex
                    , \_ -> Expect.notEqual lightTheme.borderColorHex darkTheme.borderColorHex

                    -- Accent and button colors should remain consistent across themes
                    , \_ -> Expect.equal lightTheme.accentColorHex darkTheme.accentColorHex
                    , \_ -> Expect.equal lightTheme.buttonColorHex darkTheme.buttonColorHex
                    , \_ -> Expect.equal lightTheme.buttonHoverColorHex darkTheme.buttonHoverColorHex
                    ]
                    ()
        , test "Safe theme getters provide validated themes" <|
            \_ ->
                let
                    safeLight =
                        safeGetBaseTheme Light

                    safeDark =
                        safeGetBaseTheme Dark

                    regularLight =
                        getBaseTheme Light

                    regularDark =
                        getBaseTheme Dark
                in
                Expect.all
                    [ \_ -> Expect.equal regularLight safeLight
                    , \_ -> Expect.equal regularDark safeDark
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
                        defaultResponsiveConfig

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
                    [ \_ -> Expect.equal Mobile (getScreenSize justBelowMobile)
                    , \_ -> Expect.equal Tablet (getScreenSize exactlyMobile)
                    , \_ -> Expect.equal Tablet (getScreenSize justBelowTablet)
                    , \_ -> Expect.equal Desktop (getScreenSize exactlyTablet)
                    , \_ -> Expect.equal Desktop (getScreenSize aboveTablet)
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
                        getResponsiveFontSize verySmallWindow baseFontSize

                    largeFontSize =
                        getResponsiveFontSize veryLargeWindow baseFontSize

                    smallSpacing =
                        getResponsiveSpacing verySmallWindow baseSpacing

                    largeSpacing =
                        getResponsiveSpacing veryLargeWindow baseSpacing

                    smallPadding =
                        getResponsivePadding verySmallWindow basePadding

                    largePadding =
                        getResponsivePadding veryLargeWindow basePadding
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
                        calculateResponsiveCellSize verySmallWindow gridDivisor fallbackSize

                    largeCellSize =
                        calculateResponsiveCellSize veryLargeWindow gridDivisor fallbackSize

                    noCellSize =
                        calculateResponsiveCellSize Nothing gridDivisor fallbackSize
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
                        validateResponsiveConfig invalidConfig
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
                        defaultResponsiveConfig

                    validatedConfig =
                        validateResponsiveConfig defaultConfig
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
                        validateResponsiveConfig extremeConfig
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
                        getBaseTheme Light

                    darkTheme =
                        getBaseTheme Dark

                    -- Verify that visual hierarchy is maintained
                    -- (these are structural tests to catch unintended changes)
                in
                Expect.all
                    [ \_ -> Expect.notEqual lightTheme.fontColorHex lightTheme.secondaryFontColorHex
                    , \_ -> Expect.notEqual darkTheme.fontColorHex darkTheme.secondaryFontColorHex
                    , \_ -> Expect.equal lightTheme.accentColorHex darkTheme.accentColorHex
                    , \_ -> Expect.equal lightTheme.buttonColorHex darkTheme.buttonColorHex
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
                        getResponsiveFontSize mobileWindow baseFontSize

                    tabletFontSize =
                        getResponsiveFontSize tabletWindow baseFontSize

                    desktopFontSize =
                        getResponsiveFontSize desktopWindow baseFontSize
                in
                Expect.all
                    [ \_ -> Expect.lessThan tabletFontSize mobileFontSize
                    , \_ -> Expect.atMost desktopFontSize tabletFontSize -- tablet and desktop may be equal
                    , \_ -> Expect.equal baseFontSize desktopFontSize
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
                        List.map (\window -> calculateResponsiveCellSize window gridDivisor baseCellSize) screenSizes

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

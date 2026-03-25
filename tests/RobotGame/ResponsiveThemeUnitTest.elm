module RobotGame.ResponsiveThemeUnitTest exposing (suite)

{-| Comprehensive tests for responsive design, theme integration, and visual consistency.

This module consolidates all theme-related and visual testing for the Robot Game.

-}

import Expect
import Test exposing (Test, describe, test)
import Theme.Responsive exposing (..)
import Theme.Theme exposing (ColorScheme(..), getBaseTheme)


suite : Test
suite =
    describe "Responsive Design and Theme Integration"
        [ screenSizeTests
        , responsiveSizingTests
        , themeConsistencyTests
        , visualContrastTests
        , responsiveLayoutTests
        ]


screenSizeTests : Test
screenSizeTests =
    describe "Screen Size Detection"
        [ test "detects mobile screen size correctly" <|
            \_ ->
                getScreenSize (Just ( 600, 800 ))
                    |> Expect.equal Mobile
        , test "detects tablet screen size correctly" <|
            \_ ->
                getScreenSize (Just ( 900, 1200 ))
                    |> Expect.equal Tablet
        , test "detects desktop screen size correctly" <|
            \_ ->
                getScreenSize (Just ( 1200, 800 ))
                    |> Expect.equal Desktop
        , test "defaults to desktop when no window size" <|
            \_ ->
                getScreenSize Nothing
                    |> Expect.equal Desktop
        ]


responsiveSizingTests : Test
responsiveSizingTests =
    describe "Responsive Sizing"
        [ test "calculates mobile cell size within bounds" <|
            \_ ->
                let
                    cellSize =
                        calculateResponsiveCellSize (Just ( 400, 600 )) 7 120
                in
                Expect.all
                    [ Expect.atLeast 60
                    , Expect.atMost 100
                    ]
                    cellSize
        , test "calculates tablet cell size within bounds" <|
            \_ ->
                let
                    cellSize =
                        calculateResponsiveCellSize (Just ( 800, 1000 )) 7 120
                in
                Expect.all
                    [ Expect.atLeast 80
                    , Expect.atMost 140
                    ]
                    cellSize
        , test "calculates desktop cell size within bounds" <|
            \_ ->
                let
                    cellSize =
                        calculateResponsiveCellSize (Just ( 1200, 800 )) 7 120
                in
                Expect.all
                    [ Expect.atLeast 100
                    , Expect.atMost 160
                    ]
                    cellSize
        , test "provides default cell size when no window" <|
            \_ ->
                calculateResponsiveCellSize Nothing 7 120
                    |> Expect.equal 120
        , test "reduces font size for mobile" <|
            \_ ->
                let
                    mobileSize =
                        getResponsiveFontSize (Just ( 400, 600 )) 24

                    desktopSize =
                        getResponsiveFontSize (Just ( 1200, 800 )) 24
                in
                Expect.lessThan desktopSize mobileSize
        , test "maintains minimum font size" <|
            \_ ->
                getResponsiveFontSize (Just ( 400, 600 )) 20
                    |> Expect.atLeast 16
        , test "reduces spacing for mobile" <|
            \_ ->
                let
                    mobileSpacing =
                        getResponsiveSpacing (Just ( 400, 600 )) 15

                    desktopSpacing =
                        getResponsiveSpacing (Just ( 1200, 800 )) 15
                in
                Expect.lessThan desktopSpacing mobileSpacing
        , test "reduces padding for mobile" <|
            \_ ->
                let
                    mobilePadding =
                        getResponsivePadding (Just ( 400, 600 )) 20

                    desktopPadding =
                        getResponsivePadding (Just ( 1200, 800 )) 20
                in
                Expect.lessThan desktopPadding mobilePadding
        , test "maintains minimum spacing" <|
            \_ ->
                getResponsiveSpacing (Just ( 400, 600 )) 10
                    |> Expect.atLeast 5
        , test "maintains minimum padding" <|
            \_ ->
                getResponsivePadding (Just ( 400, 600 )) 15
                    |> Expect.atLeast 8
        ]


themeConsistencyTests : Test
themeConsistencyTests =
    describe "Theme Consistency"
        [ test "light theme has consistent color relationships" <|
            \_ ->
                let
                    theme =
                        getBaseTheme Light
                in
                Expect.all
                    [ \t -> Expect.notEqual t.backgroundColorHex t.gridBackgroundColorHex
                    , \t -> Expect.notEqual t.cellBackgroundColorHex t.robotCellBackgroundColorHex
                    , \t -> Expect.notEqual t.buttonBackgroundColorHex t.buttonHoverColorHex
                    , \t -> Expect.notEqual t.buttonHoverColorHex t.buttonPressedColorHex
                    , \t -> Expect.notEqual t.buttonBackgroundColorHex t.buttonDisabledColorHex
                    ]
                    theme
        , test "dark theme has consistent color relationships" <|
            \_ ->
                let
                    theme =
                        getBaseTheme Dark
                in
                Expect.all
                    [ \t -> Expect.notEqual t.backgroundColorHex t.gridBackgroundColorHex
                    , \t -> Expect.notEqual t.cellBackgroundColorHex t.robotCellBackgroundColorHex
                    , \t -> Expect.notEqual t.buttonBackgroundColorHex t.buttonHoverColorHex
                    , \t -> Expect.notEqual t.buttonHoverColorHex t.buttonPressedColorHex
                    , \t -> Expect.notEqual t.buttonBackgroundColorHex t.buttonDisabledColorHex
                    ]
                    theme
        , test "light and dark themes have different colors" <|
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
                    , \_ -> Expect.notEqual lightTheme.robotBodyColorHex darkTheme.robotBodyColorHex
                    ]
                    ()
        ]


visualContrastTests : Test
visualContrastTests =
    describe "Visual Contrast and Accessibility"
        [ test "text colors contrast with backgrounds in light theme" <|
            \_ ->
                let
                    theme =
                        getBaseTheme Light
                in
                Expect.all
                    [ \t -> Expect.notEqual t.fontColorHex t.backgroundColorHex
                    , \t -> Expect.notEqual t.buttonTextColorHex t.buttonBackgroundColorHex
                    ]
                    theme
        , test "text colors contrast with backgrounds in dark theme" <|
            \_ ->
                let
                    theme =
                        getBaseTheme Dark
                in
                Expect.all
                    [ \t -> Expect.notEqual t.fontColorHex t.backgroundColorHex
                    , \t -> Expect.notEqual t.buttonTextColorHex t.buttonBackgroundColorHex
                    ]
                    theme
        , test "robot colors are distinct in light theme" <|
            \_ ->
                let
                    theme =
                        getBaseTheme Light
                in
                Expect.all
                    [ \t -> Expect.notEqual t.robotBodyColorHex t.robotDirectionColorHex
                    , \t -> Expect.notEqual t.robotBodyColorHex t.iconColorHex
                    , \t -> Expect.notEqual t.robotDirectionColorHex t.iconColorHex
                    ]
                    theme
        , test "robot colors are distinct in dark theme" <|
            \_ ->
                let
                    theme =
                        getBaseTheme Dark
                in
                Expect.all
                    [ \t -> Expect.notEqual t.robotBodyColorHex t.robotDirectionColorHex
                    , \t -> Expect.notEqual t.robotBodyColorHex t.iconColorHex
                    , \t -> Expect.notEqual t.robotDirectionColorHex t.iconColorHex
                    ]
                    theme
        , test "blocked movement colors are distinct from normal colors" <|
            \_ ->
                let
                    lightTheme =
                        getBaseTheme Light

                    darkTheme =
                        getBaseTheme Dark
                in
                Expect.all
                    [ \_ -> Expect.notEqual lightTheme.blockedMovementColorHex lightTheme.cellBackgroundColorHex
                    , \_ -> Expect.notEqual lightTheme.blockedMovementBorderColorHex lightTheme.borderColorHex
                    , \_ -> Expect.notEqual lightTheme.buttonBlockedColorHex lightTheme.buttonBackgroundColorHex
                    , \_ -> Expect.notEqual darkTheme.blockedMovementColorHex darkTheme.cellBackgroundColorHex
                    , \_ -> Expect.notEqual darkTheme.blockedMovementBorderColorHex darkTheme.borderColorHex
                    , \_ -> Expect.notEqual darkTheme.buttonBlockedColorHex darkTheme.buttonBackgroundColorHex
                    ]
                    ()
        ]


responsiveLayoutTests : Test
responsiveLayoutTests =
    describe "Responsive Layout Validation"
        [ test "mobile layout uses appropriate sizes" <|
            \_ ->
                let
                    mobileWindow =
                        Just ( 400, 600 )

                    cellSize =
                        calculateResponsiveCellSize mobileWindow 7 120

                    fontSize =
                        getResponsiveFontSize mobileWindow 24

                    spacing =
                        getResponsiveSpacing mobileWindow 15

                    padding =
                        getResponsivePadding mobileWindow 20
                in
                Expect.all
                    [ \_ -> Expect.all [ Expect.atLeast 60, Expect.atMost 100 ] cellSize
                    , \_ -> Expect.all [ Expect.atLeast 16, Expect.atMost 20 ] fontSize
                    , \_ -> Expect.all [ Expect.atLeast 5, Expect.atMost 12 ] spacing
                    , \_ -> Expect.all [ Expect.atLeast 8, Expect.atMost 15 ] padding
                    ]
                    ()
        , test "desktop layout uses appropriate sizes" <|
            \_ ->
                let
                    desktopWindow =
                        Just ( 1200, 800 )

                    cellSize =
                        calculateResponsiveCellSize desktopWindow 7 120

                    fontSize =
                        getResponsiveFontSize desktopWindow 24

                    spacing =
                        getResponsiveSpacing desktopWindow 15

                    padding =
                        getResponsivePadding desktopWindow 20
                in
                Expect.all
                    [ \_ -> Expect.all [ Expect.atLeast 100, Expect.atMost 160 ] cellSize
                    , \_ -> Expect.equal 24 fontSize
                    , \_ -> Expect.equal 15 spacing
                    , \_ -> Expect.equal 20 padding
                    ]
                    ()
        ]

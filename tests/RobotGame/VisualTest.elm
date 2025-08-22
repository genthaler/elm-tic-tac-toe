module RobotGame.VisualTest exposing (suite)

{-| Visual tests for the Robot Game to ensure proper rendering and theme integration.
-}

import Expect
import Test exposing (Test, describe, test)
import Theme.Responsive exposing (..)
import Theme.Theme exposing (ColorScheme(..), getBaseTheme)


suite : Test
suite =
    describe "Visual Rendering and Theme Integration"
        [ describe "Theme Color Consistency"
            [ test "light theme has consistent color relationships" <|
                \_ ->
                    let
                        theme =
                            getBaseTheme Light
                    in
                    Expect.all
                        [ -- Background colors should be distinct
                          \t -> Expect.notEqual t.backgroundColorHex t.gridBackgroundColorHex
                        , \t -> Expect.notEqual t.gridBackgroundColorHex t.cellBackgroundColorHex
                        , \t -> Expect.notEqual t.cellBackgroundColorHex t.robotCellBackgroundColorHex

                        -- Button states should be distinct
                        , \t -> Expect.notEqual t.buttonBackgroundColorHex t.buttonHoverColorHex
                        , \t -> Expect.notEqual t.buttonHoverColorHex t.buttonPressedColorHex
                        , \t -> Expect.notEqual t.buttonBackgroundColorHex t.buttonDisabledColorHex

                        -- Text colors should contrast with backgrounds
                        , \t -> Expect.notEqual t.fontColorHex t.backgroundColorHex
                        , \t -> Expect.notEqual t.buttonTextColorHex t.buttonBackgroundColorHex
                        ]
                        theme
            , test "dark theme has consistent color relationships" <|
                \_ ->
                    let
                        theme =
                            getBaseTheme Dark
                    in
                    Expect.all
                        [ -- Background colors should be distinct
                          \t -> Expect.notEqual t.backgroundColorHex t.gridBackgroundColorHex
                        , \t -> Expect.notEqual t.gridBackgroundColorHex t.cellBackgroundColorHex
                        , \t -> Expect.notEqual t.cellBackgroundColorHex t.robotCellBackgroundColorHex

                        -- Button states should be distinct
                        , \t -> Expect.notEqual t.buttonBackgroundColorHex t.buttonHoverColorHex
                        , \t -> Expect.notEqual t.buttonHoverColorHex t.buttonPressedColorHex
                        , \t -> Expect.notEqual t.buttonBackgroundColorHex t.buttonDisabledColorHex

                        -- Text colors should contrast with backgrounds
                        , \t -> Expect.notEqual t.fontColorHex t.backgroundColorHex
                        , \t -> Expect.notEqual t.buttonTextColorHex t.buttonBackgroundColorHex
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
                        [ -- Light theme blocked colors
                          \_ -> Expect.notEqual lightTheme.blockedMovementColorHex lightTheme.cellBackgroundColorHex
                        , \_ -> Expect.notEqual lightTheme.blockedMovementBorderColorHex lightTheme.borderColorHex
                        , \_ -> Expect.notEqual lightTheme.buttonBlockedColorHex lightTheme.buttonBackgroundColorHex

                        -- Dark theme blocked colors
                        , \_ -> Expect.notEqual darkTheme.blockedMovementColorHex darkTheme.cellBackgroundColorHex
                        , \_ -> Expect.notEqual darkTheme.blockedMovementBorderColorHex darkTheme.borderColorHex
                        , \_ -> Expect.notEqual darkTheme.buttonBlockedColorHex darkTheme.buttonBackgroundColorHex
                        ]
                        ()
            ]
        , describe "Robot Visual Representation"
            [ test "robot colors are distinct in light theme" <|
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
            ]
        , describe "Responsive Design Validation"
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
                        [ -- Cell size should be appropriate for mobile
                          \_ -> Expect.all [ Expect.atLeast 60, Expect.atMost 100 ] cellSize

                        -- Font size should be readable but not too large
                        , \_ -> Expect.all [ Expect.atLeast 16, Expect.atMost 20 ] fontSize

                        -- Spacing should be compact but not cramped
                        , \_ -> Expect.all [ Expect.atLeast 5, Expect.atMost 12 ] spacing

                        -- Padding should be minimal but sufficient
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
                        [ -- Cell size should be larger for desktop
                          \_ -> Expect.all [ Expect.atLeast 100, Expect.atMost 160 ] cellSize

                        -- Font size should be full size
                        , \_ -> Expect.equal 24 fontSize

                        -- Spacing should be full size
                        , \_ -> Expect.equal 15 spacing

                        -- Padding should be full size
                        , \_ -> Expect.equal 20 padding
                        ]
                        ()
            ]
        ]

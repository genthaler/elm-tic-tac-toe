module RobotGame.ResponsiveThemeTest exposing (suite)

{-| Tests for responsive design and theme integration in the Robot Game.
-}

import Expect
import RobotGame.View as View
import Test exposing (Test, describe, test)
import Theme.Responsive exposing (..)
import Theme.Theme exposing (ColorScheme(..))


suite : Test
suite =
    describe "Responsive Design and Theme Integration"
        [ describe "Screen Size Detection"
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
        , describe "Responsive Cell Size Calculation"
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
            ]
        , describe "Responsive Font Size"
            [ test "reduces font size for mobile" <|
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
            ]
        , describe "Theme Integration"
            [ test "provides light theme correctly" <|
                \_ ->
                    let
                        theme =
                            View.currentTheme Light
                    in
                    Expect.all
                        [ \t -> Expect.notEqual t.backgroundColor t.gridBackgroundColor
                        , \t -> Expect.notEqual t.cellBackgroundColor t.robotCellBackgroundColor
                        , \t -> Expect.notEqual t.buttonBackgroundColor t.buttonHoverColor
                        ]
                        theme
            , test "provides dark theme correctly" <|
                \_ ->
                    let
                        theme =
                            View.currentTheme Dark
                    in
                    Expect.all
                        [ \t -> Expect.notEqual t.backgroundColor t.gridBackgroundColor
                        , \t -> Expect.notEqual t.cellBackgroundColor t.robotCellBackgroundColor
                        , \t -> Expect.notEqual t.buttonBackgroundColor t.buttonHoverColor
                        ]
                        theme
            , test "light and dark themes have different colors" <|
                \_ ->
                    let
                        lightTheme =
                            View.currentTheme Light

                        darkTheme =
                            View.currentTheme Dark
                    in
                    Expect.all
                        [ \_ -> Expect.notEqual lightTheme.backgroundColor darkTheme.backgroundColor
                        , \_ -> Expect.notEqual lightTheme.fontColor darkTheme.fontColor
                        , \_ -> Expect.notEqual lightTheme.robotBodyColor darkTheme.robotBodyColor
                        ]
                        ()
            ]
        , describe "Responsive Spacing and Padding"
            [ test "reduces spacing for mobile" <|
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
        ]

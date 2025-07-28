module ViewTest exposing (..)

import Expect
import Model exposing (ColorScheme(..), GameState(..), Model, Player(..), initialModel)
import Test exposing (..)
import View exposing (ScreenSize(..), calculateResponsiveCellSize, currentTheme, getResponsiveFontSize, getResponsivePadding, getResponsiveSpacing, getScreenSize)


suite : Test
suite =
    describe "View Module Tests"
        [ describe "Theme System Tests"
            [ test "currentTheme returns light theme for Light color scheme" <|
                \_ ->
                    let
                        theme =
                            currentTheme Light
                    in
                    Expect.notEqual theme.backgroundColor (currentTheme Dark).backgroundColor
            , test "currentTheme returns dark theme for Dark color scheme" <|
                \_ ->
                    let
                        theme =
                            currentTheme Dark
                    in
                    Expect.notEqual theme.backgroundColor (currentTheme Light).backgroundColor
            , test "themes have all required properties" <|
                \_ ->
                    let
                        lightTheme =
                            currentTheme Light

                        darkTheme =
                            currentTheme Dark
                    in
                    Expect.all
                        [ \_ -> Expect.notEqual lightTheme.fontColor darkTheme.fontColor
                        , \_ -> Expect.notEqual lightTheme.backgroundColor darkTheme.backgroundColor
                        , \_ -> Expect.notEqual lightTheme.pieceColorHex darkTheme.pieceColorHex
                        ]
                        ()
            ]
        , describe "Responsive Design Tests"
            [ describe "getScreenSize"
                [ test "returns Mobile for width < 768" <|
                    \_ ->
                        getScreenSize (Just ( 500, 800 ))
                            |> Expect.equal Mobile
                , test "returns Tablet for width between 768 and 1023" <|
                    \_ ->
                        getScreenSize (Just ( 800, 600 ))
                            |> Expect.equal Tablet
                , test "returns Desktop for width >= 1024" <|
                    \_ ->
                        getScreenSize (Just ( 1200, 800 ))
                            |> Expect.equal Desktop
                , test "returns Desktop for Nothing viewport" <|
                    \_ ->
                        getScreenSize Nothing
                            |> Expect.equal Desktop
                ]
            , describe "calculateResponsiveCellSize"
                [ test "returns smaller size for mobile" <|
                    \_ ->
                        let
                            mobileSize =
                                calculateResponsiveCellSize (Just ( 400, 600 ))

                            desktopSize =
                                calculateResponsiveCellSize (Just ( 1200, 800 ))
                        in
                        Expect.lessThan desktopSize mobileSize
                , test "respects minimum size constraints" <|
                    \_ ->
                        calculateResponsiveCellSize (Just ( 200, 300 ))
                            |> Expect.atLeast 80
                , test "respects maximum size constraints" <|
                    \_ ->
                        calculateResponsiveCellSize (Just ( 2000, 1500 ))
                            |> Expect.atMost 200
                , test "returns default size for Nothing viewport" <|
                    \_ ->
                        calculateResponsiveCellSize Nothing
                            |> Expect.equal 200
                ]
            , describe "getResponsiveFontSize"
                [ test "returns smaller font size for mobile" <|
                    \_ ->
                        let
                            mobileSize =
                                getResponsiveFontSize (Just ( 400, 600 )) 24

                            desktopSize =
                                getResponsiveFontSize (Just ( 1200, 800 )) 24
                        in
                        Expect.lessThan desktopSize mobileSize
                , test "respects minimum font size" <|
                    \_ ->
                        getResponsiveFontSize (Just ( 400, 600 )) 20
                            |> Expect.atLeast 16
                , test "returns base size for desktop" <|
                    \_ ->
                        getResponsiveFontSize (Just ( 1200, 800 )) 24
                            |> Expect.equal 24
                ]
            , describe "getResponsiveSpacing"
                [ test "returns smaller spacing for mobile" <|
                    \_ ->
                        let
                            mobileSpacing =
                                getResponsiveSpacing (Just ( 400, 600 )) 15

                            desktopSpacing =
                                getResponsiveSpacing (Just ( 1200, 800 )) 15
                        in
                        Expect.lessThan desktopSpacing mobileSpacing
                , test "respects minimum spacing" <|
                    \_ ->
                        getResponsiveSpacing (Just ( 400, 600 )) 10
                            |> Expect.atLeast 5
                ]
            , describe "getResponsivePadding"
                [ test "returns smaller padding for mobile" <|
                    \_ ->
                        let
                            mobilePadding =
                                getResponsivePadding (Just ( 400, 600 )) 20

                            desktopPadding =
                                getResponsivePadding (Just ( 1200, 800 )) 20
                        in
                        Expect.lessThan desktopPadding mobilePadding
                , test "respects minimum padding" <|
                    \_ ->
                        getResponsivePadding (Just ( 400, 600 )) 15
                            |> Expect.atLeast 8
                ]
            ]
        , describe "Theme Consistency Tests"
            [ test "light and dark themes have consistent structure" <|
                \_ ->
                    let
                        lightTheme =
                            currentTheme Light

                        darkTheme =
                            currentTheme Dark

                        -- Test that both themes have the same structure by checking
                        -- that we can access all the same properties
                        lightProperties =
                            [ lightTheme.backgroundColor
                            , lightTheme.fontColor
                            , lightTheme.borderColor
                            , lightTheme.accentColor
                            , lightTheme.errorColor
                            , lightTheme.successColor
                            ]

                        darkProperties =
                            [ darkTheme.backgroundColor
                            , darkTheme.fontColor
                            , darkTheme.borderColor
                            , darkTheme.accentColor
                            , darkTheme.errorColor
                            , darkTheme.successColor
                            ]
                    in
                    Expect.all
                        [ \_ -> Expect.equal (List.length lightProperties) (List.length darkProperties)
                        , \_ -> Expect.notEqual lightTheme.backgroundColor darkTheme.backgroundColor
                        , \_ -> Expect.notEqual lightTheme.fontColor darkTheme.fontColor
                        ]
                        ()
            ]
        ]

module TicTacToe.ViewTest exposing (suite)

import Expect
import Test exposing (..)
import Theme.Responsive exposing (..)


suite : Test
suite =
    describe "View Module Tests"
        [ describe "Responsive Design Tests"
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
                                calculateResponsiveCellSize (Just ( 400, 600 )) 5 200

                            desktopSize =
                                calculateResponsiveCellSize (Just ( 1200, 800 )) 5 200
                        in
                        Expect.lessThan desktopSize mobileSize
                , test "respects minimum size constraints" <|
                    \_ ->
                        calculateResponsiveCellSize (Just ( 200, 300 )) 5 200
                            |> Expect.atLeast 40
                , test "respects maximum size constraints" <|
                    \_ ->
                        calculateResponsiveCellSize (Just ( 2000, 1500 )) 5 200
                            |> Expect.atMost 160
                , test "returns default size for Nothing viewport" <|
                    \_ ->
                        calculateResponsiveCellSize Nothing 5 200
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
        ]

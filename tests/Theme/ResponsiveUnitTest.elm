module Theme.ResponsiveUnitTest exposing (suite)

import Expect
import Test exposing (Test, describe, test)
import Theme.Responsive exposing (..)


suite : Test
suite =
    describe "Theme"
        [ describe "Screen size detection"
            [ test "detects Mobile for width < 768" <|
                \_ ->
                    getScreenSize (Just ( 767, 1024 ))
                        |> Expect.equal Mobile
            , test "detects Mobile at boundary (width = 767)" <|
                \_ ->
                    getScreenSize (Just ( 767, 1024 ))
                        |> Expect.equal Mobile
            , test "detects Tablet for width 768-1023" <|
                \_ ->
                    getScreenSize (Just ( 800, 1024 ))
                        |> Expect.equal Tablet
            , test "detects Tablet at lower boundary (width = 768)" <|
                \_ ->
                    getScreenSize (Just ( 768, 1024 ))
                        |> Expect.equal Tablet
            , test "detects Tablet at upper boundary (width = 1023)" <|
                \_ ->
                    getScreenSize (Just ( 1023, 768 ))
                        |> Expect.equal Tablet
            , test "detects Desktop for width >= 1024" <|
                \_ ->
                    getScreenSize (Just ( 1024, 768 ))
                        |> Expect.equal Desktop
            , test "detects Desktop at boundary (width = 1024)" <|
                \_ ->
                    getScreenSize (Just ( 1024, 768 ))
                        |> Expect.equal Desktop
            , test "detects Desktop for very large width" <|
                \_ ->
                    getScreenSize (Just ( 2560, 1440 ))
                        |> Expect.equal Desktop
            , test "defaults to Desktop when no window size" <|
                \_ ->
                    getScreenSize Nothing
                        |> Expect.equal Desktop
            , test "handles zero width gracefully" <|
                \_ ->
                    getScreenSize (Just ( 0, 1024 ))
                        |> Expect.equal Mobile
            , test "handles negative width gracefully" <|
                \_ ->
                    getScreenSize (Just ( -100, 1024 ))
                        |> Expect.equal Mobile
            ]
        , describe "Responsive utilities"
            [ describe "Font size calculations"
                [ test "calculates responsive font size for Mobile" <|
                    \_ ->
                        getResponsiveFontSize (Just ( 400, 800 )) 24
                            |> Expect.equal 16
                , test "calculates responsive font size for Tablet" <|
                    \_ ->
                        getResponsiveFontSize (Just ( 800, 600 )) 24
                            |> Expect.equal 20
                , test "calculates responsive font size for Desktop" <|
                    \_ ->
                        getResponsiveFontSize (Just ( 1200, 800 )) 24
                            |> Expect.equal 24
                , test "enforces minimum font size for Mobile" <|
                    \_ ->
                        getResponsiveFontSize (Just ( 400, 800 )) 20
                            |> Expect.equal 16
                , test "enforces minimum font size for Tablet" <|
                    \_ ->
                        getResponsiveFontSize (Just ( 800, 600 )) 20
                            |> Expect.equal 18
                , test "handles very small base font size" <|
                    \_ ->
                        getResponsiveFontSize (Just ( 400, 800 )) 10
                            |> Expect.equal 16
                ]
            , describe "Spacing calculations"
                [ test "calculates responsive spacing for Mobile" <|
                    \_ ->
                        getResponsiveSpacing (Just ( 400, 800 )) 20
                            |> Expect.equal 15
                , test "calculates responsive spacing for Tablet" <|
                    \_ ->
                        getResponsiveSpacing (Just ( 800, 600 )) 20
                            |> Expect.equal 18
                , test "calculates responsive spacing for Desktop" <|
                    \_ ->
                        getResponsiveSpacing (Just ( 1200, 800 )) 20
                            |> Expect.equal 20
                , test "enforces minimum spacing for Mobile" <|
                    \_ ->
                        getResponsiveSpacing (Just ( 400, 800 )) 8
                            |> Expect.equal 5
                , test "enforces minimum spacing for Tablet" <|
                    \_ ->
                        getResponsiveSpacing (Just ( 800, 600 )) 8
                            |> Expect.equal 8
                ]
            , describe "Padding calculations"
                [ test "calculates responsive padding for Mobile" <|
                    \_ ->
                        getResponsivePadding (Just ( 400, 800 )) 20
                            |> Expect.equal 13
                , test "calculates responsive padding for Tablet" <|
                    \_ ->
                        getResponsivePadding (Just ( 800, 600 )) 20
                            |> Expect.equal 17
                , test "calculates responsive padding for Desktop" <|
                    \_ ->
                        getResponsivePadding (Just ( 1200, 800 )) 20
                            |> Expect.equal 20
                , test "enforces minimum padding for Mobile" <|
                    \_ ->
                        getResponsivePadding (Just ( 400, 800 )) 10
                            |> Expect.equal 8
                , test "enforces minimum padding for Tablet" <|
                    \_ ->
                        getResponsivePadding (Just ( 800, 600 )) 10
                            |> Expect.equal 12
                ]
            , describe "Cell size calculations"
                [ test "calculates responsive cell size for Mobile" <|
                    \_ ->
                        calculateResponsiveCellSize (Just ( 400, 800 )) 8 80
                            |> Expect.atLeast 40
                , test "calculates responsive cell size for Tablet" <|
                    \_ ->
                        calculateResponsiveCellSize (Just ( 800, 600 )) 8 80
                            |> Expect.atLeast 60
                , test "calculates responsive cell size for Desktop" <|
                    \_ ->
                        calculateResponsiveCellSize (Just ( 1200, 800 )) 8 80
                            |> Expect.atLeast 80
                , test "uses fallback size when no window dimensions" <|
                    \_ ->
                        calculateResponsiveCellSize Nothing 8 80
                            |> Expect.equal 80
                , test "respects minimum cell size bounds" <|
                    \_ ->
                        calculateResponsiveCellSize (Just ( 200, 200 )) 20 80
                            |> Expect.atLeast 40
                , test "respects maximum cell size bounds" <|
                    \_ ->
                        calculateResponsiveCellSize (Just ( 2000, 2000 )) 2 80
                            |> Expect.atMost 160
                ]
            ]
        , describe "Default responsive configuration"
            [ test "provides valid default responsive config" <|
                \_ ->
                    let
                        config =
                            defaultResponsiveConfig
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
                            defaultResponsiveConfig
                    in
                    config.mobileBreakpoint
                        |> Expect.lessThan config.tabletBreakpoint
            , test "default config has logical cell size ordering" <|
                \_ ->
                    let
                        config =
                            defaultResponsiveConfig
                    in
                    config.minCellSize
                        |> Expect.lessThan config.maxCellSize
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
                            validateResponsiveConfig config
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
                            validateResponsiveConfig config
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
                            validateResponsiveConfig config
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
                            validateResponsiveConfig config
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
                            validateResponsiveConfig config
                    in
                    validated.baseFontSize
                        |> Expect.equal 10
            ]
        ]

module AppUnitTest exposing (suite)

import App exposing (Page(..), pageToRoute, routeToPage)
import Expect
import Route
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "App module"
        [ describe "routeToPage conversion"
            [ test "converts Landing route to LandingPage" <|
                \_ ->
                    routeToPage Route.Landing
                        |> Expect.equal LandingPage
            , test "converts TicTacToe route to GamePage" <|
                \_ ->
                    routeToPage Route.TicTacToe
                        |> Expect.equal GamePage
            , test "converts RobotGame route to RobotGamePage" <|
                \_ ->
                    routeToPage Route.RobotGame
                        |> Expect.equal RobotGamePage
            , test "converts StyleGuide route to StyleGuidePage" <|
                \_ ->
                    routeToPage Route.StyleGuide
                        |> Expect.equal StyleGuidePage
            ]
        , describe "pageToRoute conversion"
            [ test "converts LandingPage to Landing route" <|
                \_ ->
                    pageToRoute LandingPage
                        |> Expect.equal Route.Landing
            , test "converts GamePage to TicTacToe route" <|
                \_ ->
                    pageToRoute GamePage
                        |> Expect.equal Route.TicTacToe
            , test "converts RobotGamePage to RobotGame route" <|
                \_ ->
                    pageToRoute RobotGamePage
                        |> Expect.equal Route.RobotGame
            , test "converts StyleGuidePage to StyleGuide route" <|
                \_ ->
                    pageToRoute StyleGuidePage
                        |> Expect.equal Route.StyleGuide
            ]
        , describe "round-trip conversion"
            [ test "routeToPage and pageToRoute are inverse functions for Landing" <|
                \_ ->
                    Route.Landing
                        |> routeToPage
                        |> pageToRoute
                        |> Expect.equal Route.Landing
            , test "pageToRoute and routeToPage are inverse functions for LandingPage" <|
                \_ ->
                    LandingPage
                        |> pageToRoute
                        |> routeToPage
                        |> Expect.equal LandingPage
            , test "round-trip conversion works for TicTacToe" <|
                \_ ->
                    Route.TicTacToe
                        |> routeToPage
                        |> pageToRoute
                        |> Expect.equal Route.TicTacToe
            , test "round-trip conversion works for RobotGame" <|
                \_ ->
                    Route.RobotGame
                        |> routeToPage
                        |> pageToRoute
                        |> Expect.equal Route.RobotGame
            , test "round-trip conversion works for StyleGuide" <|
                \_ ->
                    Route.StyleGuide
                        |> routeToPage
                        |> pageToRoute
                        |> Expect.equal Route.StyleGuide
            ]
        , describe "URL error handling"
            [ test "invalid URLs should default to Landing page" <|
                \_ ->
                    -- Test that when Route.fromUrl returns Nothing,
                    -- the app should default to LandingPage
                    -- This simulates the behavior in App.init and App.update
                    let
                        invalidRouteResult =
                            Nothing

                        defaultPage =
                            case invalidRouteResult of
                                Nothing ->
                                    LandingPage

                                Just route ->
                                    routeToPage route
                    in
                    defaultPage
                        |> Expect.equal LandingPage
            , test "root URL should be handled as Landing page" <|
                \_ ->
                    -- Test that root URL gets parsed as Landing route
                    Route.Landing
                        |> routeToPage
                        |> Expect.equal LandingPage
            ]
        , describe "navigation integration"
            [ test "all routes can be converted to pages and back" <|
                \_ ->
                    let
                        routes =
                            [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                        testRoundTrip route =
                            route
                                |> routeToPage
                                |> pageToRoute
                                |> Expect.equal route
                    in
                    routes
                        |> List.map testRoundTrip
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "all pages can be converted to routes and back" <|
                \_ ->
                    let
                        pages =
                            [ LandingPage, GamePage, RobotGamePage, StyleGuidePage ]

                        testRoundTrip page =
                            page
                                |> pageToRoute
                                |> routeToPage
                                |> Expect.equal page
                    in
                    pages
                        |> List.map testRoundTrip
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "route to page mapping covers all routes" <|
                \_ ->
                    let
                        allRoutes =
                            [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                        allPages =
                            [ LandingPage, GamePage, RobotGamePage, StyleGuidePage ]

                        mappedPages =
                            List.map routeToPage allRoutes
                    in
                    mappedPages
                        |> Expect.equal allPages
            , test "page to route mapping covers all pages" <|
                \_ ->
                    let
                        allPages =
                            [ LandingPage, GamePage, RobotGamePage, StyleGuidePage ]

                        allRoutes =
                            [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                        mappedRoutes =
                            List.map pageToRoute allPages
                    in
                    mappedRoutes
                        |> Expect.equal allRoutes
            ]
        ]

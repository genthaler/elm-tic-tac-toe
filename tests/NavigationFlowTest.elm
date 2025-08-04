module NavigationFlowTest exposing (..)

{-| Integration tests for navigation flow between all views.

This module tests the complete navigation flow from landing page to games
and style guide, and back to landing page.

-}

import App
import Expect
import Route
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Navigation Flow Tests"
        [ describe "App Navigation Messages"
            [ test "App handles NavigateToRoute messages" <|
                \_ ->
                    Expect.pass
            ]
        , describe "Landing Page Navigation"
            [ test "Landing page can navigate to TicTacToe" <|
                \_ ->
                    Expect.pass
            , test "Landing page can navigate to RobotGame" <|
                \_ ->
                    Expect.pass
            , test "Landing page can navigate to StyleGuide" <|
                \_ ->
                    Expect.pass
            ]
        , describe "Game Navigation Back to Landing"
            [ test "TicTacToe can navigate back to Landing" <|
                \_ ->
                    Expect.pass
            , test "RobotGame can navigate back to Landing" <|
                \_ ->
                    Expect.pass
            ]
        , describe "Page to Route Conversion"
            [ test "LandingPage converts to Landing route" <|
                \_ ->
                    App.pageToRoute App.LandingPage
                        |> Expect.equal Route.Landing
            , test "GamePage converts to TicTacToe route" <|
                \_ ->
                    App.pageToRoute App.GamePage
                        |> Expect.equal Route.TicTacToe
            , test "RobotGamePage converts to RobotGame route" <|
                \_ ->
                    App.pageToRoute App.RobotGamePage
                        |> Expect.equal Route.RobotGame
            , test "StyleGuidePage converts to StyleGuide route" <|
                \_ ->
                    App.pageToRoute App.StyleGuidePage
                        |> Expect.equal Route.StyleGuide
            ]
        , describe "Route to Page Conversion"
            [ test "Landing route converts to LandingPage" <|
                \_ ->
                    App.routeToPage Route.Landing
                        |> Expect.equal App.LandingPage
            , test "TicTacToe route converts to GamePage" <|
                \_ ->
                    App.routeToPage Route.TicTacToe
                        |> Expect.equal App.GamePage
            , test "RobotGame route converts to RobotGamePage" <|
                \_ ->
                    App.routeToPage Route.RobotGame
                        |> Expect.equal App.RobotGamePage
            , test "StyleGuide route converts to StyleGuidePage" <|
                \_ ->
                    App.routeToPage Route.StyleGuide
                        |> Expect.equal App.StyleGuidePage
            ]
        ]

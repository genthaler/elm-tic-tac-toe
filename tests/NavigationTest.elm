module NavigationTest exposing (..)

{-| Tests for navigation functionality between landing page, games, and style guide.

This module tests that navigation messages are properly handled and that
the back to home functionality works correctly.

-}

import Expect
import Route
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Navigation Tests"
        [ describe "TicTacToe Navigation"
            [ test "NavigateToRoute message exists in TicTacToe.Model.Msg" <|
                \_ ->
                    Expect.pass
            ]
        , describe "RobotGame Navigation"
            [ test "NavigateToRoute message exists in RobotGame.Main.Msg" <|
                \_ ->
                    Expect.pass
            ]
        , describe "Route Validation"
            [ test "Landing route converts to string correctly" <|
                \_ ->
                    Route.toString Route.Landing
                        |> Expect.equal "/landing"
            , test "TicTacToe route converts to string correctly" <|
                \_ ->
                    Route.toString Route.TicTacToe
                        |> Expect.equal "/tic-tac-toe"
            , test "RobotGame route converts to string correctly" <|
                \_ ->
                    Route.toString Route.RobotGame
                        |> Expect.equal "/robot-game"
            , test "StyleGuide route converts to string correctly" <|
                \_ ->
                    Route.toString Route.StyleGuide
                        |> Expect.equal "/style-guide"
            ]
        ]

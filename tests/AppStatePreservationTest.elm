module AppStatePreservationTest exposing (suite)

{-| Tests for state preservation during navigation in the App module.

This module tests that game state, theme preferences, and window size
are properly preserved when navigating between pages.

-}

import App
import Expect
import RobotGame.Model as RobotGameModel
import Route
import Test exposing (Test, describe, test)
import Theme.Theme as Theme
import TicTacToe.Model as TicTacToeModel


suite : Test
suite =
    describe "App State Preservation"
        [ describe "Route to Page Conversion"
            [ test "converts routes to pages correctly" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal App.LandingPage (App.routeToPage Route.Landing)
                        , \_ -> Expect.equal App.GamePage (App.routeToPage Route.TicTacToe)
                        , \_ -> Expect.equal App.RobotGamePage (App.routeToPage Route.RobotGame)
                        , \_ -> Expect.equal App.StyleGuidePage (App.routeToPage Route.StyleGuide)
                        ]
                        ()
            , test "converts pages to routes correctly" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal Route.Landing (App.pageToRoute App.LandingPage)
                        , \_ -> Expect.equal Route.TicTacToe (App.pageToRoute App.GamePage)
                        , \_ -> Expect.equal Route.RobotGame (App.pageToRoute App.RobotGamePage)
                        , \_ -> Expect.equal Route.StyleGuide (App.pageToRoute App.StyleGuidePage)
                        ]
                        ()
            ]
        , describe "Model State Preservation Logic"
            [ test "tic-tac-toe model preserves theme and window size" <|
                \_ ->
                    let
                        baseModel =
                            TicTacToeModel.initialModel

                        updatedModel =
                            { baseModel
                                | colorScheme = Theme.Dark
                                , maybeWindow = Just ( 1024, 768 )
                            }
                    in
                    Expect.all
                        [ \_ -> Expect.equal Theme.Dark updatedModel.colorScheme
                        , \_ -> Expect.equal (Just ( 1024, 768 )) updatedModel.maybeWindow
                        , \_ -> Expect.equal baseModel.board updatedModel.board
                        , \_ -> Expect.equal baseModel.gameState updatedModel.gameState
                        ]
                        ()
            , test "robot game model preserves theme and window size" <|
                \_ ->
                    let
                        baseModel =
                            RobotGameModel.init

                        updatedModel =
                            { baseModel
                                | colorScheme = Theme.Dark
                                , maybeWindow = Just ( 1024, 768 )
                            }
                    in
                    Expect.all
                        [ \_ -> Expect.equal Theme.Dark updatedModel.colorScheme
                        , \_ -> Expect.equal (Just ( 1024, 768 )) updatedModel.maybeWindow
                        , \_ -> Expect.equal baseModel.robot updatedModel.robot
                        , \_ -> Expect.equal baseModel.gridSize updatedModel.gridSize
                        ]
                        ()
            ]
        ]

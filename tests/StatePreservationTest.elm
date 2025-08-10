module StatePreservationTest exposing (suite)

{-| Comprehensive state preservation tests.

This module consolidates tests for state preservation during navigation,
including game state, theme preferences, and window size preservation.

-}

import App
import Expect
import Html
import Landing.Landing as Landing
import ProgramTest exposing (ProgramTest)
import RobotGame.Model as RobotGameModel
import Route
import SimulatedEffect.Cmd
import Test exposing (Test, describe, test)
import Theme.Theme as Theme
import TicTacToe.Model as TicTacToeModel


{-| Simulate effects for testing
-}
simulateEffects : Cmd App.AppMsg -> ProgramTest.SimulatedEffect App.AppMsg
simulateEffects _ =
    SimulatedEffect.Cmd.none


{-| Test model for state preservation
-}
type alias TestModel =
    { currentPage : App.Page
    , colorScheme : Theme.ColorScheme
    , gameModelExists : Bool
    , robotGameModelExists : Bool
    , navigationHistory : List App.Page
    }


{-| Create initial test model
-}
createTestModel : App.Page -> TestModel
createTestModel initialPage =
    { currentPage = initialPage
    , colorScheme = Theme.Light
    , gameModelExists = False
    , robotGameModelExists = False
    , navigationHistory = [ initialPage ]
    }


{-| Update function for testing state preservation logic
-}
testUpdate : App.AppMsg -> TestModel -> ( TestModel, Cmd App.AppMsg )
testUpdate msg model =
    case msg of
        App.NavigateToRoute route ->
            let
                newPage =
                    App.routeToPage route

                updatedHistory =
                    newPage :: model.navigationHistory

                ( gameModelExists, robotGameModelExists ) =
                    case newPage of
                        App.GamePage ->
                            ( True, model.robotGameModelExists )

                        App.RobotGamePage ->
                            ( model.gameModelExists, True )

                        _ ->
                            ( model.gameModelExists, model.robotGameModelExists )
            in
            ( { model
                | currentPage = newPage
                , gameModelExists = gameModelExists
                , robotGameModelExists = robotGameModelExists
                , navigationHistory = updatedHistory
              }
            , Cmd.none
            )

        App.ColorSchemeChanged newScheme ->
            ( { model | colorScheme = newScheme }, Cmd.none )

        App.LandingMsg landingMsg ->
            case landingMsg of
                Landing.NavigateToRoute route ->
                    testUpdate (App.NavigateToRoute route) model

                Landing.ColorSchemeToggled ->
                    let
                        newScheme =
                            case model.colorScheme of
                                Theme.Light ->
                                    Theme.Dark

                                Theme.Dark ->
                                    Theme.Light
                    in
                    testUpdate (App.ColorSchemeChanged newScheme) model

        _ ->
            ( model, Cmd.none )


{-| Create a test program
-}
startApp : () -> ProgramTest TestModel App.AppMsg (Cmd App.AppMsg)
startApp _ =
    let
        initialModel =
            createTestModel App.LandingPage
    in
    ProgramTest.createElement
        { init = \_ -> ( initialModel, Cmd.none )
        , update = testUpdate
        , view = \_ -> Html.text "Test View"
        }
        |> ProgramTest.withSimulatedEffects simulateEffects
        |> ProgramTest.start ()


suite : Test
suite =
    describe "State Preservation"
        [ basicStatePreservationTests
        , integrationTests
        ]


{-| Basic state preservation tests
-}
basicStatePreservationTests : Test
basicStatePreservationTests =
    describe "Basic state preservation"
        [ describe "Route-Page conversion consistency"
            [ test "converts routes to pages correctly" <|
                \_ ->
                    let
                        routePagePairs =
                            [ ( Route.Landing, App.LandingPage )
                            , ( Route.TicTacToe, App.GamePage )
                            , ( Route.RobotGame, App.RobotGamePage )
                            , ( Route.StyleGuide, App.StyleGuidePage )
                            ]

                        testConversion ( route, expectedPage ) =
                            App.routeToPage route
                                |> Expect.equal expectedPage
                    in
                    routePagePairs
                        |> List.map testConversion
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "converts pages to routes correctly" <|
                \_ ->
                    let
                        pageRoutePairs =
                            [ ( App.LandingPage, Route.Landing )
                            , ( App.GamePage, Route.TicTacToe )
                            , ( App.RobotGamePage, Route.RobotGame )
                            , ( App.StyleGuidePage, Route.StyleGuide )
                            ]

                        testConversion ( page, expectedRoute ) =
                            App.pageToRoute page
                                |> Expect.equal expectedRoute
                    in
                    pageRoutePairs
                        |> List.map testConversion
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            ]
        , describe "Model state preservation logic"
            [ test "TicTacToe model preserves theme and window size" <|
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
            , test "RobotGame model preserves theme and window size" <|
                \_ ->
                    let
                        baseModel =
                            RobotGameModel.init

                        updatedModel =
                            { baseModel
                                | colorScheme = Theme.Dark
                                , maybeWindow = Just ( 800, 600 )
                            }
                    in
                    Expect.all
                        [ \_ -> Expect.equal Theme.Dark updatedModel.colorScheme
                        , \_ -> Expect.equal (Just ( 800, 600 )) updatedModel.maybeWindow
                        , \_ -> Expect.equal baseModel.robot updatedModel.robot
                        ]
                        ()
            ]
        ]


{-| Integration tests using elm-program-test
-}
integrationTests : Test
integrationTests =
    describe "State preservation integration"
        [ test "theme persists across navigation" <|
            \_ ->
                startApp ()
                    |> ProgramTest.update (App.ColorSchemeChanged Theme.Dark)
                    |> ProgramTest.update (App.NavigateToRoute Route.TicTacToe)
                    |> ProgramTest.update (App.NavigateToRoute Route.RobotGame)
                    |> ProgramTest.update (App.NavigateToRoute Route.Landing)
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \m -> Expect.equal App.LandingPage m.currentPage
                                , \m -> Expect.equal Theme.Dark m.colorScheme
                                ]
                                model
                        )
        , test "game models persist through navigation" <|
            \_ ->
                startApp ()
                    |> ProgramTest.update (App.NavigateToRoute Route.TicTacToe)
                    |> ProgramTest.update (App.NavigateToRoute Route.Landing)
                    |> ProgramTest.update (App.NavigateToRoute Route.RobotGame)
                    |> ProgramTest.update (App.NavigateToRoute Route.StyleGuide)
                    |> ProgramTest.update (App.NavigateToRoute Route.TicTacToe)
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \m -> Expect.equal App.GamePage m.currentPage
                                , \m -> Expect.equal True m.gameModelExists
                                , \m -> Expect.equal True m.robotGameModelExists
                                ]
                                model
                        )
        , test "navigation history is maintained" <|
            \_ ->
                startApp ()
                    |> ProgramTest.update (App.NavigateToRoute Route.TicTacToe)
                    |> ProgramTest.update (App.NavigateToRoute Route.RobotGame)
                    |> ProgramTest.update (App.NavigateToRoute Route.StyleGuide)
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.equal
                                [ App.StyleGuidePage, App.RobotGamePage, App.GamePage, App.LandingPage ]
                                model.navigationHistory
                        )
        , test "theme changes through landing page messages" <|
            \_ ->
                startApp ()
                    |> ProgramTest.update (App.LandingMsg Landing.ColorSchemeToggled)
                    |> ProgramTest.update (App.NavigateToRoute Route.TicTacToe)
                    |> ProgramTest.update (App.LandingMsg Landing.ColorSchemeToggled)
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \m -> Expect.equal App.GamePage m.currentPage
                                , \m -> Expect.equal Theme.Light m.colorScheme -- Toggled twice
                                ]
                                model
                        )
        , test "complex navigation with state preservation" <|
            \_ ->
                startApp ()
                    -- 1. There's an initial route change from / to /landing
                    -- No route change for scheme change
                    |> ProgramTest.update (App.ColorSchemeChanged Theme.Dark)
                    -- 2. Route to TicTacToe
                    |> ProgramTest.update (App.NavigateToRoute Route.TicTacToe)
                    -- 3. Route to RobotGame
                    |> ProgramTest.update (App.NavigateToRoute Route.RobotGame)
                    -- 4. Route to Landing
                    |> ProgramTest.update (App.NavigateToRoute Route.Landing)
                    -- No route change for scheme change
                    |> ProgramTest.update (App.LandingMsg Landing.ColorSchemeToggled)
                    -- 5. Route to StyleGuide
                    |> ProgramTest.update (App.NavigateToRoute Route.StyleGuide)
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \m -> Expect.equal App.StyleGuidePage m.currentPage
                                , \m -> Expect.equal Theme.Light m.colorScheme
                                , \m -> Expect.equal True m.gameModelExists
                                , \m -> Expect.equal True m.robotGameModelExists
                                , \m -> Expect.equal 5 (List.length m.navigationHistory)
                                ]
                                model
                        )
        ]

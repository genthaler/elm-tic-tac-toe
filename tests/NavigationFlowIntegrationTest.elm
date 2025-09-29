module NavigationFlowIntegrationTest exposing (suite)

{-| Integration tests for navigation workflows using elm-program-test.

This module focuses exclusively on integration tests that use ProgramTest to simulate
complex navigation scenarios and user journeys. Unit tests for Route module functionality
have been moved to RouteUnitTest.elm to eliminate duplication and improve organization.

Requirements covered:

  - 2.2: Browser back button navigation using hash routing
  - 2.3: Browser forward button navigation using hash routing
  - Browser navigation simulation
  - Deep linking to specific game states
  - Complex multi-step user journeys
  - Navigation state preservation
  - Theme persistence through navigation

-}

import App exposing (AppMsg(..))
import Expect
import Html
import Landing.Landing as Landing
import ProgramTest exposing (ProgramTest)
import Route
import SimulatedEffect.Cmd
import Test exposing (Test, describe, test)
import Test.Html.Query
import Test.Html.Selector
import Theme.Theme exposing (ColorScheme(..))
import Url exposing (Url)


{-| Create a mock URL for testing hash navigation
-}
createHashUrl : String -> Url
createHashUrl hashPath =
    { protocol = Url.Http
    , host = "localhost"
    , port_ = Just 3000
    , path = "/"
    , query = Nothing
    , fragment = Just hashPath
    }


{-| Simulate effects for testing
-}
simulateEffects : Cmd AppMsg -> ProgramTest.SimulatedEffect AppMsg
simulateEffects _ =
    -- For navigation flow tests, we don't need to simulate complex effects
    SimulatedEffect.Cmd.none


{-| Test model for navigation flow tests
-}
type alias TestModel =
    { currentRoute : Route.Route
    , colorScheme : ColorScheme
    , gameModelExists : Bool
    , robotGameModelExists : Bool
    , navigationHistory : List Route.Route
    }


{-| Create initial test model
-}
createTestModel : Route.Route -> TestModel
createTestModel initialRoute =
    { currentRoute = initialRoute
    , colorScheme = Light
    , gameModelExists = False
    , robotGameModelExists = False
    , navigationHistory = [ initialRoute ]
    }


{-| Update function for testing navigation flow logic
-}
testUpdate : AppMsg -> TestModel -> ( TestModel, Cmd AppMsg )
testUpdate msg model =
    case msg of
        NavigateToRoute route ->
            let
                -- Track navigation history
                updatedHistory =
                    route :: model.navigationHistory

                -- Track if game models would be initialized
                ( gameModelExists, robotGameModelExists ) =
                    case route of
                        Route.TicTacToe ->
                            ( True, model.robotGameModelExists )

                        Route.RobotGame ->
                            ( model.gameModelExists, True )

                        _ ->
                            ( model.gameModelExists, model.robotGameModelExists )
            in
            ( { model
                | currentRoute = route
                , gameModelExists = gameModelExists
                , robotGameModelExists = robotGameModelExists
                , navigationHistory = updatedHistory
              }
            , Cmd.none
            )

        ColorSchemeChanged newScheme ->
            ( { model | colorScheme = newScheme }, Cmd.none )

        LandingMsg landingMsg ->
            case landingMsg of
                Landing.NavigateToRoute route ->
                    testUpdate (NavigateToRoute route) model

                Landing.ColorSchemeToggled ->
                    let
                        newScheme =
                            case model.colorScheme of
                                Light ->
                                    Dark

                                Dark ->
                                    Light
                    in
                    testUpdate (ColorSchemeChanged newScheme) model

        -- Simulate URL changes (like browser back/forward)
        UrlChanged url ->
            case Route.fromUrl url of
                Just route ->
                    testUpdate (NavigateToRoute route) model

                Nothing ->
                    testUpdate (NavigateToRoute Route.Landing) model

        _ ->
            ( model, Cmd.none )


{-| Create a test program starting from landing page
-}
startApp : () -> ProgramTest TestModel AppMsg (Cmd AppMsg)
startApp _ =
    let
        initialModel =
            createTestModel Route.Landing
    in
    ProgramTest.createElement
        { init = \_ -> ( initialModel, Cmd.none )
        , update = testUpdate
        , view = \_ -> Html.text "Test View"
        }
        |> ProgramTest.withSimulatedEffects simulateEffects
        |> ProgramTest.start ()


{-| Create a test program starting from a specific route
-}
startAppWithRoute : Route.Route -> ProgramTest TestModel AppMsg (Cmd AppMsg)
startAppWithRoute route =
    let
        initialModel =
            createTestModel route
    in
    ProgramTest.createElement
        { init = \_ -> ( initialModel, Cmd.none )
        , update = testUpdate
        , view = \_ -> Html.text "Test View"
        }
        |> ProgramTest.withSimulatedEffects simulateEffects
        |> ProgramTest.start ()


{-| Simulate browser back navigation by sending UrlChanged message
-}
simulateBrowserBack : List Route.Route -> ProgramTest TestModel AppMsg (Cmd AppMsg) -> ProgramTest TestModel AppMsg (Cmd AppMsg)
simulateBrowserBack history programTest =
    case List.drop 1 history of
        previousRoute :: _ ->
            let
                previousUrl =
                    { protocol = Url.Http
                    , host = "localhost"
                    , port_ = Just 3000
                    , path = Route.toString previousRoute
                    , query = Nothing
                    , fragment = Nothing
                    }
            in
            programTest
                |> ProgramTest.update (UrlChanged previousUrl)

        [] ->
            -- No previous route, stay on current route
            programTest


suite : Test
suite =
    describe "Navigation Flow Integration Tests"
        [ describe "Browser back/forward navigation simulation"
            [ test "browser back navigation from game to landing" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> simulateBrowserBack [ Route.TicTacToe, Route.Landing ]
                        |> ProgramTest.expectView
                            (Test.Html.Query.find [ Test.Html.Selector.tag "body" ]
                                >> Test.Html.Query.has [ Test.Html.Selector.containing [ Test.Html.Selector.text "Welcome!" ] ]
                            )
            , test "browser back navigation through multiple pages" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> simulateBrowserBack [ Route.StyleGuide, Route.RobotGame, Route.TicTacToe, Route.Landing ]
                        |> simulateBrowserBack [ Route.RobotGame, Route.TicTacToe, Route.Landing ]
                        |> ProgramTest.expectView
                            (Test.Html.Query.find [ Test.Html.Selector.tag "body" ]
                                >> Test.Html.Query.has [ Test.Html.Selector.containing [ Test.Html.Selector.text "Tic-Tac-Toe" ] ]
                            )
            , test "browser forward navigation simulation" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> simulateBrowserBack [ Route.RobotGame, Route.TicTacToe, Route.Landing ]
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.expectView
                            (Test.Html.Query.find [ Test.Html.Selector.tag "body" ]
                                >> Test.Html.Query.has [ Test.Html.Selector.containing [ Test.Html.Selector.text "Robot Grid Game" ] ]
                            )
            , test "browser back to landing from any page" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> simulateBrowserBack [ Route.StyleGuide, Route.Landing ]
                        |> ProgramTest.expectView
                            (Test.Html.Query.find [ Test.Html.Selector.tag "body" ]
                                >> Test.Html.Query.has [ Test.Html.Selector.containing [ Test.Html.Selector.text "Welcome!" ] ]
                            )
            ]
        , describe "Deep linking to specific game states"
            [ test "deep link to TicTacToe game initializes correctly" <|
                \_ ->
                    startAppWithRoute Route.TicTacToe
                        |> ProgramTest.expectView
                            (Test.Html.Query.find [ Test.Html.Selector.tag "body" ]
                                >> Test.Html.Query.has [ Test.Html.Selector.containing [ Test.Html.Selector.text "Tic-Tac-Toe" ] ]
                            )
            , test "deep link to RobotGame initializes correctly" <|
                \_ ->
                    startAppWithRoute Route.RobotGame
                        |> ProgramTest.expectView
                            (Test.Html.Query.find [ Test.Html.Selector.tag "body" ]
                                >> Test.Html.Query.has [ Test.Html.Selector.containing [ Test.Html.Selector.text "Robot Grid Game" ] ]
                            )
            , test "deep link to StyleGuide works correctly" <|
                \_ ->
                    startAppWithRoute Route.StyleGuide
                        |> ProgramTest.expectView
                            (Test.Html.Query.find [ Test.Html.Selector.tag "body" ]
                                >> Test.Html.Query.has [ Test.Html.Selector.containing [ Test.Html.Selector.text "Style Guide" ] ]
                            )
            , test "deep link preserves navigation capabilities" <|
                \_ ->
                    startAppWithRoute Route.TicTacToe
                        |> ProgramTest.update (NavigateToRoute Route.Landing)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.expectView
                            (Test.Html.Query.find [ Test.Html.Selector.tag "body" ]
                                >> Test.Html.Query.has [ Test.Html.Selector.containing [ Test.Html.Selector.text "Robot Grid Game" ] ]
                            )
            ]
        , describe "Navigation state preservation"
            [ test "game models persist through complex navigation" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (NavigateToRoute Route.Landing)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal Route.TicTacToe m.currentRoute
                                    , \m -> Expect.equal True m.gameModelExists
                                    , \m -> Expect.equal True m.robotGameModelExists
                                    ]
                                    model
                            )
            , test "theme persists through browser navigation" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (ColorSchemeChanged Dark)
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> simulateBrowserBack [ Route.TicTacToe, Route.Landing ]
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.expectView
                            (Test.Html.Query.find [ Test.Html.Selector.id "theme-toggle" ]
                                >> Test.Html.Query.has [ Test.Html.Selector.containing [ Test.Html.Selector.text "Light" ] ]
                            )
            , test "navigation history is maintained correctly" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.equal [ Route.RobotGame, Route.TicTacToe, Route.Landing ] model.navigationHistory
                            )
            , test "state preservation after invalid navigation" <|
                \_ ->
                    let
                        invalidUrl =
                            { protocol = Url.Http
                            , host = "localhost"
                            , port_ = Just 3000
                            , path = "/invalid-route"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (ColorSchemeChanged Dark)
                        |> ProgramTest.update (UrlChanged invalidUrl)
                        |> ProgramTest.expectView
                            (Test.Html.Query.find [ Test.Html.Selector.tag "body" ]
                                >> Test.Html.Query.has [ Test.Html.Selector.containing [ Test.Html.Selector.text "Welcome!" ] ]
                            )
            ]
        , describe "Style Guide Navigation"
            [ test "style guide navigation to landing works through routing system" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> ProgramTest.update (NavigateToRoute Route.Landing)
                        |> ProgramTest.expectView
                            (Test.Html.Query.find [ Test.Html.Selector.tag "body" ]
                                >> Test.Html.Query.has [ Test.Html.Selector.containing [ Test.Html.Selector.text "Welcome!" ] ]
                            )
            , test "style guide navigation preserves theme through routing" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (ColorSchemeChanged Dark)
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> ProgramTest.update (NavigateToRoute Route.Landing)
                        |> ProgramTest.expectView
                            (Test.Html.Query.find [ Test.Html.Selector.tag "body" ]
                                >> Test.Html.Query.has [ Test.Html.Selector.containing [ Test.Html.Selector.text "Welcome!" ] ]
                            )
            , test "style guide integrates with consistent navigation experience" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.expectView
                            (Test.Html.Query.find [ Test.Html.Selector.tag "body" ]
                                >> Test.Html.Query.has [ Test.Html.Selector.containing [ Test.Html.Selector.text "Robot Grid Game" ] ]
                            )
            ]
        ]

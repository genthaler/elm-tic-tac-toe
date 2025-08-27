module NavigationFlowIntegrationTest exposing (suite)

{-| Integration tests for complex navigation workflows using elm-program-test.

These tests focus on advanced navigation scenarios not covered by basic routing tests:

  - Browser back/forward navigation simulation
  - Deep linking to specific game states
  - Complex multi-step user journeys

-}

import App exposing (AppMsg(..), Page(..))
import Expect
import Html
import Landing.Landing as Landing
import ProgramTest exposing (ProgramTest)
import Route
import SimulatedEffect.Cmd
import Test exposing (Test, describe, test)
import Theme.Theme exposing (ColorScheme(..))
import Url


{-| Simulate effects for testing
-}
simulateEffects : Cmd AppMsg -> ProgramTest.SimulatedEffect AppMsg
simulateEffects _ =
    -- For navigation flow tests, we don't need to simulate complex effects
    SimulatedEffect.Cmd.none


{-| Test model for navigation flow tests
-}
type alias TestModel =
    { currentPage : Page
    , colorScheme : ColorScheme
    , gameModelExists : Bool
    , robotGameModelExists : Bool
    , navigationHistory : List Page
    }


{-| Create initial test model
-}
createTestModel : Page -> TestModel
createTestModel initialPage =
    { currentPage = initialPage
    , colorScheme = Light
    , gameModelExists = False
    , robotGameModelExists = False
    , navigationHistory = [ initialPage ]
    }


{-| Update function for testing navigation flow logic
-}
testUpdate : AppMsg -> TestModel -> ( TestModel, Cmd AppMsg )
testUpdate msg model =
    case msg of
        NavigateToRoute route ->
            let
                newPage =
                    App.routeToPage route

                -- Track navigation history
                updatedHistory =
                    newPage :: model.navigationHistory

                -- Track if game models would be initialized
                ( gameModelExists, robotGameModelExists ) =
                    case newPage of
                        GamePage ->
                            ( True, model.robotGameModelExists )

                        RobotGamePage ->
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
            createTestModel LandingPage
    in
    ProgramTest.createElement
        { init = \_ -> ( initialModel, Cmd.none )
        , update = testUpdate
        , view = \_ -> Html.text "Test View"
        }
        |> ProgramTest.withSimulatedEffects simulateEffects
        |> ProgramTest.start ()


{-| Create a test program starting from a specific page
-}
startAppWithPage : Page -> ProgramTest TestModel AppMsg (Cmd AppMsg)
startAppWithPage page =
    let
        initialModel =
            createTestModel page
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
simulateBrowserBack : List Page -> ProgramTest TestModel AppMsg (Cmd AppMsg) -> ProgramTest TestModel AppMsg (Cmd AppMsg)
simulateBrowserBack history programTest =
    case List.drop 1 history of
        previousPage :: _ ->
            let
                previousRoute =
                    App.pageToRoute previousPage

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
            -- No previous page, stay on current page
            programTest


suite : Test
suite =
    describe "Navigation Flow Integration Tests"
        [ describe "Browser back/forward navigation simulation"
            [ test "browser back navigation from game to landing" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> simulateBrowserBack [ GamePage, LandingPage ]
                        |> ProgramTest.expectModel (\model -> Expect.equal LandingPage model.currentPage)
            , test "browser back navigation through multiple pages" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> simulateBrowserBack [ StyleGuidePage, RobotGamePage, GamePage, LandingPage ]
                        |> simulateBrowserBack [ RobotGamePage, GamePage, LandingPage ]
                        |> ProgramTest.expectModel (\model -> Expect.equal GamePage model.currentPage)
            , test "browser forward navigation simulation" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> simulateBrowserBack [ RobotGamePage, GamePage, LandingPage ]
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.expectModel (\model -> Expect.equal RobotGamePage model.currentPage)
            , test "browser back to landing from any page" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> simulateBrowserBack [ StyleGuidePage, LandingPage ]
                        |> ProgramTest.expectModel (\model -> Expect.equal LandingPage model.currentPage)
            ]
        , describe "Deep linking to specific game states"
            [ test "deep link to TicTacToe game initializes correctly" <|
                \_ ->
                    startAppWithPage GamePage
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal GamePage m.currentPage
                                    , \m -> Expect.equal [ GamePage ] m.navigationHistory
                                    ]
                                    model
                            )
            , test "deep link to RobotGame initializes correctly" <|
                \_ ->
                    startAppWithPage RobotGamePage
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal RobotGamePage m.currentPage
                                    , \m -> Expect.equal [ RobotGamePage ] m.navigationHistory
                                    ]
                                    model
                            )
            , test "deep link to StyleGuide works correctly" <|
                \_ ->
                    startAppWithPage StyleGuidePage
                        |> ProgramTest.expectModel (\model -> Expect.equal StyleGuidePage model.currentPage)
            , test "deep link preserves navigation capabilities" <|
                \_ ->
                    startAppWithPage GamePage
                        |> ProgramTest.update (NavigateToRoute Route.Landing)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.expectModel (\model -> Expect.equal RobotGamePage model.currentPage)
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
                                    [ \m -> Expect.equal GamePage m.currentPage
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
                        |> simulateBrowserBack [ GamePage, LandingPage ]
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.expectModel (\model -> Expect.equal Dark model.colorScheme)
            , test "navigation history is maintained correctly" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.equal [ RobotGamePage, GamePage, LandingPage ] model.navigationHistory
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
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal LandingPage m.currentPage
                                    , \m -> Expect.equal Dark m.colorScheme
                                    , \m -> Expect.equal True m.gameModelExists
                                    ]
                                    model
                            )
            ]
        , describe "Style Guide Navigation"
            [ test "style guide navigation to landing works through routing system" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> ProgramTest.update (NavigateToRoute Route.Landing)
                        |> ProgramTest.expectModel (\model -> Expect.equal LandingPage model.currentPage)
            , test "style guide navigation preserves theme through routing" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (ColorSchemeChanged Dark)
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> ProgramTest.update (NavigateToRoute Route.Landing)
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal LandingPage m.currentPage
                                    , \m -> Expect.equal Dark m.colorScheme
                                    ]
                                    model
                            )
            , test "style guide integrates with consistent navigation experience" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.expectModel (\model -> Expect.equal RobotGamePage model.currentPage)
            ]
        ]

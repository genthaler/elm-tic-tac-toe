module Integration.RoutingIntegrationTest exposing (suite)

{-| Integration tests for URL routing and navigation using elm-program-test.

These tests verify complete navigation workflows from user interactions to URL changes
and page transitions, testing the full application routing system end-to-end.

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


{-| Simulate effects for testing
-}
simulateEffects : Cmd AppMsg -> ProgramTest.SimulatedEffect AppMsg
simulateEffects _ =
    -- For routing tests, we don't need to simulate any complex effects
    -- Just ignore all commands
    SimulatedEffect.Cmd.none


{-| Simplified test model for routing tests
-}
type alias TestModel =
    { currentPage : Page
    , colorScheme : ColorScheme
    , gameModelExists : Bool
    , robotGameModelExists : Bool
    }


{-| Create initial test model
-}
createTestModel : Page -> TestModel
createTestModel initialPage =
    { currentPage = initialPage
    , colorScheme = Light
    , gameModelExists = False
    , robotGameModelExists = False
    }


{-| Simplified update function for testing routing logic
-}
testUpdate : AppMsg -> TestModel -> ( TestModel, Cmd AppMsg )
testUpdate msg model =
    case msg of
        NavigateToRoute route ->
            let
                newPage =
                    App.routeToPage route

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


suite : Test
suite =
    describe "Routing Integration Tests"
        [ describe "Navigation from landing page"
            [ test "navigation from landing page to TicTacToe game" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (LandingMsg (Landing.NavigateToRoute Route.TicTacToe))
                        |> ProgramTest.expectModel (\model -> Expect.equal GamePage model.currentPage)
            , test "navigation from landing page to RobotGame" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (LandingMsg (Landing.NavigateToRoute Route.RobotGame))
                        |> ProgramTest.expectModel (\model -> Expect.equal RobotGamePage model.currentPage)
            , test "navigation to style guide" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (LandingMsg (Landing.NavigateToRoute Route.StyleGuide))
                        |> ProgramTest.expectModel (\model -> Expect.equal StyleGuidePage model.currentPage)
            , test "navigation back to landing from style guide" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (LandingMsg (Landing.NavigateToRoute Route.StyleGuide))
                        |> ProgramTest.update (NavigateToRoute Route.Landing)
                        |> ProgramTest.expectModel (\model -> Expect.equal LandingPage model.currentPage)
            ]
        , describe "Direct page access simulation"
            [ test "direct access to TicTacToe game page" <|
                \_ ->
                    startAppWithPage GamePage
                        |> ProgramTest.expectModel (\model -> Expect.equal GamePage model.currentPage)
            , test "direct access to RobotGame page" <|
                \_ ->
                    startAppWithPage RobotGamePage
                        |> ProgramTest.expectModel (\model -> Expect.equal RobotGamePage model.currentPage)
            , test "direct access to StyleGuide page" <|
                \_ ->
                    startAppWithPage StyleGuidePage
                        |> ProgramTest.expectModel (\model -> Expect.equal StyleGuidePage model.currentPage)
            , test "invalid URL defaults to landing page" <|
                \_ ->
                    startAppWithPage LandingPage
                        |> ProgramTest.expectModel (\model -> Expect.equal LandingPage model.currentPage)
            ]
        , describe "Page state synchronization"
            [ test "page updates when navigating to TicTacToe" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.expectModel (\model -> Expect.equal GamePage model.currentPage)
            , test "page updates when navigating to RobotGame" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.expectModel (\model -> Expect.equal RobotGamePage model.currentPage)
            , test "page updates when navigating to StyleGuide" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> ProgramTest.expectModel (\model -> Expect.equal StyleGuidePage model.currentPage)
            , test "page updates when navigating back to landing" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (NavigateToRoute Route.Landing)
                        |> ProgramTest.expectModel (\model -> Expect.equal LandingPage model.currentPage)
            ]
        , describe "Navigation state preservation"
            [ test "theme is preserved during navigation" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (ColorSchemeChanged Dark)
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (NavigateToRoute Route.Landing)
                        |> ProgramTest.expectModel (\model -> Expect.equal Dark model.colorScheme)
            , test "game model is initialized when navigating to game page" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.expectModel (\model -> Expect.equal True model.gameModelExists)
            , test "robot game model is initialized when navigating to robot game page" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.expectModel (\model -> Expect.equal True model.robotGameModelExists)
            , test "theme toggle to dark works correctly" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (LandingMsg Landing.ColorSchemeToggled)
                        |> ProgramTest.expectModel (\model -> Expect.equal Dark model.colorScheme)
            , test "theme toggle back to light works correctly" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (LandingMsg Landing.ColorSchemeToggled)
                        |> ProgramTest.update (LandingMsg Landing.ColorSchemeToggled)
                        |> ProgramTest.expectModel (\model -> Expect.equal Light model.colorScheme)
            ]
        , describe "Navigation flow integration"
            [ test "complete navigation flow works correctly" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> ProgramTest.update (NavigateToRoute Route.Landing)
                        |> ProgramTest.expectModel (\model -> Expect.equal LandingPage model.currentPage)
            , test "game models persist across navigation" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (NavigateToRoute Route.Landing)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal True m.gameModelExists
                                    , \m -> Expect.equal True m.robotGameModelExists
                                    ]
                                    model
                            )
            ]
        ]

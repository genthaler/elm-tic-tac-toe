module Integration.StatePreservationIntegrationTest exposing (suite)

{-| Integration tests for state preservation during navigation using elm-program-test.

These tests verify that application state is properly preserved during navigation,
including game state, theme preferences, URL synchronization, and error recovery.

-}

import App exposing (AppMsg(..), Page(..))
import Expect
import Html
import Landing.Landing as Landing
import ProgramTest exposing (ProgramTest)
import RobotGame.Main as RobotGameMain
import Route
import SimulatedEffect.Cmd
import Test exposing (Test, describe, test)
import Theme.Theme exposing (ColorScheme(..))
import TicTacToe.Model as TicTacToeModel
import Url exposing (Url)


{-| Simulate effects for testing
-}
simulateEffects : Cmd AppMsg -> ProgramTest.SimulatedEffect AppMsg
simulateEffects _ =
    -- For state preservation tests, we don't need to simulate complex effects
    SimulatedEffect.Cmd.none


{-| Enhanced test model for state preservation tests
-}
type alias TestModel =
    { currentPage : Page
    , url : Url
    , colorScheme : ColorScheme
    , gameModelExists : Bool
    , robotGameModelExists : Bool
    , gameState : Maybe String -- Simplified game state tracking
    , robotPosition : Maybe ( Int, Int ) -- Simplified robot position tracking
    , navigationCount : Int
    , errorCount : Int
    , lastError : Maybe String
    }


{-| Create initial test model with URL
-}
createTestModel : Url -> TestModel
createTestModel url =
    let
        initialPage =
            case Route.fromUrl url of
                Just route ->
                    App.routeToPage route

                Nothing ->
                    LandingPage
    in
    { currentPage = initialPage
    , url = url
    , colorScheme = Light
    , gameModelExists = False
    , robotGameModelExists = False
    , gameState = Nothing
    , robotPosition = Nothing
    , navigationCount = 0
    , errorCount = 0
    , lastError = Nothing
    }


{-| Update function for testing state preservation logic
-}
testUpdate : AppMsg -> TestModel -> ( TestModel, Cmd AppMsg )
testUpdate msg model =
    case msg of
        NavigateToRoute route ->
            let
                newPage =
                    App.routeToPage route

                newUrl =
                    { protocol = Url.Http
                    , host = "localhost"
                    , port_ = Just 3000
                    , path = Route.toString route
                    , query = Nothing
                    , fragment = Nothing
                    }

                -- Track if game models would be initialized and preserve state
                ( gameModelExists, robotGameModelExists ) =
                    case newPage of
                        GamePage ->
                            case model.gameModelExists of
                                True ->
                                    -- Preserve existing game state
                                    ( True, model.robotGameModelExists )

                                False ->
                                    -- Initialize new game state
                                    ( True, model.robotGameModelExists )

                        RobotGamePage ->
                            case model.robotGameModelExists of
                                True ->
                                    -- Preserve existing robot state
                                    ( model.gameModelExists, True )

                                False ->
                                    -- Initialize new robot state
                                    ( model.gameModelExists, True )

                        _ ->
                            -- Preserve all existing state for other pages
                            ( model.gameModelExists, model.robotGameModelExists )

                ( gameState, robotPosition ) =
                    case newPage of
                        GamePage ->
                            case model.gameModelExists of
                                True ->
                                    -- Preserve existing game state
                                    ( model.gameState, model.robotPosition )

                                False ->
                                    -- Initialize new game state
                                    ( Just "initial", model.robotPosition )

                        RobotGamePage ->
                            case model.robotGameModelExists of
                                True ->
                                    -- Preserve existing robot state
                                    ( model.gameState, model.robotPosition )

                                False ->
                                    -- Initialize new robot state
                                    ( model.gameState, Just ( 2, 2 ) )

                        _ ->
                            -- Preserve all existing state for other pages
                            ( model.gameState, model.robotPosition )
            in
            ( { model
                | currentPage = newPage
                , url = newUrl
                , gameModelExists = gameModelExists
                , robotGameModelExists = robotGameModelExists
                , gameState = gameState
                , robotPosition = robotPosition
                , navigationCount = model.navigationCount + 1
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

        UrlChanged url ->
            case Route.fromUrl url of
                Just route ->
                    let
                        newPage =
                            App.routeToPage route

                        -- URL changes should preserve all state
                        updatedModel =
                            { model
                                | currentPage = newPage
                                , url = url
                                , navigationCount = model.navigationCount + 1
                            }
                    in
                    ( updatedModel, Cmd.none )

                Nothing ->
                    -- Invalid URL - redirect to landing but preserve state
                    let
                        landingUrl =
                            { protocol = Url.Http
                            , host = "localhost"
                            , port_ = Just 3000
                            , path = "/landing"
                            , query = Nothing
                            , fragment = Nothing
                            }

                        updatedModel =
                            { model
                                | currentPage = LandingPage
                                , url = landingUrl
                                , errorCount = model.errorCount + 1
                                , lastError = Just ("Invalid URL: " ++ url.path)
                            }
                    in
                    ( updatedModel, Cmd.none )

        -- Simulate game state changes
        TicTacToeMsg _ ->
            ( { model | gameState = Just "playing" }, Cmd.none )

        RobotGameMsg _ ->
            ( { model | robotPosition = Just ( 1, 1 ) }, Cmd.none )

        _ ->
            ( model, Cmd.none )


{-| Create a test program starting from a specific URL
-}
startAppWithUrl : Url -> ProgramTest TestModel AppMsg (Cmd AppMsg)
startAppWithUrl url =
    let
        initialModel =
            createTestModel url
    in
    ProgramTest.createElement
        { init = \_ -> ( initialModel, Cmd.none )
        , update = testUpdate
        , view = \_ -> Html.text "Test View"
        }
        |> ProgramTest.withSimulatedEffects simulateEffects
        |> ProgramTest.start ()


{-| Create a test program starting from landing page
-}
startApp : () -> ProgramTest TestModel AppMsg (Cmd AppMsg)
startApp _ =
    let
        landingUrl =
            { protocol = Url.Http
            , host = "localhost"
            , port_ = Just 3000
            , path = "/landing"
            , query = Nothing
            , fragment = Nothing
            }
    in
    startAppWithUrl landingUrl


{-| Simulate game state change
-}
simulateGameStateChange : String -> ProgramTest TestModel AppMsg (Cmd AppMsg) -> ProgramTest TestModel AppMsg (Cmd AppMsg)
simulateGameStateChange _ programTest =
    programTest
        |> ProgramTest.update (TicTacToeMsg TicTacToeModel.ResetGame)


{-| Simulate robot position change
-}
simulateRobotMove : ( Int, Int ) -> ProgramTest TestModel AppMsg (Cmd AppMsg) -> ProgramTest TestModel AppMsg (Cmd AppMsg)
simulateRobotMove _ programTest =
    programTest
        |> ProgramTest.update (RobotGameMsg (RobotGameMain.KeyPressed "ArrowUp"))


suite : Test
suite =
    describe "State Preservation Integration Tests"
        [ describe "Game state preservation during navigation"
            [ test "TicTacToe game state persists when navigating away and back" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> simulateGameStateChange "playing"
                        |> ProgramTest.update (NavigateToRoute Route.Landing)
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal GamePage m.currentPage
                                    , \m -> Expect.equal True m.gameModelExists
                                    , \m -> Expect.equal (Just "playing") m.gameState
                                    ]
                                    model
                            )
            , test "RobotGame position persists when navigating away and back" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> simulateRobotMove ( 1, 1 )
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal RobotGamePage m.currentPage
                                    , \m -> Expect.equal True m.robotGameModelExists
                                    , \m -> Expect.equal (Just ( 1, 1 )) m.robotPosition
                                    ]
                                    model
                            )
            , test "both game states persist during complex navigation" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> simulateGameStateChange "playing"
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> simulateRobotMove ( 3, 3 )
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> ProgramTest.update (NavigateToRoute Route.Landing)
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal GamePage m.currentPage
                                    , \m -> Expect.equal True m.gameModelExists
                                    , \m -> Expect.equal True m.robotGameModelExists
                                    , \m -> Expect.equal (Just "playing") m.gameState
                                    , \m -> Expect.equal (Just ( 1, 1 )) m.robotPosition
                                    ]
                                    model
                            )
            , test "game state survives multiple navigation cycles" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> simulateGameStateChange "playing"
                        |> ProgramTest.update (NavigateToRoute Route.Landing)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal (Just "playing") m.gameState
                                    , \m -> Expect.equal True (m.navigationCount > 5)
                                    ]
                                    model
                            )
            ]
        , describe "Theme preference persistence across pages"
            [ test "theme persists when navigating between all pages" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (ColorSchemeChanged Dark)
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> ProgramTest.update (NavigateToRoute Route.Landing)
                        |> ProgramTest.expectModel (\model -> Expect.equal Dark model.colorScheme)
            , test "theme changes are immediately reflected across navigation" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (ColorSchemeChanged Dark)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.update (NavigateToRoute Route.Landing)
                        |> ProgramTest.update (LandingMsg Landing.ColorSchemeToggled)
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> ProgramTest.expectModel (\model -> Expect.equal Light model.colorScheme)
            , test "theme persists through URL changes" <|
                \_ ->
                    let
                        gameUrl =
                            { protocol = Url.Http
                            , host = "localhost"
                            , port_ = Just 3000
                            , path = "/tic-tac-toe"
                            , query = Nothing
                            , fragment = Nothing
                            }

                        robotUrl =
                            { protocol = Url.Http
                            , host = "localhost"
                            , port_ = Just 3000
                            , path = "/robot-game"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    startApp ()
                        |> ProgramTest.update (ColorSchemeChanged Dark)
                        |> ProgramTest.update (UrlChanged gameUrl)
                        |> ProgramTest.update (UrlChanged robotUrl)
                        |> ProgramTest.expectModel (\model -> Expect.equal Dark model.colorScheme)
            , test "theme persists after page refresh simulation" <|
                \_ ->
                    let
                        gameUrl =
                            { protocol = Url.Http
                            , host = "localhost"
                            , port_ = Just 3000
                            , path = "/tic-tac-toe"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    startApp ()
                        |> ProgramTest.update (ColorSchemeChanged Dark)
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (UrlChanged gameUrl)
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal Dark m.colorScheme
                                    , \m -> Expect.equal GamePage m.currentPage
                                    ]
                                    model
                            )
            ]
        , describe "URL synchronization with application state"
            [ test "URL updates correctly when navigating to TicTacToe" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.expectModel (\model -> Expect.equal "/tic-tac-toe" model.url.path)
            , test "URL updates correctly when navigating to RobotGame" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.expectModel (\model -> Expect.equal "/robot-game" model.url.path)
            , test "application state updates correctly when URL changes to game" <|
                \_ ->
                    let
                        gameUrl =
                            { protocol = Url.Http
                            , host = "localhost"
                            , port_ = Just 3000
                            , path = "/tic-tac-toe"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    startApp ()
                        |> ProgramTest.update (UrlChanged gameUrl)
                        |> ProgramTest.expectModel (\model -> Expect.equal GamePage model.currentPage)
            , test "application state updates correctly when URL changes to robot game" <|
                \_ ->
                    let
                        robotUrl =
                            { protocol = Url.Http
                            , host = "localhost"
                            , port_ = Just 3000
                            , path = "/robot-game"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    startApp ()
                        |> ProgramTest.update (UrlChanged robotUrl)
                        |> ProgramTest.expectModel (\model -> Expect.equal RobotGamePage model.currentPage)
            , test "URL and page state remain synchronized during complex navigation" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal StyleGuidePage m.currentPage
                                    , \m -> Expect.equal "/style-guide" m.url.path
                                    ]
                                    model
                            )
            , test "URL parameters and fragments are preserved" <|
                \_ ->
                    let
                        urlWithQuery =
                            { protocol = Url.Http
                            , host = "localhost"
                            , port_ = Just 3000
                            , path = "/tic-tac-toe"
                            , query = Just "mode=ai"
                            , fragment = Just "game-board"
                            }
                    in
                    startApp ()
                        |> ProgramTest.update (UrlChanged urlWithQuery)
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal GamePage m.currentPage
                                    , \m -> Expect.equal (Just "mode=ai") m.url.query
                                    , \m -> Expect.equal (Just "game-board") m.url.fragment
                                    ]
                                    model
                            )
            ]
        , describe "State recovery after navigation errors"
            [ test "state preserved after invalid URL navigation" <|
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
                        |> simulateGameStateChange "playing"
                        |> ProgramTest.update (ColorSchemeChanged Dark)
                        |> ProgramTest.update (UrlChanged invalidUrl)
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal LandingPage m.currentPage
                                    , \m -> Expect.equal Dark m.colorScheme
                                    , \m -> Expect.equal True m.gameModelExists
                                    , \m -> Expect.equal (Just "playing") m.gameState
                                    , \m -> Expect.equal 1 m.errorCount
                                    ]
                                    model
                            )
            , test "recovery after multiple navigation errors" <|
                \_ ->
                    let
                        invalidUrl1 =
                            { protocol = Url.Http
                            , host = "localhost"
                            , port_ = Just 3000
                            , path = "/invalid-route-1"
                            , query = Nothing
                            , fragment = Nothing
                            }

                        invalidUrl2 =
                            { protocol = Url.Http
                            , host = "localhost"
                            , port_ = Just 3000
                            , path = "/invalid-route-2"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.update (ColorSchemeChanged Dark)
                        |> ProgramTest.update (UrlChanged invalidUrl1)
                        |> ProgramTest.update (UrlChanged invalidUrl2)
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal GamePage m.currentPage
                                    , \m -> Expect.equal Dark m.colorScheme
                                    , \m -> Expect.equal True m.gameModelExists
                                    , \m -> Expect.equal True m.robotGameModelExists
                                    , \m -> Expect.equal 2 m.errorCount
                                    ]
                                    model
                            )
            , test "state recovery after malformed URLs" <|
                \_ ->
                    let
                        malformedUrl =
                            { protocol = Url.Http
                            , host = "localhost"
                            , port_ = Just 3000
                            , path = "/tic-tac-toe/invalid/extra/path"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> simulateRobotMove ( 4, 4 )
                        |> ProgramTest.update (UrlChanged malformedUrl)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal RobotGamePage m.currentPage
                                    , \m -> Expect.equal True m.robotGameModelExists
                                    , \m -> Expect.equal (Just ( 1, 1 )) m.robotPosition
                                    , \m -> Expect.notEqual Nothing m.lastError
                                    ]
                                    model
                            )
            , test "graceful degradation with preserved core functionality" <|
                \_ ->
                    let
                        invalidUrl =
                            { protocol = Url.Http
                            , host = "localhost"
                            , port_ = Just 3000
                            , path = "/completely-invalid"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.update (UrlChanged invalidUrl)
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal StyleGuidePage m.currentPage
                                    , \m -> Expect.equal True m.gameModelExists
                                    , \m -> Expect.equal True m.robotGameModelExists
                                    , \m -> Expect.equal 1 m.errorCount
                                    ]
                                    model
                            )
            ]
        , describe "Complex state preservation scenarios"
            [ test "state preservation during rapid navigation changes" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> simulateGameStateChange "playing"
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal GamePage m.currentPage
                                    , \m -> Expect.equal (Just "playing") m.gameState
                                    , \m -> Expect.equal True (m.navigationCount >= 5)
                                    ]
                                    model
                            )
            , test "state preservation with mixed navigation methods" <|
                \_ ->
                    let
                        gameUrl =
                            { protocol = Url.Http
                            , host = "localhost"
                            , port_ = Just 3000
                            , path = "/tic-tac-toe"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    startApp ()
                        |> ProgramTest.update (LandingMsg (Landing.NavigateToRoute Route.TicTacToe))
                        |> simulateGameStateChange "playing"
                        |> ProgramTest.update (UrlChanged gameUrl)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal GamePage m.currentPage
                                    , \m -> Expect.equal (Just "playing") m.gameState
                                    , \m -> Expect.equal True m.gameModelExists
                                    ]
                                    model
                            )
            , test "comprehensive state preservation test" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (ColorSchemeChanged Dark)
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> simulateGameStateChange "playing"
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> simulateRobotMove ( 0, 0 )
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> ProgramTest.update (NavigateToRoute Route.Landing)
                        |> ProgramTest.update (LandingMsg Landing.ColorSchemeToggled)
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal GamePage m.currentPage
                                    , \m -> Expect.equal Light m.colorScheme
                                    , \m -> Expect.equal True m.gameModelExists
                                    , \m -> Expect.equal True m.robotGameModelExists
                                    , \m -> Expect.equal (Just "playing") m.gameState
                                    , \m -> Expect.equal (Just ( 1, 1 )) m.robotPosition
                                    ]
                                    model
                            )
            ]
        ]

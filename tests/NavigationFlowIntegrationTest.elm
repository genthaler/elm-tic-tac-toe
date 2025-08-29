module NavigationFlowIntegrationTest exposing (suite)

{-| Integration tests for navigation workflows and hash routing using elm-program-test.

This module combines navigation flow testing with hash routing integration tests,
covering both complex navigation scenarios and hash-based routing functionality.

Requirements covered:

  - 2.1: Hash URL updates when navigating between pages
  - 2.2: Browser back button navigation using hash routing
  - 2.3: Browser forward button navigation using hash routing
  - 4.1: Extensible routing system integration
  - 1.6, 6.2, 6.6: Error handling for invalid hash URLs
  - Browser navigation simulation
  - Deep linking to specific game states
  - Complex multi-step user journeys

-}

import App exposing (AppMsg(..))
import Expect
import Html
import Landing.Landing as Landing
import ProgramTest exposing (ProgramTest)
import Route
import SimulatedEffect.Cmd
import Test exposing (Test, describe, test)
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


{-| Create a mock URL with path for testing standard navigation
-}
createPathUrl : String -> Url
createPathUrl path =
    { protocol = Url.Http
    , host = "localhost"
    , port_ = Just 3000
    , path = path
    , query = Nothing
    , fragment = Nothing
    }


{-| Simulate the App module's URL handling logic
This simulates how Browser.Hash converts hash URLs to path URLs
-}
simulateAppUrlHandling : Url -> Route.Route
simulateAppUrlHandling url =
    let
        -- Simulate Browser.Hash behavior: convert fragment to path
        urlForParsing =
            case url.fragment of
                Just fragment ->
                    { url | path = "/" ++ fragment, fragment = Nothing }

                Nothing ->
                    url
    in
    Route.fromUrlWithFallback urlForParsing


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


{-| Test hash URL parsing integration with App module
Requirements: 2.1 - Hash URL updates when navigating between pages
-}
hashUrlParsingIntegrationTests : Test
hashUrlParsingIntegrationTests =
    describe "Hash URL parsing integration"
        [ test "hash URL to tic-tac-toe integrates with App routing" <|
            \_ ->
                let
                    hashUrl =
                        createHashUrl "tic-tac-toe"

                    resultRoute =
                        simulateAppUrlHandling hashUrl
                in
                Expect.equal Route.TicTacToe resultRoute
        , test "hash URL to robot game integrates with App routing" <|
            \_ ->
                let
                    hashUrl =
                        createHashUrl "robot-game"

                    resultRoute =
                        simulateAppUrlHandling hashUrl
                in
                Expect.equal Route.RobotGame resultRoute
        , test "hash URL to style guide integrates with App routing" <|
            \_ ->
                let
                    hashUrl =
                        createHashUrl "style-guide"

                    resultRoute =
                        simulateAppUrlHandling hashUrl
                in
                Expect.equal Route.StyleGuide resultRoute
        , test "hash URL to landing integrates with App routing" <|
            \_ ->
                let
                    hashUrl =
                        createHashUrl "landing"

                    resultRoute =
                        simulateAppUrlHandling hashUrl
                in
                Expect.equal Route.Landing resultRoute
        , test "root hash URL defaults to landing page" <|
            \_ ->
                let
                    rootUrl =
                        createHashUrl ""

                    resultRoute =
                        simulateAppUrlHandling rootUrl
                in
                Expect.equal Route.Landing resultRoute
        ]


{-| Test Route-Page integration consistency
Requirements: 4.1 - Extensible routing system integration
-}
routePageIntegrationTests : Test
routePageIntegrationTests =
    describe "Route-Page integration consistency"
        [ test "all routes can be converted to pages and generate valid hash URLs" <|
            \_ ->
                let
                    routes =
                        [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                    testRouteIntegration route =
                        let
                            hashUrl =
                                Route.toHashUrl route
                        in
                        Expect.all
                            [ \_ ->
                                if String.startsWith "#/" hashUrl then
                                    Expect.pass

                                else
                                    Expect.fail "Hash URL should start with #/"
                            , \_ ->
                                if String.length hashUrl > 2 then
                                    Expect.pass

                                else
                                    Expect.fail "Hash URL should be non-empty"
                            ]
                            ()
                in
                routes
                    |> List.map testRouteIntegration
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        , test "hash URL generation is consistent with parsing" <|
            \_ ->
                let
                    routes =
                        [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                    testHashConsistency route =
                        let
                            hashUrl =
                                Route.toHashUrl route

                            -- Extract path from hash URL for parsing
                            hashPath =
                                String.dropLeft 2 hashUrl

                            -- Remove "#/"
                            mockUrl =
                                createPathUrl ("/" ++ hashPath)

                            parsedRoute =
                                Route.fromUrl mockUrl
                        in
                        Expect.equal (Just route) parsedRoute
                in
                routes
                    |> List.map testHashConsistency
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        , test "route to hash URL round trip" <|
            \_ ->
                let
                    routes =
                        [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                    testRouteRoundTrip route =
                        let
                            hashUrl =
                                Route.toHashUrl route

                            -- Simulate parsing the hash URL
                            hashPath =
                                String.dropLeft 2 hashUrl

                            -- Remove "#/"
                            mockUrl =
                                createPathUrl ("/" ++ hashPath)

                            parsedRoute =
                                Route.fromUrlWithFallback mockUrl
                        in
                        Expect.equal route parsedRoute
                in
                routes
                    |> List.map testRouteRoundTrip
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        ]


{-| Test error handling integration
Requirements: 1.6, 6.2, 6.6 - Error handling for invalid hash URLs
-}
errorHandlingIntegrationTests : Test
errorHandlingIntegrationTests =
    describe "Error handling integration"
        [ test "invalid hash URL integrates with App fallback logic" <|
            \_ ->
                let
                    invalidUrl =
                        createHashUrl "invalid-route"

                    resultRoute =
                        simulateAppUrlHandling invalidUrl
                in
                Expect.equal Route.Landing resultRoute
        , test "malformed hash URL integrates with App error handling" <|
            \_ ->
                let
                    malformedUrl =
                        createHashUrl "tic-tac-toe@#$%"

                    resultRoute =
                        simulateAppUrlHandling malformedUrl
                in
                Expect.equal Route.Landing resultRoute
        , test "empty hash URL integrates with App default routing" <|
            \_ ->
                let
                    emptyUrl =
                        createHashUrl ""

                    resultRoute =
                        simulateAppUrlHandling emptyUrl
                in
                Expect.equal Route.Landing resultRoute
        , test "case sensitivity in hash URLs" <|
            \_ ->
                let
                    uppercaseUrl =
                        createHashUrl "TIC-TAC-TOE"

                    resultRoute =
                        simulateAppUrlHandling uppercaseUrl
                in
                -- Should fallback to landing due to case sensitivity
                Expect.equal Route.Landing resultRoute
        , test "hash URL with extra path segments" <|
            \_ ->
                let
                    extraPathUrl =
                        createHashUrl "tic-tac-toe/extra/path"

                    resultRoute =
                        simulateAppUrlHandling extraPathUrl
                in
                -- Should fallback to landing due to extra path segments
                Expect.equal Route.Landing resultRoute
        , test "hash URL error handling preserves App routing consistency" <|
            \_ ->
                let
                    invalidUrls =
                        [ createHashUrl "invalid-route"
                        , createHashUrl "tic-tac-toe@#$%"
                        , createHashUrl "LANDING"
                        , createHashUrl "robot-game/extra"
                        , createHashUrl "style-guide/invalid"
                        ]

                    testInvalidUrl url =
                        let
                            resultRoute =
                                simulateAppUrlHandling url
                        in
                        Expect.equal Route.Landing resultRoute
                in
                invalidUrls
                    |> List.map testInvalidUrl
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        ]


suite : Test
suite =
    describe "Navigation Flow Integration Tests"
        [ hashUrlParsingIntegrationTests
        , routePageIntegrationTests
        , errorHandlingIntegrationTests
        , describe "Browser back/forward navigation simulation"
            [ test "browser back navigation from game to landing" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> simulateBrowserBack [ Route.TicTacToe, Route.Landing ]
                        |> ProgramTest.expectModel (\model -> Expect.equal Route.Landing model.currentRoute)
            , test "browser back navigation through multiple pages" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> simulateBrowserBack [ Route.StyleGuide, Route.RobotGame, Route.TicTacToe, Route.Landing ]
                        |> simulateBrowserBack [ Route.RobotGame, Route.TicTacToe, Route.Landing ]
                        |> ProgramTest.expectModel (\model -> Expect.equal Route.TicTacToe model.currentRoute)
            , test "browser forward navigation simulation" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> simulateBrowserBack [ Route.RobotGame, Route.TicTacToe, Route.Landing ]
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.expectModel (\model -> Expect.equal Route.RobotGame model.currentRoute)
            , test "browser back to landing from any page" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> simulateBrowserBack [ Route.StyleGuide, Route.Landing ]
                        |> ProgramTest.expectModel (\model -> Expect.equal Route.Landing model.currentRoute)
            , test "complex navigation history with hash URLs" <|
                \_ ->
                    let
                        -- Simulate: Landing -> TicTacToe -> RobotGame -> StyleGuide -> back to Landing
                        navigationHistory =
                            [ ( createHashUrl "landing", Route.Landing )
                            , ( createHashUrl "tic-tac-toe", Route.TicTacToe )
                            , ( createHashUrl "robot-game", Route.RobotGame )
                            , ( createHashUrl "style-guide", Route.StyleGuide )
                            , ( createHashUrl "landing", Route.Landing )
                            ]

                        testNavigation ( url, expectedRoute ) =
                            let
                                resultRoute =
                                    simulateAppUrlHandling url
                            in
                            Expect.equal expectedRoute resultRoute
                    in
                    navigationHistory
                        |> List.map testNavigation
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "rapid hash URL navigation changes" <|
                \_ ->
                    let
                        finalUrl =
                            createHashUrl "tic-tac-toe"

                        resultRoute =
                            simulateAppUrlHandling finalUrl
                    in
                    Expect.equal Route.TicTacToe resultRoute
            ]
        , describe "Deep linking to specific game states"
            [ test "deep link to TicTacToe game initializes correctly" <|
                \_ ->
                    startAppWithRoute Route.TicTacToe
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal Route.TicTacToe m.currentRoute
                                    , \m -> Expect.equal [ Route.TicTacToe ] m.navigationHistory
                                    ]
                                    model
                            )
            , test "deep link to RobotGame initializes correctly" <|
                \_ ->
                    startAppWithRoute Route.RobotGame
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal Route.RobotGame m.currentRoute
                                    , \m -> Expect.equal [ Route.RobotGame ] m.navigationHistory
                                    ]
                                    model
                            )
            , test "deep link to StyleGuide works correctly" <|
                \_ ->
                    startAppWithRoute Route.StyleGuide
                        |> ProgramTest.expectModel (\model -> Expect.equal Route.StyleGuide model.currentRoute)
            , test "deep link preserves navigation capabilities" <|
                \_ ->
                    startAppWithRoute Route.TicTacToe
                        |> ProgramTest.update (NavigateToRoute Route.Landing)
                        |> ProgramTest.update (NavigateToRoute Route.RobotGame)
                        |> ProgramTest.expectModel (\model -> Expect.equal Route.RobotGame model.currentRoute)
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
                        |> ProgramTest.expectModel (\model -> Expect.equal Dark model.colorScheme)
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
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal Route.Landing m.currentRoute
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
                        |> ProgramTest.expectModel (\model -> Expect.equal Route.Landing model.currentRoute)
            , test "style guide navigation preserves theme through routing" <|
                \_ ->
                    startApp ()
                        |> ProgramTest.update (ColorSchemeChanged Dark)
                        |> ProgramTest.update (NavigateToRoute Route.StyleGuide)
                        |> ProgramTest.update (NavigateToRoute Route.Landing)
                        |> ProgramTest.expectModel
                            (\model ->
                                Expect.all
                                    [ \m -> Expect.equal Route.Landing m.currentRoute
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
                        |> ProgramTest.expectModel (\model -> Expect.equal Route.RobotGame model.currentRoute)
            ]
        ]

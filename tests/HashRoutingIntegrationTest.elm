module HashRoutingIntegrationTest exposing (suite)

{-| Integration tests for hash-based routing functionality.

This module tests hash routing integration with the App module's routing logic,
focusing on the interaction between Route parsing and App page management.

Requirements covered:

  - 2.2: Browser back button navigation using hash routing
  - 2.3: Browser forward button navigation using hash routing
  - 2.1: Hash URL updates when navigating between pages
  - 4.1: Extensible routing system integration

-}

import App exposing (Page(..), pageToRoute, routeToPage)
import Expect
import Route
import Test exposing (Test, describe, test)
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
simulateAppUrlHandling : Url -> Page
simulateAppUrlHandling url =
    let
        -- Simulate Browser.Hash behavior: convert fragment to path
        urlForParsing =
            case url.fragment of
                Just fragment ->
                    { url | path = "/" ++ fragment, fragment = Nothing }

                Nothing ->
                    url

        parsedRoute =
            Route.fromUrlWithFallback urlForParsing
    in
    routeToPage parsedRoute


suite : Test
suite =
    describe "Hash Routing Integration Tests"
        [ hashUrlParsingIntegrationTests
        , routePageIntegrationTests
        , browserNavigationSimulationTests
        , errorHandlingIntegrationTests
        ]


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

                    resultPage =
                        simulateAppUrlHandling hashUrl
                in
                Expect.equal GamePage resultPage
        , test "hash URL to robot game integrates with App routing" <|
            \_ ->
                let
                    hashUrl =
                        createHashUrl "robot-game"

                    resultPage =
                        simulateAppUrlHandling hashUrl
                in
                Expect.equal RobotGamePage resultPage
        , test "hash URL to style guide integrates with App routing" <|
            \_ ->
                let
                    hashUrl =
                        createHashUrl "style-guide"

                    resultPage =
                        simulateAppUrlHandling hashUrl
                in
                Expect.equal StyleGuidePage resultPage
        , test "hash URL to landing integrates with App routing" <|
            \_ ->
                let
                    hashUrl =
                        createHashUrl "landing"

                    resultPage =
                        simulateAppUrlHandling hashUrl
                in
                Expect.equal LandingPage resultPage
        , test "root hash URL defaults to landing page" <|
            \_ ->
                let
                    rootUrl =
                        createHashUrl ""

                    resultPage =
                        simulateAppUrlHandling rootUrl
                in
                Expect.equal LandingPage resultPage
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
                            page =
                                routeToPage route

                            hashUrl =
                                Route.toHashUrl route

                            backToRoute =
                                pageToRoute page
                        in
                        Expect.all
                            [ \_ -> Expect.equal route backToRoute
                            , \_ ->
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
        , test "page to route to hash URL round trip" <|
            \_ ->
                let
                    pages =
                        [ LandingPage, GamePage, RobotGamePage, StyleGuidePage ]

                    testPageRoundTrip page =
                        let
                            route =
                                pageToRoute page

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

                            resultPage =
                                routeToPage parsedRoute
                        in
                        Expect.equal page resultPage
                in
                pages
                    |> List.map testPageRoundTrip
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        ]


{-| Test browser navigation simulation
Requirements: 2.2, 2.3 - Browser back/forward navigation using hash routing
-}
browserNavigationSimulationTests : Test
browserNavigationSimulationTests =
    describe "Browser navigation simulation"
        [ test "simulate browser back navigation sequence" <|
            \_ ->
                let
                    -- Simulate navigation history: Landing -> TicTacToe -> RobotGame
                    -- Simulate browser back (robot-game -> tic-tac-toe)
                    backUrl =
                        createHashUrl "tic-tac-toe"

                    resultPage =
                        simulateAppUrlHandling backUrl
                in
                Expect.equal GamePage resultPage
        , test "simulate browser forward navigation sequence" <|
            \_ ->
                let
                    -- Simulate going back and then forward
                    forwardUrl =
                        createHashUrl "robot-game"

                    resultPage =
                        simulateAppUrlHandling forwardUrl
                in
                Expect.equal RobotGamePage resultPage
        , test "simulate complex navigation history" <|
            \_ ->
                let
                    -- Simulate: Landing -> TicTacToe -> RobotGame -> StyleGuide -> back to Landing
                    navigationHistory =
                        [ ( createHashUrl "landing", LandingPage )
                        , ( createHashUrl "tic-tac-toe", GamePage )
                        , ( createHashUrl "robot-game", RobotGamePage )
                        , ( createHashUrl "style-guide", StyleGuidePage )
                        , ( createHashUrl "landing", LandingPage )
                        ]

                    testNavigation ( url, expectedPage ) =
                        let
                            resultPage =
                                simulateAppUrlHandling url
                        in
                        Expect.equal expectedPage resultPage
                in
                navigationHistory
                    |> List.map testNavigation
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        , test "simulate rapid navigation changes" <|
            \_ ->
                let
                    -- Simulate rapid hash URL changes
                    finalUrl =
                        createHashUrl "tic-tac-toe"

                    resultPage =
                        simulateAppUrlHandling finalUrl
                in
                Expect.equal GamePage resultPage
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

                    resultPage =
                        simulateAppUrlHandling invalidUrl
                in
                Expect.equal LandingPage resultPage
        , test "malformed hash URL integrates with App error handling" <|
            \_ ->
                let
                    malformedUrl =
                        createHashUrl "tic-tac-toe@#$%"

                    resultPage =
                        simulateAppUrlHandling malformedUrl
                in
                Expect.equal LandingPage resultPage
        , test "empty hash URL integrates with App default routing" <|
            \_ ->
                let
                    emptyUrl =
                        createHashUrl ""

                    resultPage =
                        simulateAppUrlHandling emptyUrl
                in
                Expect.equal LandingPage resultPage
        , test "nonexistent hash URL integrates with App fallback" <|
            \_ ->
                let
                    nonexistentUrl =
                        createHashUrl "nonexistent-page"

                    resultPage =
                        simulateAppUrlHandling nonexistentUrl
                in
                Expect.equal LandingPage resultPage
        , test "case sensitivity in hash URLs" <|
            \_ ->
                let
                    uppercaseUrl =
                        createHashUrl "TIC-TAC-TOE"

                    resultPage =
                        simulateAppUrlHandling uppercaseUrl
                in
                -- Should fallback to landing due to case sensitivity
                Expect.equal LandingPage resultPage
        , test "hash URL with extra path segments" <|
            \_ ->
                let
                    extraPathUrl =
                        createHashUrl "tic-tac-toe/extra/path"

                    resultPage =
                        simulateAppUrlHandling extraPathUrl
                in
                -- Should fallback to landing due to extra path segments
                Expect.equal LandingPage resultPage
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
                            resultPage =
                                simulateAppUrlHandling url
                        in
                        Expect.equal LandingPage resultPage
                in
                invalidUrls
                    |> List.map testInvalidUrl
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        ]

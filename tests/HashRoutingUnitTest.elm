module HashRoutingUnitTest exposing (suite)

{-| Hash routing verification tests.

This module contains tests to verify that hash routing works correctly,
covering direct hash URL access, bookmark functionality, and refresh behavior.

Requirements covered:

  - 1.1: Navigate directly to specific pages using hash URLs
  - 1.2: Direct access to landing page via hash URLs
  - 1.3: Direct access to tic-tac-toe page via hash URLs
  - 1.4: Direct access to robot game page via hash URLs
  - 1.5: Direct access to style guide page via hash URLs
  - 3.4: Current page determined from URL on refresh

This test module focuses on the production build requirements and verifies
that the built application handles hash routing correctly.

-}

import App exposing (Page(..), pageToRoute, routeToPage)
import Expect
import Route
import Test exposing (Test, describe, test)
import Url exposing (Url)


{-| Create a test URL with hash fragment for testing hash routing
-}
createHashUrl : String -> String -> Url
createHashUrl host hashFragment =
    { protocol = Url.Http
    , host = host
    , port_ = Just 3000
    , path = "/"
    , query = Nothing
    , fragment =
        if String.isEmpty hashFragment then
            Nothing

        else
            Just hashFragment
    }


{-| Simulate hash URL parsing with fallback
-}
simulateHashUrlParsingWithFallback : String -> Route.Route
simulateHashUrlParsingWithFallback hashFragment =
    let
        hashUrl =
            createHashUrl "localhost" hashFragment

        -- Simulate Browser.Hash behavior: convert hash fragment to path
        urlForParsing =
            case hashUrl.fragment of
                Just fragment ->
                    { hashUrl | path = "/" ++ fragment, fragment = Nothing }

                Nothing ->
                    hashUrl
    in
    Route.fromUrlWithFallback urlForParsing


suite : Test
suite =
    describe "Production Hash Routing Tests"
        [ directHashUrlAccessTests
        , bookmarkAndRefreshTests
        , hashUrlConsistencyTests
        , productionBuildSpecificTests
        ]


{-| Test direct hash URL access to all routes
Requirements: 1.1, 1.2, 1.3, 1.4, 1.5
-}
directHashUrlAccessTests : Test
directHashUrlAccessTests =
    describe "Direct hash URL access"
        [ test "direct access to landing page via root hash" <|
            \_ ->
                let
                    parsedRoute =
                        simulateHashUrlParsingWithFallback ""

                    resultPage =
                        routeToPage parsedRoute
                in
                Expect.all
                    [ \_ -> Expect.equal Route.Landing parsedRoute
                    , \_ -> Expect.equal LandingPage resultPage
                    ]
                    ()
        , test "direct access to landing page via #/landing" <|
            \_ ->
                let
                    parsedRoute =
                        simulateHashUrlParsingWithFallback "landing"

                    resultPage =
                        routeToPage parsedRoute
                in
                Expect.all
                    [ \_ -> Expect.equal Route.Landing parsedRoute
                    , \_ -> Expect.equal LandingPage resultPage
                    ]
                    ()
        , test "direct access to tic-tac-toe page via #/tic-tac-toe" <|
            \_ ->
                let
                    parsedRoute =
                        simulateHashUrlParsingWithFallback "tic-tac-toe"

                    resultPage =
                        routeToPage parsedRoute
                in
                Expect.all
                    [ \_ -> Expect.equal Route.TicTacToe parsedRoute
                    , \_ -> Expect.equal GamePage resultPage
                    ]
                    ()
        , test "direct access to robot game page via #/robot-game" <|
            \_ ->
                let
                    parsedRoute =
                        simulateHashUrlParsingWithFallback "robot-game"

                    resultPage =
                        routeToPage parsedRoute
                in
                Expect.all
                    [ \_ -> Expect.equal Route.RobotGame parsedRoute
                    , \_ -> Expect.equal RobotGamePage resultPage
                    ]
                    ()
        , test "direct access to style guide page via #/style-guide" <|
            \_ ->
                let
                    parsedRoute =
                        simulateHashUrlParsingWithFallback "style-guide"

                    resultPage =
                        routeToPage parsedRoute
                in
                Expect.all
                    [ \_ -> Expect.equal Route.StyleGuide parsedRoute
                    , \_ -> Expect.equal StyleGuidePage resultPage
                    ]
                    ()
        , test "invalid hash URL defaults to landing page" <|
            \_ ->
                let
                    parsedRoute =
                        simulateHashUrlParsingWithFallback "invalid-route"

                    resultPage =
                        routeToPage parsedRoute
                in
                Expect.all
                    [ \_ -> Expect.equal Route.Landing parsedRoute
                    , \_ -> Expect.equal LandingPage resultPage
                    ]
                    ()
        ]


{-| Test bookmark and refresh functionality
Requirements: 3.4 - Current page determined from URL on refresh
-}
bookmarkAndRefreshTests : Test
bookmarkAndRefreshTests =
    describe "Bookmark and refresh functionality"
        [ test "bookmarked tic-tac-toe hash URL loads correctly" <|
            \_ ->
                let
                    parsedRoute =
                        simulateHashUrlParsingWithFallback "tic-tac-toe"

                    resultPage =
                        routeToPage parsedRoute
                in
                Expect.all
                    [ \_ -> Expect.equal Route.TicTacToe parsedRoute
                    , \_ -> Expect.equal GamePage resultPage
                    ]
                    ()
        , test "bookmarked robot game hash URL loads correctly" <|
            \_ ->
                let
                    parsedRoute =
                        simulateHashUrlParsingWithFallback "robot-game"

                    resultPage =
                        routeToPage parsedRoute
                in
                Expect.all
                    [ \_ -> Expect.equal Route.RobotGame parsedRoute
                    , \_ -> Expect.equal RobotGamePage resultPage
                    ]
                    ()
        , test "bookmarked style guide hash URL loads correctly" <|
            \_ ->
                let
                    parsedRoute =
                        simulateHashUrlParsingWithFallback "style-guide"

                    resultPage =
                        routeToPage parsedRoute
                in
                Expect.all
                    [ \_ -> Expect.equal Route.StyleGuide parsedRoute
                    , \_ -> Expect.equal StyleGuidePage resultPage
                    ]
                    ()
        , test "refresh on landing page maintains correct route" <|
            \_ ->
                let
                    parsedRoute =
                        simulateHashUrlParsingWithFallback "landing"

                    resultPage =
                        routeToPage parsedRoute
                in
                Expect.all
                    [ \_ -> Expect.equal Route.Landing parsedRoute
                    , \_ -> Expect.equal LandingPage resultPage
                    ]
                    ()
        , test "malformed bookmark URL falls back to landing" <|
            \_ ->
                let
                    parsedRoute =
                        simulateHashUrlParsingWithFallback "tic-tac-toe/invalid/path"

                    resultPage =
                        routeToPage parsedRoute
                in
                Expect.all
                    [ \_ -> Expect.equal Route.Landing parsedRoute
                    , \_ -> Expect.equal LandingPage resultPage
                    ]
                    ()
        ]


{-| Test hash URL consistency in production build
Requirements: 1.1 - Navigate directly to specific pages using hash URLs
-}
hashUrlConsistencyTests : Test
hashUrlConsistencyTests =
    describe "Hash URL consistency"
        [ test "hash URL format is consistent across all routes" <|
            \_ ->
                let
                    routes =
                        [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                    testHashFormat route =
                        let
                            hashUrl =
                                Route.toHashUrl route
                        in
                        Expect.all
                            [ \url ->
                                if String.startsWith "#/" url then
                                    Expect.pass

                                else
                                    Expect.fail ("Hash URL should start with #/: " ++ url)
                            , \url ->
                                if String.length url > 2 then
                                    Expect.pass

                                else
                                    Expect.fail ("Hash URL should not be empty: " ++ url)
                            , \url ->
                                if not (String.contains " " url) then
                                    Expect.pass

                                else
                                    Expect.fail ("Hash URL should not contain spaces: " ++ url)
                            ]
                            hashUrl
                in
                routes
                    |> List.map testHashFormat
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        , test "route conversion maintains consistency" <|
            \_ ->
                let
                    pages =
                        [ LandingPage, GamePage, RobotGamePage, StyleGuidePage ]

                    testRouteConversion page =
                        let
                            route =
                                pageToRoute page

                            backToPage =
                                routeToPage route
                        in
                        Expect.equal page backToPage
                in
                pages
                    |> List.map testRouteConversion
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        , test "hash URL round trip consistency" <|
            \_ ->
                let
                    routes =
                        [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                    testRoundTrip route =
                        let
                            hashUrl =
                                Route.toHashUrl route

                            -- Extract fragment from hash URL (remove #/)
                            fragment =
                                String.dropLeft 2 hashUrl

                            parsedRoute =
                                simulateHashUrlParsingWithFallback fragment
                        in
                        Expect.equal route parsedRoute
                in
                routes
                    |> List.map testRoundTrip
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        ]


{-| Test production build specific functionality
Requirements: All requirements in production environment
-}
productionBuildSpecificTests : Test
productionBuildSpecificTests =
    describe "Production build specific tests"
        [ test "error handling works correctly" <|
            \_ ->
                let
                    invalidRoutes =
                        [ "completely-invalid-route-12345"
                        , "TIC-TAC-TOE" -- case sensitivity
                        , "tic-tac-toe/extra/path" -- extra path segments
                        , "robot-game@#$%" -- special characters
                        ]

                    testInvalidRoute fragment =
                        let
                            parsedRoute =
                                simulateHashUrlParsingWithFallback fragment

                            resultPage =
                                routeToPage parsedRoute
                        in
                        Expect.all
                            [ \_ -> Expect.equal Route.Landing parsedRoute
                            , \_ -> Expect.equal LandingPage resultPage
                            ]
                            ()
                in
                invalidRoutes
                    |> List.map testInvalidRoute
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        , test "case sensitivity is enforced" <|
            \_ ->
                let
                    caseSensitiveTests =
                        [ "TIC-TAC-TOE"
                        , "ROBOT-GAME"
                        , "STYLE-GUIDE"
                        , "LANDING"
                        ]

                    testCaseSensitivity fragment =
                        let
                            parsedRoute =
                                simulateHashUrlParsingWithFallback fragment
                        in
                        -- Should fallback to landing due to case sensitivity
                        Expect.equal Route.Landing parsedRoute
                in
                caseSensitiveTests
                    |> List.map testCaseSensitivity
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        , test "special characters in hash URLs are handled" <|
            \_ ->
                let
                    specialCharTests =
                        [ "tic-tac-toe@#$%"
                        , "robot-game/../../../etc/passwd"
                        , "landing%20with%20encoded%20spaces"
                        , "style-guide?param=value&redirect=evil"
                        ]

                    testSpecialChars fragment =
                        let
                            parsedRoute =
                                simulateHashUrlParsingWithFallback fragment
                        in
                        -- Should fallback to landing due to invalid characters
                        Expect.equal Route.Landing parsedRoute
                in
                specialCharTests
                    |> List.map testSpecialChars
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        , test "empty and root hash URLs work correctly" <|
            \_ ->
                let
                    rootTests =
                        [ "" -- empty hash
                        , "/" -- just slash
                        ]

                    testRootUrl fragment =
                        let
                            parsedRoute =
                                simulateHashUrlParsingWithFallback fragment

                            resultPage =
                                routeToPage parsedRoute
                        in
                        Expect.all
                            [ \_ -> Expect.equal Route.Landing parsedRoute
                            , \_ -> Expect.equal LandingPage resultPage
                            ]
                            ()
                in
                rootTests
                    |> List.map testRootUrl
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        ]

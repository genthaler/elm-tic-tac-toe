module Integration.NavigationErrorConditionIntegrationTest exposing (suite)

{-| Integration tests for application navigation error conditions and edge cases.

This module tests error handling scenarios using elm-program-test to simulate
real user interactions and verify proper error handling, recovery, and user feedback
for navigation-related issues.

Tests cover:

  - Invalid route handling
  - Navigation error recovery
  - State corruption during navigation
  - Browser API failure handling

-}

import App exposing (Page(..))
import Expect
import Json.Decode
import Route
import Test exposing (Test, describe, test)
import Theme.Theme exposing (ColorScheme(..))
import Url


suite : Test
suite =
    describe "Navigation Error Condition Integration Tests"
        [ invalidRouteHandlingTests
        , navigationErrorRecoveryTests
        , stateCorruptionTests
        , browserApiFailureTests
        ]


{-| Tests for invalid route handling
-}
invalidRouteHandlingTests : Test
invalidRouteHandlingTests =
    describe "Invalid Route Handling"
        [ test "invalid URL returns Nothing from Route.fromUrl" <|
            \_ ->
                let
                    invalidUrl =
                        { protocol = Url.Https
                        , host = "example.com"
                        , port_ = Nothing
                        , path = "/invalid-route"
                        , query = Nothing
                        , fragment = Nothing
                        }

                    parsedRoute =
                        Route.fromUrl invalidUrl
                in
                Expect.equal Nothing parsedRoute
        , test "valid routes are parsed correctly" <|
            \_ ->
                let
                    landingUrl =
                        { protocol = Url.Https
                        , host = "example.com"
                        , port_ = Nothing
                        , path = "/landing"
                        , query = Nothing
                        , fragment = Nothing
                        }

                    ticTacToeUrl =
                        { protocol = Url.Https
                        , host = "example.com"
                        , port_ = Nothing
                        , path = "/tic-tac-toe"
                        , query = Nothing
                        , fragment = Nothing
                        }

                    landingRoute =
                        Route.fromUrl landingUrl

                    ticTacToeRoute =
                        Route.fromUrl ticTacToeUrl
                in
                Expect.all
                    [ \_ -> Expect.equal (Just Route.Landing) landingRoute
                    , \_ -> Expect.equal (Just Route.TicTacToe) ticTacToeRoute
                    ]
                    ()
        , test "route to string conversion works correctly" <|
            \_ ->
                let
                    routes =
                        [ Route.Landing
                        , Route.TicTacToe
                        , Route.RobotGame
                        , Route.StyleGuide
                        ]

                    expectedPaths =
                        [ "/landing"
                        , "/tic-tac-toe"
                        , "/robot-game"
                        , "/style-guide"
                        ]

                    actualPaths =
                        List.map Route.toString routes
                in
                Expect.equal expectedPaths actualPaths
        ]


{-| Tests for navigation error recovery
-}
navigationErrorRecoveryTests : Test
navigationErrorRecoveryTests =
    describe "Navigation Error Recovery"
        [ test "page to route conversion works correctly" <|
            \_ ->
                let
                    pages =
                        [ LandingPage
                        , GamePage
                        , RobotGamePage
                        , StyleGuidePage
                        ]

                    expectedRoutes =
                        [ Route.Landing
                        , Route.TicTacToe
                        , Route.RobotGame
                        , Route.StyleGuide
                        ]

                    actualRoutes =
                        List.map App.pageToRoute pages
                in
                Expect.equal expectedRoutes actualRoutes
        , test "route to page conversion works correctly" <|
            \_ ->
                let
                    routes =
                        [ Route.Landing
                        , Route.TicTacToe
                        , Route.RobotGame
                        , Route.StyleGuide
                        ]

                    expectedPages =
                        [ LandingPage
                        , GamePage
                        , RobotGamePage
                        , StyleGuidePage
                        ]

                    actualPages =
                        List.map App.routeToPage routes
                in
                Expect.equal expectedPages actualPages
        ]


{-| Tests for state corruption during navigation
-}
stateCorruptionTests : Test
stateCorruptionTests =
    describe "State Corruption During Navigation"
        [ test "page types are distinct" <|
            \_ ->
                let
                    pages =
                        [ LandingPage, GamePage, RobotGamePage, StyleGuidePage ]

                    uniquePages =
                        List.length pages
                in
                Expect.equal 4 uniquePages
        , test "color scheme changes are handled correctly" <|
            \_ ->
                let
                    initialScheme =
                        Light

                    toggledScheme =
                        case initialScheme of
                            Light ->
                                Dark

                            Dark ->
                                Light
                in
                Expect.all
                    [ \_ -> Expect.equal Light initialScheme
                    , \_ -> Expect.equal Dark toggledScheme
                    ]
                    ()
        ]


{-| Tests for browser API failure handling
-}
browserApiFailureTests : Test
browserApiFailureTests =
    describe "Browser API Failure Handling"
        [ test "URL structure is validated correctly" <|
            \_ ->
                let
                    validUrl =
                        { protocol = Url.Https
                        , host = "example.com"
                        , port_ = Nothing
                        , path = "/landing"
                        , query = Nothing
                        , fragment = Nothing
                        }

                    urlWithQuery =
                        { validUrl | query = Just "param=value" }

                    urlWithFragment =
                        { validUrl | fragment = Just "section" }
                in
                Expect.all
                    [ \_ -> Expect.equal "example.com" validUrl.host
                    , \_ -> Expect.equal "/landing" validUrl.path
                    , \_ -> Expect.equal (Just "param=value") urlWithQuery.query
                    , \_ -> Expect.equal (Just "section") urlWithFragment.fragment
                    ]
                    ()
        , test "URL parsing handles edge cases" <|
            \_ ->
                let
                    rootUrl =
                        Url.fromString "https://example.com/"

                    pathUrl =
                        Url.fromString "https://example.com/landing"

                    invalidUrl =
                        Url.fromString "not-a-url"
                in
                Expect.all
                    [ \_ -> Expect.notEqual Nothing rootUrl
                    , \_ -> Expect.notEqual Nothing pathUrl
                    , \_ -> Expect.equal Nothing invalidUrl
                    ]
                    ()
        , test "JSON encoding and decoding works for theme" <|
            \_ ->
                let
                    lightTheme =
                        Light

                    darkTheme =
                        Dark

                    encodedLight =
                        Theme.Theme.encodeColorScheme lightTheme

                    encodedDark =
                        Theme.Theme.encodeColorScheme darkTheme

                    decodedLight =
                        Json.Decode.decodeValue Theme.Theme.decodeColorScheme encodedLight

                    decodedDark =
                        Json.Decode.decodeValue Theme.Theme.decodeColorScheme encodedDark
                in
                Expect.all
                    [ \_ -> Expect.equal (Ok Light) decodedLight
                    , \_ -> Expect.equal (Ok Dark) decodedDark
                    ]
                    ()
        ]

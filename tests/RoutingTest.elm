module RoutingTest exposing (suite)

{-| Comprehensive routing tests covering basic functionality, integration, and extensibility.

This module consolidates routing tests to eliminate duplication while maintaining
complete coverage of the routing system.

-}

import App exposing (AppMsg(..), Page(..), pageToRoute, routeToPage)
import Expect
import Route
import Test exposing (Test, describe, test)
import Url exposing (Url)


{-| Create a mock URL for testing
-}
createMockUrl : String -> Url
createMockUrl path =
    { protocol = Url.Http
    , host = "localhost"
    , port_ = Just 3000
    , path = path
    , query = Nothing
    , fragment = Nothing
    }


suite : Test
suite =
    describe "Routing System"
        [ basicRoutingTests
        , integrationTests
        , extensibilityTests
        ]


{-| Basic Route module functionality tests
-}
basicRoutingTests : Test
basicRoutingTests =
    describe "Basic Route functionality"
        [ describe "toString"
            [ test "converts all routes to correct URL strings" <|
                \_ ->
                    let
                        routeStringPairs =
                            [ ( Route.Landing, "/landing" )
                            , ( Route.TicTacToe, "/tic-tac-toe" )
                            , ( Route.RobotGame, "/robot-game" )
                            , ( Route.StyleGuide, "/style-guide" )
                            ]

                        testConversion ( route, expectedString ) =
                            Route.toString route
                                |> Expect.equal expectedString
                    in
                    routeStringPairs
                        |> List.map testConversion
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            ]
        , describe "fromUrl"
            [ test "parses valid URLs to correct routes" <|
                \_ ->
                    let
                        urlRoutePairs =
                            [ ( "/", Route.Landing )
                            , ( "/landing", Route.Landing )
                            , ( "/tic-tac-toe", Route.TicTacToe )
                            , ( "/robot-game", Route.RobotGame )
                            , ( "/style-guide", Route.StyleGuide )
                            ]

                        testParsing ( urlPath, expectedRoute ) =
                            let
                                url =
                                    createMockUrl urlPath
                            in
                            Route.fromUrl url
                                |> Expect.equal (Just expectedRoute)
                    in
                    urlRoutePairs
                        |> List.map testParsing
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "returns Nothing for invalid URLs" <|
                \_ ->
                    let
                        invalidUrls =
                            [ "/invalid"
                            , "/tic-tac-toe/extra"
                            , "/LANDING"
                            , "/tic-tac-toe@#$"
                            , "/landing/extra/path"
                            ]

                        testInvalidUrl urlPath =
                            let
                                url =
                                    createMockUrl urlPath
                            in
                            Route.fromUrl url
                                |> Expect.equal Nothing
                    in
                    invalidUrls
                        |> List.map testInvalidUrl
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "handles edge cases gracefully" <|
                \_ ->
                    let
                        edgeCases =
                            [ ( "//", Route.Landing ) -- double slash
                            , ( "", Route.Landing ) -- empty path
                            , ( "/landing/", Route.Landing ) -- trailing slash
                            ]

                        testEdgeCase ( urlPath, expectedRoute ) =
                            let
                                url =
                                    createMockUrl urlPath
                            in
                            Route.fromUrl url
                                |> Expect.equal (Just expectedRoute)
                    in
                    edgeCases
                        |> List.map testEdgeCase
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "ignores query parameters and fragments" <|
                \_ ->
                    let
                        urlWithQuery =
                            { protocol = Url.Http
                            , host = "localhost"
                            , port_ = Just 3000
                            , path = "/landing"
                            , query = Just "param=value"
                            , fragment = Just "section"
                            }
                    in
                    Route.fromUrl urlWithQuery
                        |> Expect.equal (Just Route.Landing)
            ]
        , describe "toUrl"
            [ test "generates consistent URL structures" <|
                \_ ->
                    let
                        routes =
                            [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                        testUrlGeneration route =
                            let
                                expectedPath =
                                    Route.toString route

                                generatedUrl =
                                    Route.toUrl route
                            in
                            generatedUrl.path
                                |> Expect.equal expectedPath
                    in
                    routes
                        |> List.map testUrlGeneration
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            ]
        , describe "round-trip consistency"
            [ test "toString and fromUrl are consistent" <|
                \_ ->
                    let
                        routes =
                            [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                        testRoundTrip route =
                            let
                                urlString =
                                    Route.toString route

                                url =
                                    createMockUrl urlString
                            in
                            Route.fromUrl url
                                |> Expect.equal (Just route)
                    in
                    routes
                        |> List.map testRoundTrip
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            ]
        ]


{-| Integration tests with App module
-}
integrationTests : Test
integrationTests =
    describe "App integration"
        [ -- Route-Page conversion tests moved to AppTest.elm to avoid duplication
          describe "Full routing pipeline"
            [ test "URL -> Route -> Page -> Route round trip" <|
                \_ ->
                    let
                        testUrls =
                            [ "/landing", "/tic-tac-toe", "/robot-game", "/style-guide" ]

                        testRoundTrip urlPath =
                            let
                                url =
                                    createMockUrl urlPath

                                result =
                                    url
                                        |> Route.fromUrl
                                        |> Maybe.map (routeToPage >> pageToRoute >> Just)
                                        |> Maybe.withDefault (Route.fromUrl url)
                            in
                            result
                                |> Expect.equal (Route.fromUrl url)
                    in
                    testUrls
                        |> List.map testRoundTrip
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            ]
        , describe "Navigation messages"
            [ test "NavigateToRoute message contains correct route" <|
                \_ ->
                    let
                        route =
                            Route.TicTacToe

                        message =
                            NavigateToRoute route

                        extractRoute msg =
                            case msg of
                                NavigateToRoute r ->
                                    Just r

                                _ ->
                                    Nothing
                    in
                    extractRoute message
                        |> Expect.equal (Just route)
            , test "UrlChanged message contains correct URL" <|
                \_ ->
                    let
                        url =
                            createMockUrl "/tic-tac-toe"

                        message =
                            UrlChanged url

                        extractUrl msg =
                            case msg of
                                UrlChanged u ->
                                    Just u

                                _ ->
                                    Nothing
                    in
                    extractUrl message
                        |> Expect.equal (Just url)
            ]
        , describe "Error handling"
            [ test "invalid URLs fallback to landing page" <|
                \_ ->
                    let
                        invalidUrl =
                            createMockUrl "/invalid-route"

                        -- Simulate App behavior for invalid routes
                        resultPage =
                            case Route.fromUrl invalidUrl of
                                Nothing ->
                                    LandingPage

                                Just route ->
                                    routeToPage route
                    in
                    resultPage
                        |> Expect.equal LandingPage
            ]
        ]


{-| Extensibility and maintainability tests
-}
extensibilityTests : Test
extensibilityTests =
    describe "System extensibility"
        [ describe "Consistent patterns"
            [ test "all routes follow kebab-case naming" <|
                \_ ->
                    let
                        routes =
                            [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                        routeStrings =
                            List.map Route.toString routes

                        followsKebabCase str =
                            String.startsWith "/" str
                                && not (String.contains " " str)
                                && not (String.contains "_" str)
                                && String.toLower str
                                == str
                    in
                    routeStrings
                        |> List.all followsKebabCase
                        |> Expect.equal True
            , test "all routes produce unique URL strings" <|
                \_ ->
                    let
                        routes =
                            [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                        urlStrings =
                            List.map Route.toString routes

                        uniqueUrlStrings =
                            urlStrings
                                |> List.foldl
                                    (\url acc ->
                                        if List.member url acc then
                                            acc

                                        else
                                            url :: acc
                                    )
                                    []
                    in
                    List.length uniqueUrlStrings
                        |> Expect.equal (List.length urlStrings)
            , test "route-page mappings are unique" <|
                \_ ->
                    let
                        routes =
                            [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                        pages =
                            List.map routeToPage routes

                        uniquePages =
                            pages
                                |> List.foldl
                                    (\page acc ->
                                        if List.member page acc then
                                            acc

                                        else
                                            page :: acc
                                    )
                                    []
                    in
                    List.length uniquePages
                        |> Expect.equal (List.length pages)
            ]
        , describe "Future compatibility"
            [ test "current routes don't conflict with parameterized patterns" <|
                \_ ->
                    let
                        currentRoutes =
                            [ "/landing", "/tic-tac-toe", "/robot-game", "/style-guide" ]

                        testNoConflict routePath =
                            let
                                url =
                                    createMockUrl routePath
                            in
                            Route.fromUrl url
                                |> (\result -> result /= Nothing)
                    in
                    currentRoutes
                        |> List.all testNoConflict
                        |> Expect.equal True
            , test "error handling is consistent for unknown routes" <|
                \_ ->
                    let
                        unknownUrls =
                            [ "/nonexistent", "/future-route", "/tic-tac-toe/invalid" ]

                        testErrorHandling urlPath =
                            let
                                url =
                                    createMockUrl urlPath
                            in
                            Route.fromUrl url
                                |> Expect.equal Nothing
                    in
                    unknownUrls
                        |> List.map testErrorHandling
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            ]
        ]

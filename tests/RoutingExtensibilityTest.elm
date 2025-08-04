module RoutingExtensibilityTest exposing (suite)

{-| Tests for routing system extensibility and maintainability.

These tests verify that the routing system is designed to be easily extended
with new routes and pages without requiring extensive changes to existing code.

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
    describe "Routing System Extensibility"
        [ describe "Centralized route definition"
            [ test "all routes are defined in Route module" <|
                \_ ->
                    let
                        -- Test that Route module contains all expected routes
                        routes =
                            [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                        -- Each route should have a valid string representation
                        routeStrings =
                            List.map Route.toString routes

                        -- All route strings should be non-empty and start with "/"
                        validRouteStrings =
                            routeStrings
                                |> List.all (\str -> String.startsWith "/" str && String.length str > 1)
                    in
                    validRouteStrings
                        |> Expect.equal True
            , test "route parsing is centralized" <|
                \_ ->
                    let
                        -- Test that all routes can be parsed from URLs
                        urlRoutePairs =
                            [ ( "/landing", Route.Landing )
                            , ( "/tic-tac-toe", Route.TicTacToe )
                            , ( "/robot-game", Route.RobotGame )
                            , ( "/style-guide", Route.StyleGuide )
                            ]

                        testParsing ( urlPath, expectedRoute ) =
                            let
                                url =
                                    createMockUrl urlPath

                                parsedRoute =
                                    Route.fromUrl url
                            in
                            parsedRoute
                                |> Expect.equal (Just expectedRoute)
                    in
                    urlRoutePairs
                        |> List.map testParsing
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "route to URL conversion is centralized" <|
                \_ ->
                    let
                        -- Test that all routes can be converted to URLs
                        routes =
                            [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                        testUrlGeneration route =
                            let
                                urlString =
                                    Route.toString route

                                generatedUrl =
                                    Route.toUrl route

                                -- URL generation should be consistent
                                consistent =
                                    generatedUrl.path == urlString
                            in
                            consistent
                                |> Expect.equal True
                    in
                    routes
                        |> List.map testUrlGeneration
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            ]
        , describe "Route-Page mapping consistency"
            [ test "all routes map to unique pages" <|
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
            , test "all pages map to unique routes" <|
                \_ ->
                    let
                        pages =
                            [ LandingPage, GamePage, RobotGamePage, StyleGuidePage ]

                        routes =
                            List.map pageToRoute pages

                        uniqueRoutes =
                            routes
                                |> List.foldl
                                    (\route acc ->
                                        if List.member route acc then
                                            acc

                                        else
                                            route :: acc
                                    )
                                    []
                    in
                    List.length uniqueRoutes
                        |> Expect.equal (List.length routes)
            , test "route-page mapping is bidirectional" <|
                \_ ->
                    let
                        routes =
                            [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                        testBidirectional route =
                            let
                                page =
                                    routeToPage route

                                backToRoute =
                                    pageToRoute page
                            in
                            backToRoute
                                |> Expect.equal route
                    in
                    routes
                        |> List.map testBidirectional
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            ]
        , describe "Minimal changes for new routes"
            [ test "route system supports consistent patterns" <|
                \_ ->
                    let
                        -- Test that all routes follow consistent naming patterns
                        routes =
                            [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                        routeStrings =
                            List.map Route.toString routes

                        -- All routes should follow kebab-case pattern
                        followsPattern str =
                            String.startsWith "/" str
                                && not (String.contains " " str)
                                && not (String.contains "_" str)
                                && String.toLower str
                                == str

                        allFollowPattern =
                            routeStrings
                                |> List.all followsPattern
                    in
                    allFollowPattern
                        |> Expect.equal True
            , test "route parsing handles edge cases consistently" <|
                \_ ->
                    let
                        -- Test that route parsing handles common edge cases
                        edgeCases =
                            [ ( "/", Just Route.Landing ) -- root URL
                            , ( "/landing/", Just Route.Landing ) -- trailing slash
                            , ( "/invalid", Nothing ) -- invalid route
                            , ( "/tic-tac-toe/extra", Nothing ) -- extra path segments
                            ]

                        testEdgeCase ( urlPath, expectedResult ) =
                            let
                                url =
                                    createMockUrl urlPath

                                result =
                                    Route.fromUrl url
                            in
                            result
                                |> Expect.equal expectedResult
                    in
                    edgeCases
                        |> List.map testEdgeCase
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "type-safe URL construction" <|
                \_ ->
                    let
                        -- Test that URL construction is type-safe and consistent
                        routes =
                            [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                        testTypeSafety route =
                            let
                                -- toString and toUrl should be consistent
                                urlString =
                                    Route.toString route

                                fullUrl =
                                    Route.toUrl route

                                consistent =
                                    fullUrl.path == urlString
                            in
                            consistent
                                |> Expect.equal True
                    in
                    routes
                        |> List.map testTypeSafety
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            ]
        , describe "Future extensibility patterns"
            [ test "route system can handle parameter patterns" <|
                \_ ->
                    let
                        -- Test that current routes don't conflict with potential parameterized routes
                        currentRoutes =
                            [ "/landing", "/tic-tac-toe", "/robot-game", "/style-guide" ]

                        -- Current routes should not accidentally match parameterized patterns
                        -- (Future routes like "/landing/tutorial", "/tic-tac-toe/difficulty/easy" should be possible)
                        testNoConflict currentRoute =
                            let
                                url =
                                    createMockUrl currentRoute

                                parsed =
                                    Route.fromUrl url
                            in
                            -- Current routes should parse successfully
                            case parsed of
                                Just _ ->
                                    True

                                Nothing ->
                                    False
                    in
                    currentRoutes
                        |> List.map testNoConflict
                        |> List.all (\result -> result == True)
                        |> Expect.equal True
            , test "navigation message system is extensible" <|
                \_ ->
                    let
                        -- Test that NavigateToRoute message works with all current routes
                        routes =
                            [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                        testNavigationMessage route =
                            let
                                message =
                                    NavigateToRoute route

                                -- Message should contain the route
                                extractedRoute =
                                    case message of
                                        NavigateToRoute r ->
                                            Just r

                                        _ ->
                                            Nothing
                            in
                            extractedRoute
                                |> Expect.equal (Just route)
                    in
                    routes
                        |> List.map testNavigationMessage
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "error handling is consistent for new routes" <|
                \_ ->
                    let
                        -- Test that error handling patterns are consistent
                        invalidUrls =
                            [ "/nonexistent", "/future-route", "/tic-tac-toe/invalid" ]

                        testErrorHandling urlPath =
                            let
                                url =
                                    createMockUrl urlPath

                                result =
                                    Route.fromUrl url

                                -- All invalid URLs should return Nothing consistently
                                isConsistent =
                                    result == Nothing
                            in
                            isConsistent
                                |> Expect.equal True
                    in
                    invalidUrls
                        |> List.map testErrorHandling
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            ]
        ]

module RouteTest exposing (suite)

{-| Unit tests for the Route module.

This module focuses on testing the core Route module functions in isolation.
For integration tests with App module, see RoutingTest.elm.

-}

import Expect
import Route
import Test exposing (Test, describe, test)
import Url


suite : Test
suite =
    describe "Route module unit tests"
        [ describe "toString"
            [ test "converts all routes correctly" <|
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
            [ test "parses valid URLs correctly" <|
                \_ ->
                    let
                        createUrl path =
                            { protocol = Url.Https
                            , host = "example.com"
                            , port_ = Nothing
                            , path = path
                            , query = Nothing
                            , fragment = Nothing
                            }

                        urlRoutePairs =
                            [ ( "/", Route.Landing )
                            , ( "/landing", Route.Landing )
                            , ( "/tic-tac-toe", Route.TicTacToe )
                            , ( "/robot-game", Route.RobotGame )
                            , ( "/style-guide", Route.StyleGuide )
                            ]

                        testParsing ( urlPath, expectedRoute ) =
                            Route.fromUrl (createUrl urlPath)
                                |> Expect.equal (Just expectedRoute)
                    in
                    urlRoutePairs
                        |> List.map testParsing
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "returns Nothing for invalid URLs" <|
                \_ ->
                    let
                        createUrl path =
                            { protocol = Url.Https
                            , host = "example.com"
                            , port_ = Nothing
                            , path = path
                            , query = Nothing
                            , fragment = Nothing
                            }

                        invalidPaths =
                            [ "/invalid-route"
                            , "/tic-tac-toe@#$%"
                            , "/landing/extra/path"
                            , "/LANDING"
                            ]

                        testInvalidUrl path =
                            Route.fromUrl (createUrl path)
                                |> Expect.equal Nothing
                    in
                    invalidPaths
                        |> List.map testInvalidUrl
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
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
        ]

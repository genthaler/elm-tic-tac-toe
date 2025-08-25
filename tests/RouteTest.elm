module RouteTest exposing (suite)

{-| Comprehensive unit tests for the Route module hash routing functionality.

This module focuses on testing the core Route module functions in isolation,
with emphasis on hash URL parsing and generation as required for hash-based routing.

For integration tests with App module, see RoutingTest.elm and HashNavigationIntegrationTest.elm.

Requirements covered:

  - 4.1: Extensible routing system with centralized route definition
  - 4.2: Centralized route definition
  - 4.3: Reliable hash URL parsing
  - 4.4: Type-safe URL construction helper functions

-}

import Expect
import Route
import Test exposing (Test, describe, test)
import Url


suite : Test
suite =
    describe "Route module comprehensive hash routing tests"
        [ hashUrlParsingTests
        , hashUrlGenerationTests
        , routeConversionTests
        , errorHandlingTests
        , roundTripConsistencyTests
        ]


{-| Test hash URL parsing functionality
Requirements: 4.3 - Reliable hash URL parsing
-}
hashUrlParsingTests : Test
hashUrlParsingTests =
    describe "Hash URL parsing"
        [ test "parses all valid hash URLs correctly" <|
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
        , test "handles hash URL edge cases" <|
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

                    edgeCases =
                        [ ( "", Route.Landing ) -- empty path
                        , ( "/", Route.Landing ) -- root path
                        , ( "//", Route.Landing ) -- double slash
                        ]

                    testEdgeCase ( urlPath, expectedRoute ) =
                        Route.fromUrl (createUrl urlPath)
                            |> Expect.equal (Just expectedRoute)
                in
                edgeCases
                    |> List.map testEdgeCase
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        , test "ignores query parameters and fragments in hash URLs" <|
            \_ ->
                let
                    urlWithQueryAndFragment =
                        { protocol = Url.Https
                        , host = "example.com"
                        , port_ = Nothing
                        , path = "/tic-tac-toe"
                        , query = Just "param=value&other=test"
                        , fragment = Just "section"
                        }
                in
                Route.fromUrl urlWithQueryAndFragment
                    |> Expect.equal (Just Route.TicTacToe)
        , test "returns Nothing for invalid hash URLs" <|
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
                        , "/LANDING" -- case sensitive
                        , "/tic-tac-toe/subpath"
                        , "/robot-game/invalid"
                        , "/style-guide/extra"
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


{-| Test hash URL generation functionality
Requirements: 4.4 - Type-safe URL construction helper functions
-}
hashUrlGenerationTests : Test
hashUrlGenerationTests =
    describe "Hash URL generation"
        [ test "generates correct hash URLs for all routes" <|
            \_ ->
                let
                    routeHashPairs =
                        [ ( Route.Landing, "#/landing" )
                        , ( Route.TicTacToe, "#/tic-tac-toe" )
                        , ( Route.RobotGame, "#/robot-game" )
                        , ( Route.StyleGuide, "#/style-guide" )
                        ]

                    testHashGeneration ( route, expectedHash ) =
                        Route.toHashUrl route
                            |> Expect.equal expectedHash
                in
                routeHashPairs
                    |> List.map testHashGeneration
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        , test "hash URLs follow consistent format" <|
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
                                    Expect.fail "Hash URL should start with #/"
                            , \url ->
                                if String.contains " " url then
                                    Expect.fail "Hash URL should not contain spaces"

                                else
                                    Expect.pass
                            , \url ->
                                if String.any Char.isUpper url then
                                    Expect.fail "Hash URL should not contain uppercase"

                                else
                                    Expect.pass
                            , \url ->
                                if String.length url > 2 then
                                    Expect.pass

                                else
                                    Expect.fail "Hash URL should be non-empty"
                            ]
                            hashUrl
                in
                routes
                    |> List.map testHashFormat
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        , test "hash URLs are unique for each route" <|
            \_ ->
                let
                    routes =
                        [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                    hashUrls =
                        List.map Route.toHashUrl routes

                    uniqueHashUrls =
                        hashUrls
                            |> List.foldl
                                (\url acc ->
                                    if List.member url acc then
                                        acc

                                    else
                                        url :: acc
                                )
                                []
                in
                List.length uniqueHashUrls
                    |> Expect.equal (List.length hashUrls)
        ]


{-| Test route conversion functions
Requirements: 4.2 - Centralized route definition
-}
routeConversionTests : Test
routeConversionTests =
    describe "Route conversion functions"
        [ test "toString converts all routes correctly" <|
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
        , test "toUrl generates consistent URL structures" <|
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
        , test "all routes follow kebab-case naming convention" <|
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
        ]


{-| Test error handling and fallback behavior
Requirements: 1.6 - Invalid hash URLs default to landing page
-}
errorHandlingTests : Test
errorHandlingTests =
    describe "Error handling and fallback behavior"
        [ test "fromUrlWithFallback returns valid routes for valid URLs" <|
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
                        Route.fromUrlWithFallback (createUrl urlPath)
                            |> Expect.equal expectedRoute
                in
                urlRoutePairs
                    |> List.map testParsing
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        , test "fromUrlWithFallback returns Landing for invalid URLs" <|
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
                        , "/nonexistent"
                        , "/malformed/path/with/many/segments"
                        , "/tic-tac-toe/subpath"
                        , "/robot-game/invalid"
                        , "/style-guide/extra"
                        , "/random-gibberish"
                        ]

                    testInvalidUrl path =
                        Route.fromUrlWithFallback (createUrl path)
                            |> Expect.equal Route.Landing
                in
                invalidPaths
                    |> List.map testInvalidUrl
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        , test "fromUrlWithFallback handles malformed URLs gracefully" <|
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

                    malformedPaths =
                        [ "///multiple/slashes///"
                        , "/tic-tac-toe/../../../etc/passwd"
                        , "/landing%20with%20encoded%20spaces"
                        , "/tic-tac-toe?param=value&redirect=evil"
                        , "/robot-game#fragment-injection"
                        ]

                    testMalformedUrl path =
                        Route.fromUrlWithFallback (createUrl path)
                            |> Expect.equal Route.Landing
                in
                malformedPaths
                    |> List.map testMalformedUrl
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        ]


{-| Test round-trip consistency between parsing and generation
Requirements: 4.3, 4.4 - Reliable parsing and type-safe URL construction
-}
roundTripConsistencyTests : Test
roundTripConsistencyTests =
    describe "Round-trip consistency"
        [ test "toString and fromUrl are consistent" <|
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

                    routes =
                        [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                    testRoundTrip route =
                        let
                            urlString =
                                Route.toString route

                            url =
                                createUrl urlString
                        in
                        Route.fromUrl url
                            |> Expect.equal (Just route)
                in
                routes
                    |> List.map testRoundTrip
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        , test "toHashUrl and hash parsing are consistent" <|
            \_ ->
                let
                    -- Simulate hash URL parsing by extracting path from hash URL
                    parseHashUrl hashUrl =
                        if String.startsWith "#/" hashUrl then
                            let
                                path =
                                    String.dropLeft 1 hashUrl

                                -- Remove the #
                            in
                            { protocol = Url.Https
                            , host = "example.com"
                            , port_ = Nothing
                            , path = path
                            , query = Nothing
                            , fragment = Nothing
                            }
                                |> Route.fromUrl

                        else
                            Nothing

                    routes =
                        [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                    testHashRoundTrip route =
                        let
                            hashUrl =
                                Route.toHashUrl route
                        in
                        parseHashUrl hashUrl
                            |> Expect.equal (Just route)
                in
                routes
                    |> List.map testHashRoundTrip
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        , test "toUrl and fromUrl are consistent" <|
            \_ ->
                let
                    routes =
                        [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                    testUrlRoundTrip route =
                        let
                            url =
                                Route.toUrl route
                        in
                        Route.fromUrl url
                            |> Expect.equal (Just route)
                in
                routes
                    |> List.map testUrlRoundTrip
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        ]

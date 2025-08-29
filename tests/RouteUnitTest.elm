module RouteUnitTest exposing (suite)

{-| Comprehensive unit tests for the Route module hash routing functionality.

This module consolidates all Route module tests, including hash routing, URL parsing,
generation, and integration with the App module. It eliminates duplication from
HashRoutingUnitTest and RoutingUnitTest while maintaining complete coverage.

Requirements covered:

  - 1.1: Navigate directly to specific pages using hash URLs
  - 1.2: Direct access to landing page via hash URLs
  - 1.3: Direct access to tic-tac-toe page via hash URLs
  - 1.4: Direct access to robot game page via hash URLs
  - 1.5: Direct access to style guide page via hash URLs
  - 1.6: Invalid hash URLs default to landing page
  - 3.4: Current page determined from URL on refresh
  - 4.1: Extensible routing system with centralized route definition
  - 4.2: Centralized route definition
  - 4.3: Reliable hash URL parsing
  - 4.4: Type-safe URL construction helper functions

-}

import Expect
import Route
import Test exposing (Test, describe, test)
import Url


{-| Create a test URL with hash fragment for testing hash routing
-}
createHashUrl : String -> String -> Url.Url
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


{-| Create a mock URL for testing
-}
createMockUrl : String -> Url.Url
createMockUrl path =
    { protocol = Url.Http
    , host = "localhost"
    , port_ = Just 3000
    , path = path
    , query = Nothing
    , fragment = Nothing
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
    describe "Route module comprehensive tests"
        [ basicRouteFunctionalityTests
        , hashUrlParsingTests
        , hashUrlGenerationTests
        , productionHashRoutingTests
        , errorHandlingTests
        , roundTripConsistencyTests
        , extensibilityTests
        ]


{-| Test basic Route module functionality
Requirements: 4.2, 4.3, 4.4 - Centralized route definition, parsing, and URL construction
-}
basicRouteFunctionalityTests : Test
basicRouteFunctionalityTests =
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
                            Route.fromUrl (createMockUrl urlPath)
                                |> Expect.equal (Just expectedRoute)
                    in
                    urlRoutePairs
                        |> List.map testParsing
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "returns Nothing for invalid URLs" <|
                \_ ->
                    let
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
                            Route.fromUrl (createMockUrl path)
                                |> Expect.equal Nothing
                    in
                    invalidPaths
                        |> List.map testInvalidUrl
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "handles edge cases gracefully" <|
                \_ ->
                    let
                        edgeCases =
                            [ ( "", Route.Landing ) -- empty path
                            , ( "/", Route.Landing ) -- root path
                            , ( "//", Route.Landing ) -- double slash
                            , ( "/landing/", Route.Landing ) -- trailing slash
                            ]

                        testEdgeCase ( urlPath, expectedRoute ) =
                            Route.fromUrl (createMockUrl urlPath)
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
                            , path = "/tic-tac-toe"
                            , query = Just "param=value&other=test"
                            , fragment = Just "section"
                            }
                    in
                    Route.fromUrl urlWithQuery
                        |> Expect.equal (Just Route.TicTacToe)
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


{-| Test hash URL parsing functionality
Requirements: 4.3 - Reliable hash URL parsing, 1.1-1.5 - Direct hash URL access
-}
hashUrlParsingTests : Test
hashUrlParsingTests =
    describe "Hash URL parsing"
        [ test "direct access to all pages via hash URLs" <|
            \_ ->
                let
                    hashRoutePairs =
                        [ ( "", Route.Landing ) -- root hash
                        , ( "landing", Route.Landing )
                        , ( "tic-tac-toe", Route.TicTacToe )
                        , ( "robot-game", Route.RobotGame )
                        , ( "style-guide", Route.StyleGuide )
                        ]

                    testHashParsing ( hashFragment, expectedRoute ) =
                        simulateHashUrlParsingWithFallback hashFragment
                            |> Expect.equal expectedRoute
                in
                hashRoutePairs
                    |> List.map testHashParsing
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        , test "invalid hash URLs default to landing page" <|
            \_ ->
                let
                    invalidHashes =
                        [ "invalid-route"
                        , "TIC-TAC-TOE" -- case sensitivity
                        , "tic-tac-toe/extra/path" -- extra path segments
                        , "robot-game@#$%" -- special characters
                        , "completely-invalid-route-12345"
                        ]

                    testInvalidHash fragment =
                        simulateHashUrlParsingWithFallback fragment
                            |> Expect.equal Route.Landing
                in
                invalidHashes
                    |> List.map testInvalidHash
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


{-| Test production hash routing functionality
Requirements: 1.1-1.6, 3.4 - Production build hash routing behavior
-}
productionHashRoutingTests : Test
productionHashRoutingTests =
    describe "Production hash routing"
        [ test "bookmark and refresh functionality" <|
            \_ ->
                let
                    bookmarkTests =
                        [ ( "tic-tac-toe", Route.TicTacToe )
                        , ( "robot-game", Route.RobotGame )
                        , ( "style-guide", Route.StyleGuide )
                        , ( "landing", Route.Landing )
                        ]

                    testBookmark ( hashFragment, expectedRoute ) =
                        simulateHashUrlParsingWithFallback hashFragment
                            |> Expect.equal expectedRoute
                in
                bookmarkTests
                    |> List.map testBookmark
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
                        simulateHashUrlParsingWithFallback fragment
                            |> Expect.equal Route.Landing
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
                        simulateHashUrlParsingWithFallback fragment
                            |> Expect.equal Route.Landing
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
                        simulateHashUrlParsingWithFallback fragment
                            |> Expect.equal Route.Landing
                in
                rootTests
                    |> List.map testRootUrl
                    |> List.all (\expectation -> expectation == Expect.pass)
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
                    urlRoutePairs =
                        [ ( "/", Route.Landing )
                        , ( "/landing", Route.Landing )
                        , ( "/tic-tac-toe", Route.TicTacToe )
                        , ( "/robot-game", Route.RobotGame )
                        , ( "/style-guide", Route.StyleGuide )
                        ]

                    testParsing ( urlPath, expectedRoute ) =
                        Route.fromUrlWithFallback (createMockUrl urlPath)
                            |> Expect.equal expectedRoute
                in
                urlRoutePairs
                    |> List.map testParsing
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        , test "fromUrlWithFallback returns Landing for invalid URLs" <|
            \_ ->
                let
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
                        , ""
                        , "///"
                        ]

                    testInvalidUrl path =
                        Route.fromUrlWithFallback (createMockUrl path)
                            |> Expect.equal Route.Landing
                in
                invalidPaths
                    |> List.map testInvalidUrl
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        , test "invalid URLs fallback to landing route in App context" <|
            \_ ->
                let
                    invalidUrl =
                        createMockUrl "/invalid-route"

                    -- Test that fromUrlWithFallback handles invalid routes
                    resultRoute =
                        Route.fromUrlWithFallback invalidUrl
                in
                resultRoute
                    |> Expect.equal Route.Landing
        , test "fromUrlWithFallback handles malformed URLs gracefully" <|
            \_ ->
                let
                    malformedPaths =
                        [ "///multiple/slashes///"
                        , "/tic-tac-toe/../../../etc/passwd"
                        , "/landing%20with%20encoded%20spaces"
                        , "/tic-tac-toe?param=value&redirect=evil"
                        , "/robot-game#fragment-injection"
                        ]

                    testMalformedUrl path =
                        Route.fromUrlWithFallback (createMockUrl path)
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
        , test "toHashUrl and hash parsing are consistent" <|
            \_ ->
                let
                    routes =
                        [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                    testHashRoundTrip route =
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
        , test "route hash URL generation consistency" <|
            \_ ->
                let
                    routes =
                        [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                    expectedHashUrls =
                        [ "#/landing", "#/tic-tac-toe", "#/robot-game", "#/style-guide" ]

                    actualHashUrls =
                        List.map Route.toHashUrl routes
                in
                actualHashUrls
                    |> Expect.equal expectedHashUrls
        ]


{-| Test system extensibility and maintainability
Requirements: 4.1 - Extensible routing system
-}
extensibilityTests : Test
extensibilityTests =
    describe "System extensibility"
        [ describe "Consistent patterns"
            [ test "all routes produce unique URL strings" <|
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
            , test "route hash URLs are unique" <|
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

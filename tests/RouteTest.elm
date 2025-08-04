module RouteTest exposing (suite)

import Expect
import Route
import Test exposing (Test, describe, test)
import Url


suite : Test
suite =
    describe "Route module"
        [ describe "toString"
            [ test "converts Landing to /landing" <|
                \_ ->
                    Route.toString Route.Landing
                        |> Expect.equal "/landing"
            , test "converts TicTacToe to /tic-tac-toe" <|
                \_ ->
                    Route.toString Route.TicTacToe
                        |> Expect.equal "/tic-tac-toe"
            , test "converts RobotGame to /robot-game" <|
                \_ ->
                    Route.toString Route.RobotGame
                        |> Expect.equal "/robot-game"
            , test "converts StyleGuide to /style-guide" <|
                \_ ->
                    Route.toString Route.StyleGuide
                        |> Expect.equal "/style-guide"
            ]
        , describe "fromUrl"
            [ test "parses /landing to Landing route" <|
                \_ ->
                    let
                        url =
                            { protocol = Url.Https
                            , host = "example.com"
                            , port_ = Nothing
                            , path = "/landing"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    Route.fromUrl url
                        |> Expect.equal (Just Route.Landing)
            , test "parses /tic-tac-toe to TicTacToe route" <|
                \_ ->
                    let
                        url =
                            { protocol = Url.Https
                            , host = "example.com"
                            , port_ = Nothing
                            , path = "/tic-tac-toe"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    Route.fromUrl url
                        |> Expect.equal (Just Route.TicTacToe)
            , test "parses /robot-game to RobotGame route" <|
                \_ ->
                    let
                        url =
                            { protocol = Url.Https
                            , host = "example.com"
                            , port_ = Nothing
                            , path = "/robot-game"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    Route.fromUrl url
                        |> Expect.equal (Just Route.RobotGame)
            , test "parses /style-guide to StyleGuide route" <|
                \_ ->
                    let
                        url =
                            { protocol = Url.Https
                            , host = "example.com"
                            , port_ = Nothing
                            , path = "/style-guide"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    Route.fromUrl url
                        |> Expect.equal (Just Route.StyleGuide)
            , test "returns Nothing for invalid URLs" <|
                \_ ->
                    let
                        url =
                            { protocol = Url.Https
                            , host = "example.com"
                            , port_ = Nothing
                            , path = "/invalid-route"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    Route.fromUrl url
                        |> Expect.equal Nothing
            , test "returns Nothing for malformed URLs with special characters" <|
                \_ ->
                    let
                        url =
                            { protocol = Url.Https
                            , host = "example.com"
                            , port_ = Nothing
                            , path = "/tic-tac-toe@#$%"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    Route.fromUrl url
                        |> Expect.equal Nothing
            , test "returns Nothing for URLs with extra path segments" <|
                \_ ->
                    let
                        url =
                            { protocol = Url.Https
                            , host = "example.com"
                            , port_ = Nothing
                            , path = "/landing/extra/path"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    Route.fromUrl url
                        |> Expect.equal Nothing
            , test "handles double slash as root path" <|
                \_ ->
                    let
                        url =
                            { protocol = Url.Https
                            , host = "example.com"
                            , port_ = Nothing
                            , path = "//"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    Route.fromUrl url
                        |> Expect.equal (Just Route.Landing)
            , test "parses root URL / to Landing route" <|
                \_ ->
                    let
                        url =
                            { protocol = Url.Https
                            , host = "example.com"
                            , port_ = Nothing
                            , path = "/"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    Route.fromUrl url
                        |> Expect.equal (Just Route.Landing)
            ]
        , describe "toUrl"
            [ test "generates URL structure for Landing route" <|
                \_ ->
                    let
                        expectedUrl =
                            { protocol = Url.Https
                            , host = ""
                            , port_ = Nothing
                            , path = "/landing"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    Route.toUrl Route.Landing
                        |> Expect.equal expectedUrl
            , test "generates URL structure for TicTacToe route" <|
                \_ ->
                    let
                        expectedUrl =
                            { protocol = Url.Https
                            , host = ""
                            , port_ = Nothing
                            , path = "/tic-tac-toe"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    Route.toUrl Route.TicTacToe
                        |> Expect.equal expectedUrl
            ]
        , describe "error handling and fallback behavior"
            [ test "handles URLs with query parameters gracefully" <|
                \_ ->
                    let
                        url =
                            { protocol = Url.Https
                            , host = "example.com"
                            , port_ = Nothing
                            , path = "/landing"
                            , query = Just "param=value"
                            , fragment = Nothing
                            }
                    in
                    Route.fromUrl url
                        |> Expect.equal (Just Route.Landing)
            , test "handles URLs with fragments gracefully" <|
                \_ ->
                    let
                        url =
                            { protocol = Url.Https
                            , host = "example.com"
                            , port_ = Nothing
                            , path = "/tic-tac-toe"
                            , query = Nothing
                            , fragment = Just "section"
                            }
                    in
                    Route.fromUrl url
                        |> Expect.equal (Just Route.TicTacToe)
            , test "handles case-sensitive URLs correctly" <|
                \_ ->
                    let
                        url =
                            { protocol = Url.Https
                            , host = "example.com"
                            , port_ = Nothing
                            , path = "/LANDING"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    Route.fromUrl url
                        |> Expect.equal Nothing
            , test "handles URLs with trailing slashes" <|
                \_ ->
                    let
                        url =
                            { protocol = Url.Https
                            , host = "example.com"
                            , port_ = Nothing
                            , path = "/landing/"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    -- Elm's URL parser is lenient and matches /landing/ as Landing
                    Route.fromUrl url
                        |> Expect.equal (Just Route.Landing)
            , test "handles empty path as root" <|
                \_ ->
                    let
                        url =
                            { protocol = Url.Https
                            , host = "example.com"
                            , port_ = Nothing
                            , path = ""
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    Route.fromUrl url
                        |> Expect.equal (Just Route.Landing)
            ]
        , describe "URL generation consistency"
            [ test "toString and fromUrl are consistent for all routes" <|
                \_ ->
                    let
                        routes =
                            [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                        testRoute route =
                            let
                                urlString =
                                    Route.toString route

                                reconstructedUrl =
                                    { protocol = Url.Https
                                    , host = "example.com"
                                    , port_ = Nothing
                                    , path = urlString
                                    , query = Nothing
                                    , fragment = Nothing
                                    }
                            in
                            Route.fromUrl reconstructedUrl
                                |> Expect.equal (Just route)
                    in
                    routes
                        |> List.map testRoute
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "toUrl generates valid URL structure for all routes" <|
                \_ ->
                    let
                        routes =
                            [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                        testRoute route =
                            let
                                generatedUrl =
                                    Route.toUrl route

                                expectedPath =
                                    Route.toString route
                            in
                            generatedUrl.path
                                |> Expect.equal expectedPath
                    in
                    routes
                        |> List.map testRoute
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            ]
        ]

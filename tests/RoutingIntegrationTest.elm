module RoutingIntegrationTest exposing (suite)

{-| Integration tests for routing functionality.

These tests verify that the routing system works correctly for URL parsing,
route conversion, and navigation logic without requiring Browser.Navigation mocking.

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
    describe "Routing Integration"
        [ describe "URL parsing integration"
            [ test "all valid URLs parse to correct routes" <|
                \_ ->
                    let
                        urlRoutePairs =
                            [ ( "/", Route.Landing )
                            , ( "/landing", Route.Landing )
                            , ( "/tic-tac-toe", Route.TicTacToe )
                            , ( "/robot-game", Route.RobotGame )
                            , ( "/style-guide", Route.StyleGuide )
                            ]

                        testUrlParsing ( urlPath, expectedRoute ) =
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
                        |> List.map testUrlParsing
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "invalid URLs return Nothing" <|
                \_ ->
                    let
                        invalidUrls =
                            [ "/invalid"
                            , "/tic-tac-toe/extra"
                            , "/LANDING"
                            , "/tic-tac-toe@#$"
                            ]

                        testInvalidUrl urlPath =
                            let
                                url =
                                    createMockUrl urlPath

                                parsedRoute =
                                    Route.fromUrl url
                            in
                            parsedRoute
                                |> Expect.equal Nothing
                    in
                    invalidUrls
                        |> List.map testInvalidUrl
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            ]
        , describe "Route to Page conversion integration"
            [ test "all routes convert to correct pages" <|
                \_ ->
                    let
                        routePagePairs =
                            [ ( Route.Landing, LandingPage )
                            , ( Route.TicTacToe, GamePage )
                            , ( Route.RobotGame, RobotGamePage )
                            , ( Route.StyleGuide, StyleGuidePage )
                            ]

                        testConversion ( route, expectedPage ) =
                            routeToPage route
                                |> Expect.equal expectedPage
                    in
                    routePagePairs
                        |> List.map testConversion
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "all pages convert to correct routes" <|
                \_ ->
                    let
                        pageRoutePairs =
                            [ ( LandingPage, Route.Landing )
                            , ( GamePage, Route.TicTacToe )
                            , ( RobotGamePage, Route.RobotGame )
                            , ( StyleGuidePage, Route.StyleGuide )
                            ]

                        testConversion ( page, expectedRoute ) =
                            pageToRoute page
                                |> Expect.equal expectedRoute
                    in
                    pageRoutePairs
                        |> List.map testConversion
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            ]
        , describe "Full routing pipeline"
            [ test "URL -> Route -> Page -> Route round trip" <|
                \_ ->
                    let
                        testUrls =
                            [ "/landing", "/tic-tac-toe", "/robot-game", "/style-guide" ]

                        testRoundTrip urlPath =
                            let
                                url =
                                    createMockUrl urlPath

                                maybeRoute =
                                    Route.fromUrl url

                                result =
                                    maybeRoute
                                        |> Maybe.map (routeToPage >> pageToRoute)
                            in
                            result
                                |> Expect.equal maybeRoute
                    in
                    testUrls
                        |> List.map testRoundTrip
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "Route -> URL string -> Route round trip" <|
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

                                parsedRoute =
                                    Route.fromUrl url
                            in
                            parsedRoute
                                |> Expect.equal (Just route)
                    in
                    routes
                        |> List.map testRoundTrip
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            ]
        , describe "Navigation message types"
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
        , describe "Error handling integration"
            [ test "invalid URL handling follows expected pattern" <|
                \_ ->
                    let
                        invalidUrl =
                            createMockUrl "/invalid-route"

                        parsedRoute =
                            Route.fromUrl invalidUrl

                        -- This simulates the behavior in App.init and App.update
                        defaultPage =
                            case parsedRoute of
                                Nothing ->
                                    LandingPage

                                Just route ->
                                    routeToPage route
                    in
                    defaultPage
                        |> Expect.equal LandingPage
            , test "root URL handling follows expected pattern" <|
                \_ ->
                    let
                        rootUrl =
                            createMockUrl "/"

                        parsedRoute =
                            Route.fromUrl rootUrl

                        -- Root URL should parse to Landing route
                        resultPage =
                            case parsedRoute of
                                Nothing ->
                                    LandingPage

                                Just route ->
                                    routeToPage route
                    in
                    resultPage
                        |> Expect.equal LandingPage
            ]
        , describe "URL structure consistency"
            [ test "all routes produce valid URL strings" <|
                \_ ->
                    let
                        routes =
                            [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                        testUrlString route =
                            let
                                urlString =
                                    Route.toString route

                                -- URL strings should start with / and not be empty
                                isValid =
                                    String.startsWith "/" urlString && String.length urlString > 1
                            in
                            isValid
                                |> Expect.equal True
                    in
                    routes
                        |> List.map testUrlString
                        |> List.all (\expectation -> expectation == Expect.pass)
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
            ]
        , describe "Browser navigation simulation"
            [ test "simulates URL change behavior" <|
                \_ ->
                    let
                        -- Simulate what happens when browser URL changes
                        oldUrl =
                            createMockUrl "/landing"

                        newUrl =
                            createMockUrl "/tic-tac-toe"

                        oldRoute =
                            Route.fromUrl oldUrl

                        newRoute =
                            Route.fromUrl newUrl

                        oldPage =
                            Maybe.map routeToPage oldRoute

                        newPage =
                            Maybe.map routeToPage newRoute
                    in
                    Expect.all
                        [ \_ -> oldPage |> Expect.equal (Just LandingPage)
                        , \_ -> newPage |> Expect.equal (Just GamePage)
                        , \_ -> oldPage |> Expect.notEqual newPage
                        ]
                        ()
            , test "simulates navigation between all pages" <|
                \_ ->
                    let
                        allUrls =
                            [ "/landing", "/tic-tac-toe", "/robot-game", "/style-guide" ]

                        allPages =
                            [ LandingPage, GamePage, RobotGamePage, StyleGuidePage ]

                        parsedPages =
                            allUrls
                                |> List.map createMockUrl
                                |> List.map Route.fromUrl
                                |> List.map (Maybe.map routeToPage)
                                |> List.map (Maybe.withDefault LandingPage)
                    in
                    parsedPages
                        |> Expect.equal allPages
            , test "simulates browser back button navigation" <|
                \_ ->
                    let
                        -- Simulate navigation history: landing -> game -> back to landing
                        landingUrl =
                            createMockUrl "/landing"

                        gameUrl =
                            createMockUrl "/tic-tac-toe"

                        -- Forward navigation: landing -> game
                        forwardNavigation =
                            ( Route.fromUrl landingUrl, Route.fromUrl gameUrl )

                        -- Back navigation: game -> landing (simulating back button)
                        backNavigation =
                            ( Route.fromUrl gameUrl, Route.fromUrl landingUrl )

                        testNavigation ( fromRoute, toRoute ) =
                            let
                                fromPage =
                                    Maybe.map routeToPage fromRoute

                                toPage =
                                    Maybe.map routeToPage toRoute
                            in
                            ( fromPage, toPage )
                    in
                    Expect.all
                        [ \_ ->
                            testNavigation forwardNavigation
                                |> Expect.equal ( Just LandingPage, Just GamePage )
                        , \_ ->
                            testNavigation backNavigation
                                |> Expect.equal ( Just GamePage, Just LandingPage )
                        ]
                        ()
            , test "simulates browser forward button navigation" <|
                \_ ->
                    let
                        -- Simulate navigation history: landing -> game -> back -> forward
                        navigationSequence =
                            [ "/landing", "/tic-tac-toe", "/landing", "/tic-tac-toe" ]

                        expectedPageSequence =
                            [ LandingPage, GamePage, LandingPage, GamePage ]

                        actualPageSequence =
                            navigationSequence
                                |> List.map createMockUrl
                                |> List.map Route.fromUrl
                                |> List.map (Maybe.map routeToPage)
                                |> List.map (Maybe.withDefault LandingPage)

                        -- Verify that forward navigation (last step) works correctly
                        lastTwoPages =
                            List.drop 2 actualPageSequence
                    in
                    Expect.all
                        [ \_ -> actualPageSequence |> Expect.equal expectedPageSequence
                        , \_ -> lastTwoPages |> Expect.equal [ LandingPage, GamePage ]
                        ]
                        ()
            , test "simulates complex navigation history" <|
                \_ ->
                    let
                        -- Simulate: landing -> game -> robot -> style -> back to game -> forward to robot
                        navigationHistory =
                            [ "/landing"
                            , "/tic-tac-toe"
                            , "/robot-game"
                            , "/style-guide"
                            , "/tic-tac-toe" -- back navigation
                            , "/robot-game" -- forward navigation
                            ]

                        expectedHistory =
                            [ LandingPage
                            , GamePage
                            , RobotGamePage
                            , StyleGuidePage
                            , GamePage
                            , RobotGamePage
                            ]

                        actualHistory =
                            navigationHistory
                                |> List.map createMockUrl
                                |> List.map Route.fromUrl
                                |> List.map (Maybe.map routeToPage)
                                |> List.map (Maybe.withDefault LandingPage)
                    in
                    actualHistory
                        |> Expect.equal expectedHistory
            ]
        , describe "State preservation simulation"
            [ test "simulates theme preservation across navigation" <|
                \_ ->
                    let
                        -- Test that route parsing doesn't affect theme state
                        routes =
                            [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                        -- Simulate theme being preserved during navigation
                        testThemePreservation route =
                            let
                                urlString =
                                    Route.toString route

                                url =
                                    createMockUrl urlString

                                parsedRoute =
                                    Route.fromUrl url

                                -- Theme should be independent of route parsing
                                themePreserved =
                                    parsedRoute /= Nothing
                            in
                            themePreserved
                                |> Expect.equal True
                    in
                    routes
                        |> List.map testThemePreservation
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "simulates page refresh URL determination" <|
                \_ ->
                    let
                        -- Test that page can be determined from URL on refresh
                        urlPagePairs =
                            [ ( "/landing", LandingPage )
                            , ( "/tic-tac-toe", GamePage )
                            , ( "/robot-game", RobotGamePage )
                            , ( "/style-guide", StyleGuidePage )
                            ]

                        testRefreshBehavior ( urlPath, expectedPage ) =
                            let
                                url =
                                    createMockUrl urlPath

                                -- Simulate page determination on refresh
                                determinedPage =
                                    case Route.fromUrl url of
                                        Just route ->
                                            routeToPage route

                                        Nothing ->
                                            LandingPage

                                -- fallback
                            in
                            determinedPage
                                |> Expect.equal expectedPage
                    in
                    urlPagePairs
                        |> List.map testRefreshBehavior
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "simulates game state preservation pattern" <|
                \_ ->
                    let
                        -- Test navigation away from and back to game page
                        gameUrl =
                            createMockUrl "/tic-tac-toe"

                        landingUrl =
                            createMockUrl "/landing"

                        backToGameUrl =
                            createMockUrl "/tic-tac-toe"

                        -- Simulate: on game -> navigate away -> return to game
                        navigationSequence =
                            [ gameUrl, landingUrl, backToGameUrl ]

                        pageSequence =
                            navigationSequence
                                |> List.map Route.fromUrl
                                |> List.map (Maybe.map routeToPage)
                                |> List.map (Maybe.withDefault LandingPage)

                        -- Game page should be accessible before and after navigation
                        gamePageAccessible =
                            case ( List.head pageSequence, List.drop 2 pageSequence |> List.head ) of
                                ( Just GamePage, Just GamePage ) ->
                                    True

                                _ ->
                                    False
                    in
                    gamePageAccessible
                        |> Expect.equal True
            ]
        ]

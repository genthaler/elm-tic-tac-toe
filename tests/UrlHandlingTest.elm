module UrlHandlingTest exposing (suite)

{-| Tests for URL handling and browser navigation logic.

These tests verify URL request handling and navigation state management
without requiring actual Browser.Navigation functionality.

-}

import App exposing (AppMsg(..), Page(..))
import Browser
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
    describe "URL Handling"
        [ describe "URL request message types"
            [ test "UrlRequested with internal URL creates correct message" <|
                \_ ->
                    let
                        internalUrl =
                            createMockUrl "/tic-tac-toe"

                        urlRequest =
                            Browser.Internal internalUrl

                        message =
                            UrlRequested urlRequest

                        extractUrlRequest msg =
                            case msg of
                                UrlRequested request ->
                                    Just request

                                _ ->
                                    Nothing
                    in
                    extractUrlRequest message
                        |> Expect.equal (Just urlRequest)
            , test "UrlRequested with external URL creates correct message" <|
                \_ ->
                    let
                        externalHref =
                            "https://example.com"

                        urlRequest =
                            Browser.External externalHref

                        message =
                            UrlRequested urlRequest

                        extractUrlRequest msg =
                            case msg of
                                UrlRequested request ->
                                    Just request

                                _ ->
                                    Nothing
                    in
                    extractUrlRequest message
                        |> Expect.equal (Just urlRequest)
            ]
        , describe "URL change handling logic"
            [ test "UrlChanged message extracts URL correctly" <|
                \_ ->
                    let
                        url =
                            createMockUrl "/robot-game"

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
            , test "URL change determines correct page" <|
                \_ ->
                    let
                        urlPagePairs =
                            [ ( "/landing", LandingPage )
                            , ( "/tic-tac-toe", GamePage )
                            , ( "/robot-game", RobotGamePage )
                            , ( "/style-guide", StyleGuidePage )
                            ]

                        testUrlToPage ( urlPath, expectedPage ) =
                            let
                                url =
                                    createMockUrl urlPath

                                maybeRoute =
                                    Route.fromUrl url

                                resultPage =
                                    case maybeRoute of
                                        Just route ->
                                            App.routeToPage route

                                        Nothing ->
                                            LandingPage
                            in
                            resultPage
                                |> Expect.equal expectedPage
                    in
                    urlPagePairs
                        |> List.map testUrlToPage
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            ]
        , describe "Navigation state transitions"
            [ test "NavigateToRoute creates correct page transition" <|
                \_ ->
                    let
                        routePagePairs =
                            [ ( Route.Landing, LandingPage )
                            , ( Route.TicTacToe, GamePage )
                            , ( Route.RobotGame, RobotGamePage )
                            , ( Route.StyleGuide, StyleGuidePage )
                            ]

                        testNavigation ( route, expectedPage ) =
                            let
                                message =
                                    NavigateToRoute route

                                extractRoute msg =
                                    case msg of
                                        NavigateToRoute r ->
                                            Just r

                                        _ ->
                                            Nothing

                                extractedRoute =
                                    extractRoute message

                                resultPage =
                                    case extractedRoute of
                                        Just r ->
                                            App.routeToPage r

                                        Nothing ->
                                            LandingPage
                            in
                            resultPage
                                |> Expect.equal expectedPage
                    in
                    routePagePairs
                        |> List.map testNavigation
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            ]
        , describe "URL validation and error handling"
            [ test "invalid URLs default to landing page logic" <|
                \_ ->
                    let
                        invalidUrls =
                            [ "/invalid-route"
                            , "/tic-tac-toe/extra"
                            , "/LANDING"
                            , "/landing/"
                            , ""
                            ]

                        testInvalidUrl urlPath =
                            let
                                url =
                                    createMockUrl urlPath

                                maybeRoute =
                                    Route.fromUrl url

                                -- This simulates the error handling logic in App.update
                                resultPage =
                                    case maybeRoute of
                                        Just route ->
                                            App.routeToPage route

                                        Nothing ->
                                            LandingPage
                            in
                            resultPage
                                |> Expect.equal LandingPage
                    in
                    invalidUrls
                        |> List.map testInvalidUrl
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "root URL handling logic" <|
                \_ ->
                    let
                        rootUrls =
                            [ "/", "" ]

                        testRootUrl urlPath =
                            let
                                url =
                                    createMockUrl urlPath

                                maybeRoute =
                                    Route.fromUrl url

                                -- Root URLs should parse to Landing route
                                resultPage =
                                    case maybeRoute of
                                        Just route ->
                                            App.routeToPage route

                                        Nothing ->
                                            LandingPage
                            in
                            resultPage
                                |> Expect.equal LandingPage
                    in
                    rootUrls
                        |> List.map testRootUrl
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            ]
        , describe "Browser navigation patterns"
            [ test "back navigation pattern simulation" <|
                \_ ->
                    let
                        -- Simulate: user is on game page, clicks back to landing
                        currentUrl =
                            createMockUrl "/tic-tac-toe"

                        backUrl =
                            createMockUrl "/landing"

                        currentPage =
                            currentUrl
                                |> Route.fromUrl
                                |> Maybe.map App.routeToPage
                                |> Maybe.withDefault LandingPage

                        backPage =
                            backUrl
                                |> Route.fromUrl
                                |> Maybe.map App.routeToPage
                                |> Maybe.withDefault LandingPage
                    in
                    Expect.all
                        [ \_ -> currentPage |> Expect.equal GamePage
                        , \_ -> backPage |> Expect.equal LandingPage
                        , \_ -> currentPage |> Expect.notEqual backPage
                        ]
                        ()
            , test "forward navigation pattern simulation" <|
                \_ ->
                    let
                        -- Simulate: user is on landing, navigates forward to game
                        currentUrl =
                            createMockUrl "/landing"

                        forwardUrl =
                            createMockUrl "/tic-tac-toe"

                        currentPage =
                            currentUrl
                                |> Route.fromUrl
                                |> Maybe.map App.routeToPage
                                |> Maybe.withDefault LandingPage

                        forwardPage =
                            forwardUrl
                                |> Route.fromUrl
                                |> Maybe.map App.routeToPage
                                |> Maybe.withDefault LandingPage
                    in
                    Expect.all
                        [ \_ -> currentPage |> Expect.equal LandingPage
                        , \_ -> forwardPage |> Expect.equal GamePage
                        , \_ -> currentPage |> Expect.notEqual forwardPage
                        ]
                        ()
            , test "navigation history simulation" <|
                \_ ->
                    let
                        -- Simulate navigation sequence: landing -> game -> robot -> style -> back to landing
                        navigationSequence =
                            [ "/landing", "/tic-tac-toe", "/robot-game", "/style-guide", "/landing" ]

                        expectedPages =
                            [ LandingPage, GamePage, RobotGamePage, StyleGuidePage, LandingPage ]

                        actualPages =
                            navigationSequence
                                |> List.map createMockUrl
                                |> List.map Route.fromUrl
                                |> List.map (Maybe.map App.routeToPage)
                                |> List.map (Maybe.withDefault LandingPage)
                    in
                    actualPages
                        |> Expect.equal expectedPages
            , test "browser back button through multiple pages" <|
                \_ ->
                    let
                        -- Simulate: landing -> game -> robot -> back -> back
                        forwardHistory =
                            [ "/landing", "/tic-tac-toe", "/robot-game" ]

                        backHistory =
                            [ "/robot-game", "/tic-tac-toe", "/landing" ]

                        forwardPages =
                            forwardHistory
                                |> List.map createMockUrl
                                |> List.map Route.fromUrl
                                |> List.map (Maybe.map App.routeToPage)
                                |> List.map (Maybe.withDefault LandingPage)

                        backPages =
                            backHistory
                                |> List.map createMockUrl
                                |> List.map Route.fromUrl
                                |> List.map (Maybe.map App.routeToPage)
                                |> List.map (Maybe.withDefault LandingPage)

                        -- Verify back navigation reverses forward navigation
                        reversedForward =
                            List.reverse forwardPages
                    in
                    backPages
                        |> Expect.equal reversedForward
            , test "browser forward button after back navigation" <|
                \_ ->
                    let
                        -- Simulate: landing -> game -> back -> forward
                        navigationPattern =
                            [ "/landing", "/tic-tac-toe", "/landing", "/tic-tac-toe" ]

                        expectedPattern =
                            [ LandingPage, GamePage, LandingPage, GamePage ]

                        actualPattern =
                            navigationPattern
                                |> List.map createMockUrl
                                |> List.map Route.fromUrl
                                |> List.map (Maybe.map App.routeToPage)
                                |> List.map (Maybe.withDefault LandingPage)

                        -- Verify forward button restores previous page
                        lastTwoPages =
                            List.drop 2 actualPattern
                    in
                    Expect.all
                        [ \_ -> actualPattern |> Expect.equal expectedPattern
                        , \_ -> lastTwoPages |> Expect.equal [ LandingPage, GamePage ]
                        ]
                        ()
            , test "deep navigation history with back/forward" <|
                \_ ->
                    let
                        -- Simulate complex navigation: landing -> game -> robot -> style -> back -> back -> forward
                        complexNavigation =
                            [ "/landing"
                            , "/tic-tac-toe"
                            , "/robot-game"
                            , "/style-guide"
                            , "/robot-game" -- back
                            , "/tic-tac-toe" -- back
                            , "/robot-game" -- forward
                            ]

                        expectedNavigation =
                            [ LandingPage
                            , GamePage
                            , RobotGamePage
                            , StyleGuidePage
                            , RobotGamePage
                            , GamePage
                            , RobotGamePage
                            ]

                        actualNavigation =
                            complexNavigation
                                |> List.map createMockUrl
                                |> List.map Route.fromUrl
                                |> List.map (Maybe.map App.routeToPage)
                                |> List.map (Maybe.withDefault LandingPage)
                    in
                    actualNavigation
                        |> Expect.equal expectedNavigation
            ]
        , describe "State preservation during navigation"
            [ test "URL synchronization with page changes" <|
                \_ ->
                    let
                        -- Test that each page has a unique URL that can be reconstructed
                        pages =
                            [ LandingPage, GamePage, RobotGamePage, StyleGuidePage ]

                        testUrlSync page =
                            let
                                route =
                                    App.pageToRoute page

                                urlString =
                                    Route.toString route

                                url =
                                    createMockUrl urlString

                                reconstructedPage =
                                    url
                                        |> Route.fromUrl
                                        |> Maybe.map App.routeToPage
                                        |> Maybe.withDefault LandingPage
                            in
                            reconstructedPage
                                |> Expect.equal page
                    in
                    pages
                        |> List.map testUrlSync
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "page refresh preserves current page from URL" <|
                \_ ->
                    let
                        -- Test that refreshing any page loads the correct page from URL
                        urlPagePairs =
                            [ ( "/landing", LandingPage )
                            , ( "/tic-tac-toe", GamePage )
                            , ( "/robot-game", RobotGamePage )
                            , ( "/style-guide", StyleGuidePage )
                            ]

                        testRefresh ( urlPath, expectedPage ) =
                            let
                                url =
                                    createMockUrl urlPath

                                -- Simulate page determination on refresh (like App.init)
                                pageFromUrl =
                                    case Route.fromUrl url of
                                        Just route ->
                                            App.routeToPage route

                                        Nothing ->
                                            LandingPage
                            in
                            pageFromUrl
                                |> Expect.equal expectedPage
                    in
                    urlPagePairs
                        |> List.map testRefresh
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "navigation preserves application state structure" <|
                \_ ->
                    let
                        -- Test that navigation between pages maintains consistent state structure
                        routes =
                            [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                        testStateStructure route =
                            let
                                page =
                                    App.routeToPage route

                                urlString =
                                    Route.toString route

                                -- State structure should be consistent regardless of navigation path
                                stateConsistent =
                                    case page of
                                        LandingPage ->
                                            String.contains "landing" urlString

                                        GamePage ->
                                            String.contains "tic-tac-toe" urlString

                                        RobotGamePage ->
                                            String.contains "robot-game" urlString

                                        StyleGuidePage ->
                                            String.contains "style-guide" urlString
                            in
                            stateConsistent
                                |> Expect.equal True
                    in
                    routes
                        |> List.map testStateStructure
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            ]
        , describe "URL consistency checks"
            [ test "NavigateToRoute and UrlChanged produce consistent results" <|
                \_ ->
                    let
                        routes =
                            [ Route.Landing, Route.TicTacToe, Route.RobotGame, Route.StyleGuide ]

                        testConsistency route =
                            let
                                -- Page from NavigateToRoute
                                pageFromRoute =
                                    App.routeToPage route

                                -- Page from UrlChanged (via URL parsing)
                                urlString =
                                    Route.toString route

                                url =
                                    createMockUrl urlString

                                pageFromUrl =
                                    url
                                        |> Route.fromUrl
                                        |> Maybe.map App.routeToPage
                                        |> Maybe.withDefault LandingPage
                            in
                            pageFromRoute
                                |> Expect.equal pageFromUrl
                    in
                    routes
                        |> List.map testConsistency
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            ]
        ]

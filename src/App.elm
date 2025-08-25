port module App exposing (AppModel, AppMsg(..), Flags, Page(..), main, pageToRoute, routeToPage)

{-| Main application module that provides routing between landing page, game, and style guide.

This module serves as the new entry point for the Tic-Tac-Toe application, providing
navigation between three main views while preserving state and theme preferences.

-}

import Browser
import Browser.Dom
import Browser.Events
import Browser.Hash as Hash
import Browser.Navigation as Nav
import Element
import Html exposing (Html)
import Json.Decode as Decode
import Json.Encode as Encode
import Landing.Landing as Landing
import Landing.LandingView as LandingView
import RobotGame.Main as RobotGameMain
import RobotGame.Model as RobotGameModel
import RobotGame.View as RobotGameView
import Route
import Task
import Theme.StyleGuide exposing (viewStyleGuideWithNavigation)
import Theme.Theme exposing (ColorScheme(..), decodeColorScheme)
import TicTacToe.Main as TicTacToeMain
import TicTacToe.Model as TicTacToeModel
import TicTacToe.View as TicTacToeView
import Url exposing (Url)


{-| Represents the four possible pages in the application
-}
type Page
    = LandingPage
    | GamePage
    | RobotGamePage
    | StyleGuidePage


{-| Main application model containing all page states
-}
type alias AppModel =
    { currentPage : Page
    , currentRoute : Maybe Route.Route
    , url : Url
    , navKey : Nav.Key
    , colorScheme : ColorScheme
    , gameModel : Maybe TicTacToeModel.Model
    , robotGameModel : Maybe RobotGameModel.Model
    , landingModel : Landing.Model
    , maybeWindow : Maybe ( Int, Int )
    }


{-| Flags passed to the application on initialization
-}
type alias Flags =
    { colorScheme : String }


{-| Messages for the main application routing and state management
-}
type AppMsg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url
    | NavigateToRoute Route.Route
    | TicTacToeMsg TicTacToeModel.Msg
    | RobotGameMsg RobotGameMain.Msg
    | LandingMsg Landing.Msg
    | ColorSchemeChanged ColorScheme
    | WindowResized Int Int
    | GetViewPort Browser.Dom.Viewport


{-| Initialize the application with URL and navigation key
-}
init : Flags -> Url -> Nav.Key -> ( AppModel, Cmd AppMsg )
init flags url navKey =
    let
        colorScheme =
            case Decode.decodeString decodeColorScheme flags.colorScheme of
                Ok decodedColorScheme ->
                    decodedColorScheme

                Err _ ->
                    Light

        landingModel =
            Landing.init colorScheme Nothing

        -- Determine initial page and route from URL with fallback handling
        initialRoute =
            Route.fromUrlWithFallback url

        initialPage =
            case initialRoute of
                Route.Landing ->
                    LandingPage

                Route.TicTacToe ->
                    GamePage

                Route.RobotGame ->
                    RobotGamePage

                Route.StyleGuide ->
                    StyleGuidePage

        -- Initialize game models if needed based on initial page
        ( initialGameModel, initialRobotGameModel ) =
            case initialPage of
                GamePage ->
                    -- Initialize tic-tac-toe game model with current theme
                    let
                        baseGameModel =
                            TicTacToeModel.initialModel

                        gameModel =
                            { baseGameModel | colorScheme = colorScheme }
                    in
                    ( Just gameModel, Nothing )

                RobotGamePage ->
                    -- Initialize robot game model with current theme
                    let
                        baseRobotGameModel =
                            RobotGameModel.init

                        robotGameModel =
                            { baseRobotGameModel | colorScheme = colorScheme }
                    in
                    ( Nothing, Just robotGameModel )

                _ ->
                    -- No game models needed for other pages
                    ( Nothing, Nothing )
    in
    ( { currentPage = initialPage
      , currentRoute = Just initialRoute
      , url = url
      , navKey = navKey
      , colorScheme = colorScheme
      , gameModel = initialGameModel
      , robotGameModel = initialRobotGameModel
      , landingModel = landingModel
      , maybeWindow = Nothing
      }
    , Task.perform GetViewPort Browser.Dom.getViewport
    )


{-| Update function handling all application messages and routing
-}
update : AppMsg -> AppModel -> ( AppModel, Cmd AppMsg )
update msg model =
    case msg of
        UrlRequested urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    -- Handle internal navigation by pushing to history
                    ( model, Nav.pushUrl model.navKey (Url.toString url) )

                Browser.External href ->
                    -- Handle external links by opening in new tab
                    ( model, Nav.load href )

        UrlChanged url ->
            let
                -- Parse the new URL to determine the route with fallback handling
                parsedRoute =
                    Route.fromUrlWithFallback url

                -- Check if the original parsing failed (for redirect logic)
                originalParseResult =
                    Route.fromUrl url

                -- Determine the new page based on the route
                newPage =
                    case parsedRoute of
                        Route.Landing ->
                            LandingPage

                        Route.TicTacToe ->
                            GamePage

                        Route.RobotGame ->
                            RobotGamePage

                        Route.StyleGuide ->
                            StyleGuidePage

                -- Initialize game models if needed when navigating to game pages
                ( updatedModel, initCmd ) =
                    case newPage of
                        GamePage ->
                            case model.gameModel of
                                Nothing ->
                                    -- Initialize tic-tac-toe game model with preserved state
                                    let
                                        baseGameModel =
                                            TicTacToeModel.initialModel

                                        initialGameModel =
                                            { baseGameModel
                                                | colorScheme = model.colorScheme
                                                , maybeWindow = model.maybeWindow
                                            }
                                    in
                                    ( { model | gameModel = Just initialGameModel }
                                    , Cmd.none
                                    )

                                Just _ ->
                                    -- Game model already exists, preserve it
                                    ( model, Cmd.none )

                        RobotGamePage ->
                            case model.robotGameModel of
                                Nothing ->
                                    -- Initialize robot game model with preserved state
                                    let
                                        baseRobotGameModel =
                                            RobotGameModel.init

                                        initialRobotGameModel =
                                            { baseRobotGameModel
                                                | colorScheme = model.colorScheme
                                                , maybeWindow = model.maybeWindow
                                            }
                                    in
                                    ( { model | robotGameModel = Just initialRobotGameModel }
                                    , Cmd.none
                                    )

                                Just _ ->
                                    -- Robot game model already exists, preserve it
                                    ( model, Cmd.none )

                        _ ->
                            -- No initialization needed for other pages
                            ( model, Cmd.none )

                -- Handle URL redirects and fallbacks for malformed URLs
                redirectCmd =
                    case originalParseResult of
                        Nothing ->
                            -- Invalid/malformed URL, redirect to landing page hash URL
                            Nav.replaceUrl model.navKey (Route.toHashUrl Route.Landing)

                        Just Route.Landing ->
                            -- Check if this was a root URL that got parsed as Landing
                            -- If the URL path is "/" we should redirect to hash URL for consistency
                            if url.path == "/" then
                                Nav.replaceUrl model.navKey (Route.toHashUrl Route.Landing)

                            else
                                Cmd.none

                        Just _ ->
                            -- Valid non-landing route, no redirect needed
                            Cmd.none

                finalModel =
                    { updatedModel
                        | currentPage = newPage
                        , currentRoute = Just parsedRoute
                        , url = url
                    }
            in
            ( finalModel
            , Cmd.batch [ initCmd, redirectCmd ]
            )

        NavigateToRoute route ->
            let
                -- Convert route to page
                newPage =
                    routeToPage route

                -- Initialize game models if needed when navigating to game pages
                updatedModel =
                    case newPage of
                        GamePage ->
                            case model.gameModel of
                                Nothing ->
                                    -- Initialize tic-tac-toe game model with preserved state
                                    let
                                        baseGameModel =
                                            TicTacToeModel.initialModel

                                        initialGameModel =
                                            { baseGameModel
                                                | colorScheme = model.colorScheme
                                                , maybeWindow = model.maybeWindow
                                            }
                                    in
                                    { model | gameModel = Just initialGameModel }

                                Just _ ->
                                    -- Game model already exists, preserve it
                                    model

                        RobotGamePage ->
                            case model.robotGameModel of
                                Nothing ->
                                    -- Initialize robot game model with preserved state
                                    let
                                        baseRobotGameModel =
                                            RobotGameModel.init

                                        initialRobotGameModel =
                                            { baseRobotGameModel
                                                | colorScheme = model.colorScheme
                                                , maybeWindow = model.maybeWindow
                                            }
                                    in
                                    { model | robotGameModel = Just initialRobotGameModel }

                                Just _ ->
                                    -- Robot game model already exists, preserve it
                                    model

                        _ ->
                            -- No initialization needed for other pages
                            model

                -- Safe navigation with error handling
                navigationCmd =
                    Route.navigateTo model.navKey route
            in
            ( { updatedModel
                | currentPage = newPage
                , currentRoute = Just route
              }
            , navigationCmd
            )

        TicTacToeMsg gameMsg ->
            -- Handle game messages and update game state
            case model.gameModel of
                Just gameModel ->
                    let
                        ( updatedGameModel, gameCmd ) =
                            TicTacToeMain.update gameMsg gameModel

                        -- Handle theme changes from game
                    in
                    case gameMsg of
                        TicTacToeModel.ColorScheme newScheme ->
                            update (ColorSchemeChanged newScheme)
                                { model | gameModel = Just updatedGameModel }

                        TicTacToeModel.NavigateToRoute route ->
                            update (NavigateToRoute route)
                                { model | gameModel = Just updatedGameModel }

                        _ ->
                            let
                                -- Handle worker communication - send model to worker when AI needs to think
                                workerCmd =
                                    case updatedGameModel.gameState of
                                        TicTacToeModel.Thinking _ ->
                                            -- Send the current model to the worker for AI calculation
                                            let
                                                encodedModel =
                                                    TicTacToeModel.encodeModel updatedGameModel
                                            in
                                            sendToWorker encodedModel

                                        _ ->
                                            Cmd.none
                            in
                            ( { model | gameModel = Just updatedGameModel }
                            , Cmd.batch
                                [ Cmd.map TicTacToeMsg gameCmd
                                , workerCmd
                                ]
                            )

                Nothing ->
                    -- No game model to update
                    ( model, Cmd.none )

        RobotGameMsg robotGameMsg ->
            -- Handle robot game messages and update robot game state
            case model.robotGameModel of
                Just robotGameModel ->
                    let
                        ( updatedRobotGameModel, robotGameCmd ) =
                            RobotGameMain.update robotGameMsg robotGameModel

                        -- Handle theme changes from robot game
                    in
                    case robotGameMsg of
                        RobotGameMain.ColorScheme newScheme ->
                            update (ColorSchemeChanged (convertColorSchemeFromRobot newScheme))
                                { model | robotGameModel = Just updatedRobotGameModel }

                        RobotGameMain.NavigateToRoute route ->
                            update (NavigateToRoute route)
                                { model | robotGameModel = Just updatedRobotGameModel }

                        _ ->
                            ( { model | robotGameModel = Just updatedRobotGameModel }
                            , Cmd.map RobotGameMsg robotGameCmd
                            )

                Nothing ->
                    -- No robot game model to update
                    ( model, Cmd.none )

        LandingMsg landingMsg ->
            let
                updatedLandingModel =
                    Landing.update landingMsg model.landingModel
            in
            case landingMsg of
                Landing.NavigateToRoute route ->
                    update (NavigateToRoute route) { model | landingModel = updatedLandingModel }

                Landing.ColorSchemeToggled ->
                    let
                        newScheme =
                            case model.colorScheme of
                                Light ->
                                    Dark

                                Dark ->
                                    Light
                    in
                    update (ColorSchemeChanged newScheme) { model | landingModel = updatedLandingModel }

        ColorSchemeChanged newScheme ->
            let
                -- Update landing model with new theme
                updatedLandingModel =
                    Landing.init newScheme model.landingModel.maybeWindow

                -- Update game model with new theme if it exists
                updatedGameModel =
                    Maybe.map (\game -> { game | colorScheme = newScheme }) model.gameModel

                -- Update robot game model with new theme if it exists
                updatedRobotGameModel =
                    Maybe.map (\robotGame -> { robotGame | colorScheme = convertColorScheme newScheme }) model.robotGameModel
            in
            ( { model
                | colorScheme = newScheme
                , landingModel = updatedLandingModel
                , gameModel = updatedGameModel
                , robotGameModel = updatedRobotGameModel
              }
            , themeChanged
                (case newScheme of
                    Light ->
                        "Light"

                    Dark ->
                        "Dark"
                )
            )

        WindowResized width height ->
            let
                newWindow =
                    Just ( width, height )

                -- Update landing model with new window size
                updatedLandingModel =
                    Landing.init model.landingModel.colorScheme newWindow

                -- Update game model with new window size if it exists
                updatedGameModel =
                    Maybe.map (\game -> { game | maybeWindow = newWindow }) model.gameModel

                -- Update robot game model with new window size if it exists
                updatedRobotGameModel =
                    Maybe.map (\robotGame -> { robotGame | maybeWindow = newWindow }) model.robotGameModel
            in
            ( { model
                | maybeWindow = newWindow
                , landingModel = updatedLandingModel
                , gameModel = updatedGameModel
                , robotGameModel = updatedRobotGameModel
              }
            , Cmd.none
            )

        GetViewPort viewport ->
            update (WindowResized (round viewport.scene.width) (round viewport.scene.height)) model


{-| Render the appropriate view based on current page
-}
view : AppModel -> Html AppMsg
view model =
    case model.currentPage of
        LandingPage ->
            LandingView.view model.landingModel LandingMsg

        GamePage ->
            case model.gameModel of
                Just gameModel ->
                    TicTacToeView.view gameModel
                        |> Html.map TicTacToeMsg

                Nothing ->
                    -- Fallback if no game model exists
                    Element.layout []
                        (Element.text "Loading game...")

        RobotGamePage ->
            case model.robotGameModel of
                Just robotGameModel ->
                    RobotGameView.view robotGameModel
                        |> Html.map RobotGameMsg

                Nothing ->
                    -- Fallback if no robot game model exists
                    Element.layout []
                        (Element.text "Loading robot game...")

        StyleGuidePage ->
            -- Use the Theme module's style guide with route-based navigation
            viewStyleGuideWithNavigation model.colorScheme model.maybeWindow (NavigateToRoute Route.Landing)


{-| Subscriptions for the application
-}
subscriptions : AppModel -> Sub AppMsg
subscriptions model =
    Sub.batch
        [ -- Window resize events
          Browser.Events.onResize WindowResized

        -- Theme change events from JavaScript
        , modeChanged
            (Decode.decodeValue decodeColorScheme
                >> Result.map ColorSchemeChanged
                >> Result.withDefault (ColorSchemeChanged Light)
            )

        -- Game-specific subscriptions when on game page
        , case ( model.currentPage, model.gameModel ) of
            ( GamePage, Just gameModel ) ->
                Sub.batch
                    [ TicTacToeMain.subscriptions gameModel
                        |> Sub.map TicTacToeMsg
                    , receiveFromWorker
                        (Decode.decodeValue TicTacToeModel.decodeMsg
                            >> Result.map TicTacToeMsg
                            >> Result.withDefault (TicTacToeMsg (TicTacToeModel.GameError (TicTacToeModel.createJsonError "Failed to decode worker message")))
                        )
                    ]

            _ ->
                Sub.none

        -- Robot game-specific subscriptions when on robot game page
        , case ( model.currentPage, model.robotGameModel ) of
            ( RobotGamePage, Just robotGameModel ) ->
                RobotGameMain.subscriptions robotGameModel
                    |> Sub.map RobotGameMsg

            _ ->
                Sub.none
        ]


{-| Convert shared ColorScheme to RobotGame ColorScheme (now they're the same)
-}
convertColorScheme : ColorScheme -> ColorScheme
convertColorScheme scheme =
    scheme


{-| Convert RobotGame ColorScheme to shared ColorScheme (now they're the same)
-}
convertColorSchemeFromRobot : ColorScheme -> ColorScheme
convertColorSchemeFromRobot scheme =
    scheme


{-| Convert a Route to a Page
-}
routeToPage : Route.Route -> Page
routeToPage route =
    case route of
        Route.Landing ->
            LandingPage

        Route.TicTacToe ->
            GamePage

        Route.RobotGame ->
            RobotGamePage

        Route.StyleGuide ->
            StyleGuidePage


{-| Convert a Page to a Route
-}
pageToRoute : Page -> Route.Route
pageToRoute page =
    case page of
        LandingPage ->
            Route.Landing

        GamePage ->
            Route.TicTacToe

        RobotGamePage ->
            Route.RobotGame

        StyleGuidePage ->
            Route.StyleGuide


{-| Main program entry point using hash routing
-}
main : Program Flags AppModel AppMsg
main =
    Hash.application
        { init = init
        , view = \model -> { title = "Elm Games", body = [ view model ] }
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }



-- Ports for JavaScript integration


port modeChanged : (Decode.Value -> msg) -> Sub msg


port themeChanged : String -> Cmd msg


port sendToWorker : Encode.Value -> Cmd msg


port receiveFromWorker : (Decode.Value -> msg) -> Sub msg

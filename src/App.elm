port module App exposing (AppModel, AppMsg, Flags, Page, main)

{-| Main application module that provides routing between landing page, game, and style guide.

This module serves as the new entry point for the Tic-Tac-Toe application, providing
navigation between three main views while preserving state and theme preferences.

-}

import Browser
import Browser.Dom
import Browser.Events
import Element
import Html exposing (Html)
import Json.Decode as Decode
import Json.Encode as Encode
import Landing.Landing as Landing
import Landing.LandingView as LandingView
import RobotGame.Main as RobotGameMain
import RobotGame.Model as RobotGameModel
import RobotGame.View as RobotGameView
import Task
import Theme.Theme exposing (ColorScheme(..), decodeColorScheme, viewStyleGuideWithNavigation)
import TicTacToe.Main as TicTacToeMain
import TicTacToe.Model as TicTacToeModel
import TicTacToe.View as TicTacToeView


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
    = NavigateToGame
    | NavigateToRobotGame
    | NavigateToStyleGuide
    | NavigateToLanding
    | GameMsg TicTacToeModel.Msg
    | RobotGameMsg RobotGameMain.Msg
    | LandingMsg Landing.Msg
    | ColorSchemeChanged ColorScheme
    | WindowResized Int Int
    | GetViewPort Browser.Dom.Viewport


{-| Initialize the application with landing page as default
-}
init : Flags -> ( AppModel, Cmd AppMsg )
init flags =
    let
        colorScheme =
            case Decode.decodeString decodeColorScheme flags.colorScheme of
                Ok decodedColorScheme ->
                    decodedColorScheme

                Err _ ->
                    Light

        landingModel =
            Landing.init colorScheme Nothing
    in
    ( { currentPage = LandingPage
      , colorScheme = colorScheme
      , gameModel = Nothing
      , robotGameModel = Nothing
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
        NavigateToGame ->
            let
                -- Preserve existing game state or create new one
                newGameModel =
                    case model.gameModel of
                        Just existingGame ->
                            -- Preserve game state but update theme and window
                            { existingGame
                                | colorScheme = model.colorScheme
                                , maybeWindow = model.maybeWindow
                            }

                        Nothing ->
                            -- Create new game with current theme and window
                            let
                                initialGame =
                                    TicTacToeModel.initialModel
                            in
                            { initialGame
                                | colorScheme = model.colorScheme
                                , maybeWindow = model.maybeWindow
                            }
            in
            ( { model
                | currentPage = GamePage
                , gameModel = Just newGameModel
              }
            , Cmd.none
            )

        NavigateToRobotGame ->
            let
                -- Preserve existing robot game state or create new one
                newRobotGameModel =
                    case model.robotGameModel of
                        Just existingRobotGame ->
                            -- Preserve robot game state but update theme and window
                            { existingRobotGame
                                | colorScheme = convertColorScheme model.colorScheme
                                , maybeWindow = model.maybeWindow
                            }

                        Nothing ->
                            -- Create new robot game with current theme and window
                            let
                                initialRobotGame =
                                    RobotGameModel.init
                            in
                            { initialRobotGame
                                | colorScheme = convertColorScheme model.colorScheme
                                , maybeWindow = model.maybeWindow
                            }
            in
            ( { model
                | currentPage = RobotGamePage
                , robotGameModel = Just newRobotGameModel
              }
            , Cmd.none
            )

        NavigateToStyleGuide ->
            ( { model | currentPage = StyleGuidePage }
            , Cmd.none
            )

        NavigateToLanding ->
            ( { model | currentPage = LandingPage }
            , Cmd.none
            )

        GameMsg gameMsg ->
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
                                [ Cmd.map GameMsg gameCmd
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
                Landing.PlayGameClicked ->
                    update NavigateToGame { model | landingModel = updatedLandingModel }

                Landing.PlayRobotGameClicked ->
                    update NavigateToRobotGame { model | landingModel = updatedLandingModel }

                Landing.ViewStyleGuideClicked ->
                    update NavigateToStyleGuide { model | landingModel = updatedLandingModel }

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
                        |> Html.map GameMsg

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
            -- Use the Theme module's style guide
            viewStyleGuideWithNavigation model.colorScheme model.maybeWindow NavigateToLanding


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
                        |> Sub.map GameMsg
                    , receiveFromWorker
                        (Decode.decodeValue TicTacToeModel.decodeMsg
                            >> Result.map GameMsg
                            >> Result.withDefault (GameMsg (TicTacToeModel.GameError (TicTacToeModel.createJsonError "Failed to decode worker message")))
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


{-| Main program entry point
-}
main : Program Flags AppModel AppMsg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- Ports for JavaScript integration


port modeChanged : (Decode.Value -> msg) -> Sub msg


port themeChanged : String -> Cmd msg


port sendToWorker : Encode.Value -> Cmd msg


port receiveFromWorker : (Decode.Value -> msg) -> Sub msg

port module App exposing (AppModel, AppMsg, Flags, Page, main)

{-| Main application module that provides routing between landing page, game, and style guide.

This module serves as the new entry point for the Tic-Tac-Toe application, providing
navigation between three main views while preserving state and theme preferences.

-}

import Browser
import Browser.Dom
import Browser.Events
import Element
import Element.Background as Background
import Element.Border
import Element.Events
import Element.Font as Font
import Html exposing (Html)
import Json.Decode as Decode
import Json.Encode as Encode
import Landing.Landing as Landing
import Landing.LandingView as LandingView
import Task
import TicTacToe.Main as TicTacToeMain
import TicTacToe.Model as TicTacToeModel
import TicTacToe.View as TicTacToeView


{-| Represents the three possible pages in the application
-}
type Page
    = LandingPage
    | GamePage
    | StyleGuidePage


{-| Main application model containing all page states
-}
type alias AppModel =
    { currentPage : Page
    , colorScheme : TicTacToeModel.ColorScheme
    , gameModel : Maybe TicTacToeModel.Model
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
    | NavigateToStyleGuide
    | NavigateToLanding
    | GameMsg TicTacToeModel.Msg
    | LandingMsg Landing.Msg
    | ColorSchemeChanged TicTacToeModel.ColorScheme
    | WindowResized Int Int
    | GetViewPort Browser.Dom.Viewport


{-| Initialize the application with landing page as default
-}
init : Flags -> ( AppModel, Cmd AppMsg )
init flags =
    let
        colorScheme =
            case Decode.decodeString TicTacToeModel.decodeColorScheme flags.colorScheme of
                Ok decodedColorScheme ->
                    decodedColorScheme

                Err _ ->
                    TicTacToeModel.Light

        landingModel =
            Landing.init colorScheme Nothing
    in
    ( { currentPage = LandingPage
      , colorScheme = colorScheme
      , gameModel = Nothing
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
                                            case TicTacToeModel.encodeModel updatedGameModel of
                                                encodedModel ->
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

        LandingMsg landingMsg ->
            let
                updatedLandingModel =
                    Landing.update landingMsg model.landingModel
            in
            case landingMsg of
                Landing.PlayGameClicked ->
                    update NavigateToGame { model | landingModel = updatedLandingModel }

                Landing.ViewStyleGuideClicked ->
                    update NavigateToStyleGuide { model | landingModel = updatedLandingModel }

                Landing.ColorSchemeToggled ->
                    let
                        newScheme =
                            case model.colorScheme of
                                TicTacToeModel.Light ->
                                    TicTacToeModel.Dark

                                TicTacToeModel.Dark ->
                                    TicTacToeModel.Light
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
            in
            ( { model
                | colorScheme = newScheme
                , landingModel = updatedLandingModel
                , gameModel = updatedGameModel
              }
            , themeChanged
                (case newScheme of
                    TicTacToeModel.Light ->
                        "Light"

                    TicTacToeModel.Dark ->
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
            in
            ( { model
                | maybeWindow = newWindow
                , landingModel = updatedLandingModel
                , gameModel = updatedGameModel
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

        StyleGuidePage ->
            -- Integrate elm-book style guide with theme support
            viewStyleGuide model


{-| Render the style guide with theme support and navigation back to landing
-}
viewStyleGuide : AppModel -> Html AppMsg
viewStyleGuide model =
    let
        theme =
            TicTacToeView.currentTheme model.colorScheme

        -- Create a game model for the style guide with current theme
        initialModel =
            TicTacToeModel.initialModel

        styleGuideModel =
            { initialModel
                | colorScheme = model.colorScheme
                , maybeWindow = model.maybeWindow
            }
    in
    Element.layout
        [ Background.color theme.backgroundColor
        , Font.color theme.fontColor
        ]
    <|
        Element.column
            [ Element.width Element.fill
            , Element.height Element.fill
            ]
            [ -- Header with back navigation
              Element.row
                [ Element.width Element.fill
                , Element.padding 20
                , Background.color theme.headerBackgroundColor
                , Element.spacing 20
                ]
                [ Element.el
                    [ Element.pointer
                    , Element.Events.onClick NavigateToLanding
                    , Element.padding 10
                    , Background.color theme.buttonColor
                    , Element.Border.rounded 4
                    , Element.mouseOver [ Background.color theme.buttonHoverColor ]
                    ]
                    (Element.text "← Back to Home")
                , Element.el
                    [ Font.size 24
                    , Font.bold
                    , Font.color theme.fontColor
                    ]
                    (Element.text "Component Style Guide")
                ]

            -- Style guide content
            , Element.el
                [ Element.width Element.fill
                , Element.height Element.fill
                ]
                (Element.html (viewStyleGuideContent styleGuideModel |> Html.map GameMsg))
            ]


{-| Render the actual style guide content using elm-book
-}
viewStyleGuideContent : TicTacToeModel.Model -> Html TicTacToeModel.Msg
viewStyleGuideContent model =
    -- For now, create a simple themed style guide
    -- In a full implementation, this would integrate with elm-book
    let
        theme =
            TicTacToeView.currentTheme model.colorScheme
    in
    Element.layout
        [ Background.color theme.backgroundColor
        , Font.color theme.fontColor
        ]
    <|
        Element.column
            [ Element.padding 40
            , Element.spacing 30
            , Element.width Element.fill
            ]
            [ -- Theme showcase
              Element.column
                [ Element.spacing 20
                , Element.width Element.fill
                ]
                [ Element.el
                    [ Font.size 28
                    , Font.bold
                    , Font.color theme.fontColor
                    ]
                    (Element.text "Theme Colors")
                , viewThemeColorSwatch "Background" theme.backgroundColor
                , viewThemeColorSwatch "Board Background" theme.boardBackgroundColor
                , viewThemeColorSwatch "Cell Background" theme.cellBackgroundColor
                , viewThemeColorSwatch "Border" theme.borderColor
                , viewThemeColorSwatch "Accent" theme.accentColor
                , viewThemeColorSwatch "Font" theme.fontColor
                , viewThemeColorSwatch "Secondary Font" theme.secondaryFontColor
                ]

            -- Player symbols showcase
            , Element.column
                [ Element.spacing 20
                , Element.width Element.fill
                ]
                [ Element.el
                    [ Font.size 28
                    , Font.bold
                    , Font.color theme.fontColor
                    ]
                    (Element.text "Player Symbols")
                , Element.row
                    [ Element.spacing 40 ]
                    [ Element.column
                        [ Element.spacing 10 ]
                        [ Element.text "Player X"
                        , Element.el
                            [ Element.width (Element.px 100)
                            , Element.height (Element.px 100)
                            , Background.color theme.cellBackgroundColor
                            , Element.padding 20
                            , Element.Border.rounded 8
                            ]
                            (TicTacToeView.viewPlayerAsSvg model TicTacToeModel.X)
                        ]
                    , Element.column
                        [ Element.spacing 10 ]
                        [ Element.text "Player O"
                        , Element.el
                            [ Element.width (Element.px 100)
                            , Element.height (Element.px 100)
                            , Background.color theme.cellBackgroundColor
                            , Element.padding 20
                            , Element.Border.rounded 8
                            ]
                            (TicTacToeView.viewPlayerAsSvg model TicTacToeModel.O)
                        ]
                    ]
                ]

            -- Sample game cell
            , Element.column
                [ Element.spacing 20
                , Element.width Element.fill
                ]
                [ Element.el
                    [ Font.size 28
                    , Font.bold
                    , Font.color theme.fontColor
                    ]
                    (Element.text "Game Components")
                , Element.text "Sample game cells:"
                , Element.row
                    [ Element.spacing 20 ]
                    [ TicTacToeView.viewCell model 0 0 Nothing
                    , TicTacToeView.viewCell model 0 1 (Just TicTacToeModel.X)
                    , TicTacToeView.viewCell model 0 2 (Just TicTacToeModel.O)
                    ]
                ]
            ]


{-| Helper function to display a color swatch with label
-}
viewThemeColorSwatch : String -> Element.Color -> Element.Element msg
viewThemeColorSwatch label color =
    Element.row
        [ Element.spacing 20
        , Element.width Element.fill
        ]
        [ Element.el
            [ Element.width (Element.px 150) ]
            (Element.text label)
        , Element.el
            [ Background.color color
            , Element.width (Element.px 100)
            , Element.height (Element.px 40)
            , Element.Border.rounded 4
            , Element.Border.width 1
            , Element.Border.color (Element.rgb 0.8 0.8 0.8)
            ]
            Element.none
        ]


{-| Subscriptions for the application
-}
subscriptions : AppModel -> Sub AppMsg
subscriptions model =
    Sub.batch
        [ -- Window resize events
          Browser.Events.onResize WindowResized

        -- Theme change events from JavaScript
        , modeChanged
            (Decode.decodeValue TicTacToeModel.decodeColorScheme
                >> Result.map ColorSchemeChanged
                >> Result.withDefault (ColorSchemeChanged TicTacToeModel.Light)
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
        ]


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

port module TicTacToe.Main exposing (Flags, main, update)

import Browser
import Browser.Dom
import Browser.Events
import Html exposing (Html)
import Json.Decode as Decode
import Json.Encode as Encode
import Task
import Theme.Theme exposing (ColorScheme(..), decodeColorScheme)
import TicTacToe.Model as Model exposing (ErrorInfo, GameState(..), Model, Msg(..), Player(..), Position, createGameLogicError, createInvalidMoveError, createJsonError, createTimeoutError, encodeModel, initialModel)
import TicTacToe.TicTacToe as TicTacToe exposing (isValidMove, makeMove, updateGameState)
import TicTacToe.View as View
import Time


type alias Flags =
    { colorScheme : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        colorScheme =
            case Decode.decodeString decodeColorScheme flags.colorScheme of
                Ok decodedColorScheme ->
                    decodedColorScheme

                Err _ ->
                    Light
    in
    ( { initialModel | colorScheme = colorScheme }
    , Task.perform GetViewPort Browser.Dom.getViewport
    )


view : Model -> Html Msg
view =
    View.view


{-| Validate a move with detailed error information
-}
validateMove : Position -> Model.Board -> GameState -> Result ErrorInfo ()
validateMove position board gameState =
    if not (TicTacToe.isValidPosition position) then
        Err (createInvalidMoveError ("Position (" ++ String.fromInt position.row ++ ", " ++ String.fromInt position.col ++ ") is out of bounds"))

    else if TicTacToe.getCellState position board /= Nothing then
        Err (createInvalidMoveError ("Cell at (" ++ String.fromInt position.row ++ ", " ++ String.fromInt position.col ++ ") is already occupied"))

    else
        case gameState of
            Waiting _ ->
                Ok ()

            Thinking _ ->
                Ok ()

            Winner _ ->
                Err (createGameLogicError "Cannot make moves after game has ended with a winner")

            Draw ->
                Err (createGameLogicError "Cannot make moves after game has ended in a draw")

            Error _ ->
                Err (createGameLogicError "Cannot make moves while game is in error state")


encodeModelSafely : Model -> Result ErrorInfo Encode.Value
encodeModelSafely model =
    case validateModelForEncoding model of
        Ok () ->
            Ok (encodeModel model)

        Err errorInfo ->
            Err errorInfo


validateModelForEncoding : Model -> Result ErrorInfo ()
validateModelForEncoding model =
    if List.length model.board /= 3 then
        Err (createGameLogicError "Invalid board: must have exactly 3 rows")

    else if not (List.all (\row -> List.length row == 3) model.board) then
        Err (createGameLogicError "Invalid board: all rows must have exactly 3 columns")

    else
        case model.gameState of
            Thinking _ ->
                Ok ()

            _ ->
                Err (createGameLogicError "Model can only be sent to worker when in Thinking state")


handleMoveMade : Model -> Position -> ( Model, Cmd Msg )
handleMoveMade model position =
    case model.gameState of
        Waiting player ->
            case validateMove position model.board model.gameState of
                Ok () ->
                    let
                        newBoard =
                            makeMove player position model.board

                        newGameState =
                            updateGameState newBoard (Waiting player)

                        updatedModel =
                            { model
                                | board = newBoard
                                , gameState = newGameState
                                , lastMove = model.now
                            }
                    in
                    case newGameState of
                        Waiting nextPlayer ->
                            if nextPlayer == O then
                                let
                                    thinkingModel =
                                        { updatedModel | gameState = Thinking nextPlayer }

                                    encodedModel =
                                        encodeModelSafely thinkingModel
                                in
                                case encodedModel of
                                    Ok encoded ->
                                        ( thinkingModel, sendToWorker encoded )

                                    Err errorInfo ->
                                        ( { updatedModel | gameState = Error errorInfo }, Cmd.none )

                            else
                                ( updatedModel, Cmd.none )

                        _ ->
                            ( updatedModel, Cmd.none )

                Err errorInfo ->
                    ( { model | gameState = Error errorInfo }, Cmd.none )

        Thinking player ->
            if isValidMove position model.board (Waiting player) then
                let
                    newBoard =
                        makeMove player position model.board

                    newGameState =
                        updateGameState newBoard (Waiting player)

                    updatedModel =
                        { model
                            | board = newBoard
                            , gameState = newGameState
                            , lastMove = model.now
                        }
                in
                ( updatedModel, Cmd.none )

            else
                ( { model | gameState = Error (createGameLogicError "AI made invalid move - this should not happen") }, Cmd.none )

        _ ->
            ( { model | gameState = Error (createGameLogicError "Move attempted in invalid game state - game may have already ended") }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveMade position ->
            handleMoveMade model position

        ResetGame ->
            let
                resetModel =
                    { initialModel
                        | colorScheme = model.colorScheme
                        , lastMove = Nothing
                        , maybeWindow = model.maybeWindow
                    }
            in
            ( resetModel, Cmd.none )

        GameError errorInfo ->
            ( { model | gameState = Error errorInfo }, Cmd.none )

        ColorScheme colorScheme ->
            ( { model | colorScheme = colorScheme }
            , themeChanged
                (case colorScheme of
                    Light ->
                        "Light"

                    Dark ->
                        "Dark"
                )
            )

        GetViewPort viewport ->
            ( { model | maybeWindow = Just ( round viewport.scene.width, round viewport.scene.height ) }, Cmd.none )

        GetResize x y ->
            ( { model | maybeWindow = Just ( x, y ) }, Cmd.none )

        Tick now ->
            case ( model.gameState, model.lastMove ) of
                ( Waiting player, Just lastMove ) ->
                    if Time.posixToMillis now - Time.posixToMillis lastMove > Model.idleTimeoutMillis then
                        case TicTacToe.findBestMove player model.board of
                            Just bestPosition ->
                                handleMoveMade { model | now = Just now } bestPosition

                            Nothing ->
                                ( { model
                                    | gameState = Error (createGameLogicError "No valid moves available for auto-play - this should not happen")
                                    , now = Just now
                                  }
                                , Cmd.none
                                )

                    else
                        ( { model | now = Just now }, Cmd.none )

                ( Thinking _, Just lastMove ) ->
                    if Time.posixToMillis now - Time.posixToMillis lastMove > 10000 then
                        ( { model
                            | gameState = Error (createTimeoutError "AI worker timeout - please reset the game")
                            , now = Just now
                          }
                        , Cmd.none
                        )

                    else
                        ( { model | now = Just now }, Cmd.none )

                _ ->
                    ( { model | now = Just now }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Browser.Events.onResize GetResize
        , modeChanged
            (Decode.decodeValue decodeColorScheme
                >> Result.map ColorScheme
                >> Result.withDefault (ColorScheme Light)
            )
        , receiveFromWorker
            (Decode.decodeValue Model.decodeMsg
                >> Result.withDefault (GameError (createJsonError "Failed to decode worker message"))
            )
        , case model.gameState of
            Waiting _ ->
                Time.every 1000 Tick

            Thinking _ ->
                Time.every 1000 Tick

            _ ->
                Sub.none
        ]


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


port modeChanged : (Decode.Value -> msg) -> Sub msg


port themeChanged : String -> Cmd msg


port sendToWorker : Encode.Value -> Cmd msg


port receiveFromWorker : (Decode.Value -> msg) -> Sub msg

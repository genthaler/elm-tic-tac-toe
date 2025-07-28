port module Main exposing (Flags, encodeModelSafely, handleWorkerMessage, main, update, validateModelForEncoding, validateWorkerMessage)

{-| Main application module for the Elm Tic-Tac-Toe game.

This module implements a complete tic-tac-toe game with the following features:

  - **Human vs AI gameplay**: Play against an intelligent computer opponent
  - **Optimized AI**: Uses negamax algorithm with alpha-beta pruning for fast, strategic moves
  - **Web Worker integration**: AI computations run in background to keep UI responsive
  - **Responsive design**: Adapts to different screen sizes and devices
  - **Theme support**: Light and dark color schemes with smooth transitions
  - **Timeout handling**: Auto-play feature prevents games from stalling
  - **Comprehensive error handling**: Graceful recovery from various error conditions


# Architecture

The application follows Elm's Model-View-Update (MVU) architecture with these key components:

  - **Model**: Immutable game state including board, player turns, and UI state
  - **View**: Declarative UI rendering using elm-ui with SVG graphics
  - **Update**: Pure functions handling all state transitions and side effects
  - **Ports**: Communication bridge with JavaScript for web worker integration


# Performance Features

  - **Adaptive search depth**: AI adjusts thinking time based on game complexity
  - **Move ordering optimization**: Better alpha-beta pruning through tactical move prioritization
  - **Early termination**: Immediate detection of winning/blocking moves
  - **Iterative deepening**: Progressive search refinement for complex positions
  - **Efficient board evaluation**: Optimized scoring with position caching


# Usage

The game starts automatically when loaded. Players click empty cells to make moves,
and the AI responds intelligently. Use the reset button to start new games and the
theme toggle to switch between light and dark modes.

-}

import Browser
import Browser.Dom
import Browser.Events
import Json.Decode as Decode
import Json.Encode as Encode
import Model exposing (ColorScheme(..), ErrorInfo, Flags, GameState(..), Model, Msg(..), Player(..), Position, createGameLogicError, createInvalidMoveError, createJsonError, createTimeoutError, createWorkerCommunicationError, decodeColorScheme, decodeMsg, encodeModel, initialModel, isRecoverableError, recoverFromError)
import Result.Extra
import Task
import TicTacToe.TicTacToe exposing (findBestMove, isValidMove, makeMove, updateGameState)
import Time
import View exposing (view)


{-| Validate a move with detailed error information
-}
validateMove : Position -> Model.Board -> GameState -> Result ErrorInfo ()
validateMove position board gameState =
    if not (TicTacToe.TicTacToe.isValidPosition position) then
        Err (createInvalidMoveError ("Position (" ++ String.fromInt position.row ++ ", " ++ String.fromInt position.col ++ ") is out of bounds"))

    else if TicTacToe.TicTacToe.getCellState position board /= Nothing then
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



-- Init


type alias Flags =
    { colorScheme : String }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        colorScheme : ColorScheme
        colorScheme =
            case Decode.decodeString decodeColorScheme flags.colorScheme of
                Ok decodedColorScheme ->
                    decodedColorScheme

                Err _ ->
                    Light
    in
    ( { initialModel | colorScheme = colorScheme }, Task.perform GetViewPort Browser.Dom.getViewport )



-- Update


{-| Handle messages received from the web worker with robust error handling
-}
handleWorkerMessage : Decode.Value -> Msg
handleWorkerMessage value =
    case Decode.decodeValue decodeMsg value of
        Ok msg ->
            validateWorkerMessage msg

        Err error ->
            let
                errorDetails =
                    "Failed to decode worker message: " ++ Decode.errorToString error

                jsonString =
                    Encode.encode 0 value
                        |> String.left 200
                        |> (\s ->
                                if String.length s == 200 then
                                    s ++ "..."

                                else
                                    s
                           )

                fullError =
                    errorDetails ++ " (JSON: " ++ jsonString ++ ")"
            in
            GameError (createJsonError fullError)


{-| Validate that worker messages are reasonable and safe
-}
validateWorkerMessage : Msg -> Msg
validateWorkerMessage msg =
    case msg of
        MoveMade position ->
            if TicTacToe.TicTacToe.isValidPosition position then
                msg

            else
                GameError (createWorkerCommunicationError ("Worker sent invalid position: (" ++ String.fromInt position.row ++ ", " ++ String.fromInt position.col ++ ")"))

        GameError errorInfo ->
            -- Validate error info structure
            if String.isEmpty errorInfo.message then
                GameError (createWorkerCommunicationError "Worker sent empty error message")

            else
                msg

        -- Other messages are passed through as-is
        _ ->
            msg


{-| Safely encode a model with validation and error handling
-}
encodeModelSafely : Model -> Result ErrorInfo Encode.Value
encodeModelSafely model =
    -- Validate model before encoding
    case validateModelForEncoding model of
        Ok () ->
            -- Try to encode the model
            case encodeModelWithErrorHandling model of
                Ok encoded ->
                    Ok encoded

                Err error ->
                    Err (createJsonError ("Failed to encode model: " ++ error))

        Err errorInfo ->
            Err errorInfo


{-| Validate that a model is safe to encode and send to worker
-}
validateModelForEncoding : Model -> Result ErrorInfo ()
validateModelForEncoding model =
    -- Check board structure
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


{-| Encode model with error handling
-}
encodeModelWithErrorHandling : Model -> Result String Encode.Value
encodeModelWithErrorHandling model =
    try (\_ -> encodeModel model)
        |> Result.mapError (\_ -> "Encoding failed due to invalid model structure")


{-| Simple try function for error handling
-}
try : (() -> a) -> Result String a
try fn =
    -- In Elm, we can't actually catch runtime errors, so we'll just call the function
    -- This is more of a placeholder for where we might add more sophisticated error handling
    Ok (fn ())


{-| Handle a move made by either human or AI player
-}
handleMoveMade : Model -> Position -> ( Model, Cmd Msg )
handleMoveMade model position =
    case model.gameState of
        Waiting player ->
            -- Validate the move with detailed error messages
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
                                -- AI's turn - send to worker with error handling
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
                                -- Human's turn continues
                                ( updatedModel, Cmd.none )

                        _ ->
                            -- Game ended
                            ( updatedModel, Cmd.none )

                Err errorInfo ->
                    ( { model | gameState = Error errorInfo }, Cmd.none )

        Thinking player ->
            -- This is an AI move response from the worker
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
                    { initialModel | colorScheme = model.colorScheme, lastMove = Nothing }
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
                    -- if it's been idle long enough, trigger auto-play
                    if Time.posixToMillis now - Time.posixToMillis lastMove > Model.idleTimeoutMillis then
                        -- Find best move for the timed-out player and apply it automatically
                        case TicTacToe.TicTacToe.findBestMove player model.board of
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

                ( Thinking player, Just lastMove ) ->
                    -- Check for worker timeout (10 seconds)
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



-- Main


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- Ports


port sendToWorker : Encode.Value -> Cmd msg


port receiveFromWorker : (Decode.Value -> msg) -> Sub msg


port modeChanged : (Decode.Value -> msg) -> Sub msg


port themeChanged : String -> Cmd msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Browser.Events.onResize GetResize
        , Decode.decodeValue decodeColorScheme
            >> Result.map ColorScheme
            >> Result.mapError (Decode.errorToString >> createWorkerCommunicationError >> GameError)
            >> Result.Extra.merge
            |> modeChanged
        , case model.gameState of
            Waiting _ ->
                Time.every 1000 Tick

            Thinking _ ->
                Sub.batch
                    [ receiveFromWorker handleWorkerMessage
                    , Time.every 1000 Tick -- Continue time tracking during AI thinking
                    ]

            _ ->
                Sub.none
        ]

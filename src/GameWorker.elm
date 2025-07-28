port module GameWorker exposing (main)

{-| GameWorker module handles AI computations in a web worker to prevent blocking the main UI thread.

This module runs in a separate JavaScript worker thread and provides:


# Key Features

  - **Non-blocking AI**: Calculations run in background without freezing UI
  - **Robust communication**: JSON-based message passing with error handling
  - **Input validation**: Comprehensive validation of incoming game states
  - **Error recovery**: Graceful handling of invalid states and communication failures


# Architecture

The worker follows a simple request-response pattern:

1.  Main thread sends game model when AI needs to move
2.  Worker validates the model and game state
3.  Worker calculates the best move using optimized algorithms
4.  Worker sends the move back to the main thread
5.  Main thread applies the move and updates the UI


# Performance

  - Uses optimized negamax with alpha-beta pruning
  - Adaptive search depth based on game complexity
  - Move ordering for better pruning efficiency
  - Comprehensive input validation to prevent errors


# Error Handling

The worker includes extensive error handling for:

  - Invalid JSON messages
  - Malformed game states
  - Board validation errors
  - AI calculation failures
  - Communication timeouts

-}

import Json.Decode as Decode
import Json.Encode as Encode
import Model exposing (GameState(..), Msg(..), createGameLogicError, createJsonError, createWorkerCommunicationError, decodeModel, encodeMsg)
import TicTacToe.TicTacToe exposing (findBestMove)


{-| Worker state - we don't need to maintain any state in the worker
-}
type alias WorkerModel =
    ()


{-| Initialize the worker with empty state
-}
init : () -> ( WorkerModel, Cmd Msg )
init _ =
    ( (), Cmd.none )


{-| Update function handles messages by encoding them and sending back to main thread
-}
update : Msg -> WorkerModel -> ( WorkerModel, Cmd Msg )
update msg model =
    ( model, sendMove (encodeMsg msg) )


{-| Subscriptions handle incoming models from the main thread and calculate AI moves
-}
subscriptions : WorkerModel -> Sub Msg
subscriptions _ =
    getModel handleIncomingModel


{-| Handle incoming model data from the main thread
Decode the model and calculate the appropriate AI move based on game state
-}
handleIncomingModel : Decode.Value -> Msg
handleIncomingModel value =
    case Decode.decodeValue decodeModel value of
        Ok model ->
            case validateIncomingModel model of
                Ok validatedModel ->
                    calculateAIMove validatedModel

                Err errorInfo ->
                    GameError errorInfo

        Err error ->
            let
                errorDetails =
                    "Worker failed to decode model: " ++ Decode.errorToString error

                jsonString =
                    Encode.encode 0 value
                        |> String.left 100
                        |> (\s ->
                                if String.length s == 100 then
                                    s ++ "..."

                                else
                                    s
                           )

                fullError =
                    errorDetails ++ " (JSON: " ++ jsonString ++ ")"
            in
            GameError (createJsonError fullError)


{-| Calculate the AI move based on the current game state
Only processes Thinking states - other states are considered errors in the worker context
-}
calculateAIMove : Model.Model -> Msg
calculateAIMove model =
    case model.gameState of
        Thinking player ->
            -- Validate board state before attempting to find move
            case validateBoardForAI model.board of
                Ok validBoard ->
                    case findBestMove player validBoard of
                        Just position ->
                            MoveMade position

                        Nothing ->
                            GameError (createGameLogicError "AI could not find a valid move - board may be full or invalid")

                Err errorInfo ->
                    GameError errorInfo

        _ ->
            GameError (createWorkerCommunicationError "Worker received unexpected game state")


{-| Validate incoming model from main thread
-}
validateIncomingModel : Model.Model -> Result Model.ErrorInfo Model.Model
validateIncomingModel model =
    -- Check basic model structure
    if List.length model.board /= 3 then
        Err (createWorkerCommunicationError "Invalid model: board must have exactly 3 rows")

    else if not (List.all (\row -> List.length row == 3) model.board) then
        Err (createWorkerCommunicationError "Invalid model: all rows must have exactly 3 columns")

    else
        case model.gameState of
            Thinking _ ->
                Ok model

            _ ->
                Err (createWorkerCommunicationError "Worker should only receive Thinking state")


{-| Validate that the board state is reasonable for AI processing
-}
validateBoardForAI : Model.Board -> Result Model.ErrorInfo Model.Board
validateBoardForAI board =
    let
        -- Check board has correct dimensions (3x3)
        hasCorrectDimensions =
            List.length board == 3 && List.all (\row -> List.length row == 3) board

        -- Count X and O pieces to ensure valid game state
        ( xCount, oCount ) =
            board
                |> List.concat
                |> List.foldl
                    (\cell ( xAccum, oAccum ) ->
                        case cell of
                            Just Model.X ->
                                ( xAccum + 1, oAccum )

                            Just Model.O ->
                                ( xAccum, oAccum + 1 )

                            Nothing ->
                                ( xAccum, oAccum )
                    )
                    ( 0, 0 )

        -- X should have equal or one more piece than O (X goes first)
        validPieceCount =
            xCount == oCount || xCount == oCount + 1

        -- Check for reasonable piece counts (max 9 total pieces)
        totalPieces =
            xCount + oCount

        reasonablePieceCount =
            totalPieces <= 9
    in
    if not hasCorrectDimensions then
        Err (createWorkerCommunicationError "Board has invalid dimensions - must be 3x3")

    else if not validPieceCount then
        Err (createWorkerCommunicationError ("Invalid piece count - X: " ++ String.fromInt xCount ++ ", O: " ++ String.fromInt oCount))

    else if not reasonablePieceCount then
        Err (createWorkerCommunicationError ("Too many pieces on board - total: " ++ String.fromInt totalPieces))

    else
        Ok board


{-| Main program entry point for the web worker
-}
main : Program () WorkerModel Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }


{-| Port for receiving model data from the main thread
-}
port getModel : (Decode.Value -> msg) -> Sub msg


{-| Port for sending move messages back to the main thread
-}
port sendMove : Encode.Value -> Cmd msg

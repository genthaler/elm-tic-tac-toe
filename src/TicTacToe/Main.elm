port module TicTacToe.Main exposing (Flags, main, update)

import Browser
import Browser.Dom
import Browser.Events
import Dict
import Html exposing (Html)
import Json.Decode as Decode
import Json.Encode as Encode
import Task
import Theme.Theme exposing (ColorScheme(..), decodeColorScheme)
import TicTacToe.Model as Model exposing (AITurnState(..), ErrorInfo, GameState(..), Model, Msg(..), Player(..), Position, SearchAlgorithm(..), createGameLogicError, createInvalidMoveError, createJsonError, createTimeoutError, encodeModel, initialModel, startSearchInspection)
import TicTacToe.SearchTrace as SearchTrace
import TicTacToe.TicTacToe as TicTacToe exposing (getCellState, isValidPosition, makeMove, updateGameState)
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


validateMove : Position -> Model.Board -> GameState -> Result ErrorInfo ()
validateMove position board gameState =
    if not (isValidPosition position) then
        Err (createInvalidMoveError ("Position (" ++ String.fromInt position.row ++ ", " ++ String.fromInt position.col ++ ") is out of bounds"))

    else if getCellState position board /= Nothing then
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


applyMoveForPlayer : Player -> Model -> Position -> Result ErrorInfo Model
applyMoveForPlayer player model position =
    case validateMove position model.board model.gameState of
        Ok () ->
            let
                newBoard =
                    makeMove player position model.board

                newGameState =
                    updateGameState newBoard (Waiting player)
            in
            Ok
                { model
                    | board = newBoard
                    , gameState = newGameState
                    , lastMove = model.now
                }

        Err errorInfo ->
            Err errorInfo


queueComputerChoice : Model -> Model
queueComputerChoice model =
    case model.gameState of
        Waiting O ->
            { model | aiTurnState = Just AwaitingChoice }

        _ ->
            { model | aiTurnState = Nothing }


handleMoveMade : Model -> Position -> ( Model, Cmd Msg )
handleMoveMade model position =
    case model.gameState of
        Waiting X ->
            case applyMoveForPlayer X model position of
                Ok updatedModel ->
                    ( queueComputerChoice updatedModel, Cmd.none )

                Err errorInfo ->
                    ( { model | gameState = Error errorInfo, aiTurnState = Nothing }, Cmd.none )

        Thinking player ->
            case applyMoveForPlayer player { model | aiTurnState = Nothing } position of
                Ok updatedModel ->
                    ( queueComputerChoice updatedModel, Cmd.none )

                Err errorInfo ->
                    ( { model | gameState = Error errorInfo, aiTurnState = Nothing }, Cmd.none )

        Waiting O ->
            ( { model | gameState = Error (createGameLogicError "Choose Auto move or inspect the AI search before applying Player O's move") }
            , Cmd.none
            )

        _ ->
            ( { model | gameState = Error (createGameLogicError "Move attempted in invalid game state - game may have already ended") }
            , Cmd.none
            )


requestFastAIMove : Model -> ( Model, Cmd Msg )
requestFastAIMove model =
    case model.gameState of
        Waiting O ->
            let
                thinkingModel =
                    { model | gameState = Thinking O, aiTurnState = Just FastThinking }
            in
            case encodeModelSafely thinkingModel of
                Ok encoded ->
                    ( thinkingModel, sendToWorker encoded )

                Err errorInfo ->
                    ( { model | gameState = Error errorInfo, aiTurnState = Nothing }, Cmd.none )

        _ ->
            ( model, Cmd.none )


startInspection : SearchAlgorithm -> Model -> Model
startInspection algorithm model =
    case model.gameState of
        Waiting O ->
            let
                trace =
                    case algorithm of
                        Negamax ->
                            SearchTrace.buildNegamaxTrace O model.board

                        AlphaBeta ->
                            SearchTrace.buildAlphaBetaTrace O model.board
            in
            { model | aiTurnState = Just (Inspecting (startSearchInspection algorithm (convertSearchTrace trace))) }

        _ ->
            model


convertSearchTrace : SearchTrace.SearchTrace -> Model.SearchTrace
convertSearchTrace trace =
    { algorithm = convertSearchAlgorithmFromTrace trace.algorithm
    , rootNodeId = trace.rootNodeId
    , nodes =
        trace.nodes
            |> Dict.toList
            |> List.map (\( nodeId, node ) -> ( nodeId, convertSearchNode node ))
            |> Dict.fromList
    , events = List.map convertSearchEvent trace.events
    , bestMove = trace.bestMove
    }


convertSearchAlgorithmFromTrace : SearchTrace.SearchAlgorithm -> SearchAlgorithm
convertSearchAlgorithmFromTrace algorithm =
    case algorithm of
        SearchTrace.Negamax ->
            Negamax

        SearchTrace.AlphaBeta ->
            AlphaBeta


convertSearchNode : SearchTrace.SearchNode -> Model.SearchNode
convertSearchNode node =
    { id = node.id
    , board = node.board
    , player = node.player
    , depth = node.depth
    , moveFromParent = node.moveFromParent
    , score = node.score
    , alpha = node.alpha
    , beta = node.beta
    , status = convertSearchNodeStatus node.status
    , children = node.children
    }


convertSearchNodeStatus : SearchTrace.SearchNodeStatus -> Model.SearchNodeStatus
convertSearchNodeStatus status =
    case status of
        SearchTrace.Unvisited ->
            Model.Unvisited

        SearchTrace.Active ->
            Model.Active

        SearchTrace.Expanded ->
            Model.Expanded

        SearchTrace.Finalized ->
            Model.Finalized

        SearchTrace.Pruned ->
            Model.Pruned


convertSearchEvent : SearchTrace.SearchEvent -> Model.SearchEvent
convertSearchEvent event =
    case event of
        SearchTrace.EnteredNode nodeId ->
            Model.EnteredNode nodeId

        SearchTrace.ConsideredMove nodeId position childId ->
            Model.ConsideredMove nodeId position childId

        SearchTrace.LeafEvaluated nodeId score ->
            Model.LeafEvaluated nodeId score

        SearchTrace.ScorePropagated nodeId childId score ->
            Model.ScorePropagated nodeId childId score

        SearchTrace.AlphaUpdated nodeId value ->
            Model.AlphaUpdated nodeId value

        SearchTrace.BetaUpdated nodeId value ->
            Model.BetaUpdated nodeId value

        SearchTrace.PrunedBranch nodeId childId position alpha beta ->
            Model.PrunedBranch nodeId childId position alpha beta

        SearchTrace.NodeFinalized nodeId score ->
            Model.NodeFinalized nodeId score


applyInspectionMove : Model -> ( Model, Cmd Msg )
applyInspectionMove model =
    case model.aiTurnState of
        Just (Inspecting inspection) ->
            case inspection.trace.bestMove of
                Just bestMove ->
                    case applyMoveForPlayer O { model | gameState = Thinking O } bestMove of
                        Ok updatedModel ->
                            ( { updatedModel | aiTurnState = Nothing }, Cmd.none )

                        Err errorInfo ->
                            ( { model | gameState = Error errorInfo, aiTurnState = Nothing }, Cmd.none )

                Nothing ->
                    ( { model | gameState = Error (createGameLogicError "No inspected move is available to apply"), aiTurnState = Nothing }
                    , Cmd.none
                    )

        _ ->
            ( model, Cmd.none )


updateInspection : (Model.SearchInspection -> Model.SearchInspection) -> Model -> Model
updateInspection transform model =
    case model.aiTurnState of
        Just (Inspecting inspection) ->
            { model | aiTurnState = Just (Inspecting (transform inspection)) }

        _ ->
            model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveMade position ->
            handleMoveMade model position

        ResetGame ->
            ( { initialModel
                | colorScheme = model.colorScheme
                , lastMove = Nothing
                , maybeWindow = model.maybeWindow
              }
            , Cmd.none
            )

        GameError errorInfo ->
            ( { model | gameState = Error errorInfo, aiTurnState = Nothing }, Cmd.none )

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
                ( Waiting X, Just lastMove ) ->
                    if Time.posixToMillis now - Time.posixToMillis lastMove > Model.idleTimeoutMillis then
                        case TicTacToe.findBestMove X model.board of
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
                            , aiTurnState = Nothing
                          }
                        , Cmd.none
                        )

                    else
                        ( { model | now = Just now }, Cmd.none )

                _ ->
                    ( { model | now = Just now }, Cmd.none )

        RequestFastAIMove ->
            requestFastAIMove model

        StartInspection algorithm ->
            ( startInspection algorithm model, Cmd.none )

        StepInspectionBackward ->
            ( updateInspection Model.searchInspectionStepBackward model, Cmd.none )

        StepInspectionForward ->
            ( updateInspection Model.searchInspectionStepForward model, Cmd.none )

        PlayInspectionToEnd ->
            ( updateInspection Model.searchInspectionPlayToEnd model, Cmd.none )

        ApplyInspectionMove ->
            applyInspectionMove
                (updateInspection Model.searchInspectionMarkCommitted model)

        SelectInspectionNode nodeId ->
            ( updateInspection (Model.searchInspectionSelectNode nodeId) model, Cmd.none )


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
            Waiting X ->
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

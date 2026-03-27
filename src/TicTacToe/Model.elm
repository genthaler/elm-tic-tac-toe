module TicTacToe.Model exposing
    ( AITurnState(..)
    , Board
    , ErrorInfo
    , ErrorType(..)
    , GameState(..)
    , Line
    , Model
    , Msg(..)
    , Player(..)
    , Position
    , SearchAlgorithm(..)
    , SearchEvent(..)
    , SearchInspection
    , SearchNode
    , SearchNodeId
    , SearchNodeStatus(..)
    , SearchTrace
    , createGameLogicError
    , createInvalidMoveError
    , createJsonError
    , createTimeoutError
    , createUnknownError
    , createWorkerCommunicationError
    , decodeErrorType
    , decodeModel
    , decodeMsg
    , encodeModel
    , encodeMsg
    , idleTimeoutMillis
    , initialModel
    , recoverFromError
    , searchInspectionCurrentEvent
    , searchInspectionCurrentNode
    , searchInspectionGoToIndex
    , searchInspectionMarkCommitted
    , searchInspectionPlayToEnd
    , searchInspectionSelectNode
    , searchInspectionStepBackward
    , searchInspectionStepForward
    , startSearchInspection
    , timeSpent
    )

import Browser.Dom
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Decode.Pipeline as DecodePipeline
import Json.Encode as Encode
import Json.Encode.Extra as EncodeExtra
import Theme.Theme exposing (ColorScheme(..), decodeColorScheme, encodeColorScheme)
import Time


type alias Line =
    List (Maybe Player)


type alias Position =
    { row : Int, col : Int }


type alias Board =
    List Line


type alias Model =
    { board : Board
    , gameState : GameState
    , lastMove : Maybe Time.Posix
    , now : Maybe Time.Posix
    , colorScheme : ColorScheme
    , maybeWindow : Maybe ( Int, Int )
    , aiTurnState : Maybe AITurnState
    }


type GameState
    = Waiting Player
    | Thinking Player
    | Winner Player
    | Draw
    | Error ErrorInfo


type alias ErrorInfo =
    { message : String
    , errorType : ErrorType
    , recoverable : Bool
    }


type ErrorType
    = InvalidMove
    | GameLogicError
    | WorkerCommunicationError
    | JsonError
    | TimeoutError
    | UnknownError


type Player
    = X
    | O


type SearchAlgorithm
    = Negamax
    | AlphaBeta


type alias SearchNodeId =
    Int


type SearchNodeStatus
    = Unvisited
    | Active
    | Expanded
    | Finalized
    | Pruned


type alias SearchNode =
    { id : SearchNodeId
    , board : Board
    , player : Player
    , depth : Int
    , moveFromParent : Maybe Position
    , score : Maybe Int
    , alpha : Maybe Int
    , beta : Maybe Int
    , status : SearchNodeStatus
    , children : List SearchNodeId
    }


type SearchEvent
    = EnteredNode SearchNodeId
    | ConsideredMove SearchNodeId Position SearchNodeId
    | LeafEvaluated SearchNodeId Int
    | ScorePropagated SearchNodeId SearchNodeId Int
    | AlphaUpdated SearchNodeId Int
    | BetaUpdated SearchNodeId Int
    | PrunedBranch SearchNodeId SearchNodeId Position Int Int
    | NodeFinalized SearchNodeId Int


type alias SearchTrace =
    { algorithm : SearchAlgorithm
    , rootNodeId : SearchNodeId
    , nodes : Dict SearchNodeId SearchNode
    , events : List SearchEvent
    , bestMove : Maybe Position
    }


type alias SearchInspection =
    { trace : SearchTrace
    , currentEventIndex : Int
    , selectedNodeId : SearchNodeId
    , committed : Bool
    }


type AITurnState
    = AwaitingChoice
    | FastThinking
    | Inspecting SearchInspection


idleTimeoutMillis : Int
idleTimeoutMillis =
    5000


timeSpent : Model -> Float
timeSpent model =
    Maybe.map2 (\lastMove now -> Time.posixToMillis now - Time.posixToMillis lastMove |> Basics.toFloat) model.lastMove model.now
        |> Maybe.withDefault (toFloat idleTimeoutMillis)


initialModel : Model
initialModel =
    { board =
        [ [ Nothing, Nothing, Nothing ]
        , [ Nothing, Nothing, Nothing ]
        , [ Nothing, Nothing, Nothing ]
        ]
    , gameState = Waiting X
    , colorScheme = Light
    , lastMove = Nothing
    , now = Nothing
    , maybeWindow = Nothing
    , aiTurnState = Nothing
    }


type Msg
    = MoveMade Position
    | ResetGame
    | GameError ErrorInfo
    | ColorScheme ColorScheme
    | GetViewPort Browser.Dom.Viewport
    | GetResize Int Int
    | Tick Time.Posix
    | RequestFastAIMove
    | StartInspection SearchAlgorithm
    | StepInspectionBackward
    | StepInspectionForward
    | PlayInspectionToEnd
    | ApplyInspectionMove
    | SelectInspectionNode SearchNodeId


encodePosition : Position -> Encode.Value
encodePosition position =
    Encode.object
        [ ( "row", Encode.int position.row )
        , ( "col", Encode.int position.col )
        ]


decodePosition : Decode.Decoder Position
decodePosition =
    Decode.succeed Position
        |> DecodePipeline.required "row" Decode.int
        |> DecodePipeline.required "col" Decode.int


encodePlayer : Maybe Player -> Encode.Value
encodePlayer player =
    case player of
        Just X ->
            Encode.string "X"

        Just O ->
            Encode.string "O"

        Nothing ->
            Encode.null


decodePlayer : Decode.Decoder Player
decodePlayer =
    Decode.string
        |> Decode.andThen
            (\value ->
                case value of
                    "X" ->
                        Decode.succeed X

                    "O" ->
                        Decode.succeed O

                    _ ->
                        Decode.fail ("Invalid player: " ++ value)
            )


encodeViewport : Browser.Dom.Viewport -> Encode.Value
encodeViewport viewport =
    Encode.object
        [ ( "scene"
          , Encode.object
                [ ( "width", Encode.float viewport.scene.width )
                , ( "height", Encode.float viewport.scene.height )
                ]
          )
        , ( "viewport"
          , Encode.object
                [ ( "x", Encode.float viewport.viewport.x )
                , ( "y", Encode.float viewport.viewport.y )
                , ( "width", Encode.float viewport.viewport.width )
                , ( "height", Encode.float viewport.viewport.height )
                ]
          )
        ]


decodeViewport : Decode.Decoder Browser.Dom.Viewport
decodeViewport =
    Decode.succeed Browser.Dom.Viewport
        |> DecodePipeline.required "scene"
            (Decode.succeed (\width height -> { width = width, height = height })
                |> DecodePipeline.required "width" Decode.float
                |> DecodePipeline.required "height" Decode.float
            )
        |> DecodePipeline.required "viewport"
            (Decode.succeed (\x y width height -> { x = x, y = y, width = width, height = height })
                |> DecodePipeline.required "x" Decode.float
                |> DecodePipeline.required "y" Decode.float
                |> DecodePipeline.required "width" Decode.float
                |> DecodePipeline.required "height" Decode.float
            )


encodeGameState : GameState -> Encode.Value
encodeGameState state =
    case state of
        Waiting player ->
            Encode.object
                [ ( "type", Encode.string "Waiting" )
                , ( "player", encodePlayer (Just player) )
                ]

        Thinking player ->
            Encode.object
                [ ( "type", Encode.string "Thinking" )
                , ( "player", encodePlayer (Just player) )
                ]

        Winner player ->
            Encode.object
                [ ( "type", Encode.string "Winner" )
                , ( "player", encodePlayer (Just player) )
                ]

        Draw ->
            Encode.object [ ( "type", Encode.string "Draw" ) ]

        Error errorInfo ->
            Encode.object
                [ ( "type", Encode.string "Error" )
                , ( "message", Encode.string errorInfo.message )
                , ( "errorType", encodeErrorType errorInfo.errorType )
                , ( "recoverable", Encode.bool errorInfo.recoverable )
                ]


decodeGameState : Decode.Decoder GameState
decodeGameState =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\typeStr ->
                case typeStr of
                    "Waiting" ->
                        Decode.map Waiting (Decode.field "player" decodePlayer)

                    "Thinking" ->
                        Decode.map Thinking (Decode.field "player" decodePlayer)

                    "Winner" ->
                        Decode.map Winner (Decode.field "player" decodePlayer)

                    "Draw" ->
                        Decode.succeed Draw

                    "Error" ->
                        Decode.map Error
                            (Decode.succeed ErrorInfo
                                |> DecodePipeline.required "message" Decode.string
                                |> DecodePipeline.optional "errorType" decodeErrorType UnknownError
                                |> DecodePipeline.optional "recoverable" Decode.bool True
                            )

                    _ ->
                        Decode.fail ("Invalid game state type: " ++ typeStr)
            )


encodeModel : Model -> Encode.Value
encodeModel model =
    Encode.object
        [ ( "board", Encode.list (Encode.list encodePlayer) model.board )
        , ( "gameState", encodeGameState model.gameState )
        , ( "lastMove", EncodeExtra.maybe (Encode.int << Time.posixToMillis) model.lastMove )
        , ( "now", EncodeExtra.maybe (Encode.int << Time.posixToMillis) model.now )
        , ( "colorScheme", encodeColorScheme model.colorScheme )
        , ( "maybeWindow"
          , EncodeExtra.maybe
                (\( width, height ) ->
                    Encode.object
                        [ ( "width", Encode.int width )
                        , ( "height", Encode.int height )
                        ]
                )
                model.maybeWindow
          )
        , ( "aiTurnState", EncodeExtra.maybe encodeAITurnState model.aiTurnState )
        ]


decodeModel : Decode.Decoder Model
decodeModel =
    Decode.succeed
        (\board gameState lastMove now colorScheme maybeWindow aiTurnState ->
            { board = board
            , gameState = gameState
            , lastMove = lastMove
            , now = now
            , colorScheme = colorScheme
            , maybeWindow = maybeWindow
            , aiTurnState = aiTurnState
            }
        )
        |> DecodePipeline.required "board" (Decode.list (Decode.list (Decode.nullable decodePlayer)))
        |> DecodePipeline.required "gameState" decodeGameState
        |> DecodePipeline.optional "lastMove" (Decode.nullable (Decode.map Time.millisToPosix Decode.int)) Nothing
        |> DecodePipeline.optional "now" (Decode.nullable (Decode.map Time.millisToPosix Decode.int)) Nothing
        |> DecodePipeline.optional "colorScheme" decodeColorScheme Light
        |> DecodePipeline.optional "maybeWindow" (Decode.nullable (Decode.map2 Tuple.pair (Decode.field "width" Decode.int) (Decode.field "height" Decode.int))) Nothing
        |> DecodePipeline.optional "aiTurnState" (Decode.nullable decodeAITurnState) Nothing


encodeAITurnState : AITurnState -> Encode.Value
encodeAITurnState aiTurnState =
    case aiTurnState of
        AwaitingChoice ->
            Encode.object [ ( "type", Encode.string "AwaitingChoice" ) ]

        FastThinking ->
            Encode.object [ ( "type", Encode.string "FastThinking" ) ]

        Inspecting inspection ->
            Encode.object
                [ ( "type", Encode.string "Inspecting" )
                , ( "trace", encodeSearchTrace inspection.trace )
                , ( "currentEventIndex", Encode.int inspection.currentEventIndex )
                , ( "selectedNodeId", Encode.int inspection.selectedNodeId )
                , ( "committed", Encode.bool inspection.committed )
                ]


decodeAITurnState : Decode.Decoder AITurnState
decodeAITurnState =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\typeStr ->
                case typeStr of
                    "AwaitingChoice" ->
                        Decode.succeed AwaitingChoice

                    "FastThinking" ->
                        Decode.succeed FastThinking

                    "Inspecting" ->
                        Decode.succeed
                            (\trace currentEventIndex selectedNodeId committed ->
                                Inspecting
                                    { trace = trace
                                    , currentEventIndex = currentEventIndex
                                    , selectedNodeId = selectedNodeId
                                    , committed = committed
                                    }
                            )
                            |> DecodePipeline.required "trace" decodeSearchTrace
                            |> DecodePipeline.required "currentEventIndex" Decode.int
                            |> DecodePipeline.required "selectedNodeId" Decode.int
                            |> DecodePipeline.optional "committed" Decode.bool False

                    _ ->
                        Decode.fail ("Invalid AI turn state: " ++ typeStr)
            )


encodeSearchTrace : SearchTrace -> Encode.Value
encodeSearchTrace trace =
    Encode.object
        [ ( "algorithm", encodeSearchAlgorithm trace.algorithm )
        , ( "rootNodeId", Encode.int trace.rootNodeId )
        , ( "nodes", Encode.list encodeSearchNode (Dict.values trace.nodes |> List.sortBy .id) )
        , ( "events", Encode.list encodeSearchEvent trace.events )
        , ( "bestMove", EncodeExtra.maybe encodePosition trace.bestMove )
        ]


decodeSearchTrace : Decode.Decoder SearchTrace
decodeSearchTrace =
    Decode.succeed
        (\algorithm rootNodeId nodes events bestMove ->
            { algorithm = algorithm
            , rootNodeId = rootNodeId
            , nodes = Dict.fromList (List.map (\node -> ( node.id, node )) nodes)
            , events = events
            , bestMove = bestMove
            }
        )
        |> DecodePipeline.required "algorithm" decodeSearchAlgorithm
        |> DecodePipeline.required "rootNodeId" Decode.int
        |> DecodePipeline.required "nodes" (Decode.list decodeSearchNode)
        |> DecodePipeline.required "events" (Decode.list decodeSearchEvent)
        |> DecodePipeline.optional "bestMove" (Decode.nullable decodePosition) Nothing


encodeSearchAlgorithm : SearchAlgorithm -> Encode.Value
encodeSearchAlgorithm algorithm =
    case algorithm of
        Negamax ->
            Encode.string "Negamax"

        AlphaBeta ->
            Encode.string "AlphaBeta"


decodeSearchAlgorithm : Decode.Decoder SearchAlgorithm
decodeSearchAlgorithm =
    Decode.string
        |> Decode.andThen
            (\value ->
                case value of
                    "Negamax" ->
                        Decode.succeed Negamax

                    "AlphaBeta" ->
                        Decode.succeed AlphaBeta

                    _ ->
                        Decode.fail ("Invalid search algorithm: " ++ value)
            )


encodeSearchNode : SearchNode -> Encode.Value
encodeSearchNode node =
    Encode.object
        [ ( "id", Encode.int node.id )
        , ( "board", Encode.list (Encode.list encodePlayer) node.board )
        , ( "player", encodePlayer (Just node.player) )
        , ( "depth", Encode.int node.depth )
        , ( "moveFromParent", EncodeExtra.maybe encodePosition node.moveFromParent )
        , ( "score", EncodeExtra.maybe Encode.int node.score )
        , ( "alpha", EncodeExtra.maybe Encode.int node.alpha )
        , ( "beta", EncodeExtra.maybe Encode.int node.beta )
        , ( "status", encodeSearchNodeStatus node.status )
        , ( "children", Encode.list Encode.int node.children )
        ]


decodeSearchNode : Decode.Decoder SearchNode
decodeSearchNode =
    Decode.succeed
        (\id board player depth moveFromParent score alpha beta status children ->
            { id = id
            , board = board
            , player = player
            , depth = depth
            , moveFromParent = moveFromParent
            , score = score
            , alpha = alpha
            , beta = beta
            , status = status
            , children = children
            }
        )
        |> DecodePipeline.required "id" Decode.int
        |> DecodePipeline.required "board" (Decode.list (Decode.list (Decode.nullable decodePlayer)))
        |> DecodePipeline.required "player" decodePlayer
        |> DecodePipeline.required "depth" Decode.int
        |> DecodePipeline.optional "moveFromParent" (Decode.nullable decodePosition) Nothing
        |> DecodePipeline.optional "score" (Decode.nullable Decode.int) Nothing
        |> DecodePipeline.optional "alpha" (Decode.nullable Decode.int) Nothing
        |> DecodePipeline.optional "beta" (Decode.nullable Decode.int) Nothing
        |> DecodePipeline.required "status" decodeSearchNodeStatus
        |> DecodePipeline.required "children" (Decode.list Decode.int)


encodeSearchNodeStatus : SearchNodeStatus -> Encode.Value
encodeSearchNodeStatus status =
    case status of
        Unvisited ->
            Encode.string "Unvisited"

        Active ->
            Encode.string "Active"

        Expanded ->
            Encode.string "Expanded"

        Finalized ->
            Encode.string "Finalized"

        Pruned ->
            Encode.string "Pruned"


decodeSearchNodeStatus : Decode.Decoder SearchNodeStatus
decodeSearchNodeStatus =
    Decode.string
        |> Decode.andThen
            (\value ->
                case value of
                    "Unvisited" ->
                        Decode.succeed Unvisited

                    "Active" ->
                        Decode.succeed Active

                    "Expanded" ->
                        Decode.succeed Expanded

                    "Finalized" ->
                        Decode.succeed Finalized

                    "Pruned" ->
                        Decode.succeed Pruned

                    _ ->
                        Decode.fail ("Invalid search node status: " ++ value)
            )


encodeSearchEvent : SearchEvent -> Encode.Value
encodeSearchEvent event =
    case event of
        EnteredNode nodeId ->
            Encode.object
                [ ( "type", Encode.string "EnteredNode" )
                , ( "nodeId", Encode.int nodeId )
                ]

        ConsideredMove nodeId position childId ->
            Encode.object
                [ ( "type", Encode.string "ConsideredMove" )
                , ( "nodeId", Encode.int nodeId )
                , ( "position", encodePosition position )
                , ( "childId", Encode.int childId )
                ]

        LeafEvaluated nodeId score ->
            Encode.object
                [ ( "type", Encode.string "LeafEvaluated" )
                , ( "nodeId", Encode.int nodeId )
                , ( "score", Encode.int score )
                ]

        ScorePropagated nodeId childId score ->
            Encode.object
                [ ( "type", Encode.string "ScorePropagated" )
                , ( "nodeId", Encode.int nodeId )
                , ( "childId", Encode.int childId )
                , ( "score", Encode.int score )
                ]

        AlphaUpdated nodeId value ->
            Encode.object
                [ ( "type", Encode.string "AlphaUpdated" )
                , ( "nodeId", Encode.int nodeId )
                , ( "value", Encode.int value )
                ]

        BetaUpdated nodeId value ->
            Encode.object
                [ ( "type", Encode.string "BetaUpdated" )
                , ( "nodeId", Encode.int nodeId )
                , ( "value", Encode.int value )
                ]

        PrunedBranch nodeId childId position alpha beta ->
            Encode.object
                [ ( "type", Encode.string "PrunedBranch" )
                , ( "nodeId", Encode.int nodeId )
                , ( "childId", Encode.int childId )
                , ( "position", encodePosition position )
                , ( "alpha", Encode.int alpha )
                , ( "beta", Encode.int beta )
                ]

        NodeFinalized nodeId score ->
            Encode.object
                [ ( "type", Encode.string "NodeFinalized" )
                , ( "nodeId", Encode.int nodeId )
                , ( "score", Encode.int score )
                ]


decodeSearchEvent : Decode.Decoder SearchEvent
decodeSearchEvent =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\typeStr ->
                case typeStr of
                    "EnteredNode" ->
                        Decode.map EnteredNode (Decode.field "nodeId" Decode.int)

                    "ConsideredMove" ->
                        Decode.map3 ConsideredMove
                            (Decode.field "nodeId" Decode.int)
                            (Decode.field "position" decodePosition)
                            (Decode.field "childId" Decode.int)

                    "LeafEvaluated" ->
                        Decode.map2 LeafEvaluated
                            (Decode.field "nodeId" Decode.int)
                            (Decode.field "score" Decode.int)

                    "ScorePropagated" ->
                        Decode.map3 ScorePropagated
                            (Decode.field "nodeId" Decode.int)
                            (Decode.field "childId" Decode.int)
                            (Decode.field "score" Decode.int)

                    "AlphaUpdated" ->
                        Decode.map2 AlphaUpdated
                            (Decode.field "nodeId" Decode.int)
                            (Decode.field "value" Decode.int)

                    "BetaUpdated" ->
                        Decode.map2 BetaUpdated
                            (Decode.field "nodeId" Decode.int)
                            (Decode.field "value" Decode.int)

                    "PrunedBranch" ->
                        Decode.map5 PrunedBranch
                            (Decode.field "nodeId" Decode.int)
                            (Decode.field "childId" Decode.int)
                            (Decode.field "position" decodePosition)
                            (Decode.field "alpha" Decode.int)
                            (Decode.field "beta" Decode.int)

                    "NodeFinalized" ->
                        Decode.map2 NodeFinalized
                            (Decode.field "nodeId" Decode.int)
                            (Decode.field "score" Decode.int)

                    _ ->
                        Decode.fail ("Invalid search event: " ++ typeStr)
            )


startSearchInspection : SearchAlgorithm -> SearchTrace -> SearchInspection
startSearchInspection _ trace =
    { trace = trace
    , currentEventIndex = 0
    , selectedNodeId = trace.rootNodeId
    , committed = False
    }


searchInspectionCurrentEvent : SearchInspection -> Maybe SearchEvent
searchInspectionCurrentEvent inspection =
    eventAt inspection.currentEventIndex inspection.trace


searchInspectionCurrentNode : SearchInspection -> Maybe SearchNode
searchInspectionCurrentNode inspection =
    nodeAt inspection.trace inspection.selectedNodeId


searchInspectionGoToIndex : Int -> SearchInspection -> SearchInspection
searchInspectionGoToIndex index inspection =
    let
        clampedIndex =
            clampEventIndex inspection.trace index

        selectedNodeId =
            eventAt clampedIndex inspection.trace
                |> Maybe.map eventNodeId
                |> Maybe.withDefault inspection.trace.rootNodeId
    in
    { inspection
        | currentEventIndex = clampedIndex
        , selectedNodeId = selectedNodeId
    }


searchInspectionStepBackward : SearchInspection -> SearchInspection
searchInspectionStepBackward inspection =
    searchInspectionGoToIndex (inspection.currentEventIndex - 1) inspection


searchInspectionStepForward : SearchInspection -> SearchInspection
searchInspectionStepForward inspection =
    searchInspectionGoToIndex (inspection.currentEventIndex + 1) inspection


searchInspectionPlayToEnd : SearchInspection -> SearchInspection
searchInspectionPlayToEnd inspection =
    searchInspectionGoToIndex (eventCount inspection.trace - 1) inspection


searchInspectionMarkCommitted : SearchInspection -> SearchInspection
searchInspectionMarkCommitted inspection =
    { inspection | committed = True }


searchInspectionSelectNode : SearchNodeId -> SearchInspection -> SearchInspection
searchInspectionSelectNode nodeId inspection =
    { inspection | selectedNodeId = nodeId }


eventNodeId : SearchEvent -> SearchNodeId
eventNodeId event =
    case event of
        EnteredNode nodeId ->
            nodeId

        ConsideredMove nodeId _ _ ->
            nodeId

        LeafEvaluated nodeId _ ->
            nodeId

        ScorePropagated nodeId _ _ ->
            nodeId

        AlphaUpdated nodeId _ ->
            nodeId

        BetaUpdated nodeId _ ->
            nodeId

        PrunedBranch nodeId _ _ _ _ ->
            nodeId

        NodeFinalized nodeId _ ->
            nodeId


eventCount : SearchTrace -> Int
eventCount trace =
    List.length trace.events


eventAt : Int -> SearchTrace -> Maybe SearchEvent
eventAt index trace =
    if index < 0 then
        Nothing

    else
        trace.events
            |> List.drop index
            |> List.head


clampEventIndex : SearchTrace -> Int -> Int
clampEventIndex trace index =
    if eventCount trace <= 0 then
        0

    else
        let
            upperBound =
                max 0 (eventCount trace - 1)
        in
        max 0 (min upperBound index)


nodeAt : SearchTrace -> SearchNodeId -> Maybe SearchNode
nodeAt trace nodeId =
    Dict.get nodeId trace.nodes


encodeErrorType : ErrorType -> Encode.Value
encodeErrorType errorType =
    case errorType of
        InvalidMove ->
            Encode.string "InvalidMove"

        GameLogicError ->
            Encode.string "GameLogicError"

        WorkerCommunicationError ->
            Encode.string "WorkerCommunicationError"

        JsonError ->
            Encode.string "JsonError"

        TimeoutError ->
            Encode.string "TimeoutError"

        UnknownError ->
            Encode.string "UnknownError"


decodeErrorType : Decode.Decoder ErrorType
decodeErrorType =
    Decode.string
        |> Decode.map
            (\errorTypeStr ->
                case errorTypeStr of
                    "InvalidMove" ->
                        InvalidMove

                    "GameLogicError" ->
                        GameLogicError

                    "WorkerCommunicationError" ->
                        WorkerCommunicationError

                    "JsonError" ->
                        JsonError

                    "TimeoutError" ->
                        TimeoutError

                    "UnknownError" ->
                        UnknownError

                    _ ->
                        UnknownError
            )


createInvalidMoveError : String -> ErrorInfo
createInvalidMoveError message =
    { message = message
    , errorType = InvalidMove
    , recoverable = True
    }


createGameLogicError : String -> ErrorInfo
createGameLogicError message =
    { message = message
    , errorType = GameLogicError
    , recoverable = True
    }


createWorkerCommunicationError : String -> ErrorInfo
createWorkerCommunicationError message =
    { message = message
    , errorType = WorkerCommunicationError
    , recoverable = True
    }


createJsonError : String -> ErrorInfo
createJsonError message =
    { message = message
    , errorType = JsonError
    , recoverable = True
    }


createTimeoutError : String -> ErrorInfo
createTimeoutError message =
    { message = message
    , errorType = TimeoutError
    , recoverable = True
    }


createUnknownError : String -> ErrorInfo
createUnknownError message =
    { message = message
    , errorType = UnknownError
    , recoverable = True
    }


recoverFromError : Model -> Model
recoverFromError model =
    case model.gameState of
        Error errorInfo ->
            if errorInfo.recoverable then
                { initialModel
                    | colorScheme = model.colorScheme
                    , maybeWindow = model.maybeWindow
                }

            else
                model

        _ ->
            model


encodeMsg : Msg -> Encode.Value
encodeMsg msg =
    case msg of
        MoveMade position ->
            Encode.object
                [ ( "type", Encode.string "MoveMade" )
                , ( "position", encodePosition position )
                ]

        ResetGame ->
            Encode.object [ ( "type", Encode.string "ResetGame" ) ]

        GameError errorInfo ->
            Encode.object
                [ ( "type", Encode.string "GameError" )
                , ( "errorInfo"
                  , Encode.object
                        [ ( "message", Encode.string errorInfo.message )
                        , ( "errorType", encodeErrorType errorInfo.errorType )
                        , ( "recoverable", Encode.bool errorInfo.recoverable )
                        ]
                  )
                ]

        ColorScheme colorScheme ->
            Encode.object
                [ ( "type", Encode.string "ColorScheme" )
                , ( "colorScheme", encodeColorScheme colorScheme )
                ]

        GetViewPort viewport ->
            Encode.object
                [ ( "type", Encode.string "GetViewPort" )
                , ( "viewport", encodeViewport viewport )
                ]

        GetResize width height ->
            Encode.object
                [ ( "type", Encode.string "GetResize" )
                , ( "width", Encode.int width )
                , ( "height", Encode.int height )
                ]

        Tick time ->
            Encode.object
                [ ( "type", Encode.string "Tick" )
                , ( "time", Encode.int (Time.posixToMillis time) )
                ]

        RequestFastAIMove ->
            Encode.object [ ( "type", Encode.string "RequestFastAIMove" ) ]

        StartInspection algorithm ->
            Encode.object
                [ ( "type", Encode.string "StartInspection" )
                , ( "algorithm", encodeSearchAlgorithm algorithm )
                ]

        StepInspectionBackward ->
            Encode.object [ ( "type", Encode.string "StepInspectionBackward" ) ]

        StepInspectionForward ->
            Encode.object [ ( "type", Encode.string "StepInspectionForward" ) ]

        PlayInspectionToEnd ->
            Encode.object [ ( "type", Encode.string "PlayInspectionToEnd" ) ]

        ApplyInspectionMove ->
            Encode.object [ ( "type", Encode.string "ApplyInspectionMove" ) ]

        SelectInspectionNode nodeId ->
            Encode.object
                [ ( "type", Encode.string "SelectInspectionNode" )
                , ( "nodeId", Encode.int nodeId )
                ]


decodeMsg : Decode.Decoder Msg
decodeMsg =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\msgType ->
                case msgType of
                    "MoveMade" ->
                        Decode.succeed MoveMade
                            |> DecodePipeline.required "position" decodePosition

                    "ResetGame" ->
                        Decode.succeed ResetGame

                    "GameError" ->
                        Decode.succeed GameError
                            |> DecodePipeline.required "errorInfo"
                                (Decode.succeed ErrorInfo
                                    |> DecodePipeline.required "message" Decode.string
                                    |> DecodePipeline.required "errorType" decodeErrorType
                                    |> DecodePipeline.required "recoverable" Decode.bool
                                )

                    "ColorScheme" ->
                        Decode.succeed ColorScheme
                            |> DecodePipeline.required "colorScheme" decodeColorScheme

                    "GetViewPort" ->
                        Decode.succeed GetViewPort
                            |> DecodePipeline.required "viewport" decodeViewport

                    "GetResize" ->
                        Decode.succeed GetResize
                            |> DecodePipeline.required "width" Decode.int
                            |> DecodePipeline.required "height" Decode.int

                    "Tick" ->
                        Decode.succeed Tick
                            |> DecodePipeline.required "time" (Decode.map Time.millisToPosix Decode.int)

                    "RequestFastAIMove" ->
                        Decode.succeed RequestFastAIMove

                    "StartInspection" ->
                        Decode.succeed StartInspection
                            |> DecodePipeline.required "algorithm" decodeSearchAlgorithm

                    "StepInspectionBackward" ->
                        Decode.succeed StepInspectionBackward

                    "StepInspectionForward" ->
                        Decode.succeed StepInspectionForward

                    "PlayInspectionToEnd" ->
                        Decode.succeed PlayInspectionToEnd

                    "ApplyInspectionMove" ->
                        Decode.succeed ApplyInspectionMove

                    "SelectInspectionNode" ->
                        Decode.succeed SelectInspectionNode
                            |> DecodePipeline.required "nodeId" Decode.int

                    _ ->
                        Decode.fail ("Invalid message type: " ++ msgType)
            )

module TicTacToe.SearchTrace exposing
    ( SearchAlgorithm(..)
    , SearchEvent(..)
    , SearchNode
    , SearchNodeId
    , SearchNodeStatus(..)
    , SearchTrace
    , bestMoveNode
    , buildAlphaBetaTrace
    , buildNegamaxTrace
    , currentEvent
    , currentNode
    , describeAlgorithm
    , describeEvent
    , describeNodeStatus
    , eventCount
    , nodesInOrder
    )

{-| Instrumented search traces for Tic-Tac-Toe AI visualization.

This module builds deterministic search trees and event streams for
negamax and alpha-beta search. The fast gameplay path remains in
`TicTacToe.TicTacToe`; this module is only for teaching and inspection.

-}

import Dict exposing (Dict)
import TicTacToe.Model exposing (Board, Player, Position)
import TicTacToe.TicTacToe as TicTacToe exposing (orderMovesForPlayer, switchPlayer)


type alias SearchNodeId =
    Int


type SearchAlgorithm
    = Negamax
    | AlphaBeta


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


type alias SearchOutcome =
    { score : Int
    , bestMove : Maybe Position
    }


type alias Builder =
    { nextNodeId : SearchNodeId
    , nodes : Dict SearchNodeId SearchNode
    , events : List SearchEvent
    }


negativeInfinity : Int
negativeInfinity =
    -10000


positiveInfinity : Int
positiveInfinity =
    10000


buildNegamaxTrace : Player -> Board -> SearchTrace
buildNegamaxTrace player board =
    buildTrace Negamax player board


buildAlphaBetaTrace : Player -> Board -> SearchTrace
buildAlphaBetaTrace player board =
    buildTrace AlphaBeta player board


buildTrace : SearchAlgorithm -> Player -> Board -> SearchTrace
buildTrace algorithm player board =
    let
        depth =
            List.length (TicTacToe.generateAvailableMoves board)

        ( rootNodeId, builderWithRoot ) =
            createRootNode algorithm player board depth

        ( outcome, finalBuilder ) =
            search algorithm builderWithRoot rootNodeId board player depth
    in
    { algorithm = algorithm
    , rootNodeId = rootNodeId
    , nodes = finalBuilder.nodes
    , events = List.reverse finalBuilder.events
    , bestMove = outcome.bestMove
    }


createRootNode : SearchAlgorithm -> Player -> Board -> Int -> ( SearchNodeId, Builder )
createRootNode algorithm player board depth =
    let
        initialBuilder =
            { nextNodeId = 0
            , nodes = Dict.empty
            , events = []
            }

        ( nodeId, builderAfterId ) =
            allocateNodeId initialBuilder

        initialAlpha =
            case algorithm of
                AlphaBeta ->
                    Just negativeInfinity

                Negamax ->
                    Nothing

        initialBeta =
            case algorithm of
                AlphaBeta ->
                    Just positiveInfinity

                Negamax ->
                    Nothing

        node =
            createNode algorithm nodeId board player depth Nothing initialAlpha initialBeta
    in
    ( nodeId, insertNode node builderAfterId )


createNode :
    SearchAlgorithm
    -> SearchNodeId
    -> Board
    -> Player
    -> Int
    -> Maybe Position
    -> Maybe Int
    -> Maybe Int
    -> SearchNode
createNode algorithm nodeId board player depth moveFromParent maybeAlpha maybeBeta =
    { id = nodeId
    , board = board
    , player = player
    , depth = depth
    , moveFromParent = moveFromParent
    , score = Nothing
    , alpha =
        case algorithm of
            AlphaBeta ->
                maybeAlpha

            Negamax ->
                Nothing
    , beta =
        case algorithm of
            AlphaBeta ->
                maybeBeta

            Negamax ->
                Nothing
    , status = Unvisited
    , children = []
    }


search :
    SearchAlgorithm
    -> Builder
    -> SearchNodeId
    -> Board
    -> Player
    -> Int
    -> ( SearchOutcome, Builder )
search algorithm builder nodeId board player depth =
    let
        enteredBuilder =
            recordNodeEntry algorithm nodeId builder
    in
    if depth == 0 || TicTacToe.isTerminalPosition board then
        finalizeLeaf enteredBuilder nodeId board player

    else
        case algorithm of
            Negamax ->
                searchNegamaxMoves enteredBuilder nodeId board player depth

            AlphaBeta ->
                case Dict.get nodeId enteredBuilder.nodes of
                    Nothing ->
                        searchAlphaBetaMoves enteredBuilder nodeId board player depth positiveInfinity (TicTacToe.orderMovesForPlayer player board (TicTacToe.generateAvailableMoves board)) { score = negativeInfinity, bestMove = Nothing } negativeInfinity

                    Just node ->
                        let
                            alpha =
                                Maybe.withDefault negativeInfinity node.alpha

                            beta =
                                Maybe.withDefault positiveInfinity node.beta
                        in
                        searchAlphaBetaMoves enteredBuilder nodeId board player depth beta (TicTacToe.orderMovesForPlayer player board (TicTacToe.generateAvailableMoves board)) { score = negativeInfinity, bestMove = Nothing } alpha


searchNegamaxMoves :
    Builder
    -> SearchNodeId
    -> Board
    -> Player
    -> Int
    -> ( SearchOutcome, Builder )
searchNegamaxMoves builder nodeId board player depth =
    let
        moves =
            TicTacToe.generateAvailableMoves board
                |> orderMovesForPlayer player board
    in
    searchNegamaxMoveList builder nodeId board player depth moves { score = negativeInfinity, bestMove = Nothing }


searchNegamaxMoveList :
    Builder
    -> SearchNodeId
    -> Board
    -> Player
    -> Int
    -> List Position
    -> SearchOutcome
    -> ( SearchOutcome, Builder )
searchNegamaxMoveList builder nodeId board player depth moves bestOutcome =
    case moves of
        [] ->
            finalizeInternalNode builder nodeId board player bestOutcome

        move :: remainingMoves ->
            let
                ( childNodeId, builderAfterChildId ) =
                    allocateNodeId builder

                childBoard =
                    TicTacToe.makeMove player move board

                childNode =
                    createNode Negamax childNodeId childBoard (switchPlayer player) (depth - 1) (Just move) Nothing Nothing

                builderWithChild =
                    builderAfterChildId
                        |> insertNode childNode
                        |> appendChild nodeId childNodeId
                        |> pushEvent (ConsideredMove nodeId move childNodeId)

                ( childOutcome, builderAfterSearch ) =
                    search Negamax builderWithChild childNodeId childBoard (switchPlayer player) (depth - 1)

                candidateScore =
                    -childOutcome.score

                builderWithScore =
                    builderAfterSearch
                        |> pushEvent (ScorePropagated nodeId childNodeId candidateScore)

                updatedBestOutcome =
                    if candidateScore > bestOutcome.score then
                        { score = candidateScore
                        , bestMove = Just move
                        }

                    else
                        bestOutcome
            in
            searchNegamaxMoveList builderWithScore nodeId board player depth remainingMoves updatedBestOutcome


searchAlphaBetaMoves :
    Builder
    -> SearchNodeId
    -> Board
    -> Player
    -> Int
    -> Int
    -> List Position
    -> SearchOutcome
    -> Int
    -> ( SearchOutcome, Builder )
searchAlphaBetaMoves builder nodeId board player depth beta moves bestOutcome currentAlpha =
    case moves of
        [] ->
            finalizeInternalNode builder nodeId board player bestOutcome

        move :: remainingMoves ->
            let
                ( childNodeId, builderAfterChildId ) =
                    allocateNodeId builder

                childBoard =
                    TicTacToe.makeMove player move board

                childAlpha =
                    -beta

                childBeta =
                    -currentAlpha

                childNode =
                    createNode AlphaBeta childNodeId childBoard (switchPlayer player) (depth - 1) (Just move) (Just childAlpha) (Just childBeta)

                builderWithChild =
                    builderAfterChildId
                        |> insertNode childNode
                        |> appendChild nodeId childNodeId
                        |> pushEvent (ConsideredMove nodeId move childNodeId)

                ( childOutcome, builderAfterSearch ) =
                    search AlphaBeta builderWithChild childNodeId childBoard (switchPlayer player) (depth - 1)

                candidateScore =
                    -childOutcome.score

                builderWithScore =
                    builderAfterSearch
                        |> pushEvent (ScorePropagated nodeId childNodeId candidateScore)

                ( updatedBestOutcome, updatedAlpha, builderAfterAlpha ) =
                    if candidateScore > bestOutcome.score then
                        let
                            newBestOutcome =
                                { score = candidateScore
                                , bestMove = Just move
                                }

                            newAlpha =
                                max currentAlpha candidateScore

                            alphaBuilder =
                                if newAlpha /= currentAlpha then
                                    builderWithScore
                                        |> updateNode nodeId (\node -> { node | alpha = Just newAlpha })
                                        |> pushEvent (AlphaUpdated nodeId newAlpha)

                                else
                                    builderWithScore
                        in
                        ( newBestOutcome, newAlpha, alphaBuilder )

                    else
                        ( bestOutcome, currentAlpha, builderWithScore )

                builderAfterPrune =
                    if updatedAlpha >= beta then
                        pruneRemainingBranches builderAfterAlpha nodeId board player depth updatedAlpha beta remainingMoves

                    else
                        builderAfterAlpha
            in
            if updatedAlpha >= beta then
                finalizeInternalNode builderAfterPrune nodeId board player updatedBestOutcome

            else
                searchAlphaBetaMoves builderAfterPrune nodeId board player depth beta remainingMoves updatedBestOutcome updatedAlpha


finalizeLeaf :
    Builder
    -> SearchNodeId
    -> Board
    -> Player
    -> ( SearchOutcome, Builder )
finalizeLeaf builder nodeId board player =
    let
        score =
            TicTacToe.scoreBoard player board
    in
    ( { score = score, bestMove = Nothing }
    , builder
        |> updateNode nodeId (\node -> { node | score = Just score, status = Finalized })
        |> pushEvent (LeafEvaluated nodeId score)
        |> pushEvent (NodeFinalized nodeId score)
    )


finalizeInternalNode :
    Builder
    -> SearchNodeId
    -> Board
    -> Player
    -> SearchOutcome
    -> ( SearchOutcome, Builder )
finalizeInternalNode builder nodeId board player outcome =
    let
        finalScore =
            case outcome.bestMove of
                Nothing ->
                    TicTacToe.scoreBoard player board

                Just _ ->
                    outcome.score

        finalStatus node =
            case node.status of
                Pruned ->
                    Pruned

                _ ->
                    if List.isEmpty node.children then
                        Finalized

                    else
                        Expanded

        finalizedBuilder =
            builder
                |> updateNode nodeId
                    (\node ->
                        { node
                            | score = Just finalScore
                            , status = finalStatus node
                        }
                    )
                |> pushEvent (NodeFinalized nodeId finalScore)
    in
    ( { outcome | score = finalScore }, finalizedBuilder )


updateAlphaBetaEntry : SearchAlgorithm -> SearchNodeId -> Builder -> Builder
updateAlphaBetaEntry algorithm nodeId builder =
    case algorithm of
        Negamax ->
            builder

        AlphaBeta ->
            case Dict.get nodeId builder.nodes of
                Nothing ->
                    builder

                Just node ->
                    let
                        alphaValue =
                            Maybe.withDefault negativeInfinity node.alpha

                        betaValue =
                            Maybe.withDefault positiveInfinity node.beta
                    in
                    builder
                        |> updateNode nodeId (\existing -> { existing | alpha = Just alphaValue, beta = Just betaValue })
                        |> pushEvent (AlphaUpdated nodeId alphaValue)
                        |> pushEvent (BetaUpdated nodeId betaValue)


recordNodeEntry : SearchAlgorithm -> SearchNodeId -> Builder -> Builder
recordNodeEntry algorithm nodeId builder =
    case algorithm of
        Negamax ->
            builder
                |> pushEvent (EnteredNode nodeId)
                |> updateNode nodeId (\node -> { node | status = Active })

        AlphaBeta ->
            builder
                |> pushEvent (EnteredNode nodeId)
                |> updateNode nodeId (\node -> { node | status = Active })
                |> updateAlphaBetaEntry AlphaBeta nodeId


pruneRemainingBranches :
    Builder
    -> SearchNodeId
    -> Board
    -> Player
    -> Int
    -> Int
    -> Int
    -> List Position
    -> Builder
pruneRemainingBranches builder nodeId board player depth alpha beta remainingMoves =
    case remainingMoves of
        [] ->
            builder

        move :: rest ->
            let
                ( childNodeId, builderAfterChildId ) =
                    allocateNodeId builder

                childBoard =
                    TicTacToe.makeMove player move board

                childNode =
                    createNode AlphaBeta childNodeId childBoard (switchPlayer player) (depth - 1) (Just move) (Just -beta) (Just -alpha)

                builderWithPrunedChild =
                    builderAfterChildId
                        |> insertNode { childNode | status = Pruned }
                        |> appendChild nodeId childNodeId
                        |> pushEvent (PrunedBranch nodeId childNodeId move alpha beta)
            in
            pruneRemainingBranches builderWithPrunedChild nodeId board player depth alpha beta rest


allocateNodeId : Builder -> ( SearchNodeId, Builder )
allocateNodeId builder =
    ( builder.nextNodeId
    , { builder | nextNodeId = builder.nextNodeId + 1 }
    )


insertNode : SearchNode -> Builder -> Builder
insertNode node builder =
    { builder | nodes = Dict.insert node.id node builder.nodes }


updateNode : SearchNodeId -> (SearchNode -> SearchNode) -> Builder -> Builder
updateNode nodeId transform builder =
    { builder
        | nodes =
            Dict.update nodeId (Maybe.map transform) builder.nodes
    }


appendChild : SearchNodeId -> SearchNodeId -> Builder -> Builder
appendChild parentId childId builder =
    updateNode parentId (\node -> { node | children = node.children ++ [ childId ] }) builder


pushEvent : SearchEvent -> Builder -> Builder
pushEvent event builder =
    { builder | events = event :: builder.events }


createNodeLabel : Position -> String
createNodeLabel position =
    "(" ++ String.fromInt position.row ++ ", " ++ String.fromInt position.col ++ ")"


eventNodeId : SearchEvent -> Maybe SearchNodeId
eventNodeId event =
    case event of
        EnteredNode nodeId ->
            Just nodeId

        ConsideredMove nodeId _ _ ->
            Just nodeId

        LeafEvaluated nodeId _ ->
            Just nodeId

        ScorePropagated nodeId _ _ ->
            Just nodeId

        AlphaUpdated nodeId _ ->
            Just nodeId

        BetaUpdated nodeId _ ->
            Just nodeId

        PrunedBranch nodeId _ _ _ _ ->
            Just nodeId

        NodeFinalized nodeId _ ->
            Just nodeId


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


currentEvent : SearchTrace -> Int -> Maybe SearchEvent
currentEvent trace index =
    if index >= eventCount trace then
        Nothing

    else
        eventAt index trace


currentNode : SearchTrace -> Int -> Maybe SearchNode
currentNode trace index =
    currentNodeId trace index
        |> Maybe.andThen (nodeAt trace)


currentNodeId : SearchTrace -> Int -> Maybe SearchNodeId
currentNodeId trace index =
    case trace.events of
        [] ->
            Nothing

        _ ->
            let
                focusedIndex =
                    if index >= eventCount trace then
                        eventCount trace - 1

                    else
                        index
            in
            eventAt focusedIndex trace
                |> Maybe.andThen eventNodeId


nodeAt : SearchTrace -> SearchNodeId -> Maybe SearchNode
nodeAt trace nodeId =
    Dict.get nodeId trace.nodes


nodesInOrder : SearchTrace -> List SearchNode
nodesInOrder trace =
    trace.nodes
        |> Dict.values
        |> List.sortBy .id


bestMoveNodeId : SearchTrace -> Maybe SearchNodeId
bestMoveNodeId trace =
    case trace.bestMove of
        Nothing ->
            Nothing

        Just bestMove ->
            case nodeAt trace trace.rootNodeId of
                Nothing ->
                    Nothing

                Just rootNode ->
                    rootNode.children
                        |> List.filterMap
                            (\childId ->
                                case nodeAt trace childId of
                                    Nothing ->
                                        Nothing

                                    Just childNode ->
                                        if childNode.moveFromParent == Just bestMove then
                                            Just childNode.id

                                        else
                                            Nothing
                            )
                        |> List.head


bestMoveNode : SearchTrace -> Maybe SearchNode
bestMoveNode trace =
    bestMoveNodeId trace
        |> Maybe.andThen (nodeAt trace)


describeAlgorithm : SearchAlgorithm -> String
describeAlgorithm algorithm =
    case algorithm of
        Negamax ->
            "Negamax"

        AlphaBeta ->
            "Alpha-Beta"


describeNodeStatus : SearchNodeStatus -> String
describeNodeStatus status =
    case status of
        Unvisited ->
            "Unvisited"

        Active ->
            "Active"

        Expanded ->
            "Expanded"

        Finalized ->
            "Finalized"

        Pruned ->
            "Pruned"


describeEvent : SearchEvent -> String
describeEvent event =
    case event of
        EnteredNode nodeId ->
            "Entered node " ++ String.fromInt nodeId

        ConsideredMove nodeId position childId ->
            "Node " ++ String.fromInt nodeId ++ " considered move " ++ createNodeLabel position ++ " -> " ++ String.fromInt childId

        LeafEvaluated nodeId score ->
            "Node " ++ String.fromInt nodeId ++ " evaluated leaf score " ++ String.fromInt score

        ScorePropagated nodeId childId score ->
            "Node " ++ String.fromInt nodeId ++ " received score " ++ String.fromInt score ++ " from " ++ String.fromInt childId

        AlphaUpdated nodeId alpha ->
            "Node " ++ String.fromInt nodeId ++ " alpha = " ++ String.fromInt alpha

        BetaUpdated nodeId beta ->
            "Node " ++ String.fromInt nodeId ++ " beta = " ++ String.fromInt beta

        PrunedBranch nodeId childId position alpha beta ->
            "Node " ++ String.fromInt nodeId ++ " pruned " ++ createNodeLabel position ++ " -> " ++ String.fromInt childId ++ " at " ++ String.fromInt alpha ++ "/" ++ String.fromInt beta

        NodeFinalized nodeId score ->
            "Node " ++ String.fromInt nodeId ++ " finalized with " ++ String.fromInt score

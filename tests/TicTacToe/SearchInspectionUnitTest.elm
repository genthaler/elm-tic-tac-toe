module TicTacToe.SearchInspectionUnitTest exposing (suite)

import Dict
import Expect
import Test exposing (Test, describe, test)
import TicTacToe.Model as Model
    exposing
        ( Player(..)
        , SearchAlgorithm(..)
        , SearchTrace
        , searchInspectionCurrentEvent
        , searchInspectionCurrentNode
        , searchInspectionGoToIndex
        , searchInspectionMarkCommitted
        , searchInspectionPlayToEnd
        , searchInspectionSelectNode
        , searchInspectionStepBackward
        , searchInspectionStepForward
        , startSearchInspection
        )
import TicTacToe.SearchTrace exposing (buildAlphaBetaTrace, buildNegamaxTrace)


suite : Test
suite =
    describe "TicTacToe search inspection state"
        [ startStateTests
        , steppingTests
        , selectionTests
        ]


inspectionTrace : SearchTrace
inspectionTrace =
    buildAlphaBetaTrace O
        [ [ Just X, Nothing, Just O ]
        , [ Nothing, Just X, Nothing ]
        , [ Just O, Nothing, Nothing ]
        ]
        |> convertTrace


negamaxTrace : SearchTrace
negamaxTrace =
    buildNegamaxTrace O
        [ [ Just O, Just O, Nothing ]
        , [ Just X, Just X, Nothing ]
        , [ Nothing, Nothing, Nothing ]
        ]
        |> convertTrace


startStateTests : Test
startStateTests =
    describe "Initial inspection state"
        [ test "starts at the root node and the first event" <|
            \_ ->
                let
                    inspection =
                        startSearchInspection Negamax negamaxTrace
                in
                Expect.all
                    [ \_ -> Expect.equal 0 inspection.currentEventIndex
                    , \_ -> Expect.equal negamaxTrace.rootNodeId inspection.selectedNodeId
                    , \_ -> Expect.equal False inspection.committed
                    , \_ ->
                        case searchInspectionCurrentEvent inspection of
                            Just event ->
                                case event of
                                    Model.EnteredNode nodeId ->
                                        Expect.equal negamaxTrace.rootNodeId nodeId

                                    _ ->
                                        Expect.fail "expected the first inspection event to be the root entry"

                            Nothing ->
                                Expect.fail "expected an initial inspection event"
                    , \_ ->
                        case searchInspectionCurrentNode inspection of
                            Just node ->
                                Expect.equal negamaxTrace.rootNodeId node.id

                            Nothing ->
                                Expect.fail "expected an initial inspection node"
                    ]
                    ()
        ]


steppingTests : Test
steppingTests =
    describe "Step behavior"
        [ test "step forward, backward, and play to end clamp correctly" <|
            \_ ->
                let
                    inspection =
                        startSearchInspection AlphaBeta inspectionTrace

                    steppedForward =
                        searchInspectionStepForward inspection

                    steppedBack =
                        searchInspectionStepBackward steppedForward

                    playedToEnd =
                        searchInspectionPlayToEnd inspection
                in
                Expect.all
                    [ \_ -> Expect.equal 1 steppedForward.currentEventIndex
                    , \_ -> Expect.equal 0 steppedBack.currentEventIndex
                    , \_ -> Expect.equal (max 0 (List.length inspectionTrace.events - 1)) playedToEnd.currentEventIndex
                    , \_ -> Expect.equal True (searchInspectionMarkCommitted playedToEnd).committed
                    , \_ -> Expect.equal (max 0 (List.length inspectionTrace.events - 1)) (searchInspectionGoToIndex 999 inspection).currentEventIndex
                    ]
                    ()
        ]


selectionTests : Test
selectionTests =
    describe "Node selection"
        [ test "selecting a node updates the active node without changing the event cursor" <|
            \_ ->
                case
                    inspectionTrace.nodes
                        |> Dict.values
                        |> List.filter (\node -> node.id /= inspectionTrace.rootNodeId)
                        |> List.head
                of
                    Just node ->
                        let
                            inspection =
                                startSearchInspection AlphaBeta inspectionTrace

                            selectedInspection =
                                searchInspectionSelectNode node.id inspection
                        in
                        Expect.all
                            [ \_ -> Expect.equal inspection.currentEventIndex selectedInspection.currentEventIndex
                            , \_ -> Expect.equal node.id selectedInspection.selectedNodeId
                            , \_ ->
                                case searchInspectionCurrentNode selectedInspection of
                                    Just activeNode ->
                                        Expect.equal node.id activeNode.id

                                    Nothing ->
                                        Expect.fail "expected a selected node to be available"
                            ]
                            ()

                    Nothing ->
                        Expect.fail "expected the trace to contain a non-root node"
        ]


convertTrace : TicTacToe.SearchTrace.SearchTrace -> SearchTrace
convertTrace trace =
    { algorithm =
        case trace.algorithm of
            TicTacToe.SearchTrace.Negamax ->
                Negamax

            TicTacToe.SearchTrace.AlphaBeta ->
                AlphaBeta
    , rootNodeId = trace.rootNodeId
    , nodes =
        trace.nodes
            |> Dict.toList
            |> List.map (\( nodeId, node ) -> ( nodeId, convertNode node ))
            |> Dict.fromList
    , events = List.map convertEvent trace.events
    , bestMove = trace.bestMove
    }


convertNode : TicTacToe.SearchTrace.SearchNode -> Model.SearchNode
convertNode node =
    { id = node.id
    , board = node.board
    , player = node.player
    , depth = node.depth
    , moveFromParent = node.moveFromParent
    , score = node.score
    , alpha = node.alpha
    , beta = node.beta
    , status =
        case node.status of
            TicTacToe.SearchTrace.Unvisited ->
                Model.Unvisited

            TicTacToe.SearchTrace.Active ->
                Model.Active

            TicTacToe.SearchTrace.Expanded ->
                Model.Expanded

            TicTacToe.SearchTrace.Finalized ->
                Model.Finalized

            TicTacToe.SearchTrace.Pruned ->
                Model.Pruned
    , children = node.children
    }


convertEvent : TicTacToe.SearchTrace.SearchEvent -> Model.SearchEvent
convertEvent event =
    case event of
        TicTacToe.SearchTrace.EnteredNode nodeId ->
            Model.EnteredNode nodeId

        TicTacToe.SearchTrace.ConsideredMove nodeId position childId ->
            Model.ConsideredMove nodeId position childId

        TicTacToe.SearchTrace.LeafEvaluated nodeId score ->
            Model.LeafEvaluated nodeId score

        TicTacToe.SearchTrace.ScorePropagated nodeId childId score ->
            Model.ScorePropagated nodeId childId score

        TicTacToe.SearchTrace.AlphaUpdated nodeId value ->
            Model.AlphaUpdated nodeId value

        TicTacToe.SearchTrace.BetaUpdated nodeId value ->
            Model.BetaUpdated nodeId value

        TicTacToe.SearchTrace.PrunedBranch nodeId childId position alpha beta ->
            Model.PrunedBranch nodeId childId position alpha beta

        TicTacToe.SearchTrace.NodeFinalized nodeId score ->
            Model.NodeFinalized nodeId score

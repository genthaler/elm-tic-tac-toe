module TicTacToe.SearchTraceUnitTest exposing (suite)

import Dict
import Expect
import String
import Test exposing (Test, describe, test)
import TicTacToe.Model exposing (Board, Player(..))
import TicTacToe.SearchTrace
    exposing
        ( SearchAlgorithm(..)
        , SearchNodeStatus(..)
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
import TicTacToe.TicTacToe as TicTacToe


suite : Test
suite =
    describe "TicTacToe search traces"
        [ negamaxTraceTests
        , alphaBetaTraceTests
        , traceHelperTests
        ]


fastPlayBoard : Board
fastPlayBoard =
    [ [ Just O, Just O, Nothing ]
    , [ Just X, Just X, Nothing ]
    , [ Nothing, Nothing, Nothing ]
    ]


inspectionBoard : Board
inspectionBoard =
    [ [ Just X, Nothing, Just O ]
    , [ Nothing, Just X, Nothing ]
    , [ Just O, Nothing, Nothing ]
    ]


negamaxTraceTests : Test
negamaxTraceTests =
    describe "Negamax trace generation"
        [ test "records the root node, final node, and the fast-play best move" <|
            \_ ->
                let
                    trace =
                        buildNegamaxTrace O fastPlayBoard
                in
                Expect.all
                    [ \_ -> Expect.equal Negamax trace.algorithm
                    , \_ -> Expect.equal "Negamax" (describeAlgorithm trace.algorithm)
                    , \_ -> Expect.equal (TicTacToe.findBestMove O fastPlayBoard) trace.bestMove
                    , \_ ->
                        case currentNode trace 0 of
                            Just node ->
                                Expect.equal Expanded node.status

                            Nothing ->
                                Expect.fail "expected the root node to be available at event 0"
                    , \_ ->
                        case currentEvent trace 0 of
                            Just event ->
                                Expect.equal ("Entered node " ++ String.fromInt trace.rootNodeId) (describeEvent event)

                            Nothing ->
                                Expect.fail "expected the first trace event to exist"
                    , \_ ->
                        case bestMoveNode trace of
                            Just node ->
                                Expect.equal trace.bestMove node.moveFromParent

                            Nothing ->
                                Expect.fail "expected a best-move node to be available"
                    ]
                    ()
        ]


alphaBetaTraceTests : Test
alphaBetaTraceTests =
    describe "Alpha-beta trace generation"
        [ test "records bounds, pruning, and the fast-play best move" <|
            \_ ->
                let
                    trace =
                        buildAlphaBetaTrace O inspectionBoard

                    tracedNodes =
                        nodesInOrder trace
                in
                Expect.all
                    [ \_ -> Expect.equal AlphaBeta trace.algorithm
                    , \_ -> Expect.equal "Alpha-Beta" (describeAlgorithm trace.algorithm)
                    , \_ -> Expect.equal (TicTacToe.findBestMove O inspectionBoard) trace.bestMove
                    , \_ -> Expect.equal True (List.any (\node -> node.alpha /= Nothing) tracedNodes)
                    , \_ -> Expect.equal True (List.any (\node -> node.beta /= Nothing) tracedNodes)
                    , \_ -> Expect.equal True (List.any (\node -> node.status == Pruned) tracedNodes)
                    , \_ ->
                        case currentEvent trace (eventCount trace - 1) of
                            Just event ->
                                Expect.equal True (String.contains "finalized" (String.toLower (describeEvent event)))

                            Nothing ->
                                Expect.fail "expected a final event"
                    ]
                    ()
        ]


traceHelperTests : Test
traceHelperTests =
    describe "Trace helper behavior"
        [ test "trace helper descriptions stay aligned with the visualization labels" <|
            \_ ->
                let
                    trace =
                        buildAlphaBetaTrace O inspectionBoard
                in
                Expect.all
                    [ \_ -> Expect.equal "Pruned" (describeNodeStatus Pruned)
                    , \_ -> Expect.equal "Active" (describeNodeStatus Active)
                    , \_ -> Expect.atLeast 1 (eventCount trace)
                    ]
                    ()
        , test "trace node ids remain stable enough for direct lookup" <|
            \_ ->
                let
                    trace =
                        buildAlphaBetaTrace O inspectionBoard

                    maybeRootNode =
                        Dict.get trace.rootNodeId trace.nodes
                in
                case maybeRootNode of
                    Just node ->
                        Expect.equal trace.rootNodeId node.id

                    Nothing ->
                        Expect.fail "expected root node lookup to succeed"
        ]

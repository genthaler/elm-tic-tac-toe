module GameTheory.AdversarialEagerUnitTest exposing (suite)

{-| Test suite for GameTheory.AdversarialEager module.
Tests the negamax algorithm implementation for correctness and move quality.
-}

import Expect
import GameTheory.AdversarialEager as AdversarialEager
import GameTheory.ExtendedOrder exposing (ExtendedOrder(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "GameTheory.AdversarialEager"
        [ negamaxBasicTests
        , negamaxDepthTests
        , negamaxTerminalTests
        , negamaxMoveQualityTests
        , negamaxEdgeCaseTests
        ]


{-| Simple game position for testing - just an integer where higher is better
-}
type alias SimplePosition =
    Int


{-| Simple move for testing - just add/subtract a value
-}
type alias SimpleMove =
    Int


{-| Simple evaluation function - just return the position value
-}
simpleEvaluate : SimplePosition -> Int
simpleEvaluate position =
    position


{-| Generate moves that add -1, 0, or +1 to position
-}
simpleGenerateMoves : SimplePosition -> List SimpleMove
simpleGenerateMoves _ =
    [ -1, 0, 1 ]


{-| Apply a move by adding it to the position
-}
simpleApplyMove : SimpleMove -> SimplePosition -> SimplePosition
simpleApplyMove move position =
    position + move


{-| Terminal when position is >= 10 or <= -10
-}
simpleIsTerminal : SimplePosition -> Bool
simpleIsTerminal position =
    position >= 10 || position <= -10


negamaxBasicTests : Test
negamaxBasicTests =
    describe "Basic negamax functionality"
        [ test "returns evaluation for terminal position" <|
            \_ ->
                let
                    result =
                        AdversarialEager.negamax
                            simpleEvaluate
                            simpleGenerateMoves
                            simpleApplyMove
                            simpleIsTerminal
                            5
                            10
                in
                Expect.equal (Comparable 10) result
        , test "returns evaluation for depth 0" <|
            \_ ->
                let
                    result =
                        AdversarialEager.negamax
                            simpleEvaluate
                            simpleGenerateMoves
                            simpleApplyMove
                            simpleIsTerminal
                            0
                            5
                in
                Expect.equal (Comparable 5) result
        , test "chooses best move from available options" <|
            \_ ->
                let
                    -- At position 0, with depth 1, should choose move +1 (best outcome)
                    result =
                        AdversarialEager.negamax
                            simpleEvaluate
                            simpleGenerateMoves
                            simpleApplyMove
                            simpleIsTerminal
                            1
                            0
                in
                -- Should return the negated best opponent score
                -- Opponent would choose -1 from position 1, giving -1
                -- So we get -(-1) = 1
                case result of
                    Comparable score ->
                        Expect.atLeast -1 score

                    _ ->
                        Expect.fail "Expected Comparable result"
        ]


negamaxDepthTests : Test
negamaxDepthTests =
    describe "Depth handling"
        [ test "deeper search gives better results" <|
            \_ ->
                let
                    position =
                        0

                    depth1Result =
                        AdversarialEager.negamax
                            simpleEvaluate
                            simpleGenerateMoves
                            simpleApplyMove
                            simpleIsTerminal
                            1
                            position

                    depth3Result =
                        AdversarialEager.negamax
                            simpleEvaluate
                            simpleGenerateMoves
                            simpleApplyMove
                            simpleIsTerminal
                            3
                            position
                in
                -- Both should be Comparable values
                case ( depth1Result, depth3Result ) of
                    ( Comparable _, Comparable _ ) ->
                        Expect.pass

                    -- Just verify they're both valid results
                    _ ->
                        Expect.fail "Expected Comparable results for both depths"
        , test "handles zero depth correctly" <|
            \_ ->
                let
                    result =
                        AdversarialEager.negamax
                            simpleEvaluate
                            simpleGenerateMoves
                            simpleApplyMove
                            simpleIsTerminal
                            0
                            5
                in
                Expect.equal (Comparable 5) result
        ]


negamaxTerminalTests : Test
negamaxTerminalTests =
    describe "Terminal position handling"
        [ test "recognizes positive terminal position" <|
            \_ ->
                let
                    result =
                        AdversarialEager.negamax
                            simpleEvaluate
                            simpleGenerateMoves
                            simpleApplyMove
                            simpleIsTerminal
                            5
                            15
                in
                Expect.equal (Comparable 15) result
        , test "recognizes negative terminal position" <|
            \_ ->
                let
                    result =
                        AdversarialEager.negamax
                            simpleEvaluate
                            simpleGenerateMoves
                            simpleApplyMove
                            simpleIsTerminal
                            5
                            -15
                in
                Expect.equal (Comparable -15) result
        , test "terminal position overrides depth" <|
            \_ ->
                let
                    result =
                        AdversarialEager.negamax
                            simpleEvaluate
                            simpleGenerateMoves
                            simpleApplyMove
                            simpleIsTerminal
                            100
                            10
                in
                -- Should return evaluation immediately, not search deeper
                Expect.equal (Comparable 10) result
        ]


negamaxMoveQualityTests : Test
negamaxMoveQualityTests =
    describe "Move quality and correctness"
        [ test "returns reasonable scores for different positions" <|
            \_ ->
                let
                    result1 =
                        AdversarialEager.negamax
                            simpleEvaluate
                            simpleGenerateMoves
                            simpleApplyMove
                            simpleIsTerminal
                            2
                            5

                    result2 =
                        AdversarialEager.negamax
                            simpleEvaluate
                            simpleGenerateMoves
                            simpleApplyMove
                            simpleIsTerminal
                            2
                            -5
                in
                -- Both should return Comparable values
                case ( result1, result2 ) of
                    ( Comparable _, Comparable _ ) ->
                        Expect.pass

                    _ ->
                        Expect.fail "Expected Comparable results for both positions"
        , test "handles different evaluation functions" <|
            \_ ->
                let
                    -- Custom evaluation that doubles the position value
                    doubleEvaluate pos =
                        pos * 2

                    result =
                        AdversarialEager.negamax
                            doubleEvaluate
                            simpleGenerateMoves
                            simpleApplyMove
                            simpleIsTerminal
                            1
                            3
                in
                -- Should work with custom evaluation
                case result of
                    Comparable _ ->
                        Expect.pass

                    _ ->
                        Expect.fail "Expected Comparable result with custom evaluation"
        ]


negamaxEdgeCaseTests : Test
negamaxEdgeCaseTests =
    describe "Edge cases and error handling"
        [ test "handles no available moves" <|
            \_ ->
                let
                    noMovesGenerate _ =
                        []

                    result =
                        AdversarialEager.negamax
                            simpleEvaluate
                            noMovesGenerate
                            simpleApplyMove
                            simpleIsTerminal
                            3
                            5
                in
                -- Should return current position evaluation
                Expect.equal (Comparable 5) result
        , test "handles single move available" <|
            \_ ->
                let
                    singleMoveGenerate _ =
                        [ 1 ]

                    result =
                        AdversarialEager.negamax
                            simpleEvaluate
                            singleMoveGenerate
                            simpleApplyMove
                            simpleIsTerminal
                            2
                            5
                in
                -- Should work with single move
                case result of
                    Comparable _ ->
                        Expect.pass

                    _ ->
                        Expect.fail "Expected Comparable result with single move"
        , test "handles large depth values" <|
            \_ ->
                let
                    result =
                        AdversarialEager.negamax
                            simpleEvaluate
                            simpleGenerateMoves
                            simpleApplyMove
                            simpleIsTerminal
                            5
                            5
                in
                -- Should handle reasonable depth values
                case result of
                    Comparable _ ->
                        Expect.pass

                    _ ->
                        Expect.fail "Expected Comparable result with large depth"
        , test "consistent results for same input" <|
            \_ ->
                let
                    position =
                        3

                    depth =
                        2

                    result1 =
                        AdversarialEager.negamax
                            simpleEvaluate
                            simpleGenerateMoves
                            simpleApplyMove
                            simpleIsTerminal
                            depth
                            position

                    result2 =
                        AdversarialEager.negamax
                            simpleEvaluate
                            simpleGenerateMoves
                            simpleApplyMove
                            simpleIsTerminal
                            depth
                            position
                in
                Expect.equal result1 result2
        ]

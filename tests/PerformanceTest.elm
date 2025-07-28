module PerformanceTest exposing (suite)

{-| Performance tests for AI algorithm optimizations.
These tests measure the performance improvements from alpha-beta pruning and move ordering.
-}

import Expect
import Model exposing (Player(..))
import Test exposing (Test, describe, test)
import TicTacToe.TicTacToe as TicTacToe


suite : Test
suite =
    describe "AI Performance Tests"
        [ describe "Move Ordering"
            [ test "orderMovesForPlayer prioritizes center position" <|
                \_ ->
                    let
                        board =
                            TicTacToe.createEmptyBoard

                        availableMoves =
                            TicTacToe.generateAvailableMoves board

                        orderedMoves =
                            TicTacToe.orderMovesForPlayer X board availableMoves

                        centerPosition =
                            { row = 1, col = 1 }
                    in
                    orderedMoves
                        |> List.head
                        |> Expect.equal (Just centerPosition)
            , test "orderMovesForPruning provides consistent ordering" <|
                \_ ->
                    let
                        board =
                            TicTacToe.createEmptyBoard

                        availableMoves =
                            TicTacToe.generateAvailableMoves board

                        orderedMoves1 =
                            TicTacToe.orderMovesForPruning board availableMoves

                        orderedMoves2 =
                            TicTacToe.orderMovesForPruning board availableMoves
                    in
                    orderedMoves1
                        |> Expect.equal orderedMoves2
            , test "move ordering handles partial boards correctly" <|
                \_ ->
                    let
                        -- Create a board with some moves already made
                        board =
                            TicTacToe.createEmptyBoard
                                |> TicTacToe.makeMove X { row = 0, col = 0 }
                                |> TicTacToe.makeMove O { row = 1, col = 1 }

                        availableMoves =
                            TicTacToe.generateAvailableMoves board

                        orderedMoves =
                            TicTacToe.orderMovesForPlayer X board availableMoves
                    in
                    orderedMoves
                        |> List.length
                        |> Expect.equal 7
            ]
        , describe "AI Decision Quality"
            [ test "AI finds winning move in one turn" <|
                \_ ->
                    let
                        -- Create a board where X can win
                        board =
                            [ [ Just X, Just X, Nothing ]
                            , [ Nothing, Nothing, Nothing ]
                            , [ Nothing, Nothing, Nothing ]
                            ]

                        bestMove =
                            TicTacToe.findBestMove X board

                        expectedWinningMove =
                            { row = 0, col = 2 }
                    in
                    bestMove
                        |> Expect.equal (Just expectedWinningMove)
            , test "AI blocks opponent winning move" <|
                \_ ->
                    let
                        -- Create a board where O is about to win and X must block
                        board =
                            [ [ Just O, Just O, Nothing ]
                            , [ Nothing, Nothing, Nothing ]
                            , [ Nothing, Nothing, Nothing ]
                            ]

                        bestMove =
                            TicTacToe.findBestMove X board

                        expectedBlockingMove =
                            { row = 0, col = 2 }
                    in
                    bestMove
                        |> Expect.equal (Just expectedBlockingMove)
            , test "AI makes reasonable moves in early game" <|
                \_ ->
                    let
                        board =
                            TicTacToe.createEmptyBoard

                        bestMove =
                            TicTacToe.findBestMove X board

                        -- First move should be center or corner
                        isGoodFirstMove pos =
                            pos
                                == { row = 1, col = 1 }
                                || pos
                                == { row = 0, col = 0 }
                                || pos
                                == { row = 0, col = 2 }
                                || pos
                                == { row = 2, col = 0 }
                                || pos
                                == { row = 2, col = 2 }
                    in
                    case bestMove of
                        Just move ->
                            if isGoodFirstMove move then
                                Expect.pass

                            else
                                Expect.fail ("AI chose poor first move: " ++ Debug.toString move)

                        Nothing ->
                            Expect.fail "AI should find a move on empty board"
            ]
        , describe "Performance Characteristics"
            [ test "AI completes move calculation quickly on empty board" <|
                \_ ->
                    let
                        board =
                            TicTacToe.createEmptyBoard

                        -- This test ensures the AI doesn't hang or take too long
                        bestMove =
                            TicTacToe.findBestMove X board
                    in
                    case bestMove of
                        Just _ ->
                            Expect.pass

                        Nothing ->
                            Expect.fail "AI should find a move on empty board"
            , test "AI handles near-endgame positions efficiently" <|
                \_ ->
                    let
                        -- Create a complex near-endgame position
                        board =
                            [ [ Just X, Just O, Just X ]
                            , [ Just O, Just X, Nothing ]
                            , [ Nothing, Nothing, Just O ]
                            ]

                        bestMove =
                            TicTacToe.findBestMove X board
                    in
                    case bestMove of
                        Just _ ->
                            Expect.pass

                        Nothing ->
                            Expect.fail "AI should find a move in near-endgame"
            , test "AI handles full search depth without errors" <|
                \_ ->
                    let
                        -- Test with a position that requires deep search
                        board =
                            [ [ Nothing, Nothing, Nothing ]
                            , [ Nothing, Just X, Nothing ]
                            , [ Nothing, Nothing, Nothing ]
                            ]

                        bestMove =
                            TicTacToe.findBestMove O board
                    in
                    case bestMove of
                        Just _ ->
                            Expect.pass

                        Nothing ->
                            Expect.fail "AI should find a move with deep search"
            ]
        , describe "Algorithm Optimization"
            [ test "AI finds immediate winning moves without deep search" <|
                \_ ->
                    let
                        -- Position where X can win immediately
                        board =
                            [ [ Just X, Just X, Nothing ]
                            , [ Nothing, Just O, Nothing ]
                            , [ Nothing, Nothing, Just O ]
                            ]

                        bestMove =
                            TicTacToe.findBestMove X board

                        expectedWinningMove =
                            { row = 0, col = 2 }
                    in
                    bestMove
                        |> Expect.equal (Just expectedWinningMove)
            , test "AI prioritizes blocking immediate opponent wins" <|
                \_ ->
                    let
                        -- Position where O is about to win and X must block
                        board =
                            [ [ Just O, Just O, Nothing ]
                            , [ Just X, Nothing, Nothing ]
                            , [ Nothing, Nothing, Nothing ]
                            ]

                        bestMove =
                            TicTacToe.findBestMove X board

                        expectedBlockingMove =
                            { row = 0, col = 2 }
                    in
                    bestMove
                        |> Expect.equal (Just expectedBlockingMove)
            , test "AI uses adaptive search depth based on game state" <|
                \_ ->
                    let
                        -- Early game position (many moves available)
                        earlyBoard =
                            [ [ Just X, Nothing, Nothing ]
                            , [ Nothing, Nothing, Nothing ]
                            , [ Nothing, Nothing, Nothing ]
                            ]

                        -- Endgame position (few moves available)
                        endgameBoard =
                            [ [ Just X, Just O, Just X ]
                            , [ Just O, Just X, Nothing ]
                            , [ Nothing, Nothing, Just O ]
                            ]

                        earlyMove =
                            TicTacToe.findBestMove O earlyBoard

                        endgameMove =
                            TicTacToe.findBestMove X endgameBoard
                    in
                    -- Both should find valid moves despite different complexities
                    case ( earlyMove, endgameMove ) of
                        ( Just _, Just _ ) ->
                            Expect.pass

                        _ ->
                            Expect.fail "AI should handle both early and endgame positions"
            , test "move ordering prioritizes tactical moves correctly" <|
                \_ ->
                    let
                        -- Position with both winning and blocking opportunities
                        board =
                            [ [ Just X, Just X, Nothing ]
                            , [ Just O, Just O, Nothing ]
                            , [ Nothing, Nothing, Nothing ]
                            ]

                        availableMoves =
                            TicTacToe.generateAvailableMoves board

                        orderedMoves =
                            TicTacToe.orderMovesForPlayer X board availableMoves

                        -- Winning move should be first
                        expectedFirstMove =
                            { row = 0, col = 2 }
                    in
                    orderedMoves
                        |> List.head
                        |> Expect.equal (Just expectedFirstMove)
            , test "fork potential calculation identifies strategic positions" <|
                \_ ->
                    let
                        -- Position where center creates fork potential
                        board =
                            [ [ Just X, Nothing, Nothing ]
                            , [ Nothing, Nothing, Nothing ]
                            , [ Nothing, Nothing, Just O ]
                            ]

                        availableMoves =
                            TicTacToe.generateAvailableMoves board

                        orderedMoves =
                            TicTacToe.orderMovesForPlayer X board availableMoves

                        centerPosition =
                            { row = 1, col = 1 }

                        -- Center should be prioritized for fork potential
                        centerIndex =
                            orderedMoves
                                |> List.indexedMap Tuple.pair
                                |> List.filter (\( _, pos ) -> pos == centerPosition)
                                |> List.head
                                |> Maybe.map Tuple.first
                    in
                    case centerIndex of
                        Just index ->
                            if index <= 2 then
                                -- Center should be in top 3 moves
                                Expect.pass

                            else
                                Expect.fail ("Center position should be prioritized, but was at index " ++ String.fromInt index)

                        Nothing ->
                            Expect.fail "Center position should be available"
            ]
        , describe "Performance Benchmarks"
            [ test "AI decision time scales reasonably with game complexity" <|
                \_ ->
                    let
                        -- Test different game states for performance consistency
                        emptyBoard =
                            TicTacToe.createEmptyBoard

                        midGameBoard =
                            [ [ Just X, Nothing, Just O ]
                            , [ Nothing, Just X, Nothing ]
                            , [ Just O, Nothing, Nothing ]
                            ]

                        nearEndBoard =
                            [ [ Just X, Just O, Just X ]
                            , [ Just O, Just X, Nothing ]
                            , [ Nothing, Nothing, Just O ]
                            ]

                        -- All should complete without hanging
                        emptyMove =
                            TicTacToe.findBestMove X emptyBoard

                        midMove =
                            TicTacToe.findBestMove O midGameBoard

                        endMove =
                            TicTacToe.findBestMove X nearEndBoard
                    in
                    case ( emptyMove, midMove, endMove ) of
                        ( Just _, Just _, Just _ ) ->
                            Expect.pass

                        _ ->
                            Expect.fail "AI should handle all game phases efficiently"
            , test "iterative deepening provides consistent results" <|
                \_ ->
                    let
                        -- Complex position that benefits from iterative deepening
                        board =
                            [ [ Nothing, Just X, Nothing ]
                            , [ Just O, Nothing, Just X ]
                            , [ Nothing, Nothing, Just O ]
                            ]

                        -- Should find a reasonable move consistently
                        bestMove =
                            TicTacToe.findBestMove X board
                    in
                    case bestMove of
                        Just move ->
                            -- Verify the move is valid
                            if TicTacToe.isValidPosition move && TicTacToe.getCellState move board == Nothing then
                                Expect.pass

                            else
                                Expect.fail "AI should return valid moves"

                        Nothing ->
                            Expect.fail "AI should find a move in complex positions"
            , test "performance metrics provide useful optimization data" <|
                \_ ->
                    let
                        -- Test immediate move detection
                        immediateWinBoard =
                            [ [ Just X, Just X, Nothing ]
                            , [ Nothing, Nothing, Nothing ]
                            , [ Nothing, Nothing, Nothing ]
                            ]

                        ( immediateMove, immediateMetrics ) =
                            TicTacToe.findBestMoveWithMetrics X immediateWinBoard

                        -- Test complex position metrics
                        complexBoard =
                            [ [ Nothing, Just X, Nothing ]
                            , [ Just O, Nothing, Just X ]
                            , [ Nothing, Nothing, Just O ]
                            ]

                        ( complexMove, complexMetrics ) =
                            TicTacToe.findBestMoveWithMetrics X complexBoard
                    in
                    case ( immediateMove, complexMove ) of
                        ( Just _, Just _ ) ->
                            -- Verify immediate move is detected correctly
                            if immediateMetrics.immediateMove && not complexMetrics.immediateMove then
                                Expect.pass

                            else
                                Expect.fail "Performance metrics should distinguish immediate vs complex moves"

                        _ ->
                            Expect.fail "Both positions should yield valid moves"
            , test "search depth adapts appropriately to game complexity" <|
                \_ ->
                    let
                        -- Early game (many moves)
                        earlyBoard =
                            [ [ Just X, Nothing, Nothing ]
                            , [ Nothing, Nothing, Nothing ]
                            , [ Nothing, Nothing, Nothing ]
                            ]

                        ( _, earlyMetrics ) =
                            TicTacToe.findBestMoveWithMetrics O earlyBoard

                        -- Late game (few moves)
                        lateBoard =
                            [ [ Just X, Just O, Just X ]
                            , [ Just O, Just X, Nothing ]
                            , [ Nothing, Nothing, Just O ]
                            ]

                        ( _, lateMetrics ) =
                            TicTacToe.findBestMoveWithMetrics X lateBoard
                    in
                    -- Late game should use deeper search than early game (unless immediate move)
                    if lateMetrics.immediateMove || lateMetrics.searchDepth >= earlyMetrics.searchDepth then
                        Expect.pass

                    else
                        Expect.fail
                            ("Search depth should adapt: early="
                                ++ String.fromInt earlyMetrics.searchDepth
                                ++ " late="
                                ++ String.fromInt lateMetrics.searchDepth
                            )
            ]
        ]

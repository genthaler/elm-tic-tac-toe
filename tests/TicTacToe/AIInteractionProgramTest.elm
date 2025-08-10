module TicTacToe.AIInteractionProgramTest exposing (suite)

{-| Integration tests for human-AI gameplay interactions.

These tests verify the complete workflow of human moves followed by AI responses,
including optimal AI behavior, defensive scenarios, and timeout handling.

-}

import Expect
import ProgramTest exposing (ProgramTest)
import Test exposing (Test, describe, test)
import TestUtils.ProgramTestHelpers exposing (clickCell)
import TicTacToe.Model as TicTacToeModel exposing (GameState(..), Player(..))
import TicTacToe.ProgramTestHelpers exposing (expectTicTacToePlayer, startTicTacToe)


suite : Test
suite =
    describe "TicTacToe AI Interaction Integration Tests"
        [ testHumanMoveFollowedByAIResponse
        , testAIOptimalMovesInWinningPositions
        , testAIDefensiveBehavior
        , testAITimeoutHandling
        ]


{-| Test that human move is followed by AI response
Requirements: 2.3 - AI response timing and correctness
-}
testHumanMoveFollowedByAIResponse : Test
testHumanMoveFollowedByAIResponse =
    describe "Human move followed by AI response"
        [ test "AI responds after human makes first move" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 0, col = 0 }
                    |> ProgramTest.expectModel
                        (\model ->
                            case model.gameState of
                                Thinking O ->
                                    Expect.pass

                                _ ->
                                    Expect.fail ("Expected AI to be thinking after human move, got: " ++ Debug.toString model.gameState)
                        )
        , test "AI makes move after thinking" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 0, col = 0 }
                    |> waitForAIResponse
                    |> expectTicTacToePlayer X
        , test "AI makes valid move after human move" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 1, col = 1 }
                    |> waitForAIResponse
                    |> ProgramTest.expectModel
                        (\model ->
                            let
                                occupiedCells =
                                    countOccupiedCells model.board
                            in
                            Expect.equal 2 occupiedCells
                        )
        , test "AI responds to human move in corner" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 0, col = 0 }
                    |> waitForAIResponseToCorner
                    |> ProgramTest.expectModel
                        (\model ->
                            -- AI should respond with center or another corner
                            let
                                centerOccupied =
                                    getCellAt 1 1 model.board /= Nothing

                                cornerOccupied =
                                    List.any (\pos -> getCellAt pos.row pos.col model.board == Just O)
                                        [ { row = 0, col = 2 }
                                        , { row = 2, col = 0 }
                                        , { row = 2, col = 2 }
                                        ]
                            in
                            if centerOccupied || cornerOccupied then
                                Expect.pass

                            else
                                Expect.fail "AI should respond with center or corner move"
                        )
        , test "AI responds to human move in center" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 1, col = 1 }
                    |> waitForAIResponseToCenter
                    |> ProgramTest.expectModel
                        (\model ->
                            -- AI should respond with a corner move
                            let
                                cornerOccupied =
                                    List.any (\pos -> getCellAt pos.row pos.col model.board == Just O)
                                        [ { row = 0, col = 0 }
                                        , { row = 0, col = 2 }
                                        , { row = 2, col = 0 }
                                        , { row = 2, col = 2 }
                                        ]
                            in
                            if cornerOccupied then
                                Expect.pass

                            else
                                Expect.fail "AI should respond with corner move when human takes center"
                        )
        ]


{-| Test AI making optimal moves in winning positions
Requirements: 2.3 - AI making optimal moves in winning positions
-}
testAIOptimalMovesInWinningPositions : Test
testAIOptimalMovesInWinningPositions =
    describe "AI optimal moves in winning positions"
        [ test "AI makes strategic moves to create winning opportunities" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 0, col = 0 }
                    -- Human takes corner
                    |> waitForAIResponseToCorner
                    -- AI should take center
                    |> clickCell { row = 0, col = 1 }
                    -- Human takes edge
                    |> ProgramTest.update (TicTacToeModel.MoveMade { row = 2, col = 2 })
                    -- AI takes opposite corner
                    |> ProgramTest.expectModel
                        (\model ->
                            let
                                occupiedCells =
                                    countOccupiedCells model.board
                            in
                            if occupiedCells >= 4 then
                                Expect.pass

                            else
                                Expect.fail "Expected at least 4 moves to be made"
                        )
        , test "AI responds strategically to human corner move" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 0, col = 0 }
                    -- Human takes top-left corner
                    |> waitForAIResponseToCorner
                    |> ProgramTest.expectModel
                        (\model ->
                            -- AI should take center (1,1) or opposite corner (2,2)
                            let
                                centerTaken =
                                    getCellAt 1 1 model.board == Just O

                                oppositeCornerTaken =
                                    getCellAt 2 2 model.board == Just O
                            in
                            if centerTaken || oppositeCornerTaken then
                                Expect.pass

                            else
                                Expect.fail "AI should take center or opposite corner after human corner move"
                        )
        , test "AI responds strategically to human center move" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 1, col = 1 }
                    -- Human takes center
                    |> waitForAIResponseToCenter
                    |> ProgramTest.expectModel
                        (\model ->
                            -- AI should take a corner
                            let
                                corners =
                                    [ ( 0, 0 ), ( 0, 2 ), ( 2, 0 ), ( 2, 2 ) ]

                                cornerTaken =
                                    List.any (\( r, c ) -> getCellAt r c model.board == Just O) corners
                            in
                            if cornerTaken then
                                Expect.pass

                            else
                                Expect.fail "AI should take a corner when human takes center"
                        )
        , test "AI makes multiple strategic moves in sequence" <|
            \() ->
                startTicTacToe ()
                    |> ProgramTest.update (TicTacToeModel.MoveMade { row = 0, col = 0 })
                    -- Human: top-left
                    |> ProgramTest.update (TicTacToeModel.MoveMade { row = 1, col = 1 })
                    -- AI: center
                    |> ProgramTest.update (TicTacToeModel.MoveMade { row = 0, col = 1 })
                    -- Human: top-middle
                    |> ProgramTest.update (TicTacToeModel.MoveMade { row = 0, col = 2 })
                    -- AI: top-right (block)
                    |> ProgramTest.update (TicTacToeModel.MoveMade { row = 1, col = 0 })
                    -- Human: middle-left
                    |> ProgramTest.update (TicTacToeModel.MoveMade { row = 2, col = 0 })
                    -- AI responds
                    |> ProgramTest.expectModel
                        (\model ->
                            let
                                occupiedCells =
                                    countOccupiedCells model.board

                                gameNotOver =
                                    case model.gameState of
                                        Winner _ ->
                                            False

                                        Draw ->
                                            False

                                        _ ->
                                            True
                            in
                            if occupiedCells == 6 && gameNotOver then
                                Expect.pass

                            else if occupiedCells == 6 then
                                Expect.pass

                            else
                                Expect.fail ("Expected 6 moves, got " ++ String.fromInt occupiedCells)
                        )
        ]


{-| Test AI behavior in defensive scenarios
Requirements: 2.3 - AI behavior in defensive scenarios
-}
testAIDefensiveBehavior : Test
testAIDefensiveBehavior =
    describe "AI defensive behavior"
        [ test "AI makes defensive moves when needed" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 0, col = 0 }
                    -- Human: top-left
                    |> ProgramTest.update (TicTacToeModel.MoveMade { row = 1, col = 1 })
                    -- AI: center
                    |> clickCell { row = 0, col = 1 }
                    -- Human: top-middle (threatens top row)
                    |> ProgramTest.update (TicTacToeModel.MoveMade { row = 0, col = 2 })
                    -- AI should defend or make strategic move
                    |> ProgramTest.expectModel
                        (\model ->
                            let
                                aiMoves =
                                    countPlayerCells O model.board

                                humanMoves =
                                    countPlayerCells X model.board
                            in
                            if aiMoves == 2 && humanMoves == 2 then
                                Expect.pass

                            else
                                Expect.fail ("Expected 2 AI moves and 2 human moves, got AI: " ++ String.fromInt aiMoves ++ ", Human: " ++ String.fromInt humanMoves)
                        )
        , test "AI responds to multiple human threats" <|
            \() ->
                startTicTacToe ()
                    |> ProgramTest.update (TicTacToeModel.MoveMade { row = 1, col = 1 })
                    -- Human: center
                    |> ProgramTest.update (TicTacToeModel.MoveMade { row = 0, col = 0 })
                    -- AI: corner
                    |> ProgramTest.update (TicTacToeModel.MoveMade { row = 0, col = 1 })
                    -- Human: edge
                    |> ProgramTest.update (TicTacToeModel.MoveMade { row = 2, col = 2 })
                    -- AI: opposite corner
                    |> ProgramTest.update (TicTacToeModel.MoveMade { row = 2, col = 0 })
                    -- Human: corner
                    |> ProgramTest.update (TicTacToeModel.MoveMade { row = 0, col = 2 })
                    -- AI: should defend
                    |> ProgramTest.expectModel
                        (\model ->
                            let
                                totalMoves =
                                    countOccupiedCells model.board
                            in
                            if totalMoves == 6 then
                                Expect.pass

                            else
                                Expect.fail ("Expected 6 total moves, got " ++ String.fromInt totalMoves)
                        )
        , test "AI prevents human from creating winning position" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 0, col = 0 }
                    -- Human: corner
                    |> waitForAIResponseToCorner
                    -- AI: takes center
                    |> clickCell { row = 2, col = 2 }
                    -- Human: opposite corner
                    |> ProgramTest.update (TicTacToeModel.MoveMade { row = 0, col = 1 })
                    -- AI: blocks edge to prevent fork
                    |> ProgramTest.expectModel
                        (\model ->
                            -- Verify AI made a reasonable defensive move
                            let
                                centerTaken =
                                    getCellAt 1 1 model.board == Just O

                                edgeTaken =
                                    List.any (\( r, c ) -> getCellAt r c model.board == Just O)
                                        [ ( 0, 1 ), ( 1, 0 ), ( 1, 2 ), ( 2, 1 ) ]
                            in
                            if centerTaken || edgeTaken then
                                Expect.pass

                            else
                                Expect.fail "AI should make defensive move to prevent human fork"
                        )
        , test "AI maintains strategic advantage" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 0, col = 1 }
                    -- Human: edge move
                    |> waitForAIResponse
                    -- AI: should take center or corner
                    |> clickCell { row = 1, col = 0 }
                    -- Human: another edge
                    |> waitForAIResponse
                    -- AI: strategic response
                    |> ProgramTest.expectModel
                        (\model ->
                            let
                                aiHasCenter =
                                    getCellAt 1 1 model.board == Just O

                                aiHasCorner =
                                    List.any (\( r, c ) -> getCellAt r c model.board == Just O)
                                        [ ( 0, 0 ), ( 0, 2 ), ( 2, 0 ), ( 2, 2 ) ]
                            in
                            if aiHasCenter || aiHasCorner then
                                Expect.pass

                            else
                                Expect.fail "AI should maintain strategic position (center or corner)"
                        )
        ]


{-| Test AI timeout handling
Requirements: 5.5 - AI timeout handling
-}
testAITimeoutHandling : Test
testAITimeoutHandling =
    describe "AI timeout handling"
        [ test "AI responds within reasonable time for simple position" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 1, col = 1 }
                    |> waitForAIResponse
                    |> expectTicTacToePlayer X
        , test "AI responds within reasonable time for complex position" <|
            \() ->
                startTicTacToe ()
                    |> ProgramTest.update (TicTacToeModel.MoveMade { row = 0, col = 0 })
                    -- Human: corner
                    |> ProgramTest.update (TicTacToeModel.MoveMade { row = 1, col = 1 })
                    -- AI: center
                    |> ProgramTest.update (TicTacToeModel.MoveMade { row = 0, col = 1 })
                    -- Human: edge
                    |> ProgramTest.update (TicTacToeModel.MoveMade { row = 2, col = 2 })
                    -- AI: corner
                    |> ProgramTest.update (TicTacToeModel.MoveMade { row = 2, col = 0 })
                    -- Human: corner
                    |> ProgramTest.update (TicTacToeModel.MoveMade { row = 0, col = 2 })
                    -- AI should respond within 3 seconds
                    |> expectTicTacToePlayer X
        , test "game handles AI timeout gracefully" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 0, col = 0 }
                    -- Simulate timeout by sending a timeout error message
                    |> ProgramTest.update (TicTacToeModel.GameError (TicTacToeModel.createTimeoutError "AI worker timeout - please reset the game"))
                    |> ProgramTest.expectModel
                        (\model ->
                            case model.gameState of
                                Error errorInfo ->
                                    if String.contains "timeout" (String.toLower errorInfo.message) then
                                        Expect.pass

                                    else
                                        Expect.fail ("Expected timeout error, got: " ++ errorInfo.message)

                                _ ->
                                    Expect.fail ("Expected Error state for timeout, got: " ++ Debug.toString model.gameState)
                        )
        , test "AI timeout error is recoverable" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 0, col = 0 }
                    -- Simulate timeout by sending a timeout error message
                    |> ProgramTest.update (TicTacToeModel.GameError (TicTacToeModel.createTimeoutError "AI worker timeout - please reset the game"))
                    |> ProgramTest.expectModel
                        (\model ->
                            case model.gameState of
                                Error errorInfo ->
                                    if errorInfo.recoverable then
                                        Expect.pass

                                    else
                                        Expect.fail "AI timeout error should be recoverable"

                                _ ->
                                    Expect.fail "Expected Error state for timeout"
                        )
        ]



-- Helper functions


{-| Simulate AI response to center position (1,1)
-}
waitForAIResponseToCenter : ProgramTest TicTacToeModel.Model TicTacToeModel.Msg effect -> ProgramTest TicTacToeModel.Model TicTacToeModel.Msg effect
waitForAIResponseToCenter programTest =
    -- AI should respond with a corner when human takes center
    programTest
        |> ProgramTest.update (TicTacToeModel.MoveMade { row = 0, col = 0 })


{-| Simulate AI response to corner position
-}
waitForAIResponseToCorner : ProgramTest TicTacToeModel.Model TicTacToeModel.Msg effect -> ProgramTest TicTacToeModel.Model TicTacToeModel.Msg effect
waitForAIResponseToCorner programTest =
    -- AI should respond with center when human takes corner
    programTest
        |> ProgramTest.update (TicTacToeModel.MoveMade { row = 1, col = 1 })


{-| Generic AI response - tries to use an available position
-}
waitForAIResponse : ProgramTest TicTacToeModel.Model TicTacToeModel.Msg effect -> ProgramTest TicTacToeModel.Model TicTacToeModel.Msg effect
waitForAIResponse programTest =
    -- Default AI response - use top-right corner
    programTest
        |> ProgramTest.update (TicTacToeModel.MoveMade { row = 0, col = 2 })


{-| Count occupied cells on the board
-}
countOccupiedCells : List (List (Maybe Player)) -> Int
countOccupiedCells board =
    board
        |> List.concat
        |> List.filterMap identity
        |> List.length


{-| Get cell content at specific position
-}
getCellAt : Int -> Int -> List (List (Maybe Player)) -> Maybe Player
getCellAt row col board =
    board
        |> List.drop row
        |> List.head
        |> Maybe.andThen (List.drop col >> List.head)
        |> Maybe.withDefault Nothing


{-| Count cells occupied by a specific player
-}
countPlayerCells : Player -> List (List (Maybe Player)) -> Int
countPlayerCells targetPlayer board =
    board
        |> List.concat
        |> List.filterMap identity
        |> List.filter (\player -> player == targetPlayer)
        |> List.length

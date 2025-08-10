module TicTacToe.GameFlowIntegrationTest exposing (suite)

import Expect
import ProgramTest
import Test exposing (Test, describe, test)
import TestUtils.ProgramTestHelpers exposing (clickCell)
import TicTacToe.Model exposing (GameState(..), Player(..))
import TicTacToe.ProgramTestHelpers exposing (startTicTacToe)


suite : Test
suite =
    describe "TicTacToe Game Flow Integration Tests"
        [ testBasicGameFlow
        ]


testBasicGameFlow : Test
testBasicGameFlow =
    test "can start a game and make a move" <|
        \() ->
            startTicTacToe ()
                |> clickCell { row = 0, col = 0 }
                |> ProgramTest.expectModel
                    (\model ->
                        case model.gameState of
                            Thinking O ->
                                Expect.pass

                            _ ->
                                Expect.fail ("Expected Thinking O, got " ++ Debug.toString model.gameState)
                    )

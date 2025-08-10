module TicTacToe.ProgramTestHelpers exposing
    ( startTicTacToe
    , expectTicTacToeGameState, expectTicTacToeBoard, expectTicTacToePlayer, expectTicTacToeWinner
    )

{-| Assertion helpers for elm-program-test integration testing.

This module provides custom assertion functions for verifying game states,
UI element presence and content, and model state verification.


# Application Starters

@docs startTicTacToe, startRobotGame


# TicTacToe Game Assertions

@docs expectTicTacToeGameState, expectTicTacToeBoard, expectTicTacToePlayer, expectTicTacToeWinner

-}

import Expect exposing (Expectation)
import ProgramTest exposing (ProgramTest)
import TicTacToe.Main
import TicTacToe.Model as TicTacToeModel exposing (Board, GameState(..), Player(..))
import TicTacToe.View


{-| Start the TicTacToe game directly with default configuration
-}
startTicTacToe : () -> ProgramTest TicTacToeModel.Model TicTacToeModel.Msg (Cmd TicTacToeModel.Msg)
startTicTacToe _ =
    ProgramTest.createElement
        { init = \_ -> ( TicTacToeModel.initialModel, Cmd.none )
        , update = TicTacToe.Main.update
        , view = TicTacToe.View.view
        }
        |> ProgramTest.start ()


{-| Assert that the TicTacToe game is in the expected state
-}
expectTicTacToeGameState : GameState -> ProgramTest TicTacToeModel.Model msg effect -> Expectation
expectTicTacToeGameState expectedState programTest =
    programTest
        |> ProgramTest.expectModel
            (\model ->
                Expect.equal expectedState model.gameState
            )


{-| Assert that the TicTacToe board matches the expected configuration
Takes a list of (row, col, player) tuples representing occupied cells
-}
expectTicTacToeBoard : List ( Int, Int, Player ) -> ProgramTest TicTacToeModel.Model msg effect -> Expectation
expectTicTacToeBoard expectedCells programTest =
    programTest
        |> ProgramTest.expectModel
            (\model ->
                let
                    actualCells =
                        extractBoardCells model.board

                    -- Convert to comparable format for comparison
                    expectedCellsComparable =
                        List.map cellToComparable expectedCells |> List.sort

                    actualCellsComparable =
                        List.map cellToComparable actualCells |> List.sort
                in
                Expect.equal expectedCellsComparable actualCellsComparable
            )


{-| Assert that it's the expected player's turn
-}
expectTicTacToePlayer : Player -> ProgramTest TicTacToeModel.Model msg effect -> Expectation
expectTicTacToePlayer expectedPlayer programTest =
    programTest
        |> ProgramTest.expectModel
            (\model ->
                case model.gameState of
                    Waiting player ->
                        Expect.equal expectedPlayer player

                    Thinking player ->
                        Expect.equal expectedPlayer player

                    _ ->
                        Expect.fail ("Expected game to be waiting for player " ++ playerToString expectedPlayer ++ ", but game state is " ++ gameStateToString model.gameState)
            )


{-| Assert that the game has the expected winner
-}
expectTicTacToeWinner : Player -> ProgramTest TicTacToeModel.Model msg effect -> Expectation
expectTicTacToeWinner expectedWinner programTest =
    programTest
        |> ProgramTest.expectModel
            (\model ->
                case model.gameState of
                    Winner winner ->
                        Expect.equal expectedWinner winner

                    _ ->
                        Expect.fail ("Expected game to have winner " ++ playerToString expectedWinner ++ ", but game state is " ++ gameStateToString model.gameState)
            )



-- Helper functions


{-| Extract occupied cells from a TicTacToe board
-}
extractBoardCells : Board -> List ( Int, Int, Player )
extractBoardCells board =
    board
        |> List.indexedMap
            (\rowIndex row ->
                row
                    |> List.indexedMap
                        (\colIndex cell ->
                            Maybe.map (\player -> ( rowIndex, colIndex, player )) cell
                        )
                    |> List.filterMap identity
            )
        |> List.concat


{-| Convert Player to string for error messages
-}
playerToString : Player -> String
playerToString player =
    case player of
        X ->
            "X"

        O ->
            "O"


{-| Convert GameState to string for error messages
-}
gameStateToString : GameState -> String
gameStateToString gameState =
    case gameState of
        Waiting player ->
            "Waiting for " ++ playerToString player

        Thinking player ->
            "Thinking for " ++ playerToString player

        Winner player ->
            "Winner: " ++ playerToString player

        Draw ->
            "Draw"

        Error _ ->
            "Error"


{-| Convert a cell tuple to a comparable format
-}
cellToComparable : ( Int, Int, Player ) -> ( Int, Int, String )
cellToComparable ( row, col, player ) =
    ( row, col, playerToString player )

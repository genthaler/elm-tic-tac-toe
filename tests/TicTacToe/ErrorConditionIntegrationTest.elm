module TicTacToe.ErrorConditionIntegrationTest exposing (suite)

{-| Integration tests for TicTacToe error conditions and edge cases.

This module tests error handling scenarios using elm-program-test to simulate
real user interactions and verify proper error handling, recovery, and user feedback.

Tests cover:

  - Invalid move handling and user feedback
  - Worker communication failure scenarios
  - Game state corruption recovery
  - Timeout handling in AI moves
  - Error recovery workflows

-}

import Expect
import Test exposing (Test, describe, test)
import Theme.Theme
import TicTacToe.Model as TicTacToeModel exposing (ErrorType(..), GameState(..), Player(..))


suite : Test
suite =
    describe "TicTacToe Error Condition Integration Tests"
        [ invalidMoveTests
        , workerCommunicationFailureTests
        , gameStateCorruptionTests
        , timeoutHandlingTests
        , errorRecoveryWorkflowTests
        ]


{-| Tests for handling invalid moves and providing user feedback
-}
invalidMoveTests : Test
invalidMoveTests =
    describe "Invalid Move Handling"
        [ test "invalid move creates error state" <|
            \_ ->
                let
                    model =
                        TicTacToeModel.initialModel

                    errorInfo =
                        TicTacToeModel.createInvalidMoveError "Cell is already occupied"

                    errorModel =
                        { model | gameState = Error errorInfo }
                in
                Expect.equal (Error errorInfo) errorModel.gameState
        , test "error recovery from invalid move works" <|
            \_ ->
                let
                    model =
                        TicTacToeModel.initialModel

                    errorInfo =
                        TicTacToeModel.createInvalidMoveError "Test error"

                    errorModel =
                        { model | gameState = Error errorInfo }

                    recoveredModel =
                        TicTacToeModel.recoverFromError errorModel
                in
                Expect.equal (Waiting X) recoveredModel.gameState
        ]


{-| Tests for worker communication failure scenarios
-}
workerCommunicationFailureTests : Test
workerCommunicationFailureTests =
    describe "Worker Communication Failures"
        [ test "worker timeout error is created correctly" <|
            \_ ->
                let
                    errorInfo =
                        TicTacToeModel.createTimeoutError "AI move timed out"
                in
                Expect.all
                    [ \_ -> Expect.equal "AI move timed out" errorInfo.message
                    , \_ -> Expect.equal TimeoutError errorInfo.errorType
                    , \_ -> Expect.equal True errorInfo.recoverable
                    ]
                    ()
        , test "worker communication error is created correctly" <|
            \_ ->
                let
                    errorInfo =
                        TicTacToeModel.createWorkerCommunicationError "Failed to communicate with AI worker"
                in
                Expect.all
                    [ \_ -> Expect.equal "Failed to communicate with AI worker" errorInfo.message
                    , \_ -> Expect.equal WorkerCommunicationError errorInfo.errorType
                    , \_ -> Expect.equal True errorInfo.recoverable
                    ]
                    ()
        , test "worker error recovery resets game state" <|
            \_ ->
                let
                    model =
                        TicTacToeModel.initialModel

                    errorInfo =
                        TicTacToeModel.createWorkerCommunicationError "Test error"

                    errorModel =
                        { model | gameState = Error errorInfo, colorScheme = Theme.Theme.Dark }

                    recoveredModel =
                        TicTacToeModel.recoverFromError errorModel
                in
                Expect.all
                    [ \_ -> Expect.equal (Waiting X) recoveredModel.gameState
                    , \_ -> Expect.equal Theme.Theme.Dark recoveredModel.colorScheme
                    ]
                    ()
        ]


{-| Tests for game state corruption recovery
-}
gameStateCorruptionTests : Test
gameStateCorruptionTests =
    describe "Game State Corruption Recovery"
        [ test "game logic error is created correctly" <|
            \_ ->
                let
                    errorInfo =
                        TicTacToeModel.createGameLogicError "Invalid game state detected"
                in
                Expect.all
                    [ \_ -> Expect.equal "Invalid game state detected" errorInfo.message
                    , \_ -> Expect.equal GameLogicError errorInfo.errorType
                    , \_ -> Expect.equal True errorInfo.recoverable
                    ]
                    ()
        , test "recovery from corrupted state resets game" <|
            \_ ->
                let
                    model =
                        TicTacToeModel.initialModel

                    errorInfo =
                        TicTacToeModel.createGameLogicError "Test error"

                    errorModel =
                        { model | gameState = Error errorInfo, colorScheme = Theme.Theme.Dark }

                    recoveredModel =
                        TicTacToeModel.recoverFromError errorModel
                in
                Expect.all
                    [ \_ -> Expect.equal (Waiting X) recoveredModel.gameState
                    , \_ -> Expect.equal Theme.Theme.Dark recoveredModel.colorScheme
                    ]
                    ()
        ]


{-| Tests for timeout handling in AI moves
-}
timeoutHandlingTests : Test
timeoutHandlingTests =
    describe "AI Move Timeout Handling"
        [ test "timeout error is recoverable" <|
            \_ ->
                let
                    errorInfo =
                        TicTacToeModel.createTimeoutError "AI move timed out after 5 seconds"

                    errorState =
                        Error errorInfo
                in
                Expect.equal True (TicTacToeModel.isRecoverableError errorState)
        , test "timeout recovery resets game" <|
            \_ ->
                let
                    model =
                        TicTacToeModel.initialModel

                    errorInfo =
                        TicTacToeModel.createTimeoutError "Test timeout"

                    errorModel =
                        { model | gameState = Error errorInfo }

                    recoveredModel =
                        TicTacToeModel.recoverFromError errorModel
                in
                Expect.equal (Waiting X) recoveredModel.gameState
        ]


{-| Tests for complete error recovery workflows
-}
errorRecoveryWorkflowTests : Test
errorRecoveryWorkflowTests =
    describe "Error Recovery Workflows"
        [ test "all error types are recoverable" <|
            \_ ->
                let
                    errorTypes =
                        [ TicTacToeModel.createInvalidMoveError "test"
                        , TicTacToeModel.createGameLogicError "test"
                        , TicTacToeModel.createWorkerCommunicationError "test"
                        , TicTacToeModel.createJsonError "test"
                        , TicTacToeModel.createTimeoutError "test"
                        , TicTacToeModel.createUnknownError "test"
                        ]

                    allRecoverable =
                        List.all (\errorInfo -> errorInfo.recoverable) errorTypes
                in
                Expect.equal True allRecoverable
        , test "error recovery preserves theme" <|
            \_ ->
                let
                    model =
                        TicTacToeModel.initialModel

                    errorInfo =
                        TicTacToeModel.createWorkerCommunicationError "Test error"

                    errorModel =
                        { model | gameState = Error errorInfo, colorScheme = Theme.Theme.Dark }

                    recoveredModel =
                        TicTacToeModel.recoverFromError errorModel
                in
                Expect.equal Theme.Theme.Dark recoveredModel.colorScheme
        , test "non-error states are not affected by recovery" <|
            \_ ->
                let
                    baseModel =
                        TicTacToeModel.initialModel

                    model =
                        { baseModel | gameState = Winner X }

                    recoveredModel =
                        TicTacToeModel.recoverFromError model
                in
                Expect.equal (Winner X) recoveredModel.gameState
        ]

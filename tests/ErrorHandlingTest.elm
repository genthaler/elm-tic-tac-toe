module ErrorHandlingTest exposing (suite)

{-| Test suite for error handling functionality.
Tests error state management, error recovery, and error message formatting.
-}

import Expect
import Model exposing (ColorScheme(..), ErrorInfo, ErrorType(..), GameState(..), Model, Player(..), Position, createGameLogicError, createInvalidMoveError, createJsonError, createTimeoutError, createUnknownError, createWorkerCommunicationError, initialModel, isRecoverableError, recoverFromError)
import Test exposing (Test, describe, test)
import TicTacToe.TicTacToe as TicTacToe


suite : Test
suite =
    describe "Error Handling"
        [ errorCreationTests
        , errorRecoveryTests
        , errorStateManagementTests
        , errorMessageFormattingTests
        ]


errorCreationTests : Test
errorCreationTests =
    describe "Error Creation"
        [ test "createInvalidMoveError creates correct error info" <|
            \_ ->
                let
                    errorInfo =
                        createInvalidMoveError "Test invalid move"
                in
                Expect.all
                    [ \_ -> Expect.equal "Test invalid move" errorInfo.message
                    , \_ -> Expect.equal InvalidMove errorInfo.errorType
                    , \_ -> Expect.equal True errorInfo.recoverable
                    ]
                    ()
        , test "createGameLogicError creates correct error info" <|
            \_ ->
                let
                    errorInfo =
                        createGameLogicError "Test game logic error"
                in
                Expect.all
                    [ \_ -> Expect.equal "Test game logic error" errorInfo.message
                    , \_ -> Expect.equal GameLogicError errorInfo.errorType
                    , \_ -> Expect.equal True errorInfo.recoverable
                    ]
                    ()
        , test "createWorkerCommunicationError creates correct error info" <|
            \_ ->
                let
                    errorInfo =
                        createWorkerCommunicationError "Test worker error"
                in
                Expect.all
                    [ \_ -> Expect.equal "Test worker error" errorInfo.message
                    , \_ -> Expect.equal WorkerCommunicationError errorInfo.errorType
                    , \_ -> Expect.equal True errorInfo.recoverable
                    ]
                    ()
        , test "createJsonError creates correct error info" <|
            \_ ->
                let
                    errorInfo =
                        createJsonError "Test JSON error"
                in
                Expect.all
                    [ \_ -> Expect.equal "Test JSON error" errorInfo.message
                    , \_ -> Expect.equal JsonError errorInfo.errorType
                    , \_ -> Expect.equal True errorInfo.recoverable
                    ]
                    ()
        , test "createTimeoutError creates correct error info" <|
            \_ ->
                let
                    errorInfo =
                        createTimeoutError "Test timeout error"
                in
                Expect.all
                    [ \_ -> Expect.equal "Test timeout error" errorInfo.message
                    , \_ -> Expect.equal TimeoutError errorInfo.errorType
                    , \_ -> Expect.equal True errorInfo.recoverable
                    ]
                    ()
        , test "createUnknownError creates correct error info" <|
            \_ ->
                let
                    errorInfo =
                        createUnknownError "Test unknown error"
                in
                Expect.all
                    [ \_ -> Expect.equal "Test unknown error" errorInfo.message
                    , \_ -> Expect.equal UnknownError errorInfo.errorType
                    , \_ -> Expect.equal True errorInfo.recoverable
                    ]
                    ()
        ]


errorRecoveryTests : Test
errorRecoveryTests =
    describe "Error Recovery"
        [ test "isRecoverableError returns True for recoverable error" <|
            \_ ->
                let
                    errorState =
                        Error (createInvalidMoveError "Test error")
                in
                Expect.equal True (isRecoverableError errorState)
        , test "isRecoverableError returns False for non-error states" <|
            \_ ->
                let
                    testCases =
                        [ Waiting X
                        , Thinking O
                        , Winner X
                        , Draw
                        ]

                    results =
                        List.map isRecoverableError testCases
                in
                Expect.equal [ False, False, False, False ] results
        , test "recoverFromError recovers from InvalidMove error" <|
            \_ ->
                let
                    errorModel =
                        { initialModel | gameState = Error (createInvalidMoveError "Test error") }

                    recoveredModel =
                        recoverFromError errorModel
                in
                Expect.equal (Waiting X) recoveredModel.gameState
        , test "recoverFromError resets game for GameLogicError" <|
            \_ ->
                let
                    errorModel =
                        { initialModel
                            | gameState = Error (createGameLogicError "Test error")
                            , colorScheme = Dark
                            , board =
                                [ [ Just X, Nothing, Nothing ]
                                , [ Nothing, Nothing, Nothing ]
                                , [ Nothing, Nothing, Nothing ]
                                ]
                        }

                    recoveredModel =
                        recoverFromError errorModel
                in
                Expect.all
                    [ \_ -> Expect.equal (Waiting X) recoveredModel.gameState
                    , \_ -> Expect.equal Dark recoveredModel.colorScheme
                    , \_ -> Expect.equal TicTacToe.createEmptyBoard recoveredModel.board
                    ]
                    ()
        , test "recoverFromError resets game for WorkerCommunicationError" <|
            \_ ->
                let
                    errorModel =
                        { initialModel
                            | gameState = Error (createWorkerCommunicationError "Test error")
                            , colorScheme = Dark
                        }

                    recoveredModel =
                        recoverFromError errorModel
                in
                Expect.all
                    [ \_ -> Expect.equal (Waiting X) recoveredModel.gameState
                    , \_ -> Expect.equal Dark recoveredModel.colorScheme
                    ]
                    ()
        , test "recoverFromError resets game for JsonError" <|
            \_ ->
                let
                    errorModel =
                        { initialModel | gameState = Error (createJsonError "Test error") }

                    recoveredModel =
                        recoverFromError errorModel
                in
                Expect.equal (Waiting X) recoveredModel.gameState
        , test "recoverFromError resets game for TimeoutError" <|
            \_ ->
                let
                    errorModel =
                        { initialModel | gameState = Error (createTimeoutError "Test error") }

                    recoveredModel =
                        recoverFromError errorModel
                in
                Expect.equal (Waiting X) recoveredModel.gameState
        , test "recoverFromError resets game for UnknownError" <|
            \_ ->
                let
                    errorModel =
                        { initialModel | gameState = Error (createUnknownError "Test error") }

                    recoveredModel =
                        recoverFromError errorModel
                in
                Expect.equal (Waiting X) recoveredModel.gameState
        , test "recoverFromError does not change non-error states" <|
            \_ ->
                let
                    testCases =
                        [ { initialModel | gameState = Waiting X }
                        , { initialModel | gameState = Thinking O }
                        , { initialModel | gameState = Winner X }
                        , { initialModel | gameState = Draw }
                        ]

                    results =
                        List.map recoverFromError testCases

                    expectedStates =
                        [ Waiting X, Thinking O, Winner X, Draw ]

                    actualStates =
                        List.map .gameState results
                in
                Expect.equal expectedStates actualStates
        ]


errorStateManagementTests : Test
errorStateManagementTests =
    describe "Error State Management"
        [ test "error state preserves model properties except gameState" <|
            \_ ->
                let
                    originalModel =
                        { initialModel
                            | colorScheme = Dark
                            , board =
                                [ [ Just X, Nothing, Nothing ]
                                , [ Nothing, Just O, Nothing ]
                                , [ Nothing, Nothing, Nothing ]
                                ]
                            , maybeWindow = Just ( 800, 600 )
                        }

                    errorModel =
                        { originalModel | gameState = Error (createInvalidMoveError "Test error") }
                in
                Expect.all
                    [ \_ -> Expect.equal Dark errorModel.colorScheme
                    , \_ -> Expect.equal originalModel.board errorModel.board
                    , \_ -> Expect.equal (Just ( 800, 600 )) errorModel.maybeWindow
                    , \_ ->
                        case errorModel.gameState of
                            Error errorInfo ->
                                Expect.equal "Test error" errorInfo.message

                            _ ->
                                Expect.fail "Expected Error state"
                    ]
                    ()
        , test "different error types have correct properties" <|
            \_ ->
                let
                    errorTypes =
                        [ InvalidMove
                        , GameLogicError
                        , WorkerCommunicationError
                        , JsonError
                        , TimeoutError
                        , UnknownError
                        ]

                    allRecoverable =
                        List.all
                            (\errorType ->
                                let
                                    errorInfo =
                                        { message = "Test", errorType = errorType, recoverable = True }
                                in
                                errorInfo.recoverable
                            )
                            errorTypes
                in
                Expect.equal True allRecoverable
        ]


errorMessageFormattingTests : Test
errorMessageFormattingTests =
    describe "Error Message Formatting"
        [ test "error messages contain helpful information" <|
            \_ ->
                let
                    testCases =
                        [ ( createInvalidMoveError "Cell occupied", "Cell occupied" )
                        , ( createGameLogicError "Invalid state", "Invalid state" )
                        , ( createWorkerCommunicationError "Worker failed", "Worker failed" )
                        , ( createJsonError "Parse error", "Parse error" )
                        , ( createTimeoutError "Timeout occurred", "Timeout occurred" )
                        , ( createUnknownError "Unknown issue", "Unknown issue" )
                        ]

                    results =
                        List.map (\( errorInfo, expectedMessage ) -> errorInfo.message == expectedMessage) testCases
                in
                Expect.equal (List.repeat 6 True) results
        , test "error types are correctly assigned" <|
            \_ ->
                let
                    testCases =
                        [ ( createInvalidMoveError "Test", InvalidMove )
                        , ( createGameLogicError "Test", GameLogicError )
                        , ( createWorkerCommunicationError "Test", WorkerCommunicationError )
                        , ( createJsonError "Test", JsonError )
                        , ( createTimeoutError "Test", TimeoutError )
                        , ( createUnknownError "Test", UnknownError )
                        ]

                    results =
                        List.map (\( errorInfo, expectedType ) -> errorInfo.errorType == expectedType) testCases
                in
                Expect.equal (List.repeat 6 True) results
        ]

module TicTacToe.JsonCommunicationTest exposing (suite)

{-| Test suite for JSON communication error handling.
Tests encoding/decoding failures, validation, and error recovery.
-}

import Expect
import Json.Encode as Encode
import Test exposing (Test, describe, test)
import Theme.Theme exposing (ColorScheme(..))
import TicTacToe.Main exposing (encodeModelSafely, handleWorkerMessage, validateModelForEncoding, validateWorkerMessage)
import TicTacToe.Model exposing (ErrorType(..), GameState(..), Msg(..), Player(..), createGameLogicError, createJsonError, createWorkerCommunicationError, initialModel)
import Time


suite : Test
suite =
    describe "JSON Communication Error Handling"
        [ modelEncodingTests
        , modelValidationTests
        , workerMessageHandlingTests
        , workerMessageValidationTests
        , errorRecoveryTests
        ]


modelEncodingTests : Test
modelEncodingTests =
    describe "Model Encoding"
        [ test "encodeModelSafely succeeds for valid thinking model" <|
            \_ ->
                let
                    model =
                        { initialModel | gameState = Thinking O }

                    result =
                        encodeModelSafely model
                in
                case result of
                    Ok _ ->
                        Expect.pass

                    Err errorInfo ->
                        Expect.fail ("Expected successful encoding, got error: " ++ errorInfo.message)
        , test "encodeModelSafely fails for non-thinking model" <|
            \_ ->
                let
                    model =
                        { initialModel | gameState = Waiting X }

                    result =
                        encodeModelSafely model
                in
                case result of
                    Ok _ ->
                        Expect.fail "Expected encoding to fail for non-thinking model"

                    Err errorInfo ->
                        Expect.all
                            [ \_ -> Expect.equal GameLogicError errorInfo.errorType
                            , \_ -> Expect.equal True (String.contains "Thinking state" errorInfo.message)
                            ]
                            ()
        , test "encodeModelSafely fails for invalid board dimensions" <|
            \_ ->
                let
                    model =
                        { initialModel
                            | gameState = Thinking O
                            , board = [ [ Nothing, Nothing ] ] -- Invalid: only 1 row with 2 columns
                        }

                    result =
                        encodeModelSafely model
                in
                case result of
                    Ok _ ->
                        Expect.fail "Expected encoding to fail for invalid board"

                    Err errorInfo ->
                        Expect.all
                            [ \_ -> Expect.equal GameLogicError errorInfo.errorType
                            , \_ -> Expect.equal True (String.contains "board" errorInfo.message)
                            ]
                            ()
        ]


modelValidationTests : Test
modelValidationTests =
    describe "Model Validation"
        [ test "validateModelForEncoding accepts valid thinking model" <|
            \_ ->
                let
                    model =
                        { initialModel | gameState = Thinking O }

                    result =
                        validateModelForEncoding model
                in
                case result of
                    Ok () ->
                        Expect.pass

                    Err errorInfo ->
                        Expect.fail ("Expected validation to pass, got error: " ++ errorInfo.message)
        , test "validateModelForEncoding rejects model with wrong number of rows" <|
            \_ ->
                let
                    model =
                        { initialModel
                            | gameState = Thinking O
                            , board = [ [ Nothing, Nothing, Nothing ], [ Nothing, Nothing, Nothing ] ] -- Only 2 rows
                        }

                    result =
                        validateModelForEncoding model
                in
                case result of
                    Ok () ->
                        Expect.fail "Expected validation to fail for wrong number of rows"

                    Err errorInfo ->
                        Expect.equal True (String.contains "3 rows" errorInfo.message)
        , test "validateModelForEncoding rejects model with wrong number of columns" <|
            \_ ->
                let
                    model =
                        { initialModel
                            | gameState = Thinking O
                            , board =
                                [ [ Nothing, Nothing ] -- Only 2 columns
                                , [ Nothing, Nothing, Nothing ]
                                , [ Nothing, Nothing, Nothing ]
                                ]
                        }

                    result =
                        validateModelForEncoding model
                in
                case result of
                    Ok () ->
                        Expect.fail "Expected validation to fail for wrong number of columns"

                    Err errorInfo ->
                        Expect.equal True (String.contains "3 columns" errorInfo.message)
        , test "validateModelForEncoding rejects non-thinking states" <|
            \_ ->
                let
                    testCases =
                        [ Waiting X
                        , Winner O
                        , Draw
                        , Error (createGameLogicError "Test")
                        ]

                    results =
                        List.map
                            (\gameState ->
                                validateModelForEncoding { initialModel | gameState = gameState }
                            )
                            testCases

                    allFailed =
                        List.all
                            (\result ->
                                case result of
                                    Err _ ->
                                        True

                                    Ok () ->
                                        False
                            )
                            results
                in
                Expect.equal True allFailed
        ]


workerMessageHandlingTests : Test
workerMessageHandlingTests =
    describe "Worker Message Handling"
        [ test "handleWorkerMessage decodes valid MoveMade message" <|
            \_ ->
                let
                    position =
                        { row = 1, col = 1 }

                    encodedMsg =
                        Encode.object
                            [ ( "type", Encode.string "MoveMade" )
                            , ( "position"
                              , Encode.object
                                    [ ( "row", Encode.int position.row )
                                    , ( "col", Encode.int position.col )
                                    ]
                              )
                            ]

                    result =
                        handleWorkerMessage encodedMsg
                in
                case result of
                    MoveMade decodedPosition ->
                        Expect.equal position decodedPosition

                    _ ->
                        Expect.fail "Expected MoveMade message"
        , test "handleWorkerMessage handles invalid JSON gracefully" <|
            \_ ->
                let
                    invalidJson =
                        Encode.object [ ( "invalid", Encode.string "data" ) ]

                    result =
                        handleWorkerMessage invalidJson
                in
                case result of
                    GameError errorInfo ->
                        Expect.all
                            [ \_ -> Expect.equal JsonError errorInfo.errorType
                            , \_ -> Expect.equal True (String.contains "decode" errorInfo.message)
                            ]
                            ()

                    _ ->
                        Expect.fail "Expected GameError for invalid JSON"
        , test "handleWorkerMessage includes JSON context in error messages" <|
            \_ ->
                let
                    invalidJson =
                        Encode.object [ ( "type", Encode.string "UnknownType" ) ]

                    result =
                        handleWorkerMessage invalidJson
                in
                case result of
                    GameError errorInfo ->
                        Expect.equal True (String.contains "JSON:" errorInfo.message)

                    _ ->
                        Expect.fail "Expected GameError with JSON context"
        ]


workerMessageValidationTests : Test
workerMessageValidationTests =
    describe "Worker Message Validation"
        [ test "validateWorkerMessage accepts valid MoveMade message" <|
            \_ ->
                let
                    validMove =
                        MoveMade { row = 1, col = 1 }

                    result =
                        validateWorkerMessage validMove
                in
                Expect.equal validMove result
        , test "validateWorkerMessage rejects MoveMade with invalid position" <|
            \_ ->
                let
                    invalidMove =
                        MoveMade { row = 5, col = 1 }

                    -- Row 5 is out of bounds
                    result =
                        validateWorkerMessage invalidMove
                in
                case result of
                    GameError errorInfo ->
                        Expect.all
                            [ \_ -> Expect.equal WorkerCommunicationError errorInfo.errorType
                            , \_ -> Expect.equal True (String.contains "invalid position" errorInfo.message)
                            ]
                            ()

                    _ ->
                        Expect.fail "Expected GameError for invalid position"
        , test "validateWorkerMessage rejects GameError with empty message" <|
            \_ ->
                let
                    emptyErrorMsg =
                        GameError { message = "", errorType = UnknownError, recoverable = True }

                    result =
                        validateWorkerMessage emptyErrorMsg
                in
                case result of
                    GameError errorInfo ->
                        Expect.all
                            [ \_ -> Expect.equal WorkerCommunicationError errorInfo.errorType
                            , \_ -> Expect.equal True (String.contains "empty error message" errorInfo.message)
                            ]
                            ()

                    _ ->
                        Expect.fail "Expected GameError for empty error message"
        , test "validateWorkerMessage passes through valid GameError" <|
            \_ ->
                let
                    validError =
                        GameError (createGameLogicError "Valid error message")

                    result =
                        validateWorkerMessage validError
                in
                Expect.equal validError result
        , test "validateWorkerMessage passes through other message types" <|
            \_ ->
                let
                    testMessages =
                        [ ResetGame
                        , ColorScheme Light
                        , Tick (Time.millisToPosix 0)
                        ]

                    results =
                        List.map validateWorkerMessage testMessages
                in
                Expect.equal testMessages results
        ]


errorRecoveryTests : Test
errorRecoveryTests =
    describe "Error Recovery"
        [ test "JSON errors are recoverable" <|
            \_ ->
                let
                    jsonError =
                        createJsonError "Test JSON error"
                in
                Expect.equal True jsonError.recoverable
        , test "Worker communication errors are recoverable" <|
            \_ ->
                let
                    workerError =
                        createWorkerCommunicationError "Test worker error"
                in
                Expect.equal True workerError.recoverable
        , test "Error messages provide helpful context" <|
            \_ ->
                let
                    testCases =
                        [ ( createJsonError "Parse failed", "Parse failed" )
                        , ( createWorkerCommunicationError "Worker timeout", "Worker timeout" )
                        ]

                    results =
                        List.map (\( errorInfo, expectedMessage ) -> String.contains expectedMessage errorInfo.message) testCases
                in
                Expect.equal [ True, True ] results
        ]

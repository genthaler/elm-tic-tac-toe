module TicTacToe.WorkerIntegrationTest exposing (suite)

{-| End-to-end integration tests for worker communication
These tests simulate the complete worker communication flow
-}

import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)
import TicTacToe.Model exposing (GameState(..), Msg(..), Player(..), createGameLogicError, createUnknownError, createWorkerCommunicationError, decodeModel, decodeMsg, encodeModel, encodeMsg, initialModel)
import TicTacToe.TicTacToe exposing (findBestMove, makeMove)


{-| Simulate the complete worker processing pipeline
-}
simulateWorkerProcessing : Encode.Value -> Encode.Value
simulateWorkerProcessing encodedModel =
    case Decode.decodeValue decodeModel encodedModel of
        Ok model ->
            let
                response =
                    case model.gameState of
                        Thinking player ->
                            case findBestMove player model.board of
                                Just position ->
                                    MoveMade position

                                Nothing ->
                                    GameError (createGameLogicError "AI could not find a valid move")

                        _ ->
                            GameError (createUnknownError ("Worker received unexpected game state: " ++ Debug.toString model.gameState))
            in
            encodeMsg response

        Err error ->
            encodeMsg (GameError (createWorkerCommunicationError ("Worker failed to decode model: " ++ Decode.errorToString error)))


suite : Test
suite =
    describe "Worker Integration"
        [ describe "Complete worker communication flow"
            [ test "successful AI move calculation" <|
                \_ ->
                    let
                        -- Set up initial game state with human move
                        boardWithHumanMove =
                            makeMove X { row = 0, col = 0 } initialModel.board

                        modelForWorker =
                            { initialModel
                                | gameState = Thinking O
                                , board = boardWithHumanMove
                            }

                        -- Encode model for worker
                        encodedModel =
                            encodeModel modelForWorker

                        -- Simulate worker processing
                        workerResponse =
                            simulateWorkerProcessing encodedModel

                        -- Decode worker response
                        decodedResponse =
                            case Decode.decodeValue decodeMsg workerResponse of
                                Ok msg ->
                                    msg

                                Err error ->
                                    GameError (createWorkerCommunicationError ("Failed to decode worker response: " ++ Decode.errorToString error))
                    in
                    case decodedResponse of
                        MoveMade position ->
                            Expect.all
                                [ \pos -> Expect.atLeast 0 pos.row
                                , \pos -> Expect.atMost 2 pos.row
                                , \pos -> Expect.atLeast 0 pos.col
                                , \pos -> Expect.atMost 2 pos.col
                                ]
                                position

                        _ ->
                            Expect.fail ("Expected MoveMade response, got: " ++ Debug.toString decodedResponse)
            , test "worker handles invalid game state" <|
                \_ ->
                    let
                        -- Send model with invalid game state
                        invalidModel =
                            { initialModel | gameState = Winner X }

                        encodedModel =
                            encodeModel invalidModel

                        workerResponse =
                            simulateWorkerProcessing encodedModel

                        decodedResponse =
                            case Decode.decodeValue decodeMsg workerResponse of
                                Ok msg ->
                                    msg

                                Err error ->
                                    GameError (createWorkerCommunicationError ("Failed to decode worker response: " ++ Decode.errorToString error))
                    in
                    case decodedResponse of
                        GameError errorInfo ->
                            if String.contains "unexpected game state" errorInfo.message then
                                Expect.pass

                            else
                                Expect.fail ("Expected unexpected game state error, got: " ++ errorInfo.message)

                        _ ->
                            Expect.fail ("Expected GameError response, got: " ++ Debug.toString decodedResponse)
            , test "worker handles corrupted model data" <|
                \_ ->
                    let
                        -- Send corrupted JSON
                        corruptedJson =
                            Encode.object [ ( "invalid", Encode.string "data" ) ]

                        workerResponse =
                            simulateWorkerProcessing corruptedJson

                        decodedResponse =
                            case Decode.decodeValue decodeMsg workerResponse of
                                Ok msg ->
                                    msg

                                Err error ->
                                    GameError (createWorkerCommunicationError ("Failed to decode worker response: " ++ Decode.errorToString error))
                    in
                    case decodedResponse of
                        GameError errorInfo ->
                            if String.contains "failed to decode model" errorInfo.message then
                                Expect.pass

                            else
                                Expect.fail ("Expected decode error, got: " ++ errorInfo.message)

                        _ ->
                            Expect.fail ("Expected GameError response, got: " ++ Debug.toString decodedResponse)
            , test "worker handles full board scenario" <|
                \_ ->
                    let
                        -- Create a full board
                        fullBoard =
                            [ [ Just X, Just O, Just X ]
                            , [ Just O, Just X, Just O ]
                            , [ Just O, Just X, Just O ]
                            ]

                        modelForWorker =
                            { initialModel
                                | gameState = Thinking O
                                , board = fullBoard
                            }

                        encodedModel =
                            encodeModel modelForWorker

                        workerResponse =
                            simulateWorkerProcessing encodedModel

                        decodedResponse =
                            case Decode.decodeValue decodeMsg workerResponse of
                                Ok msg ->
                                    msg

                                Err error ->
                                    GameError (createWorkerCommunicationError ("Failed to decode worker response: " ++ Decode.errorToString error))
                    in
                    case decodedResponse of
                        GameError errorInfo ->
                            Expect.equal "AI could not find a valid move" errorInfo.message

                        _ ->
                            Expect.fail ("Expected GameError for full board, got: " ++ Debug.toString decodedResponse)
            , test "round-trip encoding preserves data integrity" <|
                \_ ->
                    let
                        originalModel =
                            { initialModel
                                | gameState = Thinking O
                                , board =
                                    [ [ Just X, Nothing, Just O ]
                                    , [ Nothing, Just X, Nothing ]
                                    , [ Just O, Nothing, Nothing ]
                                    ]
                            }

                        -- Encode and decode the model
                        roundTripModel =
                            originalModel
                                |> encodeModel
                                |> Decode.decodeValue decodeModel
                    in
                    case roundTripModel of
                        Ok decodedModel ->
                            Expect.all
                                [ \_ -> Expect.equal originalModel.board decodedModel.board
                                , \_ -> Expect.equal originalModel.gameState decodedModel.gameState
                                ]
                                ()

                        Err error ->
                            Expect.fail ("Round-trip encoding failed: " ++ Decode.errorToString error)
            , test "worker response encoding preserves message integrity" <|
                \_ ->
                    let
                        originalMsg =
                            MoveMade { row = 1, col = 2 }

                        -- Encode and decode the message
                        roundTripMsg =
                            originalMsg
                                |> encodeMsg
                                |> Decode.decodeValue decodeMsg
                    in
                    case roundTripMsg of
                        Ok decodedMsg ->
                            Expect.equal originalMsg decodedMsg

                        Err error ->
                            Expect.fail ("Message round-trip failed: " ++ Decode.errorToString error)
            ]
        , describe "Error handling scenarios"
            [ test "handles malformed JSON gracefully" <|
                \_ ->
                    let
                        malformedJson =
                            Encode.object
                                [ ( "board", Encode.string "not-a-board" )
                                , ( "gameState", Encode.int 42 )
                                ]

                        result =
                            simulateWorkerProcessing malformedJson

                        decodedResult =
                            Decode.decodeValue decodeMsg result
                    in
                    case decodedResult of
                        Ok (GameError errorInfo) ->
                            if String.contains "failed to decode model" errorInfo.message then
                                Expect.pass

                            else
                                Expect.fail ("Expected decode error, got: " ++ errorInfo.message)

                        Ok _ ->
                            Expect.fail "Expected GameError for malformed JSON"

                        Err error ->
                            Expect.fail ("Failed to decode error response: " ++ Decode.errorToString error)
            , test "handles missing required fields" <|
                \_ ->
                    let
                        incompleteJson =
                            Encode.object [ ( "board", Encode.null ) ]

                        -- Missing gameState field
                        result =
                            simulateWorkerProcessing incompleteJson

                        decodedResult =
                            Decode.decodeValue decodeMsg result
                    in
                    case decodedResult of
                        Ok (GameError _) ->
                            Expect.pass

                        -- Any error is acceptable for incomplete data
                        Ok _ ->
                            Expect.fail "Expected GameError for incomplete JSON"

                        Err error ->
                            Expect.fail ("Failed to decode error response: " ++ Decode.errorToString error)
            ]
        ]

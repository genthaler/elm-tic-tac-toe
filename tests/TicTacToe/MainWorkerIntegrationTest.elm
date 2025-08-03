module TicTacToe.MainWorkerIntegrationTest exposing (suite)

{-| Integration tests for Main application and Worker communication
These tests focus on the data flow and message handling between main thread and worker
-}

import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)
import TicTacToe.Model exposing (GameState(..), Model, Msg(..), Player(..), Position, createGameLogicError, createInvalidMoveError, createWorkerCommunicationError, decodeModel, decodeMsg, encodeModel, encodeMsg, initialModel)
import TicTacToe.TicTacToe exposing (isValidMove, makeMove, updateGameState)
import Time


{-| Simulate the worker message handling logic from Main.elm
-}
simulateHandleWorkerMessage : Decode.Value -> Msg
simulateHandleWorkerMessage value =
    case Decode.decodeValue decodeMsg value of
        Ok msg ->
            msg

        Err error ->
            GameError (createWorkerCommunicationError ("Worker communication error: " ++ Decode.errorToString error))


{-| Simulate the move handling logic from Main.elm
-}
simulateHandleMoveMade : Model -> Position -> ( Model, Bool )
simulateHandleMoveMade model position =
    case model.gameState of
        Waiting player ->
            if isValidMove position model.board model.gameState then
                let
                    newBoard =
                        makeMove player position model.board

                    newGameState =
                        updateGameState newBoard (Waiting player)

                    updatedModel =
                        { model
                            | board = newBoard
                            , gameState = newGameState
                            , lastMove = model.now
                        }
                in
                case newGameState of
                    Waiting nextPlayer ->
                        if nextPlayer == O then
                            -- AI's turn - would send to worker
                            ( { updatedModel | gameState = Thinking nextPlayer }, True )

                        else
                            -- Human's turn continues
                            ( updatedModel, False )

                    _ ->
                        -- Game ended
                        ( updatedModel, False )

            else
                ( { model | gameState = Error (createInvalidMoveError "Invalid move - cell is occupied or position is out of bounds") }, False )

        Thinking player ->
            -- This is an AI move response from the worker
            if isValidMove position model.board (Waiting player) then
                let
                    newBoard =
                        makeMove player position model.board

                    newGameState =
                        updateGameState newBoard (Waiting player)

                    updatedModel =
                        { model
                            | board = newBoard
                            , gameState = newGameState
                            , lastMove = model.now
                        }
                in
                ( updatedModel, False )

            else
                ( { model | gameState = Error (createGameLogicError "AI made invalid move - this should not happen") }, False )

        _ ->
            ( { model | gameState = Error (createGameLogicError "Move attempted in invalid game state - game may have already ended") }, False )


suite : Test
suite =
    describe "Main-Worker Integration"
        [ describe "Worker message handling"
            [ test "handles valid MoveMade message from worker" <|
                \_ ->
                    let
                        moveMessage =
                            MoveMade { row = 1, col = 1 }

                        encodedMessage =
                            encodeMsg moveMessage

                        result =
                            simulateHandleWorkerMessage encodedMessage
                    in
                    Expect.equal moveMessage result
            , test "handles invalid JSON from worker" <|
                \_ ->
                    let
                        invalidJson =
                            Encode.object [ ( "invalid", Encode.string "data" ) ]

                        result =
                            simulateHandleWorkerMessage invalidJson
                    in
                    case result of
                        GameError errorInfo ->
                            if String.contains "Worker communication error" errorInfo.message then
                                Expect.pass

                            else
                                Expect.fail ("Expected worker communication error, got: " ++ errorInfo.message)

                        _ ->
                            Expect.fail "Expected GameError for invalid JSON"
            , test "handles GameError message from worker" <|
                \_ ->
                    let
                        errorMessage =
                            GameError (createGameLogicError "AI could not find a valid move")

                        encodedMessage =
                            encodeMsg errorMessage

                        result =
                            simulateHandleWorkerMessage encodedMessage
                    in
                    Expect.equal errorMessage result
            ]
        , describe "Move handling integration"
            [ test "human move triggers AI thinking state" <|
                \_ ->
                    let
                        initialState =
                            { initialModel | gameState = Waiting X }

                        position =
                            { row = 0, col = 0 }

                        ( newModel, shouldSendToWorker ) =
                            simulateHandleMoveMade initialState position
                    in
                    Expect.all
                        [ \( model, _ ) ->
                            case model.gameState of
                                Thinking O ->
                                    Expect.pass

                                _ ->
                                    Expect.fail ("Expected Thinking O state, got: " ++ Debug.toString model.gameState)
                        , \( _, sendToWorker ) ->
                            if sendToWorker then
                                Expect.pass

                            else
                                Expect.fail "Expected to send model to worker"
                        ]
                        ( newModel, shouldSendToWorker )
            , test "AI move from worker updates game state correctly" <|
                \_ ->
                    let
                        boardWithHumanMove =
                            makeMove X { row = 0, col = 0 } initialModel.board

                        thinkingState =
                            { initialModel
                                | gameState = Thinking O
                                , board = boardWithHumanMove
                            }

                        aiPosition =
                            { row = 1, col = 1 }

                        ( newModel, _ ) =
                            simulateHandleMoveMade thinkingState aiPosition

                        expectedBoard =
                            makeMove O aiPosition boardWithHumanMove
                    in
                    Expect.all
                        [ \model -> Expect.equal expectedBoard model.board
                        , \model ->
                            case model.gameState of
                                Waiting X ->
                                    Expect.pass

                                _ ->
                                    Expect.fail ("Expected Waiting X state, got: " ++ Debug.toString model.gameState)
                        ]
                        newModel
            , test "invalid move results in error state" <|
                \_ ->
                    let
                        initialState =
                            { initialModel | gameState = Waiting X }

                        -- Try to move to an occupied position
                        boardWithMove =
                            makeMove X { row = 0, col = 0 } initialModel.board

                        stateWithMove =
                            { initialState | board = boardWithMove }

                        invalidPosition =
                            { row = 0, col = 0 }

                        -- Same position as already occupied
                        ( newModel, _ ) =
                            simulateHandleMoveMade stateWithMove invalidPosition
                    in
                    case newModel.gameState of
                        Error errorInfo ->
                            Expect.equal "Invalid move - cell is occupied or position is out of bounds" errorInfo.message

                        _ ->
                            Expect.fail ("Expected Error state, got: " ++ Debug.toString newModel.gameState)
            , test "move in ended game results in error" <|
                \_ ->
                    let
                        endedGameState =
                            { initialModel | gameState = Winner X }

                        position =
                            { row = 1, col = 1 }

                        ( newModel, _ ) =
                            simulateHandleMoveMade endedGameState position
                    in
                    case newModel.gameState of
                        Error errorInfo ->
                            Expect.equal "Move attempted in invalid game state - game may have already ended" errorInfo.message

                        _ ->
                            Expect.fail ("Expected Error state, got: " ++ Debug.toString newModel.gameState)
            ]
        , describe "Model encoding for worker communication"
            [ test "model with Thinking state encodes and decodes correctly" <|
                \_ ->
                    let
                        model =
                            { initialModel
                                | gameState = Thinking O
                                , board =
                                    [ [ Just X, Nothing, Nothing ]
                                    , [ Nothing, Nothing, Nothing ]
                                    , [ Nothing, Nothing, Nothing ]
                                    ]
                            }

                        encoded =
                            encodeModel model

                        decoded =
                            Decode.decodeValue decodeModel encoded
                    in
                    case decoded of
                        Ok decodedModel ->
                            Expect.all
                                [ \m -> Expect.equal model.gameState m.gameState
                                , \m -> Expect.equal model.board m.board
                                ]
                                decodedModel

                        Err error ->
                            Expect.fail ("Model encoding/decoding failed: " ++ Decode.errorToString error)
            , test "complex game state encodes correctly for worker" <|
                \_ ->
                    let
                        complexBoard =
                            [ [ Just X, Just O, Nothing ]
                            , [ Nothing, Just X, Just O ]
                            , [ Just O, Nothing, Just X ]
                            ]

                        model =
                            { initialModel
                                | gameState = Thinking O
                                , board = complexBoard
                                , lastMove = Just (Time.millisToPosix 5000)
                                , now = Just (Time.millisToPosix 10000)
                            }

                        encoded =
                            encodeModel model

                        decoded =
                            Decode.decodeValue decodeModel encoded
                    in
                    case decoded of
                        Ok decodedModel ->
                            Expect.all
                                [ \m -> Expect.equal model.gameState m.gameState
                                , \m -> Expect.equal model.board m.board
                                , \m -> Expect.equal model.lastMove m.lastMove
                                , \m -> Expect.equal model.now m.now
                                ]
                                decodedModel

                        Err error ->
                            Expect.fail ("Complex model encoding/decoding failed: " ++ Decode.errorToString error)
            ]
        , describe "Complete main-to-worker-to-main flow simulation"
            [ test "full game flow with worker communication" <|
                \_ ->
                    let
                        -- Step 1: Human makes first move
                        initialState =
                            { initialModel | gameState = Waiting X }

                        humanPosition =
                            { row = 0, col = 0 }

                        ( stateAfterHuman, shouldSendToWorker1 ) =
                            simulateHandleMoveMade initialState humanPosition

                        -- Step 2: Simulate worker processing (encode/decode model)
                        encodedModel =
                            encodeModel stateAfterHuman

                        decodedModel =
                            case Decode.decodeValue decodeModel encodedModel of
                                Ok model ->
                                    model

                                Err _ ->
                                    stateAfterHuman

                        -- Step 3: Simulate AI finding a move and sending response
                        aiResponse =
                            MoveMade { row = 1, col = 1 }

                        encodedResponse =
                            encodeMsg aiResponse

                        decodedResponse =
                            simulateHandleWorkerMessage encodedResponse

                        -- Step 4: Apply AI move
                        ( finalState, _ ) =
                            case decodedResponse of
                                MoveMade pos ->
                                    simulateHandleMoveMade decodedModel pos

                                _ ->
                                    ( decodedModel, False )
                    in
                    Expect.all
                        [ \_ ->
                            if shouldSendToWorker1 then
                                Expect.pass

                            else
                                Expect.fail "Should send to worker after human move"
                        , \_ ->
                            case stateAfterHuman.gameState of
                                Thinking O ->
                                    Expect.pass

                                _ ->
                                    Expect.fail "Should be in Thinking O state after human move"
                        , \_ ->
                            case decodedResponse of
                                MoveMade _ ->
                                    Expect.pass

                                _ ->
                                    Expect.fail "Worker should respond with MoveMade"
                        , \_ ->
                            case finalState.gameState of
                                Waiting X ->
                                    Expect.pass

                                _ ->
                                    Expect.fail ("Should be waiting for X after AI move, got: " ++ Debug.toString finalState.gameState)
                        , \_ ->
                            -- Check that both moves are on the board
                            let
                                humanMovePresent =
                                    TicTacToe.TicTacToe.getCellState humanPosition finalState.board == Just X

                                aiMovePresent =
                                    TicTacToe.TicTacToe.getCellState { row = 1, col = 1 } finalState.board == Just O
                            in
                            if humanMovePresent && aiMovePresent then
                                Expect.pass

                            else
                                Expect.fail "Both human and AI moves should be present on board"
                        ]
                        ()
            , test "worker communication error handling" <|
                \_ ->
                    let
                        -- Simulate corrupted JSON from worker
                        corruptedJson =
                            Encode.object [ ( "invalid", Encode.string "message" ) ]

                        result =
                            simulateHandleWorkerMessage corruptedJson
                    in
                    case result of
                        GameError errorInfo ->
                            if String.contains "Worker communication error" errorInfo.message then
                                Expect.pass

                            else
                                Expect.fail ("Expected worker communication error, got: " ++ errorInfo.message)

                        _ ->
                            Expect.fail "Expected GameError for corrupted worker message"
            , test "worker error message propagation" <|
                \_ ->
                    let
                        workerError =
                            GameError (createGameLogicError "AI could not find a valid move")

                        encodedError =
                            encodeMsg workerError

                        result =
                            simulateHandleWorkerMessage encodedError
                    in
                    case result of
                        GameError errorInfo ->
                            Expect.equal "AI could not find a valid move" errorInfo.message

                        _ ->
                            Expect.fail "Expected GameError to be propagated from worker"
            , test "invalid AI move from worker handling" <|
                \_ ->
                    let
                        -- Set up a board with a move already made
                        boardWithMove =
                            makeMove X { row = 0, col = 0 } initialModel.board

                        thinkingState =
                            { initialModel
                                | gameState = Thinking O
                                , board = boardWithMove
                            }

                        -- Simulate AI trying to make move to occupied cell
                        ( result, _ ) =
                            simulateHandleMoveMade thinkingState { row = 0, col = 0 }
                    in
                    case result.gameState of
                        Error errorInfo ->
                            Expect.equal "AI made invalid move - this should not happen" errorInfo.message

                        _ ->
                            Expect.fail ("Expected Error state for invalid AI move, got: " ++ Debug.toString result.gameState)
            , test "multiple round trip communication" <|
                \_ ->
                    let
                        -- Round 1: Human X moves
                        initialState =
                            { initialModel | gameState = Waiting X }

                        ( stateAfterX1, _ ) =
                            simulateHandleMoveMade initialState { row = 0, col = 0 }

                        -- Round 1: AI O responds
                        ( stateAfterO1, _ ) =
                            simulateHandleMoveMade stateAfterX1 { row = 1, col = 1 }

                        -- Round 2: Human X moves again
                        ( stateAfterX2, _ ) =
                            simulateHandleMoveMade stateAfterO1 { row = 0, col = 1 }

                        -- Round 2: AI O responds again
                        ( finalState, _ ) =
                            simulateHandleMoveMade stateAfterX2 { row = 2, col = 2 }
                    in
                    Expect.all
                        [ \_ ->
                            case finalState.gameState of
                                Waiting X ->
                                    Expect.pass

                                _ ->
                                    Expect.fail ("Expected Waiting X after multiple rounds, got: " ++ Debug.toString finalState.gameState)
                        , \_ ->
                            -- Verify all moves are on the board
                            let
                                expectedMoves =
                                    [ ( { row = 0, col = 0 }, Just X )
                                    , ( { row = 1, col = 1 }, Just O )
                                    , ( { row = 0, col = 1 }, Just X )
                                    , ( { row = 2, col = 2 }, Just O )
                                    ]

                                allMovesPresent =
                                    expectedMoves
                                        |> List.all
                                            (\( pos, expectedPlayer ) ->
                                                TicTacToe.TicTacToe.getCellState pos finalState.board == expectedPlayer
                                            )
                            in
                            if allMovesPresent then
                                Expect.pass

                            else
                                Expect.fail "Not all moves from multiple rounds are present on board"
                        ]
                        ()
            ]
        ]

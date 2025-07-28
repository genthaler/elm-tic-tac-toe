module GameWorkerTest exposing (suite)

{-| Tests for GameWorker module functionality
-}

import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Model exposing (GameState(..), Msg(..), Player(..), createGameLogicError, createUnknownError, createWorkerCommunicationError, decodeMsg, encodeModel, initialModel)
import Test exposing (Test, describe, test)
import TicTacToe.TicTacToe exposing (makeMove)


suite : Test
suite =
    describe "GameWorker"
        [ describe "Model encoding/decoding for worker communication"
            [ test "encodes and decodes model with Thinking state" <|
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
                            Decode.decodeValue Model.decodeModel encoded
                    in
                    case decoded of
                        Ok decodedModel ->
                            Expect.equal model.gameState decodedModel.gameState

                        Err error ->
                            Expect.fail ("Decoding failed: " ++ Decode.errorToString error)
            , test "encodes and decodes model with complex board state" <|
                \_ ->
                    let
                        model =
                            { initialModel
                                | gameState = Thinking O
                                , board =
                                    [ [ Just X, Just O, Nothing ]
                                    , [ Nothing, Just X, Nothing ]
                                    , [ Just O, Nothing, Nothing ]
                                    ]
                            }

                        encoded =
                            encodeModel model

                        decoded =
                            Decode.decodeValue Model.decodeModel encoded
                    in
                    case decoded of
                        Ok decodedModel ->
                            Expect.equal model.board decodedModel.board

                        Err error ->
                            Expect.fail ("Decoding failed: " ++ Decode.errorToString error)
            ]
        , describe "Message encoding for worker responses"
            [ test "encodes MoveMade message correctly" <|
                \_ ->
                    let
                        msg =
                            MoveMade { row = 1, col = 2 }

                        encoded =
                            Model.encodeMsg msg

                        decoded =
                            Decode.decodeValue decodeMsg encoded
                    in
                    case decoded of
                        Ok decodedMsg ->
                            Expect.equal msg decodedMsg

                        Err error ->
                            Expect.fail ("Decoding failed: " ++ Decode.errorToString error)
            , test "encodes GameError message correctly" <|
                \_ ->
                    let
                        msg =
                            GameError (createGameLogicError "AI could not find a valid move")

                        encoded =
                            Model.encodeMsg msg

                        decoded =
                            Decode.decodeValue decodeMsg encoded
                    in
                    case decoded of
                        Ok decodedMsg ->
                            Expect.equal msg decodedMsg

                        Err error ->
                            Expect.fail ("Decoding failed: " ++ Decode.errorToString error)
            ]
        , describe "Worker AI move calculation scenarios"
            [ test "should handle empty board scenario" <|
                \_ ->
                    let
                        model =
                            { initialModel | gameState = Thinking O }

                        -- This simulates what the worker would do
                        result =
                            case model.gameState of
                                Thinking player ->
                                    case TicTacToe.TicTacToe.findBestMove player model.board of
                                        Just position ->
                                            MoveMade position

                                        Nothing ->
                                            GameError (createGameLogicError "AI could not find a valid move")

                                _ ->
                                    GameError (createUnknownError "Unexpected game state")
                    in
                    case result of
                        MoveMade position ->
                            Expect.all
                                [ \pos -> Expect.atLeast 0 pos.row
                                , \pos -> Expect.atMost 2 pos.row
                                , \pos -> Expect.atLeast 0 pos.col
                                , \pos -> Expect.atMost 2 pos.col
                                ]
                                position

                        _ ->
                            Expect.fail "Expected MoveMade message for empty board"
            , test "should handle board with one move scenario" <|
                \_ ->
                    let
                        boardWithOneMove =
                            makeMove X { row = 1, col = 1 } initialModel.board

                        model =
                            { initialModel
                                | gameState = Thinking O
                                , board = boardWithOneMove
                            }

                        -- This simulates what the worker would do
                        result =
                            case model.gameState of
                                Thinking player ->
                                    case TicTacToe.TicTacToe.findBestMove player model.board of
                                        Just position ->
                                            MoveMade position

                                        Nothing ->
                                            GameError (createGameLogicError "AI could not find a valid move")

                                _ ->
                                    GameError (createUnknownError "Unexpected game state")
                    in
                    case result of
                        MoveMade position ->
                            Expect.all
                                [ \pos -> Expect.atLeast 0 pos.row
                                , \pos -> Expect.atMost 2 pos.row
                                , \pos -> Expect.atLeast 0 pos.col
                                , \pos -> Expect.atMost 2 pos.col
                                ]
                                position

                        _ ->
                            Expect.fail "Expected MoveMade message for board with one move"
            , test "should handle full board scenario" <|
                \_ ->
                    let
                        fullBoard =
                            [ [ Just X, Just O, Just X ]
                            , [ Just O, Just X, Just O ]
                            , [ Just O, Just X, Just O ]
                            ]

                        model =
                            { initialModel
                                | gameState = Thinking O
                                , board = fullBoard
                            }

                        -- This simulates what the worker would do
                        result =
                            case model.gameState of
                                Thinking player ->
                                    case TicTacToe.TicTacToe.findBestMove player model.board of
                                        Just position ->
                                            MoveMade position

                                        Nothing ->
                                            GameError (createGameLogicError "AI could not find a valid move")

                                _ ->
                                    GameError (createUnknownError "Unexpected game state")
                    in
                    case result of
                        GameError errorInfo ->
                            Expect.equal "AI could not find a valid move" errorInfo.message

                        _ ->
                            Expect.fail "Expected GameError for full board"
            ]
        , describe "Worker error handling"
            [ test "should handle invalid game state" <|
                \_ ->
                    let
                        model =
                            { initialModel | gameState = Winner X }

                        -- This simulates what the worker would do
                        result =
                            case model.gameState of
                                Thinking player ->
                                    case TicTacToe.TicTacToe.findBestMove player model.board of
                                        Just position ->
                                            MoveMade position

                                        Nothing ->
                                            GameError (createGameLogicError "AI could not find a valid move")

                                _ ->
                                    GameError (createUnknownError ("Worker received unexpected game state: " ++ Debug.toString model.gameState))
                    in
                    case result of
                        GameError errorInfo ->
                            if String.contains "unexpected game state" errorInfo.message then
                                Expect.pass

                            else
                                Expect.fail ("Expected error message to contain 'unexpected game state', got: " ++ errorInfo.message)

                        _ ->
                            Expect.fail "Expected GameError for invalid game state"
            , test "should handle invalid board dimensions" <|
                \_ ->
                    let
                        invalidBoard =
                            [ [ Just X, Nothing ] -- Only 2 columns
                            , [ Nothing, Nothing, Nothing ]
                            , [ Nothing, Nothing, Nothing ]
                            ]

                        model =
                            { initialModel
                                | gameState = Thinking O
                                , board = invalidBoard
                            }

                        -- Simulate board validation
                        isValid =
                            let
                                hasCorrectDimensions =
                                    List.length model.board == 3 && List.all (\row -> List.length row == 3) model.board
                            in
                            hasCorrectDimensions

                        result =
                            if isValid then
                                case TicTacToe.TicTacToe.findBestMove O model.board of
                                    Just position ->
                                        MoveMade position

                                    Nothing ->
                                        GameError (createGameLogicError "AI could not find a valid move")

                            else
                                GameError (createWorkerCommunicationError "Invalid board state received by worker")
                    in
                    case result of
                        GameError errorInfo ->
                            Expect.equal "Invalid board state received by worker" errorInfo.message

                        _ ->
                            Expect.fail "Expected GameError for invalid board dimensions"
            , test "should handle invalid piece count" <|
                \_ ->
                    let
                        invalidBoard =
                            [ [ Just X, Just X, Just X ] -- Too many X pieces
                            , [ Nothing, Nothing, Nothing ]
                            , [ Nothing, Nothing, Nothing ]
                            ]

                        model =
                            { initialModel
                                | gameState = Thinking O
                                , board = invalidBoard
                            }

                        -- Simulate piece count validation
                        isValid =
                            let
                                ( finalXCount, finalOCount ) =
                                    model.board
                                        |> List.concat
                                        |> List.foldl
                                            (\cell ( xCount, oCount ) ->
                                                case cell of
                                                    Just X ->
                                                        ( xCount + 1, oCount )

                                                    Just O ->
                                                        ( xCount, oCount + 1 )

                                                    Nothing ->
                                                        ( xCount, oCount )
                                            )
                                            ( 0, 0 )

                                validPieceCount =
                                    finalXCount == finalOCount || finalXCount == finalOCount + 1
                            in
                            validPieceCount

                        result =
                            if isValid then
                                case TicTacToe.TicTacToe.findBestMove O model.board of
                                    Just position ->
                                        MoveMade position

                                    Nothing ->
                                        GameError (createGameLogicError "AI could not find a valid move")

                            else
                                GameError (createWorkerCommunicationError "Invalid board state received by worker")
                    in
                    case result of
                        GameError errorInfo ->
                            Expect.equal "Invalid board state received by worker" errorInfo.message

                        _ ->
                            Expect.fail "Expected GameError for invalid piece count"
            , test "should handle JSON decoding errors gracefully" <|
                \_ ->
                    let
                        invalidJson =
                            Encode.object [ ( "board", Encode.string "invalid" ) ]

                        result =
                            case Decode.decodeValue Model.decodeModel invalidJson of
                                Ok _ ->
                                    MoveMade { row = 0, col = 0 }

                                -- This shouldn't happen
                                Err error ->
                                    GameError (createWorkerCommunicationError ("Worker failed to decode model: " ++ Decode.errorToString error))
                    in
                    case result of
                        GameError errorInfo ->
                            if String.contains "Worker failed to decode model" errorInfo.message then
                                Expect.pass

                            else
                                Expect.fail ("Expected decode error message, got: " ++ errorInfo.message)

                        _ ->
                            Expect.fail "Expected GameError for JSON decoding failure"
            ]
        ]

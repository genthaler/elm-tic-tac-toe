module Model exposing (Board, ColorScheme(..), ErrorInfo, ErrorType(..), Flags, GameState(..), Line, Model, Msg(..), Player(..), Position, boardToString, createGameLogicError, createInvalidMoveError, createJsonError, createTimeoutError, createUnknownError, createWorkerCommunicationError, decodeColorScheme, decodeErrorType, decodeModel, decodeMsg, encodeColorScheme, encodeErrorType, encodeModel, encodeMsg, idleTimeoutMillis, initialModel, isRecoverableError, lineToString, playerToString, recoverFromError, timeSpent)

{-| This module defines the core data structures and types for the Tic-Tac-Toe game.
It includes types for players, game board, game state, and JSON encoding/decoding functions.
-}

import Browser.Dom
import Json.Decode as Decode
import Json.Decode.Pipeline as DecodePipeline
import Json.Encode as Encode
import Json.Encode.Extra as EncodeExtra
import Time



-- Model


{-| Represents a line on the board (row, column, or diagonal)
consisting of player positions (X, O, or empty)
-}
type alias Line =
    List (Maybe Player)


{-| Represents a position on the board with row and column coordinates
-}
type alias Position =
    { row : Int, col : Int }


{-| The game board represented as a list of lines
-}
type alias Board =
    List Line


{-| Converts a line to a string representation for debugging purposes
-}
lineToString : Line -> String
lineToString line =
    line
        |> List.map
            (\cell ->
                case cell of
                    Nothing ->
                        "_"

                    Just X ->
                        "X"

                    Just O ->
                        "O"
            )
        |> String.join " "


{-| Converts a board to a string representation for debugging purposes
-}
boardToString : Board -> String
boardToString board =
    board
        |> List.map lineToString
        |> String.join "\n"


{-| Converts a player to a string representation
-}
playerToString : Player -> String
playerToString player =
    case player of
        X ->
            "X"

        O ->
            "O"


{-| The main model for the game, containing all state information
-}
type alias Model =
    { board : Board
    , gameState : GameState
    , lastMove : Maybe Time.Posix
    , now : Maybe Time.Posix
    , colorScheme : ColorScheme
    , maybeWindow : Maybe ( Int, Int )
    }


{-| Represents the current state of the game

  - Waiting: Waiting for a player to make a move
  - Thinking: AI is calculating its next move
  - Winner: Game has ended with a winner
  - Draw: Game has ended in a draw
  - Error: An error has occurred

-}
type GameState
    = Waiting Player
    | Thinking Player
    | Winner Player
    | Draw
    | Error ErrorInfo


{-| Detailed error information for better error handling and recovery
-}
type alias ErrorInfo =
    { message : String
    , errorType : ErrorType
    , recoverable : Bool
    }


{-| Categories of errors that can occur in the game
-}
type ErrorType
    = InvalidMove
    | GameLogicError
    | WorkerCommunicationError
    | JsonError
    | TimeoutError
    | UnknownError


{-| Flags passed to the Elm application on initialization
-}
type alias Flags =
    { colorScheme : String }


{-| Represents a player in the game (X or O)
X is typically the human player, O is typically the computer
-}
type Player
    = X
    | O


{-| Represents the color scheme of the game (Light or Dark)
-}
type ColorScheme
    = Light
    | Dark


{-| The timeout threshold in milliseconds for idle player detection
After this amount of time, the game will automatically make a move for the idle player
-}
idleTimeoutMillis : Int
idleTimeoutMillis =
    5000


{-| Calculates the time spent since the last move in milliseconds
Returns the full timeout value if no move has been made yet
-}
timeSpent : Model -> Float
timeSpent model =
    Maybe.map2 (\lastMove now -> (Time.posixToMillis now - Time.posixToMillis lastMove) |> Basics.toFloat) model.lastMove model.now
        |> Maybe.withDefault (toFloat idleTimeoutMillis)



-- Initial Game


{-| Returns the initial game model with an empty board and X as the current player
-}
initialModel : Model
initialModel =
    { board =
        [ [ Nothing, Nothing, Nothing ]
        , [ Nothing, Nothing, Nothing ]
        , [ Nothing, Nothing, Nothing ]
        ]
    , gameState = Waiting X
    , colorScheme = Light
    , lastMove = Nothing
    , now = Nothing
    , maybeWindow = Nothing
    }



-- Msg


{-| Represents a message that can be sent to the game, either a move, reset, or error
-}
type Msg
    = MoveMade Position
    | ResetGame
    | GameError ErrorInfo
    | ColorScheme ColorScheme
    | GetViewPort Browser.Dom.Viewport
    | GetResize Int Int
    | Tick Time.Posix



-- JSON encoding and decoding


{-| Encodes a position as a JSON object
-}
encodePosition : Position -> Encode.Value
encodePosition position =
    Encode.object
        [ ( "row", Encode.int position.row )
        , ( "col", Encode.int position.col )
        ]


{-| Decodes a position from a JSON object
-}
decodePosition : Decode.Decoder Position
decodePosition =
    Decode.succeed Position
        |> DecodePipeline.required "row" Decode.int
        |> DecodePipeline.required "col" Decode.int


{-| Encodes a Browser.Dom.Viewport as a JSON object
Used for communicating viewport information between main thread and worker
-}
encodeViewport : Browser.Dom.Viewport -> Encode.Value
encodeViewport viewport =
    Encode.object
        [ ( "scene"
          , Encode.object
                [ ( "width", Encode.float viewport.scene.width )
                , ( "height", Encode.float viewport.scene.height )
                ]
          )
        , ( "viewport"
          , Encode.object
                [ ( "x", Encode.float viewport.viewport.x )
                , ( "y", Encode.float viewport.viewport.y )
                , ( "width", Encode.float viewport.viewport.width )
                , ( "height", Encode.float viewport.viewport.height )
                ]
          )
        ]


{-| Decodes a Browser.Dom.Viewport from a JSON object
Used for communicating viewport information between main thread and worker
-}
decodeViewport : Decode.Decoder Browser.Dom.Viewport
decodeViewport =
    Decode.succeed Browser.Dom.Viewport
        |> DecodePipeline.required "scene"
            (Decode.succeed (\width height -> { width = width, height = height })
                |> DecodePipeline.required "width" Decode.float
                |> DecodePipeline.required "height" Decode.float
            )
        |> DecodePipeline.required "viewport"
            (Decode.succeed (\x y width height -> { x = x, y = y, width = width, height = height })
                |> DecodePipeline.required "x" Decode.float
                |> DecodePipeline.required "y" Decode.float
                |> DecodePipeline.required "width" Decode.float
                |> DecodePipeline.required "height" Decode.float
            )


{-| Encodes the game model as a JSON object
-}
encodeModel : Model -> Encode.Value
encodeModel model =
    let
        encodeBoard : Board -> Encode.Value
        encodeBoard board =
            Encode.list (Encode.list encodePlayer) board

        encodePlayer : Maybe Player -> Encode.Value
        encodePlayer player =
            case player of
                Just X ->
                    Encode.string "X"

                Just O ->
                    Encode.string "O"

                Nothing ->
                    Encode.null

        encodeGameState : GameState -> Encode.Value
        encodeGameState state =
            case state of
                Waiting player ->
                    Encode.object
                        [ ( "type", Encode.string "Waiting" )
                        , ( "player", encodePlayer (Just player) )
                        ]

                Thinking player ->
                    Encode.object
                        [ ( "type", Encode.string "Thinking" )
                        , ( "player", encodePlayer (Just player) )
                        ]

                Winner player ->
                    Encode.object
                        [ ( "type", Encode.string "Winner" )
                        , ( "player", encodePlayer (Just player) )
                        ]

                Draw ->
                    Encode.object
                        [ ( "type", Encode.string "Draw" )
                        ]

                Error errorInfo ->
                    Encode.object
                        [ ( "type", Encode.string "Error" )
                        , ( "message", Encode.string errorInfo.message )
                        , ( "errorType", encodeErrorType errorInfo.errorType )
                        , ( "recoverable", Encode.bool errorInfo.recoverable )
                        ]
    in
    Encode.object
        [ ( "board", encodeBoard model.board )
        , ( "gameState", encodeGameState model.gameState )
        , ( "lastMove", EncodeExtra.maybe (Encode.int << Time.posixToMillis) model.lastMove )
        , ( "now", EncodeExtra.maybe (Encode.int << Time.posixToMillis) model.now )
        , ( "colorScheme", encodeColorScheme model.colorScheme )
        , ( "maybeWindow"
          , EncodeExtra.maybe
                (\( width, height ) ->
                    Encode.object
                        [ ( "width", Encode.int width )
                        , ( "height", Encode.int height )
                        ]
                )
                model.maybeWindow
          )
        ]


{-| Decodes the game model from a JSON object
-}
decodeModel : Decode.Decoder Model
decodeModel =
    let
        decodeBoard : Decode.Decoder Board
        decodeBoard =
            Decode.list (Decode.list (Decode.nullable decodePlayer))

        decodePlayer : Decode.Decoder Player
        decodePlayer =
            Decode.string
                |> Decode.andThen
                    (\value ->
                        case value of
                            "X" ->
                                Decode.succeed X

                            "O" ->
                                Decode.succeed O

                            _ ->
                                Decode.fail ("Invalid player: " ++ value)
                    )

        decodeGameState : Decode.Decoder GameState
        decodeGameState =
            Decode.field "type" Decode.string
                |> Decode.andThen
                    (\typeStr ->
                        case typeStr of
                            "Waiting" ->
                                Decode.map Waiting
                                    (Decode.field "player" decodePlayer)

                            "Thinking" ->
                                Decode.map Thinking
                                    (Decode.field "player" decodePlayer)

                            "Winner" ->
                                Decode.map Winner
                                    (Decode.field "player" decodePlayer)

                            "Draw" ->
                                Decode.succeed Draw

                            "Error" ->
                                Decode.map Error
                                    (Decode.succeed ErrorInfo
                                        |> DecodePipeline.required "message" Decode.string
                                        |> DecodePipeline.optional "errorType" decodeErrorType UnknownError
                                        |> DecodePipeline.optional "recoverable" Decode.bool True
                                    )

                            _ ->
                                Decode.fail ("Invalid game state type: " ++ typeStr)
                    )
    in
    Decode.succeed Model
        |> DecodePipeline.required "board" decodeBoard
        |> DecodePipeline.required "gameState" decodeGameState
        |> DecodePipeline.optional "lastMove" (Decode.nullable (Decode.map Time.millisToPosix Decode.int)) Nothing
        |> DecodePipeline.optional "now" (Decode.nullable (Decode.map Time.millisToPosix Decode.int)) Nothing
        |> DecodePipeline.required "colorScheme" decodeColorScheme
        |> DecodePipeline.optional "maybeWindow" (Decode.nullable (Decode.map2 Tuple.pair (Decode.field "width" Decode.int) (Decode.field "height" Decode.int))) Nothing


{-| Encodes the game colorScheme as a JSON string
-}
encodeColorScheme : ColorScheme -> Encode.Value
encodeColorScheme colorScheme =
    case colorScheme of
        Light ->
            Encode.string "Light"

        Dark ->
            Encode.string "Dark"


{-| Decodes the game colorScheme from a JSON string
-}
decodeColorScheme : Decode.Decoder ColorScheme
decodeColorScheme =
    Decode.string
        |> Decode.andThen
            (\colorSchemeStr ->
                case colorSchemeStr of
                    "Light" ->
                        Decode.succeed Light

                    "Dark" ->
                        Decode.succeed Dark

                    _ ->
                        Decode.fail ("Invalid colorScheme: " ++ colorSchemeStr)
            )


{-| Encodes an ErrorType as a JSON string
-}
encodeErrorType : ErrorType -> Encode.Value
encodeErrorType errorType =
    case errorType of
        InvalidMove ->
            Encode.string "InvalidMove"

        GameLogicError ->
            Encode.string "GameLogicError"

        WorkerCommunicationError ->
            Encode.string "WorkerCommunicationError"

        JsonError ->
            Encode.string "JsonError"

        TimeoutError ->
            Encode.string "TimeoutError"

        UnknownError ->
            Encode.string "UnknownError"


{-| Decodes an ErrorType from a JSON string
-}
decodeErrorType : Decode.Decoder ErrorType
decodeErrorType =
    Decode.string
        |> Decode.andThen
            (\errorTypeStr ->
                case errorTypeStr of
                    "InvalidMove" ->
                        Decode.succeed InvalidMove

                    "GameLogicError" ->
                        Decode.succeed GameLogicError

                    "WorkerCommunicationError" ->
                        Decode.succeed WorkerCommunicationError

                    "JsonError" ->
                        Decode.succeed JsonError

                    "TimeoutError" ->
                        Decode.succeed TimeoutError

                    "UnknownError" ->
                        Decode.succeed UnknownError

                    _ ->
                        Decode.succeed UnknownError
            )


{-| Helper functions for creating different types of errors
-}
createInvalidMoveError : String -> ErrorInfo
createInvalidMoveError message =
    { message = message
    , errorType = InvalidMove
    , recoverable = True
    }


createGameLogicError : String -> ErrorInfo
createGameLogicError message =
    { message = message
    , errorType = GameLogicError
    , recoverable = True
    }


createWorkerCommunicationError : String -> ErrorInfo
createWorkerCommunicationError message =
    { message = message
    , errorType = WorkerCommunicationError
    , recoverable = True
    }


createJsonError : String -> ErrorInfo
createJsonError message =
    { message = message
    , errorType = JsonError
    , recoverable = True
    }


createTimeoutError : String -> ErrorInfo
createTimeoutError message =
    { message = message
    , errorType = TimeoutError
    , recoverable = True
    }


createUnknownError : String -> ErrorInfo
createUnknownError message =
    { message = message
    , errorType = UnknownError
    , recoverable = True
    }


{-| Check if the current game state can be recovered from
-}
isRecoverableError : GameState -> Bool
isRecoverableError gameState =
    case gameState of
        Error errorInfo ->
            errorInfo.recoverable

        _ ->
            False


{-| Attempt to recover from an error state by resetting to a safe state
-}
recoverFromError : Model -> Model
recoverFromError model =
    case model.gameState of
        Error errorInfo ->
            if errorInfo.recoverable then
                case errorInfo.errorType of
                    InvalidMove ->
                        -- For invalid moves, just revert to waiting state
                        { model | gameState = Waiting X }

                    GameLogicError ->
                        -- For game logic errors, reset the game
                        { initialModel | colorScheme = model.colorScheme }

                    WorkerCommunicationError ->
                        -- For worker errors, reset the game
                        { initialModel | colorScheme = model.colorScheme }

                    JsonError ->
                        -- For JSON errors, reset the game
                        { initialModel | colorScheme = model.colorScheme }

                    TimeoutError ->
                        -- For timeout errors, reset the game
                        { initialModel | colorScheme = model.colorScheme }

                    UnknownError ->
                        -- For unknown errors, reset the game
                        { initialModel | colorScheme = model.colorScheme }

            else
                model

        _ ->
            model



-- JSON encoding and decoding for Msg


{-| Encodes a message as a JSON object
-}
encodeMsg : Msg -> Encode.Value
encodeMsg msg =
    case msg of
        MoveMade position ->
            Encode.object
                [ ( "type", Encode.string "MoveMade" )
                , ( "position", encodePosition position )
                ]

        ResetGame ->
            Encode.object
                [ ( "type", Encode.string "ResetGame" ) ]

        GameError errorInfo ->
            Encode.object
                [ ( "type", Encode.string "GameError" )
                , ( "errorInfo"
                  , Encode.object
                        [ ( "message", Encode.string errorInfo.message )
                        , ( "errorType", encodeErrorType errorInfo.errorType )
                        , ( "recoverable", Encode.bool errorInfo.recoverable )
                        ]
                  )
                ]

        ColorScheme colorScheme ->
            Encode.object
                [ ( "type", Encode.string "ColorScheme" )
                , ( "colorScheme", encodeColorScheme colorScheme )
                ]

        GetViewPort viewport ->
            Encode.object
                [ ( "type", Encode.string "GetViewPort" )
                , ( "viewport", encodeViewport viewport )
                ]

        GetResize width height ->
            Encode.object
                [ ( "type", Encode.string "GetResize" )
                , ( "width", Encode.int width )
                , ( "height", Encode.int height )
                ]

        Tick time ->
            Encode.object
                [ ( "type", Encode.string "Tick" )
                , ( "time", Encode.int (Time.posixToMillis time) )
                ]


{-| Decodes a message from a JSON object
-}
decodeMsg : Decode.Decoder Msg
decodeMsg =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\msgType ->
                case msgType of
                    "MoveMade" ->
                        Decode.succeed MoveMade
                            |> DecodePipeline.required "position" decodePosition

                    "ResetGame" ->
                        Decode.succeed ResetGame

                    "GameError" ->
                        Decode.succeed GameError
                            |> DecodePipeline.required "errorInfo"
                                (Decode.succeed ErrorInfo
                                    |> DecodePipeline.required "message" Decode.string
                                    |> DecodePipeline.required "errorType" decodeErrorType
                                    |> DecodePipeline.required "recoverable" Decode.bool
                                )

                    "ColorScheme" ->
                        Decode.succeed ColorScheme
                            |> DecodePipeline.required "colorScheme" decodeColorScheme

                    "GetViewPort" ->
                        Decode.succeed GetViewPort
                            |> DecodePipeline.required "viewport" decodeViewport

                    "GetResize" ->
                        Decode.succeed GetResize
                            |> DecodePipeline.required "width" Decode.int
                            |> DecodePipeline.required "height" Decode.int

                    "Tick" ->
                        Decode.succeed Tick
                            |> DecodePipeline.required "time" (Decode.map Time.millisToPosix Decode.int)

                    _ ->
                        Decode.fail ("Invalid message type: " ++ msgType)
            )

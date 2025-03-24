module Model exposing (Board, ColorScheme(..), Flags, Line, Model, Msg(..), Player(..), Position, boardToString, decodeColorScheme, decodeModel, decodeMsg, encodeModel, encodeMsg, idleTimeoutMillis, initialModel, lineToString, playerToString, timeSpent)

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


type alias Model =
    { board : Board
    , currentPlayer : Player
    , winner : Maybe Player
    , isThinking : Bool
    , colorScheme : ColorScheme
    , lastMove : Maybe Time.Posix
    , now : Maybe Time.Posix
    , maybeWindow : Maybe ( Int, Int )
    , errorMessage : Maybe String
    }


type alias Flags =
    { colorScheme : String }


type Player
    = X
    | O


type ColorScheme
    = Light
    | Dark


idleTimeoutMillis : Int
idleTimeoutMillis =
    5000


timeSpent : Model -> Float
timeSpent model =
    Maybe.map2 (\lastMove now -> (Time.posixToMillis now - Time.posixToMillis lastMove) |> Basics.toFloat) model.lastMove model.now
        |> Maybe.withDefault (toFloat idleTimeoutMillis)



-- Initial Game State


{-| Returns the initial game model with an empty board and X as the current player
-}
initialModel : Model
initialModel =
    { board =
        [ [ Nothing, Nothing, Nothing ]
        , [ Nothing, Nothing, Nothing ]
        , [ Nothing, Nothing, Nothing ]
        ]
    , currentPlayer = X
    , winner = Nothing
    , isThinking = False
    , errorMessage = Nothing
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
    | GameError String
    | ColorScheme ColorScheme
    | GetViewPort Browser.Dom.Viewport
    | GetResize Int Int
    | Tick Time.Posix



-- JSON encoding and decoding


{-| Encodes a player as a JSON string
-}
encodePlayer : Maybe Player -> Encode.Value
encodePlayer player =
    case player of
        Just X ->
            Encode.string "X"

        Just O ->
            Encode.string "O"

        Nothing ->
            Encode.null


{-| Decodes a player from a JSON string
-}
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


{-| Encodes the game board as a JSON list of lists
-}
encodeBoard : Board -> Encode.Value
encodeBoard board =
    Encode.list (Encode.list encodePlayer) board


{-| Decodes the game board from a JSON list of lists
-}
decodeBoard : Decode.Decoder Board
decodeBoard =
    Decode.list (Decode.list (Decode.nullable decodePlayer))


{-| Encodes the game model as a JSON object
-}
encodeModel : Model -> Encode.Value
encodeModel model =
    Encode.object
        [ ( "board", encodeBoard model.board )
        , ( "currentPlayer", encodePlayer (Just model.currentPlayer) )
        , ( "winner", EncodeExtra.maybe (encodePlayer << Just) model.winner )
        , ( "isThinking", Encode.bool model.isThinking )
        , ( "colorScheme", encodeColorScheme model.colorScheme )
        , ( "lastMove", EncodeExtra.maybe (Encode.int << Time.posixToMillis) model.lastMove )
        , ( "now", EncodeExtra.maybe (Encode.int << Time.posixToMillis) model.now )
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
        , ( "errorMessage", EncodeExtra.maybe Encode.string model.errorMessage )
        ]


{-| Decodes the game model from a JSON object
-}
decodeModel : Decode.Decoder Model
decodeModel =
    Decode.succeed Model
        |> DecodePipeline.required "board" decodeBoard
        |> DecodePipeline.required "currentPlayer" decodePlayer
        |> DecodePipeline.optional "winner" (Decode.nullable decodePlayer) Nothing
        |> DecodePipeline.required "isThinking" Decode.bool
        |> DecodePipeline.required "colorScheme" decodeColorScheme
        |> DecodePipeline.optional "lastMove" (Decode.nullable (Decode.map Time.millisToPosix Decode.int)) Nothing
        |> DecodePipeline.optional "now" (Decode.nullable (Decode.map Time.millisToPosix Decode.int)) Nothing
        |> DecodePipeline.optional "maybeWindow" (Decode.nullable (Decode.map2 Tuple.pair (Decode.field "width" Decode.int) (Decode.field "height" Decode.int))) Nothing
        |> DecodePipeline.optional "errorMessage" (Decode.nullable Decode.string) Nothing


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

        GameError errorMessage ->
            Encode.object
                [ ( "type", Encode.string "GameError" )
                , ( "errorMessage", Encode.string errorMessage )
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
                            |> DecodePipeline.required "errorMessage" Decode.string

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

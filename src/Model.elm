module Model exposing (Board, Flags, Line, Mode(..), Model, Msg(..), Player(..), Position, boardToString, decodeMode, decodeModel, decodeMsg, encodeModel, encodeMsg, initialModel, lineToString, playerToString)

import Json.Decode as Decode
import Json.Encode as Encode
import Json.Encode.Extra as EncodeExtra



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
    , errorMessage : Maybe String
    , mode : Mode
    }


type alias Flags =
    { mode : String }


type Player
    = X
    | O


type Mode
    = Light
    | Dark



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
    , mode = Light
    }



-- Msg


{-| Represents a message that can be sent to the game, either a move, reset, or error
-}
type Msg
    = MoveMade Position
    | ResetGame
    | GameError String
    | Mode Mode



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
        , ( "winner"
          , case model.winner of
                Nothing ->
                    Encode.null

                Just player ->
                    encodePlayer (Just player)
          )
        , ( "isThinking", Encode.bool model.isThinking )
        , ( "errorMessage", EncodeExtra.maybe Encode.string model.errorMessage )
        , ( "mode", encodeMode model.mode )
        ]


{-| Decodes the game model from a JSON object
-}
decodeModel : Decode.Decoder Model
decodeModel =
    Decode.map6 Model
        (Decode.field "board" decodeBoard)
        (Decode.field "currentPlayer" decodePlayer)
        (Decode.field "winner" (Decode.nullable decodePlayer))
        (Decode.field "isThinking" Decode.bool)
        (Decode.field "errorMessage" (Decode.nullable Decode.string))
        (Decode.field "mode" decodeMode)


{-| Encodes a message as a JSON object
-}
encodeMsg : Msg -> Encode.Value
encodeMsg msg =
    case msg of
        MoveMade { row, col } ->
            Encode.object
                [ ( "type", Encode.string "MoveMade" )
                , ( "row", Encode.int row )
                , ( "col", Encode.int col )
                ]

        ResetGame ->
            Encode.object
                [ ( "type", Encode.string "ResetGame" ) ]

        GameError message ->
            Encode.object
                [ ( "type", Encode.string "Error" )
                , ( "message", Encode.string message )
                ]

        Mode mode ->
            Encode.object
                [ ( "type", Encode.string "Mode" )
                , ( "mode", encodeMode mode )
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
                        Decode.map2 (\row col -> MoveMade { row = row, col = col })
                            (Decode.field "row" Decode.int)
                            (Decode.field "col" Decode.int)

                    "ResetGame" ->
                        Decode.succeed ResetGame

                    "Error" ->
                        Decode.map GameError (Decode.field "message" Decode.string)

                    "ModeChanged" ->
                        Decode.map Mode (Decode.field "mode" decodeMode)

                    _ ->
                        Decode.fail "branch '_' not implemented"
            )


{-| Encodes the game mode as a JSON string
-}
encodeMode : Mode -> Encode.Value
encodeMode mode =
    case mode of
        Light ->
            Encode.string "Light"

        Dark ->
            Encode.string "Dark"


{-| Decodes the game mode from a JSON string
-}
decodeMode : Decode.Decoder Mode
decodeMode =
    Decode.string
        |> Decode.andThen
            (\modeStr ->
                case modeStr of
                    "Light" ->
                        Decode.succeed Light

                    "Dark" ->
                        Decode.succeed Dark

                    _ ->
                        Decode.fail ("Invalid mode: " ++ modeStr)
            )

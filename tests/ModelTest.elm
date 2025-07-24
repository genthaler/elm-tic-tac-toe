module ModelTest exposing (all)

import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Model exposing (..)
import Test exposing (Test, describe, test)
import Time


all : Test
all =
    describe "Model JSON Encoding/Decoding"
        [ describe "Player encoding/decoding"
            [ test "encodes and decodes Player X" <|
                \_ ->
                    let
                        encoded =
                            Encode.string "X"

                        decoded =
                            Decode.decodeValue
                                (Decode.string
                                    |> Decode.andThen
                                        (\s ->
                                            if s == "X" then
                                                Decode.succeed X

                                            else
                                                Decode.fail "Invalid"
                                        )
                                )
                                encoded
                    in
                    decoded
                        |> Expect.equal (Ok X)
            , test "encodes and decodes Player O" <|
                \_ ->
                    let
                        encoded =
                            Encode.string "O"

                        decoded =
                            Decode.decodeValue
                                (Decode.string
                                    |> Decode.andThen
                                        (\s ->
                                            if s == "O" then
                                                Decode.succeed O

                                            else
                                                Decode.fail "Invalid"
                                        )
                                )
                                encoded
                    in
                    decoded
                        |> Expect.equal (Ok O)
            ]
        , describe "Position encoding/decoding"
            [ test "encodes and decodes Position correctly" <|
                \_ ->
                    let
                        position =
                            { row = 1, col = 2 }

                        encoded =
                            Encode.object [ ( "row", Encode.int 1 ), ( "col", Encode.int 2 ) ]

                        decoded =
                            Decode.decodeValue (Decode.map2 Position (Decode.field "row" Decode.int) (Decode.field "col" Decode.int)) encoded
                    in
                    decoded
                        |> Expect.equal (Ok position)
            , test "fails to decode invalid Position" <|
                \_ ->
                    let
                        encoded =
                            Encode.object [ ( "row", Encode.string "invalid" ) ]

                        decoded =
                            Decode.decodeValue (Decode.map2 Position (Decode.field "row" Decode.int) (Decode.field "col" Decode.int)) encoded
                    in
                    case decoded of
                        Err _ ->
                            Expect.pass

                        Ok _ ->
                            Expect.fail "Should have failed to decode invalid position"
            ]
        , describe "ColorScheme encoding/decoding"
            [ test "encodes and decodes Light theme" <|
                \_ ->
                    let
                        colorScheme =
                            Light

                        encoded =
                            encodeColorScheme colorScheme

                        decoded =
                            Decode.decodeValue decodeColorScheme encoded
                    in
                    decoded
                        |> Expect.equal (Ok Light)
            , test "encodes and decodes Dark theme" <|
                \_ ->
                    let
                        colorScheme =
                            Dark

                        encoded =
                            encodeColorScheme colorScheme

                        decoded =
                            Decode.decodeValue decodeColorScheme encoded
                    in
                    decoded
                        |> Expect.equal (Ok Dark)
            , test "fails to decode invalid ColorScheme" <|
                \_ ->
                    let
                        encoded =
                            Encode.string "Invalid"

                        decoded =
                            Decode.decodeValue decodeColorScheme encoded
                    in
                    case decoded of
                        Err _ ->
                            Expect.pass

                        Ok _ ->
                            Expect.fail "Should have failed to decode invalid color scheme"
            ]
        , describe "GameState encoding/decoding"
            [ test "encodes and decodes Waiting state" <|
                \_ ->
                    let
                        encoded =
                            Encode.object [ ( "type", Encode.string "Waiting" ), ( "player", Encode.string "X" ) ]

                        decoded =
                            Decode.decodeValue
                                (Decode.field "type" Decode.string
                                    |> Decode.andThen
                                        (\t ->
                                            if t == "Waiting" then
                                                Decode.map Waiting
                                                    (Decode.field "player"
                                                        (Decode.string
                                                            |> Decode.andThen
                                                                (\s ->
                                                                    if s == "X" then
                                                                        Decode.succeed X

                                                                    else if s == "O" then
                                                                        Decode.succeed O

                                                                    else
                                                                        Decode.fail "Invalid"
                                                                )
                                                        )
                                                    )

                                            else
                                                Decode.fail "Invalid type"
                                        )
                                )
                                encoded
                    in
                    decoded
                        |> Expect.equal (Ok (Waiting X))
            , test "encodes and decodes Thinking state" <|
                \_ ->
                    let
                        encoded =
                            Encode.object [ ( "type", Encode.string "Thinking" ), ( "player", Encode.string "O" ) ]

                        decoded =
                            Decode.decodeValue
                                (Decode.field "type" Decode.string
                                    |> Decode.andThen
                                        (\t ->
                                            if t == "Thinking" then
                                                Decode.map Thinking
                                                    (Decode.field "player"
                                                        (Decode.string
                                                            |> Decode.andThen
                                                                (\s ->
                                                                    if s == "X" then
                                                                        Decode.succeed X

                                                                    else if s == "O" then
                                                                        Decode.succeed O

                                                                    else
                                                                        Decode.fail "Invalid"
                                                                )
                                                        )
                                                    )

                                            else
                                                Decode.fail "Invalid type"
                                        )
                                )
                                encoded
                    in
                    decoded
                        |> Expect.equal (Ok (Thinking O))
            , test "encodes and decodes Winner state" <|
                \_ ->
                    let
                        encoded =
                            Encode.object [ ( "type", Encode.string "Winner" ), ( "player", Encode.string "X" ) ]

                        decoded =
                            Decode.decodeValue
                                (Decode.field "type" Decode.string
                                    |> Decode.andThen
                                        (\t ->
                                            if t == "Winner" then
                                                Decode.map Winner
                                                    (Decode.field "player"
                                                        (Decode.string
                                                            |> Decode.andThen
                                                                (\s ->
                                                                    if s == "X" then
                                                                        Decode.succeed X

                                                                    else if s == "O" then
                                                                        Decode.succeed O

                                                                    else
                                                                        Decode.fail "Invalid"
                                                                )
                                                        )
                                                    )

                                            else
                                                Decode.fail "Invalid type"
                                        )
                                )
                                encoded
                    in
                    decoded
                        |> Expect.equal (Ok (Winner X))
            , test "encodes and decodes Draw state" <|
                \_ ->
                    let
                        encoded =
                            Encode.object [ ( "type", Encode.string "Draw" ) ]

                        decoded =
                            Decode.decodeValue
                                (Decode.field "type" Decode.string
                                    |> Decode.andThen
                                        (\t ->
                                            if t == "Draw" then
                                                Decode.succeed Draw

                                            else
                                                Decode.fail "Invalid type"
                                        )
                                )
                                encoded
                    in
                    decoded
                        |> Expect.equal (Ok Draw)
            , test "encodes and decodes Error state" <|
                \_ ->
                    let
                        encoded =
                            Encode.object [ ( "type", Encode.string "Error" ), ( "message", Encode.string "Test error" ) ]

                        decoded =
                            Decode.decodeValue
                                (Decode.field "type" Decode.string
                                    |> Decode.andThen
                                        (\t ->
                                            if t == "Error" then
                                                Decode.map Error (Decode.field "message" Decode.string)

                                            else
                                                Decode.fail "Invalid type"
                                        )
                                )
                                encoded
                    in
                    decoded
                        |> Expect.equal (Ok (Error "Test error"))
            ]
        , describe "Board encoding/decoding"
            [ test "encodes and decodes empty board" <|
                \_ ->
                    let
                        board =
                            [ [ Nothing, Nothing, Nothing ]
                            , [ Nothing, Nothing, Nothing ]
                            , [ Nothing, Nothing, Nothing ]
                            ]

                        encoded =
                            Encode.list
                                (Encode.list
                                    (\cell ->
                                        case cell of
                                            Just X ->
                                                Encode.string "X"

                                            Just O ->
                                                Encode.string "O"

                                            Nothing ->
                                                Encode.null
                                    )
                                )
                                board

                        decoded =
                            Decode.decodeValue
                                (Decode.list
                                    (Decode.list
                                        (Decode.nullable
                                            (Decode.string
                                                |> Decode.andThen
                                                    (\s ->
                                                        if s == "X" then
                                                            Decode.succeed X

                                                        else if s == "O" then
                                                            Decode.succeed O

                                                        else
                                                            Decode.fail "Invalid"
                                                    )
                                            )
                                        )
                                    )
                                )
                                encoded
                    in
                    decoded
                        |> Expect.equal (Ok board)
            , test "encodes and decodes board with moves" <|
                \_ ->
                    let
                        board =
                            [ [ Just X, Nothing, Just O ]
                            , [ Nothing, Just X, Nothing ]
                            , [ Just O, Nothing, Nothing ]
                            ]

                        encoded =
                            Encode.list
                                (Encode.list
                                    (\cell ->
                                        case cell of
                                            Just X ->
                                                Encode.string "X"

                                            Just O ->
                                                Encode.string "O"

                                            Nothing ->
                                                Encode.null
                                    )
                                )
                                board

                        decoded =
                            Decode.decodeValue
                                (Decode.list
                                    (Decode.list
                                        (Decode.nullable
                                            (Decode.string
                                                |> Decode.andThen
                                                    (\s ->
                                                        if s == "X" then
                                                            Decode.succeed X

                                                        else if s == "O" then
                                                            Decode.succeed O

                                                        else
                                                            Decode.fail "Invalid"
                                                    )
                                            )
                                        )
                                    )
                                )
                                encoded
                    in
                    decoded
                        |> Expect.equal (Ok board)
            ]
        , describe "Model encoding/decoding"
            [ test "encodes and decodes complete Model" <|
                \_ ->
                    let
                        model =
                            { initialModel
                                | board =
                                    [ [ Just X, Nothing, Nothing ]
                                    , [ Nothing, Just O, Nothing ]
                                    , [ Nothing, Nothing, Nothing ]
                                    ]
                                , gameState = Waiting O
                                , colorScheme = Dark
                                , maybeWindow = Just ( 800, 600 )
                            }

                        encoded =
                            encodeModel model

                        decoded =
                            Decode.decodeValue decodeModel encoded
                    in
                    case decoded of
                        Ok decodedModel ->
                            Expect.all
                                [ \_ -> decodedModel.board |> Expect.equal model.board
                                , \_ -> decodedModel.gameState |> Expect.equal model.gameState
                                , \_ -> decodedModel.colorScheme |> Expect.equal model.colorScheme
                                , \_ -> decodedModel.maybeWindow |> Expect.equal model.maybeWindow
                                ]
                                ()

                        Err error ->
                            Expect.fail ("Failed to decode model: " ++ Decode.errorToString error)
            , test "encodes and decodes Model with time values" <|
                \_ ->
                    let
                        time1 =
                            Time.millisToPosix 1000

                        time2 =
                            Time.millisToPosix 2000

                        model =
                            { initialModel
                                | lastMove = Just time1
                                , now = Just time2
                            }

                        encoded =
                            encodeModel model

                        decoded =
                            Decode.decodeValue decodeModel encoded
                    in
                    case decoded of
                        Ok decodedModel ->
                            Expect.all
                                [ \_ -> decodedModel.lastMove |> Expect.equal model.lastMove
                                , \_ -> decodedModel.now |> Expect.equal model.now
                                ]
                                ()

                        Err error ->
                            Expect.fail ("Failed to decode model with time: " ++ Decode.errorToString error)
            ]
        , describe "Msg encoding/decoding"
            [ test "encodes and decodes MoveMade message" <|
                \_ ->
                    let
                        msg =
                            MoveMade { row = 1, col = 2 }

                        encoded =
                            encodeMsg msg

                        decoded =
                            Decode.decodeValue decodeMsg encoded
                    in
                    decoded
                        |> Expect.equal (Ok msg)
            , test "encodes and decodes ResetGame message" <|
                \_ ->
                    let
                        msg =
                            ResetGame

                        encoded =
                            encodeMsg msg

                        decoded =
                            Decode.decodeValue decodeMsg encoded
                    in
                    decoded
                        |> Expect.equal (Ok msg)
            , test "encodes and decodes GameError message" <|
                \_ ->
                    let
                        msg =
                            GameError "Test error message"

                        encoded =
                            encodeMsg msg

                        decoded =
                            Decode.decodeValue decodeMsg encoded
                    in
                    decoded
                        |> Expect.equal (Ok msg)
            , test "encodes and decodes ColorScheme message" <|
                \_ ->
                    let
                        msg =
                            ColorScheme Dark

                        encoded =
                            encodeMsg msg

                        decoded =
                            Decode.decodeValue decodeMsg encoded
                    in
                    decoded
                        |> Expect.equal (Ok msg)
            , test "encodes and decodes GetResize message" <|
                \_ ->
                    let
                        msg =
                            GetResize 1024 768

                        encoded =
                            encodeMsg msg

                        decoded =
                            Decode.decodeValue decodeMsg encoded
                    in
                    decoded
                        |> Expect.equal (Ok msg)
            , test "encodes and decodes Tick message" <|
                \_ ->
                    let
                        time =
                            Time.millisToPosix 5000

                        msg =
                            Tick time

                        encoded =
                            encodeMsg msg

                        decoded =
                            Decode.decodeValue decodeMsg encoded
                    in
                    decoded
                        |> Expect.equal (Ok msg)
            ]
        , describe "Round-trip encoding/decoding"
            [ test "Model round-trip preserves data integrity" <|
                \_ ->
                    let
                        originalModel =
                            { initialModel
                                | board =
                                    [ [ Just X, Just O, Nothing ]
                                    , [ Nothing, Just X, Just O ]
                                    , [ Just O, Nothing, Just X ]
                                    ]
                                , gameState = Winner X
                                , colorScheme = Dark
                                , lastMove = Just (Time.millisToPosix 1500)
                                , now = Just (Time.millisToPosix 3000)
                                , maybeWindow = Just ( 1920, 1080 )
                            }

                        roundTrip =
                            originalModel |> encodeModel |> Decode.decodeValue decodeModel
                    in
                    case roundTrip of
                        Ok decodedModel ->
                            Expect.all
                                [ \_ -> decodedModel.board |> Expect.equal originalModel.board
                                , \_ -> decodedModel.gameState |> Expect.equal originalModel.gameState
                                , \_ -> decodedModel.colorScheme |> Expect.equal originalModel.colorScheme
                                , \_ -> decodedModel.lastMove |> Expect.equal originalModel.lastMove
                                , \_ -> decodedModel.now |> Expect.equal originalModel.now
                                , \_ -> decodedModel.maybeWindow |> Expect.equal originalModel.maybeWindow
                                ]
                                ()

                        Err error ->
                            Expect.fail ("Round-trip failed: " ++ Decode.errorToString error)
            , test "MoveMade message round-trip" <|
                \_ ->
                    let
                        msg =
                            MoveMade { row = 0, col = 1 }
                    in
                    case msg |> encodeMsg |> Decode.decodeValue decodeMsg of
                        Ok decodedMsg ->
                            decodedMsg |> Expect.equal msg

                        Err error ->
                            Expect.fail ("Failed to round-trip message: " ++ Decode.errorToString error)
            , test "ResetGame message round-trip" <|
                \_ ->
                    let
                        msg =
                            ResetGame
                    in
                    case msg |> encodeMsg |> Decode.decodeValue decodeMsg of
                        Ok decodedMsg ->
                            decodedMsg |> Expect.equal msg

                        Err error ->
                            Expect.fail ("Failed to round-trip message: " ++ Decode.errorToString error)
            , test "GameError message round-trip" <|
                \_ ->
                    let
                        msg =
                            GameError "Error message"
                    in
                    case msg |> encodeMsg |> Decode.decodeValue decodeMsg of
                        Ok decodedMsg ->
                            decodedMsg |> Expect.equal msg

                        Err error ->
                            Expect.fail ("Failed to round-trip message: " ++ Decode.errorToString error)
            , test "ColorScheme message round-trip" <|
                \_ ->
                    let
                        msg =
                            ColorScheme Light
                    in
                    case msg |> encodeMsg |> Decode.decodeValue decodeMsg of
                        Ok decodedMsg ->
                            decodedMsg |> Expect.equal msg

                        Err error ->
                            Expect.fail ("Failed to round-trip message: " ++ Decode.errorToString error)
            , test "GetResize message round-trip" <|
                \_ ->
                    let
                        msg =
                            GetResize 800 600
                    in
                    case msg |> encodeMsg |> Decode.decodeValue decodeMsg of
                        Ok decodedMsg ->
                            decodedMsg |> Expect.equal msg

                        Err error ->
                            Expect.fail ("Failed to round-trip message: " ++ Decode.errorToString error)
            , test "Tick message round-trip" <|
                \_ ->
                    let
                        msg =
                            Tick (Time.millisToPosix 12345)
                    in
                    case msg |> encodeMsg |> Decode.decodeValue decodeMsg of
                        Ok decodedMsg ->
                            decodedMsg |> Expect.equal msg

                        Err error ->
                            Expect.fail ("Failed to round-trip message: " ++ Decode.errorToString error)
            ]
        ]

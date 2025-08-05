module Theme.ThemeTest exposing (suite)

import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)
import Theme.Theme exposing (..)


suite : Test
suite =
    describe "Theme"
        [ describe "ColorScheme JSON encoding/decoding"
            [ test "encodes Light correctly" <|
                \_ ->
                    encodeColorScheme Light
                        |> Encode.encode 0
                        |> Expect.equal "\"Light\""
            , test "encodes Dark correctly" <|
                \_ ->
                    encodeColorScheme Dark
                        |> Encode.encode 0
                        |> Expect.equal "\"Dark\""
            , test "decodes Light correctly" <|
                \_ ->
                    Decode.decodeString decodeColorScheme "\"Light\""
                        |> Expect.equal (Ok Light)
            , test "decodes Dark correctly" <|
                \_ ->
                    Decode.decodeString decodeColorScheme "\"Dark\""
                        |> Expect.equal (Ok Dark)
            , test "decodes invalid value to Light (fallback)" <|
                \_ ->
                    Decode.decodeString decodeColorScheme "\"Invalid\""
                        |> Expect.equal (Ok Light)
            , test "decodes empty string to Light (fallback)" <|
                \_ ->
                    Decode.decodeString decodeColorScheme "\"\""
                        |> Expect.equal (Ok Light)
            , test "decodes null to Light (fallback)" <|
                \_ ->
                    Decode.decodeString decodeColorScheme "null"
                        |> Result.toMaybe
                        |> Expect.equal Nothing
            , test "round-trip encoding/decoding preserves Light" <|
                \_ ->
                    Light
                        |> encodeColorScheme
                        |> Decode.decodeValue decodeColorScheme
                        |> Expect.equal (Ok Light)
            , test "round-trip encoding/decoding preserves Dark" <|
                \_ ->
                    Dark
                        |> encodeColorScheme
                        |> Decode.decodeValue decodeColorScheme
                        |> Expect.equal (Ok Dark)
            ]
        , describe "Theme selection and configuration"
            [ describe "Base theme configuration"
                [ test "provides Light base theme with correct structure" <|
                    \_ ->
                        let
                            theme =
                                getBaseTheme Light
                        in
                        Expect.all
                            [ \t -> t.backgroundColor |> always Expect.pass
                            , \t -> t.fontColor |> always Expect.pass
                            , \t -> t.secondaryFontColor |> always Expect.pass
                            , \t -> t.borderColor |> always Expect.pass
                            , \t -> t.accentColor |> always Expect.pass
                            , \t -> t.buttonColor |> always Expect.pass
                            , \t -> t.buttonHoverColor |> always Expect.pass
                            ]
                            theme
                , test "provides Dark base theme with correct structure" <|
                    \_ ->
                        let
                            theme =
                                getBaseTheme Dark
                        in
                        Expect.all
                            [ \t -> t.backgroundColor |> always Expect.pass
                            , \t -> t.fontColor |> always Expect.pass
                            , \t -> t.secondaryFontColor |> always Expect.pass
                            , \t -> t.borderColor |> always Expect.pass
                            , \t -> t.accentColor |> always Expect.pass
                            , \t -> t.buttonColor |> always Expect.pass
                            , \t -> t.buttonHoverColor |> always Expect.pass
                            ]
                            theme
                , test "Light and Dark themes have different background colors" <|
                    \_ ->
                        let
                            lightTheme =
                                getBaseTheme Light

                            darkTheme =
                                getBaseTheme Dark
                        in
                        lightTheme.backgroundColor
                            |> Expect.notEqual darkTheme.backgroundColor
                , test "Light and Dark themes have different font colors" <|
                    \_ ->
                        let
                            lightTheme =
                                getBaseTheme Light

                            darkTheme =
                                getBaseTheme Dark
                        in
                        lightTheme.fontColor
                            |> Expect.notEqual darkTheme.fontColor
                ]
            ]
        ]

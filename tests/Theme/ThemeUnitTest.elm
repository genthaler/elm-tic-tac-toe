module Theme.ThemeUnitTest exposing (suite)

import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)
import Theme.Theme as Theme
import TicTacToe.Model as TicTacToeModel


suite : Test
suite =
    describe "Theme System"
        [ colorSchemeTests
        , baseThemeTests
        , backwardCompatibilityTests
        ]


colorSchemeTests : Test
colorSchemeTests =
    describe "ColorScheme JSON encoding/decoding"
        [ test "encodes and decodes Light" <|
            \_ ->
                Theme.encodeColorScheme Theme.Light
                    |> Decode.decodeValue Theme.decodeColorScheme
                    |> Expect.equal (Ok Theme.Light)
        , test "encodes and decodes Dark" <|
            \_ ->
                Theme.encodeColorScheme Theme.Dark
                    |> Decode.decodeValue Theme.decodeColorScheme
                    |> Expect.equal (Ok Theme.Dark)
        , test "falls back to Light for invalid values" <|
            \_ ->
                Encode.string "Invalid"
                    |> Decode.decodeValue Theme.decodeColorScheme
                    |> Expect.equal (Ok Theme.Light)
        ]


baseThemeTests : Test
baseThemeTests =
    describe "Base theme configuration"
        [ test "safeGetBaseTheme matches getBaseTheme for Light" <|
            \_ ->
                Expect.equal
                    (Theme.getBaseTheme Theme.Light)
                    (Theme.safeGetBaseTheme Theme.Light)
        , test "safeGetBaseTheme matches getBaseTheme for Dark" <|
            \_ ->
                Expect.equal
                    (Theme.getBaseTheme Theme.Dark)
                    (Theme.safeGetBaseTheme Theme.Dark)
        , test "Light and Dark themes differ on core colors" <|
            \_ ->
                let
                    lightTheme =
                        Theme.getBaseTheme Theme.Light

                    darkTheme =
                        Theme.getBaseTheme Theme.Dark
                in
                Expect.notEqual lightTheme.backgroundColorHex darkTheme.backgroundColorHex
        ]


backwardCompatibilityTests : Test
backwardCompatibilityTests =
    describe "Backward compatibility"
        [ test "legacy TicTacToe model JSON without colorScheme defaults to Light" <|
            \_ ->
                legacyModelWithoutThemeJson
                    |> Decode.decodeValue TicTacToeModel.decodeModel
                    |> Result.map .colorScheme
                    |> Expect.equal (Ok Theme.Light)
        , test "legacy TicTacToe model JSON preserves encoded Dark theme" <|
            \_ ->
                legacyModelWithThemeJson
                    |> Decode.decodeValue TicTacToeModel.decodeModel
                    |> Result.map .colorScheme
                    |> Expect.equal (Ok Theme.Dark)
        ]


legacyBoard : Encode.Value
legacyBoard =
    Encode.list
        (Encode.list
            (\cell ->
                case cell of
                    Just TicTacToeModel.X ->
                        Encode.string "X"

                    Just TicTacToeModel.O ->
                        Encode.string "O"

                    Nothing ->
                        Encode.null
            )
        )
        [ [ Nothing, Nothing, Nothing ]
        , [ Nothing, Nothing, Nothing ]
        , [ Nothing, Nothing, Nothing ]
        ]


legacyBaseFields : List ( String, Encode.Value ) -> Encode.Value
legacyBaseFields extraFields =
    Encode.object
        ([ ( "board", legacyBoard )
         , ( "gameState"
           , Encode.object
                [ ( "type", Encode.string "Waiting" )
                , ( "player", Encode.string "X" )
                ]
           )
         , ( "lastMove", Encode.null )
         , ( "now", Encode.null )
         , ( "maybeWindow", Encode.null )
         ]
            ++ extraFields
        )


legacyModelWithoutThemeJson : Encode.Value
legacyModelWithoutThemeJson =
    legacyBaseFields []


legacyModelWithThemeJson : Encode.Value
legacyModelWithThemeJson =
    legacyBaseFields [ ( "colorScheme", Encode.string "Dark" ) ]

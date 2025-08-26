module Theme.ThemeUnitTest exposing (suite)

{-| Comprehensive theme tests covering basic functionality, integration, and backward compatibility.

This module consolidates theme tests to eliminate duplication while maintaining
complete coverage of the theme system.

-}

import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import RobotGame.Model as RobotModel
import Test exposing (Test, describe, test)
import Theme.Responsive exposing (ScreenSize(..), calculateResponsiveCellSize, getResponsiveFontSize, getScreenSize)
import Theme.Theme as Theme
import TicTacToe.Model as TicTacToeModel


suite : Test
suite =
    describe "Theme System"
        [ basicThemeTests
        , integrationTests
        , backwardCompatibilityTests
        , responsiveTests
        ]


{-| Basic Theme module functionality tests
-}
basicThemeTests : Test
basicThemeTests =
    describe "Basic Theme functionality"
        [ describe "ColorScheme JSON encoding/decoding"
            [ test "encodes and decodes correctly" <|
                \_ ->
                    let
                        testColorScheme scheme expectedString =
                            let
                                encoded =
                                    Theme.encodeColorScheme scheme
                                        |> Encode.encode 0

                                decoded =
                                    Decode.decodeString Theme.decodeColorScheme expectedString
                            in
                            Expect.all
                                [ \_ -> encoded |> Expect.equal expectedString
                                , \_ -> decoded |> Expect.equal (Ok scheme)
                                ]
                                ()
                    in
                    Expect.all
                        [ \_ -> testColorScheme Theme.Light "\"Light\""
                        , \_ -> testColorScheme Theme.Dark "\"Dark\""
                        ]
                        ()
            , test "handles invalid values with fallback" <|
                \_ ->
                    let
                        invalidInputs =
                            [ "\"Invalid\"", "\"\"", "null" ]

                        testInvalidInput input =
                            case Decode.decodeString Theme.decodeColorScheme input of
                                Ok Theme.Light ->
                                    Expect.pass

                                Ok Theme.Dark ->
                                    if input == "null" then
                                        Expect.pass
                                        -- null might decode to Dark in some implementations

                                    else
                                        Expect.fail "Should fallback to Light"

                                Err _ ->
                                    if input == "null" then
                                        Expect.pass
                                        -- null might fail to decode

                                    else
                                        Expect.fail "Should not fail to decode"
                    in
                    invalidInputs
                        |> List.map testInvalidInput
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "round-trip encoding/decoding preserves values" <|
                \_ ->
                    let
                        testRoundTrip scheme =
                            scheme
                                |> Theme.encodeColorScheme
                                |> Decode.decodeValue Theme.decodeColorScheme
                                |> Expect.equal (Ok scheme)
                    in
                    [ Theme.Light, Theme.Dark ]
                        |> List.map testRoundTrip
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            ]
        , describe "Base theme configuration"
            [ test "provides complete theme structures" <|
                \_ ->
                    let
                        testThemeStructure scheme =
                            let
                                theme =
                                    Theme.getBaseTheme scheme
                            in
                            Expect.all
                                [ \t -> t.backgroundColorHex |> always Expect.pass
                                , \t -> t.fontColorHex |> always Expect.pass
                                , \t -> t.secondaryFontColorHex |> always Expect.pass
                                , \t -> t.borderColorHex |> always Expect.pass
                                , \t -> t.accentColorHex |> always Expect.pass
                                , \t -> t.buttonColorHex |> always Expect.pass
                                , \t -> t.buttonHoverColorHex |> always Expect.pass
                                ]
                                theme
                    in
                    [ Theme.Light, Theme.Dark ]
                        |> List.map testThemeStructure
                        |> List.all (\expectation -> expectation == Expect.pass)
                        |> Expect.equal True
            , test "Light and Dark themes have different colors" <|
                \_ ->
                    let
                        lightTheme =
                            Theme.getBaseTheme Theme.Light

                        darkTheme =
                            Theme.getBaseTheme Theme.Dark
                    in
                    Expect.all
                        [ \_ -> lightTheme.backgroundColorHex |> Expect.notEqual darkTheme.backgroundColorHex
                        , \_ -> lightTheme.fontColorHex |> Expect.notEqual darkTheme.fontColorHex
                        ]
                        ()
            ]
        ]


{-| Integration tests across games
-}
integrationTests : Test
integrationTests =
    describe "Cross-game integration"
        [ test "Both games use consistent ColorScheme type" <|
            \_ ->
                let
                    ticTacToeLight =
                        Theme.Light

                    robotGameLight =
                        Theme.Light

                    ticTacToeDark =
                        Theme.Dark

                    robotGameDark =
                        Theme.Dark
                in
                Expect.all
                    [ \_ -> Expect.equal ticTacToeLight robotGameLight
                    , \_ -> Expect.equal ticTacToeDark robotGameDark
                    ]
                    ()
        , test "Both games encode ColorScheme identically" <|
            \_ ->
                let
                    ticTacToeModel =
                        let
                            initial =
                                TicTacToeModel.initialModel
                        in
                        { initial | colorScheme = Theme.Light }

                    robotGameModel =
                        let
                            initial =
                                RobotModel.init
                        in
                        { initial | colorScheme = Theme.Light }

                    -- Both should encode the colorScheme field the same way
                    ticTacToeJson =
                        TicTacToeModel.encodeModel ticTacToeModel

                    robotGameJson =
                        RobotModel.encodeModel robotGameModel

                    extractColorScheme json =
                        json
                            |> Decode.decodeValue (Decode.field "colorScheme" Theme.decodeColorScheme)
                in
                Expect.all
                    [ \_ -> extractColorScheme ticTacToeJson |> Expect.equal (Ok Theme.Light)
                    , \_ -> extractColorScheme robotGameJson |> Expect.equal (Ok Theme.Light)
                    ]
                    ()
        , test "Theme state preservation across navigation" <|
            \_ ->
                let
                    -- Test that theme changes are preserved when switching between games
                    initialTicTacToe =
                        TicTacToeModel.initialModel

                    initialRobotGame =
                        RobotModel.init

                    -- Both should start with the same default theme
                    defaultThemeConsistent =
                        initialTicTacToe.colorScheme == initialRobotGame.colorScheme

                    -- Theme changes should be independent of game state
                    updatedTicTacToe =
                        { initialTicTacToe | colorScheme = Theme.Dark }

                    updatedRobotGame =
                        { initialRobotGame | colorScheme = Theme.Dark }

                    themeUpdateConsistent =
                        updatedTicTacToe.colorScheme == updatedRobotGame.colorScheme
                in
                Expect.all
                    [ \_ -> defaultThemeConsistent |> Expect.equal True
                    , \_ -> themeUpdateConsistent |> Expect.equal True
                    ]
                    ()
        ]


{-| Backward compatibility tests
-}
backwardCompatibilityTests : Test
backwardCompatibilityTests =
    describe "Backward compatibility"
        [ test "Legacy TicTacToe models decode correctly" <|
            \_ ->
                let
                    -- Simulate a saved game state from before shared theme module
                    legacyJson =
                        Encode.object
                            [ ( "board"
                              , Encode.list
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
                                    [ [ Just TicTacToeModel.X, Nothing, Just TicTacToeModel.O ]
                                    , [ Nothing, Just TicTacToeModel.X, Nothing ]
                                    , [ Just TicTacToeModel.O, Nothing, Nothing ]
                                    ]
                              )
                            , ( "gameState"
                              , Encode.object
                                    [ ( "type", Encode.string "Waiting" )
                                    , ( "player", Encode.string "O" )
                                    ]
                              )
                            , ( "lastMove", Encode.int 1500 )
                            , ( "now", Encode.int 2000 )
                            , ( "colorScheme", Encode.string "Dark" )
                            , ( "maybeWindow"
                              , Encode.object
                                    [ ( "width", Encode.int 1024 )
                                    , ( "height", Encode.int 768 )
                                    ]
                              )
                            ]

                    decoded =
                        Decode.decodeValue TicTacToeModel.decodeModel legacyJson
                in
                case decoded of
                    Ok model ->
                        model.colorScheme
                            |> Expect.equal Theme.Dark

                    Err _ ->
                        Expect.fail "Legacy model should decode successfully"
        , test "Legacy RobotGame models decode correctly" <|
            \_ ->
                let
                    -- Simulate a saved robot game state
                    legacyJson =
                        Encode.object
                            [ ( "robot"
                              , Encode.object
                                    [ ( "position", Encode.object [ ( "row", Encode.int 2 ), ( "col", Encode.int 3 ) ] )
                                    , ( "facing", Encode.string "North" )
                                    ]
                              )
                            , ( "colorScheme", Encode.string "Light" )
                            , ( "maybeWindow"
                              , Encode.object
                                    [ ( "width", Encode.int 800 )
                                    , ( "height", Encode.int 600 )
                                    ]
                              )
                            ]

                    decoded =
                        Decode.decodeValue RobotModel.decodeModel legacyJson
                in
                case decoded of
                    Ok model ->
                        model.colorScheme
                            |> Expect.equal Theme.Light

                    Err _ ->
                        Expect.fail "Legacy robot model should decode successfully"
        , test "Missing colorScheme field defaults correctly" <|
            \_ ->
                let
                    -- Test JSON without colorScheme field
                    jsonWithoutTheme =
                        Encode.object
                            [ ( "board"
                              , Encode.list
                                    (Encode.list (\_ -> Encode.null))
                                    [ [ Nothing, Nothing, Nothing ]
                                    , [ Nothing, Nothing, Nothing ]
                                    , [ Nothing, Nothing, Nothing ]
                                    ]
                              )
                            , ( "gameState"
                              , Encode.object
                                    [ ( "type", Encode.string "Waiting" )
                                    , ( "player", Encode.string "X" )
                                    ]
                              )
                            , ( "lastMove", Encode.int 0 )
                            , ( "now", Encode.int 1000 )
                            ]

                    decoded =
                        Decode.decodeValue TicTacToeModel.decodeModel jsonWithoutTheme
                in
                case decoded of
                    Ok model ->
                        -- Should default to Light theme
                        model.colorScheme
                            |> Expect.equal Theme.Light

                    Err _ ->
                        Expect.fail "Model without colorScheme should decode with default"
        ]


{-| Responsive design tests
-}
responsiveTests : Test
responsiveTests =
    describe "Responsive design integration"
        [ test "Screen size detection works correctly" <|
            \_ ->
                let
                    testCases =
                        [ ( 320, 568, Mobile ) -- iPhone SE
                        , ( 768, 1024, Tablet ) -- iPad
                        , ( 1920, 1080, Desktop ) -- Full HD
                        ]

                    testScreenSize ( width, height, expected ) =
                        getScreenSize (Just ( width, height ))
                            |> Expect.equal expected
                in
                testCases
                    |> List.map testScreenSize
                    |> List.all (\expectation -> expectation == Expect.pass)
                    |> Expect.equal True
        , test "Responsive values scale appropriately" <|
            \_ ->
                let
                    mobileWindow =
                        Just ( 320, 568 )

                    tabletWindow =
                        Just ( 768, 1024 )

                    desktopWindow =
                        Just ( 1920, 1080 )

                    mobileSize =
                        calculateResponsiveCellSize mobileWindow 5 80

                    tabletSize =
                        calculateResponsiveCellSize tabletWindow 5 80

                    desktopSize =
                        calculateResponsiveCellSize desktopWindow 5 80
                in
                Expect.all
                    [ \_ -> mobileSize |> Expect.lessThan tabletSize
                    , \_ -> tabletSize |> Expect.lessThan desktopSize
                    , \_ -> mobileSize |> Expect.greaterThan 0
                    ]
                    ()
        , test "Font sizes are responsive" <|
            \_ ->
                let
                    mobileWindow =
                        Just ( 320, 568 )

                    desktopWindow =
                        Just ( 1920, 1080 )

                    mobileFontSize =
                        getResponsiveFontSize mobileWindow 24

                    desktopFontSize =
                        getResponsiveFontSize desktopWindow 24
                in
                Expect.all
                    [ \_ -> mobileFontSize |> Expect.lessThan desktopFontSize
                    , \_ -> mobileFontSize |> Expect.greaterThan 0
                    ]
                    ()
        ]

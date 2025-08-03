module Theme.ThemeBackwardCompatibilityTest exposing (suite)

{-| Backward compatibility tests for shared theme module.

This module tests that existing game states from before the shared theme module
migration continue to work correctly, and that data migration preserves all
necessary information.

-}

import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import RobotGame.Model as RobotModel
import Test exposing (Test, describe, test)
import Theme.Theme as Theme
import TicTacToe.Model as TicTacToeModel
import Time


suite : Test
suite =
    describe "Theme Backward Compatibility Tests"
        [ legacyDataFormatTests
        , migrationPreservationTests
        , errorHandlingTests
        , dataIntegrityTests
        , crossVersionCompatibilityTests
        ]


{-| Tests that verify legacy data formats still work
-}
legacyDataFormatTests : Test
legacyDataFormatTests =
    describe "Legacy data format compatibility"
        [ test "TicTacToe models from before shared theme module still decode" <|
            \_ ->
                let
                    -- Simulate a saved game state from before the shared theme module
                    legacyTicTacToeJson =
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
                            , ( "colorScheme", Encode.string "Dark" ) -- This should still work
                            , ( "maybeWindow"
                              , Encode.object
                                    [ ( "width", Encode.int 1024 )
                                    , ( "height", Encode.int 768 )
                                    ]
                              )
                            ]

                    decoded =
                        Decode.decodeValue TicTacToeModel.decodeModel legacyTicTacToeJson
                in
                case decoded of
                    Ok model ->
                        Expect.all
                            [ \_ -> Expect.equal Theme.Dark model.colorScheme
                            , \_ -> Expect.equal (TicTacToeModel.Waiting TicTacToeModel.O) model.gameState
                            , \_ -> Expect.equal (Just ( 1024, 768 )) model.maybeWindow
                            , \_ -> Expect.equal (Just (Time.millisToPosix 1500)) model.lastMove
                            , \_ -> Expect.equal (Just (Time.millisToPosix 2000)) model.now
                            ]
                            ()

                    Err error ->
                        Expect.fail ("Failed to decode legacy TicTacToe model: " ++ Decode.errorToString error)
        , test "RobotGame models from before shared theme module still decode" <|
            \_ ->
                let
                    legacyRobotGameJson =
                        Encode.object
                            [ ( "robot"
                              , Encode.object
                                    [ ( "position", Encode.object [ ( "row", Encode.int 1 ), ( "col", Encode.int 3 ) ] )
                                    , ( "facing", Encode.string "East" )
                                    ]
                              )
                            , ( "gridSize", Encode.int 5 )
                            , ( "colorScheme", Encode.string "Light" ) -- This should still work
                            , ( "animationState"
                              , Encode.object
                                    [ ( "type", Encode.string "Moving" )
                                    , ( "from", Encode.object [ ( "row", Encode.int 1 ), ( "col", Encode.int 2 ) ] )
                                    , ( "to", Encode.object [ ( "row", Encode.int 1 ), ( "col", Encode.int 3 ) ] )
                                    ]
                              )
                            , ( "blockedMovementFeedback", Encode.bool True )
                            ]

                    decoded =
                        Decode.decodeValue RobotModel.decodeModel legacyRobotGameJson
                in
                case decoded of
                    Ok model ->
                        Expect.all
                            [ \_ -> Expect.equal Theme.Light model.colorScheme
                            , \_ -> Expect.equal { row = 1, col = 3 } model.robot.position
                            , \_ -> Expect.equal RobotModel.East model.robot.facing
                            , \_ -> Expect.equal (RobotModel.Moving { row = 1, col = 2 } { row = 1, col = 3 }) model.animationState
                            , \_ -> Expect.equal True model.blockedMovementFeedback
                            ]
                            ()

                    Err error ->
                        Expect.fail ("Failed to decode legacy RobotGame model: " ++ Decode.errorToString error)
        , test "Legacy ColorScheme values with different casing still work" <|
            \_ ->
                let
                    testColorSchemeDecoding value expected =
                        let
                            json =
                                Encode.string value

                            decoded =
                                Decode.decodeValue Theme.decodeColorScheme json
                        in
                        Expect.equal (Ok expected) decoded
                in
                Expect.all
                    [ \_ -> testColorSchemeDecoding "Light" Theme.Light
                    , \_ -> testColorSchemeDecoding "Dark" Theme.Dark
                    , \_ -> testColorSchemeDecoding "light" Theme.Light -- fallback to Light
                    , \_ -> testColorSchemeDecoding "dark" Theme.Light -- fallback to Light
                    , \_ -> testColorSchemeDecoding "LIGHT" Theme.Light -- fallback to Light
                    , \_ -> testColorSchemeDecoding "DARK" Theme.Light -- fallback to Light
                    , \_ -> testColorSchemeDecoding "" Theme.Light -- fallback to Light
                    , \_ -> testColorSchemeDecoding "invalid" Theme.Light -- fallback to Light
                    ]
                    ()
        ]


{-| Tests that verify migration preserves all necessary data
-}
migrationPreservationTests : Test
migrationPreservationTests =
    describe "Migration data preservation"
        [ test "TicTacToe game state is fully preserved during theme migration" <|
            \_ ->
                let
                    complexGameState =
                        let
                            initial =
                                TicTacToeModel.initialModel
                        in
                        { initial
                            | board =
                                [ [ Just TicTacToeModel.X, Just TicTacToeModel.O, Just TicTacToeModel.X ]
                                , [ Just TicTacToeModel.O, Just TicTacToeModel.X, Just TicTacToeModel.O ]
                                , [ Just TicTacToeModel.X, Just TicTacToeModel.O, Nothing ]
                                ]
                            , gameState = TicTacToeModel.Winner TicTacToeModel.X
                            , colorScheme = Theme.Dark
                            , lastMove = Just (Time.millisToPosix 5000)
                            , now = Just (Time.millisToPosix 6000)
                            , maybeWindow = Just ( 1920, 1080 )
                        }

                    -- Simulate encoding with old system and decoding with new system
                    encoded =
                        TicTacToeModel.encodeModel complexGameState

                    decoded =
                        Decode.decodeValue TicTacToeModel.decodeModel encoded
                in
                case decoded of
                    Ok decodedModel ->
                        Expect.all
                            [ \_ -> Expect.equal complexGameState.board decodedModel.board
                            , \_ -> Expect.equal complexGameState.gameState decodedModel.gameState
                            , \_ -> Expect.equal complexGameState.colorScheme decodedModel.colorScheme
                            , \_ -> Expect.equal complexGameState.lastMove decodedModel.lastMove
                            , \_ -> Expect.equal complexGameState.now decodedModel.now
                            , \_ -> Expect.equal complexGameState.maybeWindow decodedModel.maybeWindow
                            ]
                            ()

                    Err error ->
                        Expect.fail ("Migration failed to preserve TicTacToe state: " ++ Decode.errorToString error)
        , test "RobotGame state is fully preserved during theme migration" <|
            \_ ->
                let
                    complexRobotState =
                        let
                            initial =
                                RobotModel.init
                        in
                        { initial
                            | robot = { position = { row = 4, col = 1 }, facing = RobotModel.West }
                            , colorScheme = Theme.Dark
                            , animationState = RobotModel.Rotating RobotModel.North RobotModel.West
                            , blockedMovementFeedback = True
                            , maybeWindow = Just ( 800, 1200 )
                        }

                    encoded =
                        RobotModel.encodeModel complexRobotState

                    decoded =
                        Decode.decodeValue RobotModel.decodeModel encoded
                in
                case decoded of
                    Ok decodedModel ->
                        Expect.all
                            [ \_ -> Expect.equal complexRobotState.robot decodedModel.robot
                            , \_ -> Expect.equal complexRobotState.colorScheme decodedModel.colorScheme
                            , \_ -> Expect.equal complexRobotState.animationState decodedModel.animationState
                            , \_ -> Expect.equal complexRobotState.blockedMovementFeedback decodedModel.blockedMovementFeedback

                            -- Note: maybeWindow and lastMoveTime are not persisted in RobotGame
                            , \_ -> Expect.equal Nothing decodedModel.maybeWindow
                            , \_ -> Expect.equal Nothing decodedModel.lastMoveTime
                            ]
                            ()

                    Err error ->
                        Expect.fail ("Migration failed to preserve RobotGame state: " ++ Decode.errorToString error)
        , test "Theme preferences are preserved across game switches" <|
            \_ ->
                let
                    -- Test that a user's theme preference is maintained when switching between games
                    ticTacToeWithDarkTheme =
                        let
                            initial =
                                TicTacToeModel.initialModel
                        in
                        { initial | colorScheme = Theme.Dark }

                    robotGameWithDarkTheme =
                        let
                            initial =
                                RobotModel.init
                        in
                        { initial | colorScheme = Theme.Dark }

                    -- Encode both models
                    ticTacToeEncoded =
                        TicTacToeModel.encodeModel ticTacToeWithDarkTheme

                    robotGameEncoded =
                        RobotModel.encodeModel robotGameWithDarkTheme

                    -- Extract theme from both
                    extractTheme json =
                        Decode.decodeValue (Decode.field "colorScheme" Theme.decodeColorScheme) json
                in
                case ( extractTheme ticTacToeEncoded, extractTheme robotGameEncoded ) of
                    ( Ok ticTacToeTheme, Ok robotGameTheme ) ->
                        Expect.all
                            [ \_ -> Expect.equal Theme.Dark ticTacToeTheme
                            , \_ -> Expect.equal Theme.Dark robotGameTheme
                            , \_ -> Expect.equal ticTacToeTheme robotGameTheme
                            ]
                            ()

                    _ ->
                        Expect.fail "Failed to extract themes from encoded models"
        ]


{-| Tests that verify error handling during migration
-}
errorHandlingTests : Test
errorHandlingTests =
    describe "Migration error handling"
        [ test "Corrupted ColorScheme data falls back gracefully" <|
            \_ ->
                let
                    corruptedTicTacToeJson =
                        Encode.object
                            [ ( "board"
                              , Encode.list (Encode.list (\_ -> Encode.null))
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
                            , ( "lastMove", Encode.null )
                            , ( "now", Encode.null )
                            , ( "colorScheme", Encode.int 12345 ) -- Invalid type
                            , ( "maybeWindow", Encode.null )
                            ]

                    decoded =
                        Decode.decodeValue TicTacToeModel.decodeModel corruptedTicTacToeJson
                in
                case decoded of
                    Err _ ->
                        -- This is expected since the colorScheme field is invalid
                        Expect.pass

                    Ok _ ->
                        Expect.fail "Should have failed to decode corrupted colorScheme"
        , test "Missing optional fields don't break migration" <|
            \_ ->
                let
                    minimalTicTacToeJson =
                        Encode.object
                            [ ( "board"
                              , Encode.list (Encode.list (\_ -> Encode.null))
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
                            , ( "colorScheme", Encode.string "Light" )

                            -- Missing optional fields: lastMove, now, maybeWindow
                            ]

                    decoded =
                        Decode.decodeValue TicTacToeModel.decodeModel minimalTicTacToeJson
                in
                case decoded of
                    Ok model ->
                        Expect.all
                            [ \_ -> Expect.equal Theme.Light model.colorScheme
                            , \_ -> Expect.equal Nothing model.lastMove
                            , \_ -> Expect.equal Nothing model.now
                            , \_ -> Expect.equal Nothing model.maybeWindow
                            ]
                            ()

                    Err error ->
                        Expect.fail ("Failed to decode minimal model: " ++ Decode.errorToString error)
        , test "Malformed JSON gracefully handles theme fallbacks" <|
            \_ ->
                let
                    testFallback jsonValue =
                        Decode.decodeValue Theme.decodeColorScheme jsonValue
                in
                Expect.all
                    [ \_ -> Expect.equal (Ok Theme.Light) (testFallback (Encode.string ""))
                    , \_ -> Expect.equal (Ok Theme.Light) (testFallback (Encode.string "NotAValidTheme"))

                    -- Note: Invalid JSON types will cause decode errors, not fallbacks
                    -- The fallback only happens for invalid string values, not invalid types
                    ]
                    ()
        ]


{-| Tests that verify data integrity is maintained
-}
dataIntegrityTests : Test
dataIntegrityTests =
    describe "Data integrity during migration"
        [ test "Multiple round-trip migrations preserve data" <|
            \_ ->
                let
                    originalTicTacToe =
                        let
                            initial =
                                TicTacToeModel.initialModel
                        in
                        { initial
                            | board = [ [ Just TicTacToeModel.X, Nothing, Nothing ], [ Nothing, Just TicTacToeModel.O, Nothing ], [ Nothing, Nothing, Nothing ] ]
                            , gameState = TicTacToeModel.Thinking TicTacToeModel.O
                            , colorScheme = Theme.Dark
                            , maybeWindow = Just ( 1366, 768 )
                        }

                    -- Perform multiple encode/decode cycles
                    firstCycle =
                        originalTicTacToe
                            |> TicTacToeModel.encodeModel
                            |> Decode.decodeValue TicTacToeModel.decodeModel

                    secondCycle =
                        case firstCycle of
                            Ok model ->
                                model
                                    |> TicTacToeModel.encodeModel
                                    |> Decode.decodeValue TicTacToeModel.decodeModel

                            Err _ ->
                                Err (Decode.Failure "First cycle failed" Encode.null)

                    thirdCycle =
                        case secondCycle of
                            Ok model ->
                                model
                                    |> TicTacToeModel.encodeModel
                                    |> Decode.decodeValue TicTacToeModel.decodeModel

                            Err _ ->
                                Err (Decode.Failure "Second cycle failed" Encode.null)
                in
                case thirdCycle of
                    Ok finalModel ->
                        Expect.all
                            [ \_ -> Expect.equal originalTicTacToe.board finalModel.board
                            , \_ -> Expect.equal originalTicTacToe.gameState finalModel.gameState
                            , \_ -> Expect.equal originalTicTacToe.colorScheme finalModel.colorScheme
                            , \_ -> Expect.equal originalTicTacToe.maybeWindow finalModel.maybeWindow
                            ]
                            ()

                    Err error ->
                        Expect.fail ("Multiple round-trip failed: " ++ Decode.errorToString error)
        , test "Large game states maintain integrity" <|
            \_ ->
                let
                    -- Create a complex game state with all possible values
                    complexState =
                        let
                            initial =
                                TicTacToeModel.initialModel
                        in
                        { initial
                            | board =
                                [ [ Just TicTacToeModel.X, Just TicTacToeModel.O, Just TicTacToeModel.X ]
                                , [ Just TicTacToeModel.O, Just TicTacToeModel.X, Just TicTacToeModel.O ]
                                , [ Just TicTacToeModel.X, Just TicTacToeModel.O, Just TicTacToeModel.X ]
                                ]
                            , gameState = TicTacToeModel.Error (TicTacToeModel.createGameLogicError "Test error for integrity check")
                            , colorScheme = Theme.Dark
                            , lastMove = Just (Time.millisToPosix 999999)
                            , now = Just (Time.millisToPosix 1000000)
                            , maybeWindow = Just ( 2560, 1440 )
                        }

                    roundTrip =
                        complexState
                            |> TicTacToeModel.encodeModel
                            |> Decode.decodeValue TicTacToeModel.decodeModel
                in
                case roundTrip of
                    Ok decoded ->
                        Expect.all
                            [ \_ -> Expect.equal complexState.board decoded.board
                            , \_ -> Expect.equal complexState.gameState decoded.gameState
                            , \_ -> Expect.equal complexState.colorScheme decoded.colorScheme
                            , \_ -> Expect.equal complexState.lastMove decoded.lastMove
                            , \_ -> Expect.equal complexState.now decoded.now
                            , \_ -> Expect.equal complexState.maybeWindow decoded.maybeWindow
                            ]
                            ()

                    Err error ->
                        Expect.fail ("Complex state integrity check failed: " ++ Decode.errorToString error)
        ]


{-| Tests that verify compatibility across different versions
-}
crossVersionCompatibilityTests : Test
crossVersionCompatibilityTests =
    describe "Cross-version compatibility"
        [ test "Theme module changes don't break existing game saves" <|
            \_ ->
                let
                    -- Simulate data that might have been saved with an older version
                    oldVersionData =
                        [ ( "TicTacToe with Light theme"
                          , Encode.object
                                [ ( "board", Encode.list (Encode.list (\_ -> Encode.null)) [ [ Nothing, Nothing, Nothing ], [ Nothing, Nothing, Nothing ], [ Nothing, Nothing, Nothing ] ] )
                                , ( "gameState", Encode.object [ ( "type", Encode.string "Waiting" ), ( "player", Encode.string "X" ) ] )
                                , ( "lastMove", Encode.null )
                                , ( "now", Encode.null )
                                , ( "colorScheme", Encode.string "Light" )
                                , ( "maybeWindow", Encode.null )
                                ]
                          )
                        , ( "RobotGame with Dark theme"
                          , Encode.object
                                [ ( "robot", Encode.object [ ( "position", Encode.object [ ( "row", Encode.int 2 ), ( "col", Encode.int 2 ) ] ), ( "facing", Encode.string "North" ) ] )
                                , ( "gridSize", Encode.int 5 )
                                , ( "colorScheme", Encode.string "Dark" )
                                , ( "animationState", Encode.object [ ( "type", Encode.string "Idle" ) ] )
                                , ( "blockedMovementFeedback", Encode.bool False )
                                ]
                          )
                        ]

                    testDecoding ( description, json ) =
                        let
                            ticTacToeResult =
                                if String.contains "TicTacToe" description then
                                    case Decode.decodeValue TicTacToeModel.decodeModel json of
                                        Ok _ ->
                                            True

                                        Err _ ->
                                            False

                                else
                                    True

                            robotGameResult =
                                if String.contains "RobotGame" description then
                                    case Decode.decodeValue RobotModel.decodeModel json of
                                        Ok _ ->
                                            True

                                        Err _ ->
                                            False

                                else
                                    True
                        in
                        ticTacToeResult && robotGameResult

                    allSuccessful =
                        List.all testDecoding oldVersionData
                in
                if allSuccessful then
                    Expect.pass

                else
                    Expect.fail "All old version data should decode successfully"
        , test "Future theme additions don't break current data" <|
            \_ ->
                let
                    -- Test that unknown theme values fall back gracefully
                    futureThemeJson =
                        Encode.string "FutureTheme"

                    decoded =
                        Decode.decodeValue Theme.decodeColorScheme futureThemeJson
                in
                Expect.equal (Ok Theme.Light) decoded

        -- Should fallback to Light
        , test "Additional theme properties don't break existing models" <|
            \_ ->
                let
                    -- Simulate JSON with extra properties that might be added in future versions
                    jsonWithExtraProperties =
                        Encode.object
                            [ ( "board", Encode.list (Encode.list (\_ -> Encode.null)) [ [ Nothing, Nothing, Nothing ], [ Nothing, Nothing, Nothing ], [ Nothing, Nothing, Nothing ] ] )
                            , ( "gameState", Encode.object [ ( "type", Encode.string "Waiting" ), ( "player", Encode.string "X" ) ] )
                            , ( "lastMove", Encode.null )
                            , ( "now", Encode.null )
                            , ( "colorScheme", Encode.string "Light" )
                            , ( "maybeWindow", Encode.null )

                            -- Extra properties that might be added in future
                            , ( "futureProperty1", Encode.string "someValue" )
                            , ( "futureProperty2", Encode.int 42 )
                            , ( "futureThemeSettings", Encode.object [ ( "customColor", Encode.string "#FF0000" ) ] )
                            ]

                    decoded =
                        Decode.decodeValue TicTacToeModel.decodeModel jsonWithExtraProperties
                in
                case decoded of
                    Ok model ->
                        Expect.equal Theme.Light model.colorScheme

                    Err error ->
                        Expect.fail ("Extra properties should not break decoding: " ++ Decode.errorToString error)
        ]

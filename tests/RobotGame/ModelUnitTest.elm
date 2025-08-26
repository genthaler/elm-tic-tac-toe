module RobotGame.ModelUnitTest exposing (suite)

import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import RobotGame.Model exposing (..)
import Test exposing (..)
import Theme.Theme exposing (ColorScheme(..), decodeColorScheme, encodeColorScheme)


suite : Test
suite =
    describe "RobotGame.Model"
        [ positionTests
        , directionTests
        , robotTests
        , modelTests
        , jsonEncodingDecodingTests
        , initializationTests
        ]


positionTests : Test
positionTests =
    describe "Position"
        [ test "creates position with valid coordinates" <|
            \_ ->
                let
                    position =
                        { row = 2, col = 3 }
                in
                Expect.all
                    [ \p -> Expect.equal 2 p.row
                    , \p -> Expect.equal 3 p.col
                    ]
                    position
        , test "encodes position to JSON correctly" <|
            \_ ->
                let
                    position =
                        { row = 1, col = 4 }

                    encoded =
                        encodePosition position

                    expected =
                        Encode.object
                            [ ( "row", Encode.int 1 )
                            , ( "col", Encode.int 4 )
                            ]
                in
                Expect.equal expected encoded
        , test "decodes position from JSON correctly" <|
            \_ ->
                let
                    json =
                        Encode.object
                            [ ( "row", Encode.int 3 )
                            , ( "col", Encode.int 2 )
                            ]

                    result =
                        Decode.decodeValue decodePosition json

                    expected =
                        { row = 3, col = 2 }
                in
                Expect.equal (Ok expected) result
        , test "fails to decode invalid position JSON" <|
            \_ ->
                let
                    json =
                        Encode.object [ ( "invalid", Encode.string "data" ) ]

                    result =
                        Decode.decodeValue decodePosition json
                in
                case result of
                    Err _ ->
                        Expect.pass

                    Ok _ ->
                        Expect.fail "Expected decoding to fail"
        ]


directionTests : Test
directionTests =
    describe "Direction"
        [ test "encodes all directions correctly" <|
            \_ ->
                Expect.all
                    [ \_ -> Expect.equal (Encode.string "North") (encodeDirection North)
                    , \_ -> Expect.equal (Encode.string "South") (encodeDirection South)
                    , \_ -> Expect.equal (Encode.string "East") (encodeDirection East)
                    , \_ -> Expect.equal (Encode.string "West") (encodeDirection West)
                    ]
                    ()
        , test "decodes all directions correctly" <|
            \_ ->
                Expect.all
                    [ \_ -> Expect.equal (Ok North) (Decode.decodeValue decodeDirection (Encode.string "North"))
                    , \_ -> Expect.equal (Ok South) (Decode.decodeValue decodeDirection (Encode.string "South"))
                    , \_ -> Expect.equal (Ok East) (Decode.decodeValue decodeDirection (Encode.string "East"))
                    , \_ -> Expect.equal (Ok West) (Decode.decodeValue decodeDirection (Encode.string "West"))
                    ]
                    ()
        , test "fails to decode invalid direction" <|
            \_ ->
                let
                    result =
                        Decode.decodeValue decodeDirection (Encode.string "Invalid")
                in
                case result of
                    Err _ ->
                        Expect.pass

                    Ok _ ->
                        Expect.fail "Expected decoding to fail"
        ]


robotTests : Test
robotTests =
    describe "Robot"
        [ test "creates robot with position and direction" <|
            \_ ->
                let
                    robot =
                        { position = { row = 1, col = 2 }
                        , facing = East
                        }
                in
                Expect.all
                    [ \r -> Expect.equal { row = 1, col = 2 } r.position
                    , \r -> Expect.equal East r.facing
                    ]
                    robot
        , test "encodes robot to JSON correctly" <|
            \_ ->
                let
                    robot =
                        { position = { row = 0, col = 4 }
                        , facing = West
                        }

                    encoded =
                        encodeRobot robot

                    expected =
                        Encode.object
                            [ ( "position", encodePosition { row = 0, col = 4 } )
                            , ( "facing", encodeDirection West )
                            ]
                in
                Expect.equal expected encoded
        , test "decodes robot from JSON correctly" <|
            \_ ->
                let
                    json =
                        Encode.object
                            [ ( "position", encodePosition { row = 2, col = 1 } )
                            , ( "facing", encodeDirection South )
                            ]

                    result =
                        Decode.decodeValue decodeRobot json

                    expected =
                        { position = { row = 2, col = 1 }
                        , facing = South
                        }
                in
                Expect.equal (Ok expected) result
        ]


modelTests : Test
modelTests =
    describe "Model"
        [ test "creates model with all required fields" <|
            \_ ->
                let
                    model =
                        init
                in
                Expect.all
                    [ \m -> Expect.equal 5 m.gridSize
                    , \m -> Expect.equal Light m.colorScheme
                    , \m -> Expect.equal Nothing m.maybeWindow
                    , \m -> Expect.equal Idle m.animationState
                    , \m -> Expect.equal Nothing m.lastMoveTime
                    , \m -> Expect.equal { row = 2, col = 2 } m.robot.position
                    , \m -> Expect.equal North m.robot.facing
                    ]
                    model
        ]


jsonEncodingDecodingTests : Test
jsonEncodingDecodingTests =
    describe "JSON Encoding/Decoding"
        [ test "round-trip encoding and decoding preserves model data" <|
            \_ ->
                let
                    originalModel =
                        { robot =
                            { position = { row = 3, col = 1 }
                            , facing = East
                            }
                        , gridSize = 5
                        , colorScheme = Dark
                        , maybeWindow = Just ( 800, 600 )
                        , animationState = Moving { row = 2, col = 1 } { row = 3, col = 1 }
                        , lastMoveTime = Nothing
                        , blockedMovementFeedback = False
                        }

                    encoded =
                        encodeModel originalModel

                    decoded =
                        Decode.decodeValue decodeModel encoded
                in
                case decoded of
                    Ok decodedModel ->
                        Expect.all
                            [ \m -> Expect.equal originalModel.robot m.robot
                            , \m -> Expect.equal originalModel.gridSize m.gridSize
                            , \m -> Expect.equal originalModel.colorScheme m.colorScheme
                            , \m -> Expect.equal originalModel.animationState m.animationState

                            -- Note: maybeWindow and lastMoveTime are not persisted
                            , \m -> Expect.equal Nothing m.maybeWindow
                            , \m -> Expect.equal Nothing m.lastMoveTime
                            ]
                            decodedModel

                    Err error ->
                        Expect.fail ("Decoding failed: " ++ Decode.errorToString error)
        , test "encodes and decodes animation states correctly" <|
            \_ ->
                let
                    testAnimationState state =
                        let
                            encoded =
                                encodeAnimationState state

                            decoded =
                                Decode.decodeValue decodeAnimationState encoded
                        in
                        Expect.equal (Ok state) decoded
                in
                Expect.all
                    [ \_ -> testAnimationState Idle
                    , \_ -> testAnimationState (Moving { row = 0, col = 0 } { row = 1, col = 0 })
                    , \_ -> testAnimationState (Rotating North East)
                    ]
                    ()
        , test "encodes and decodes color schemes correctly" <|
            \_ ->
                let
                    testColorScheme scheme =
                        let
                            encoded =
                                encodeColorScheme scheme

                            decoded =
                                Decode.decodeValue decodeColorScheme encoded
                        in
                        Expect.equal (Ok scheme) decoded
                in
                Expect.all
                    [ \_ -> testColorScheme Light
                    , \_ -> testColorScheme Dark
                    ]
                    ()
        ]


initializationTests : Test
initializationTests =
    describe "Initialization"
        [ test "init creates model with robot at center of grid" <|
            \_ ->
                let
                    model =
                        init

                    centerPosition =
                        { row = 2, col = 2 }
                in
                Expect.equal centerPosition model.robot.position
        , test "init creates model with robot facing North" <|
            \_ ->
                let
                    model =
                        init
                in
                Expect.equal North model.robot.facing
        , test "init creates model with 5x5 grid" <|
            \_ ->
                let
                    model =
                        init
                in
                Expect.equal 5 model.gridSize
        , test "init creates model with Light color scheme" <|
            \_ ->
                let
                    model =
                        init
                in
                Expect.equal Light model.colorScheme
        , test "init creates model with Idle animation state" <|
            \_ ->
                let
                    model =
                        init
                in
                Expect.equal Idle model.animationState
        ]

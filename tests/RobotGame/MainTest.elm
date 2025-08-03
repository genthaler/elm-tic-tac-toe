module RobotGame.MainTest exposing (suite)

import Expect
import RobotGame.Main exposing (Msg(..), init, subscriptions, update)
import RobotGame.Model as Model exposing (AnimationState(..), Direction(..), Model, Robot)
import Test exposing (..)
import Theme.Theme exposing (ColorScheme(..))
import Time


{-| Helper function to create a model with a custom robot
-}
createModelWithRobot : Robot -> Model
createModelWithRobot robot =
    { robot = robot
    , gridSize = 5
    , colorScheme = Light
    , maybeWindow = Nothing
    , animationState = Idle
    , lastMoveTime = Nothing
    , blockedMovementFeedback = False
    }


{-| Helper function to create a model with custom robot and animation state
-}
createModelWithRobotAndAnimation : Robot -> AnimationState -> Model
createModelWithRobotAndAnimation robot animationState =
    { robot = robot
    , gridSize = 5
    , colorScheme = Light
    , maybeWindow = Nothing
    , animationState = animationState
    , lastMoveTime = Nothing
    , blockedMovementFeedback = False
    }


suite : Test
suite =
    describe "RobotGame.Main"
        [ initializationTests
        , movementTests
        , rotationTests
        , keyboardInputTests
        , keyDecoderTests
        , subscriptionTests
        , animationStateTests
        , gameStateTransitionTests
        ]


initializationTests : Test
initializationTests =
    describe "Initialization"
        [ test "init returns model with robot at center facing North" <|
            \_ ->
                let
                    ( model, _ ) =
                        init
                in
                Expect.all
                    [ \m -> Expect.equal { row = 2, col = 2 } m.robot.position
                    , \m -> Expect.equal North m.robot.facing
                    , \m -> Expect.equal Idle m.animationState
                    , \m -> Expect.equal 5 m.gridSize
                    ]
                    model
        , test "init returns no initial commands" <|
            \_ ->
                let
                    ( _, cmd ) =
                        init
                in
                Expect.equal Cmd.none cmd
        ]


movementTests : Test
movementTests =
    describe "Movement"
        [ test "MoveForward moves robot forward when possible" <|
            \_ ->
                let
                    robot =
                        { position = { row = 2, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot robot

                    ( updatedModel, _ ) =
                        update MoveForward initialModel

                    expectedPosition =
                        { row = 1, col = 2 }
                in
                Expect.all
                    [ \m -> Expect.equal expectedPosition m.robot.position
                    , \m -> Expect.equal North m.robot.facing
                    , \m -> Expect.equal (Moving { row = 2, col = 2 } expectedPosition) m.animationState
                    ]
                    updatedModel
        , test "MoveForward does not move robot when at boundary" <|
            \_ ->
                let
                    robot =
                        { position = { row = 0, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot robot

                    ( updatedModel, _ ) =
                        update MoveForward initialModel

                    expectedPosition =
                        { row = 0, col = 2 }
                in
                Expect.all
                    [ \m -> Expect.equal expectedPosition m.robot.position
                    , \m -> Expect.equal North m.robot.facing
                    , \m -> Expect.equal BlockedMovement m.animationState
                    , \m -> Expect.equal True m.blockedMovementFeedback
                    ]
                    updatedModel
        , test "MoveForward ignores input during animation" <|
            \_ ->
                let
                    robot =
                        { position = { row = 2, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobotAndAnimation robot (Moving { row = 2, col = 2 } { row = 1, col = 2 })

                    ( updatedModel, _ ) =
                        update MoveForward initialModel
                in
                Expect.equal initialModel updatedModel
        , test "MoveForward works in all directions" <|
            \_ ->
                let
                    testDirection direction expectedPosition =
                        let
                            robot =
                                { position = { row = 2, col = 2 }, facing = direction }

                            initialModel =
                                createModelWithRobot robot

                            ( updatedModel, _ ) =
                                update MoveForward initialModel
                        in
                        Expect.equal expectedPosition updatedModel.robot.position
                in
                Expect.all
                    [ \_ -> testDirection North { row = 1, col = 2 }
                    , \_ -> testDirection South { row = 3, col = 2 }
                    , \_ -> testDirection East { row = 2, col = 3 }
                    , \_ -> testDirection West { row = 2, col = 1 }
                    ]
                    ()
        ]


rotationTests : Test
rotationTests =
    describe "Rotation"
        [ test "RotateLeft rotates robot counterclockwise" <|
            \_ ->
                let
                    robot =
                        { position = { row = 2, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot robot

                    ( updatedModel, _ ) =
                        update RotateLeft initialModel
                in
                Expect.all
                    [ \m -> Expect.equal { row = 2, col = 2 } m.robot.position
                    , \m -> Expect.equal West m.robot.facing
                    , \m -> Expect.equal (Rotating North West) m.animationState
                    ]
                    updatedModel
        , test "RotateRight rotates robot clockwise" <|
            \_ ->
                let
                    robot =
                        { position = { row = 2, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot robot

                    ( updatedModel, _ ) =
                        update RotateRight initialModel
                in
                Expect.all
                    [ \m -> Expect.equal { row = 2, col = 2 } m.robot.position
                    , \m -> Expect.equal East m.robot.facing
                    , \m -> Expect.equal (Rotating North East) m.animationState
                    ]
                    updatedModel
        , test "RotateToDirection changes robot to specific direction" <|
            \_ ->
                let
                    robot =
                        { position = { row = 2, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot robot

                    ( updatedModel, _ ) =
                        update (RotateToDirection South) initialModel
                in
                Expect.all
                    [ \m -> Expect.equal { row = 2, col = 2 } m.robot.position
                    , \m -> Expect.equal South m.robot.facing
                    , \m -> Expect.equal (Rotating North South) m.animationState
                    ]
                    updatedModel
        , test "RotateToDirection does nothing when already facing direction" <|
            \_ ->
                let
                    robot =
                        { position = { row = 2, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot robot

                    ( updatedModel, _ ) =
                        update (RotateToDirection North) initialModel
                in
                Expect.equal initialModel updatedModel
        , test "Rotation ignores input during animation" <|
            \_ ->
                let
                    robot =
                        { position = { row = 2, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobotAndAnimation robot (Rotating North East)

                    ( updatedModel, _ ) =
                        update RotateLeft initialModel
                in
                Expect.equal initialModel updatedModel
        ]


keyboardInputTests : Test
keyboardInputTests =
    describe "Keyboard Input"
        [ test "ArrowUp triggers MoveForward" <|
            \_ ->
                let
                    robot =
                        { position = { row = 2, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot robot

                    ( updatedModel, _ ) =
                        update (KeyPressed "ArrowUp") initialModel

                    expectedPosition =
                        { row = 1, col = 2 }
                in
                Expect.equal expectedPosition updatedModel.robot.position
        , test "ArrowLeft triggers RotateLeft" <|
            \_ ->
                let
                    robot =
                        { position = { row = 2, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot robot

                    ( updatedModel, _ ) =
                        update (KeyPressed "ArrowLeft") initialModel
                in
                Expect.equal West updatedModel.robot.facing
        , test "ArrowRight triggers RotateRight" <|
            \_ ->
                let
                    robot =
                        { position = { row = 2, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot robot

                    ( updatedModel, _ ) =
                        update (KeyPressed "ArrowRight") initialModel
                in
                Expect.equal East updatedModel.robot.facing
        , test "ArrowDown triggers rotation to opposite direction" <|
            \_ ->
                let
                    testOppositeRotation facing expectedFacing =
                        let
                            robot =
                                { position = { row = 2, col = 2 }, facing = facing }

                            initialModel =
                                createModelWithRobot robot

                            ( updatedModel, _ ) =
                                update (KeyPressed "ArrowDown") initialModel
                        in
                        Expect.equal expectedFacing updatedModel.robot.facing
                in
                Expect.all
                    [ \_ -> testOppositeRotation North South
                    , \_ -> testOppositeRotation South North
                    , \_ -> testOppositeRotation East West
                    , \_ -> testOppositeRotation West East
                    ]
                    ()
        , test "Unknown keys are ignored" <|
            \_ ->
                let
                    initialModel =
                        Model.init

                    ( updatedModel, _ ) =
                        update (KeyPressed "Space") initialModel
                in
                Expect.equal initialModel updatedModel
        ]


keyDecoderTests : Test
keyDecoderTests =
    describe "Key Decoder"
        [ test "Arrow keys are properly handled" <|
            \_ ->
                let
                    testArrowKey key =
                        let
                            initialModel =
                                Model.init

                            ( updatedModel, _ ) =
                                update (KeyPressed key) initialModel
                        in
                        case key of
                            "ArrowUp" ->
                                -- Should move forward (North from center)
                                Expect.equal { row = 1, col = 2 } updatedModel.robot.position

                            "ArrowLeft" ->
                                -- Should rotate left (West from North)
                                Expect.equal West updatedModel.robot.facing

                            "ArrowRight" ->
                                -- Should rotate right (East from North)
                                Expect.equal East updatedModel.robot.facing

                            "ArrowDown" ->
                                -- Should rotate to opposite (South from North)
                                Expect.equal South updatedModel.robot.facing

                            _ ->
                                Expect.fail ("Unexpected key: " ++ key)
                in
                Expect.all
                    [ \_ -> testArrowKey "ArrowUp"
                    , \_ -> testArrowKey "ArrowLeft"
                    , \_ -> testArrowKey "ArrowRight"
                    , \_ -> testArrowKey "ArrowDown"
                    ]
                    ()
        , test "Non-arrow keys are ignored" <|
            \_ ->
                let
                    initialModel =
                        Model.init

                    testIgnoredKey key =
                        let
                            ( updatedModel, _ ) =
                                update (KeyPressed key) initialModel
                        in
                        Expect.equal initialModel updatedModel
                in
                Expect.all
                    [ \_ -> testIgnoredKey "Space"
                    , \_ -> testIgnoredKey "Enter"
                    , \_ -> testIgnoredKey "Escape"
                    , \_ -> testIgnoredKey "a"
                    , \_ -> testIgnoredKey "1"
                    ]
                    ()
        ]


subscriptionTests : Test
subscriptionTests =
    describe "Subscriptions"
        [ test "subscriptions function exists and can be called" <|
            \_ ->
                let
                    model =
                        Model.init
                in
                -- We can't directly test the subscription content, but we can verify the function exists
                case subscriptions model of
                    _ ->
                        Expect.pass
        ]


animationStateTests : Test
animationStateTests =
    describe "Animation State Management"
        [ test "AnimationComplete returns model to Idle state" <|
            \_ ->
                let
                    initialModel =
                        createModelWithRobotAndAnimation
                            { position = { row = 2, col = 2 }, facing = North }
                            (Moving { row = 2, col = 2 } { row = 1, col = 2 })

                    ( updatedModel, _ ) =
                        update AnimationComplete initialModel
                in
                Expect.equal Idle updatedModel.animationState
        , test "ColorScheme updates color scheme" <|
            \_ ->
                let
                    initialModel =
                        createModelWithRobot { position = { row = 2, col = 2 }, facing = North }

                    ( updatedModel, _ ) =
                        update (ColorScheme Dark) initialModel
                in
                Expect.equal Dark updatedModel.colorScheme
        , test "GetResize updates window dimensions" <|
            \_ ->
                let
                    initialModel =
                        createModelWithRobot { position = { row = 2, col = 2 }, facing = North }

                    ( updatedModel, _ ) =
                        update (GetResize 800 600) initialModel
                in
                Expect.equal (Just ( 800, 600 )) updatedModel.maybeWindow
        , test "Tick updates last move time" <|
            \_ ->
                let
                    initialModel =
                        createModelWithRobot { position = { row = 2, col = 2 }, facing = North }

                    testTime =
                        Time.millisToPosix 1000

                    ( updatedModel, _ ) =
                        update (Tick testTime) initialModel
                in
                Expect.equal (Just testTime) updatedModel.lastMoveTime
        ]


gameStateTransitionTests : Test
gameStateTransitionTests =
    describe "Game State Transitions"
        [ test "Complete movement sequence with animation" <|
            \_ ->
                let
                    -- Start with robot at center facing North
                    initialModel =
                        Model.init

                    -- Move forward
                    ( afterMove, _ ) =
                        update MoveForward initialModel

                    -- Complete animation
                    ( finalModel, _ ) =
                        update AnimationComplete afterMove
                in
                Expect.all
                    [ \m -> Expect.equal { row = 1, col = 2 } m.robot.position
                    , \m -> Expect.equal North m.robot.facing
                    , \m -> Expect.equal Idle m.animationState
                    ]
                    finalModel
        , test "Complete rotation sequence with animation" <|
            \_ ->
                let
                    -- Start with robot at center facing North
                    initialModel =
                        Model.init

                    -- Rotate left
                    ( afterRotate, _ ) =
                        update RotateLeft initialModel

                    -- Complete animation
                    ( finalModel, _ ) =
                        update AnimationComplete afterRotate
                in
                Expect.all
                    [ \m -> Expect.equal { row = 2, col = 2 } m.robot.position
                    , \m -> Expect.equal West m.robot.facing
                    , \m -> Expect.equal Idle m.animationState
                    ]
                    finalModel
        , test "Multiple moves in sequence" <|
            \_ ->
                let
                    -- Start with robot at center facing North
                    initialModel =
                        Model.init

                    -- Move forward (North)
                    ( afterMove1, _ ) =
                        update MoveForward initialModel

                    ( afterAnim1, _ ) =
                        update AnimationComplete afterMove1

                    -- Rotate right to face East
                    ( afterRotate, _ ) =
                        update RotateRight afterAnim1

                    ( afterAnim2, _ ) =
                        update AnimationComplete afterRotate

                    -- Move forward (East)
                    ( afterMove2, _ ) =
                        update MoveForward afterAnim2

                    ( finalModel, _ ) =
                        update AnimationComplete afterMove2
                in
                Expect.all
                    [ \m -> Expect.equal { row = 1, col = 3 } m.robot.position
                    , \m -> Expect.equal East m.robot.facing
                    , \m -> Expect.equal Idle m.animationState
                    ]
                    finalModel
        , test "Boundary collision prevents movement but allows rotation" <|
            \_ ->
                let
                    -- Start with robot at top edge facing North
                    robot =
                        { position = { row = 0, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot robot

                    -- Try to move forward (should fail and show blocked feedback)
                    ( afterMove, _ ) =
                        update MoveForward initialModel

                    -- Clear blocked movement feedback
                    ( afterClear, _ ) =
                        update ClearBlockedMovementFeedback afterMove

                    -- Rotate right to face East (should succeed)
                    ( afterRotate, _ ) =
                        update RotateRight afterClear

                    ( finalModel, _ ) =
                        update AnimationComplete afterRotate
                in
                Expect.all
                    [ \m -> Expect.equal { row = 0, col = 2 } m.robot.position
                    , \m -> Expect.equal East m.robot.facing
                    , \m -> Expect.equal Idle m.animationState
                    ]
                    finalModel
        ]

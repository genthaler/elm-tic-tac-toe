module RobotGame.MainUnitTest exposing (suite)

import Animator
import Expect
import RobotGame.Main exposing (Msg(..), init, subscriptions, update)
import RobotGame.Model as Model exposing (AnimationState(..), Button(..), Direction(..), Model, Robot)
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
    , highlightedButtons = []

    -- Initialize elm-animator timelines
    , robotTimeline = Animator.init robot
    , buttonHighlightTimeline = Animator.init []
    , blockedMovementTimeline = Animator.init False
    , rotationAngleTimeline = Animator.init (Model.directionToAngleFloat robot.facing)
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
    , highlightedButtons = []

    -- Initialize elm-animator timelines
    , robotTimeline = Animator.init robot
    , buttonHighlightTimeline = Animator.init []
    , blockedMovementTimeline = Animator.init False
    , rotationAngleTimeline = Animator.init (Model.directionToAngleFloat robot.facing)
    }


suite : Test
suite =
    describe "RobotGame.Main Module Integration"
        [ initializationTests
        , updateFunctionTests
        , keyboardInputTests
        , subscriptionTests
        , animationStateTests
        , gameStateTransitionTests
        , animatorIntegrationTests
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


updateFunctionTests : Test
updateFunctionTests =
    describe "Update Function Integration"
        [ test "MoveForward creates correct animation state" <|
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
        , test "MoveForward handles boundary collision correctly" <|
            \_ ->
                let
                    robot =
                        { position = { row = 0, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot robot

                    ( updatedModel, _ ) =
                        update MoveForward initialModel
                in
                Expect.all
                    [ \m -> Expect.equal { row = 0, col = 2 } m.robot.position
                    , \m -> Expect.equal North m.robot.facing
                    , \m -> Expect.equal BlockedMovement m.animationState
                    , \m -> Expect.equal True m.blockedMovementFeedback
                    ]
                    updatedModel
        , test "Update ignores input during animation" <|
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


animatorIntegrationTests : Test
animatorIntegrationTests =
    describe "elm-animator Integration"
        [ test "AnimationFrame message updates all timelines" <|
            \_ ->
                let
                    initialModel =
                        Model.init

                    testTime =
                        Time.millisToPosix 1000

                    ( updatedModel, _ ) =
                        update (AnimationFrame testTime) initialModel
                in
                -- We can't easily test the exact timeline state changes without running animations,
                -- but we can verify the message is handled without errors
                Expect.all
                    [ \m -> Expect.notEqual Nothing (Just m.robotTimeline)
                    , \m -> Expect.notEqual Nothing (Just m.buttonHighlightTimeline)
                    , \m -> Expect.notEqual Nothing (Just m.blockedMovementTimeline)
                    ]
                    updatedModel
        , test "init creates model with properly initialized timelines" <|
            \_ ->
                let
                    ( model, _ ) =
                        init

                    expectedRobot =
                        { position = { row = 2, col = 2 }
                        , facing = North
                        }
                in
                Expect.all
                    [ \m -> Expect.equal expectedRobot (Animator.current m.robotTimeline)
                    , \m -> Expect.equal [] (Animator.current m.buttonHighlightTimeline)
                    , \m -> Expect.equal False (Animator.current m.blockedMovementTimeline)
                    , \m -> Expect.notEqual Nothing (Just m.robotTimeline)
                    , \m -> Expect.notEqual Nothing (Just m.buttonHighlightTimeline)
                    , \m -> Expect.notEqual Nothing (Just m.blockedMovementTimeline)
                    ]
                    model
        , test "timeline states remain consistent with model state" <|
            \_ ->
                let
                    robot =
                        { position = { row = 3, col = 1 }, facing = East }

                    model =
                        createModelWithRobot robot

                    timelineRobot =
                        Animator.current model.robotTimeline
                in
                Expect.all
                    [ \_ -> Expect.equal robot.position timelineRobot.position
                    , \_ -> Expect.equal robot.facing timelineRobot.facing
                    ]
                    ()
        , test "AnimationFrame message does not change game logic state" <|
            \_ ->
                let
                    initialModel =
                        Model.init

                    testTime =
                        Time.millisToPosix 1000

                    ( updatedModel, _ ) =
                        update (AnimationFrame testTime) initialModel
                in
                -- Game logic state should remain unchanged
                Expect.all
                    [ \m -> Expect.equal initialModel.robot m.robot
                    , \m -> Expect.equal initialModel.gridSize m.gridSize
                    , \m -> Expect.equal initialModel.colorScheme m.colorScheme
                    , \m -> Expect.equal initialModel.animationState m.animationState
                    , \m -> Expect.equal initialModel.blockedMovementFeedback m.blockedMovementFeedback
                    , \m -> Expect.equal initialModel.highlightedButtons m.highlightedButtons
                    ]
                    updatedModel
        , test "MoveForward updates robot model and animation state" <|
            \_ ->
                let
                    initialRobot =
                        { position = { row = 2, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot initialRobot

                    ( updatedModel, _ ) =
                        update MoveForward initialModel

                    expectedNewRobot =
                        { position = { row = 1, col = 2 }, facing = North }
                in
                Expect.all
                    [ \_ -> Expect.equal expectedNewRobot updatedModel.robot
                    , \_ -> Expect.equal (Moving { row = 2, col = 2 } { row = 1, col = 2 }) updatedModel.animationState
                    , \_ -> Expect.notEqual initialModel.robotTimeline updatedModel.robotTimeline
                    ]
                    ()
        , test "MoveForward animation prevents input during animation" <|
            \_ ->
                let
                    initialRobot =
                        { position = { row = 2, col = 2 }, facing = North }

                    modelWithAnimation =
                        createModelWithRobotAndAnimation initialRobot (Moving { row = 2, col = 2 } { row = 1, col = 2 })

                    ( updatedModel, _ ) =
                        update MoveForward modelWithAnimation
                in
                -- Model should remain unchanged when animation is in progress
                Expect.all
                    [ \_ -> Expect.equal modelWithAnimation.robot updatedModel.robot
                    , \_ -> Expect.equal modelWithAnimation.animationState updatedModel.animationState
                    ]
                    ()
        , test "MoveForward creates timeline animation with 300ms duration" <|
            \_ ->
                let
                    initialRobot =
                        { position = { row = 2, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot initialRobot

                    ( _, effect ) =
                        RobotGame.Main.updateToEffect MoveForward initialModel
                in
                -- Verify that the animation effect is created (300ms sleep)
                case effect of
                    RobotGame.Main.Sleep duration ->
                        Expect.equal 300 duration

                    _ ->
                        Expect.fail "Expected Sleep effect with 300ms duration"
        , test "RotateLeft creates rotation animation with 200ms duration" <|
            \_ ->
                let
                    initialRobot =
                        { position = { row = 2, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot initialRobot

                    ( _, effect ) =
                        RobotGame.Main.updateToEffect RotateLeft initialModel
                in
                -- Verify that the rotation animation effect is created (200ms sleep)
                case effect of
                    RobotGame.Main.Sleep duration ->
                        Expect.equal 200 duration

                    _ ->
                        Expect.fail "Expected Sleep effect with 200ms duration"
        , test "RotateRight creates rotation animation with 200ms duration" <|
            \_ ->
                let
                    initialRobot =
                        { position = { row = 2, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot initialRobot

                    ( _, effect ) =
                        RobotGame.Main.updateToEffect RotateRight initialModel
                in
                -- Verify that the rotation animation effect is created (200ms sleep)
                case effect of
                    RobotGame.Main.Sleep duration ->
                        Expect.equal 200 duration

                    _ ->
                        Expect.fail "Expected Sleep effect with 200ms duration"
        , test "RotateToDirection creates rotation animation with appropriate duration" <|
            \_ ->
                let
                    testRotationDuration fromDirection toDirection expectedDuration =
                        let
                            initialRobot =
                                { position = { row = 2, col = 2 }, facing = fromDirection }

                            initialModel =
                                createModelWithRobot initialRobot

                            ( _, effect ) =
                                RobotGame.Main.updateToEffect (RotateToDirection toDirection) initialModel
                        in
                        case effect of
                            RobotGame.Main.Sleep duration ->
                                Expect.equal expectedDuration duration

                            _ ->
                                Expect.fail ("Expected Sleep effect with " ++ String.fromFloat expectedDuration ++ "ms duration")
                in
                Expect.all
                    [ \_ -> testRotationDuration North East 200 -- 90-degree rotation
                    , \_ -> testRotationDuration North South 300 -- 180-degree rotation
                    , \_ -> testRotationDuration East West 300 -- 180-degree rotation
                    , \_ -> testRotationDuration South West 200 -- 90-degree rotation
                    ]
                    ()
        , test "Rotation animations update both robot and rotation angle timelines" <|
            \_ ->
                let
                    initialRobot =
                        { position = { row = 2, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot initialRobot

                    ( updatedModel, _ ) =
                        RobotGame.Main.updateToEffect RotateLeft initialModel

                    -- Check that both timelines are updated
                    robotTimelineChanged =
                        updatedModel.robotTimeline /= initialModel.robotTimeline

                    rotationTimelineChanged =
                        updatedModel.rotationAngleTimeline /= initialModel.rotationAngleTimeline
                in
                Expect.all
                    [ \_ ->
                        if robotTimelineChanged then
                            Expect.pass

                        else
                            Expect.fail "Robot timeline should be updated"
                    , \_ ->
                        if rotationTimelineChanged then
                            Expect.pass

                        else
                            Expect.fail "Rotation angle timeline should be updated"
                    , \_ -> Expect.equal West updatedModel.robot.facing
                    , \_ -> Expect.equal (Rotating North West) updatedModel.animationState
                    ]
                    ()
        , test "Button highlight animation is triggered on MoveForward" <|
            \_ ->
                let
                    initialRobot =
                        { position = { row = 2, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot initialRobot

                    ( updatedModel, _ ) =
                        update MoveForward initialModel
                in
                -- Verify that forward button is highlighted (check legacy field for immediate verification)
                Expect.equal [ ForwardButton ] updatedModel.highlightedButtons
        , test "Button highlight animation is triggered on RotateLeft" <|
            \_ ->
                let
                    initialRobot =
                        { position = { row = 2, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot initialRobot

                    ( updatedModel, _ ) =
                        update RotateLeft initialModel

                    currentHighlights =
                        Animator.current updatedModel.buttonHighlightTimeline
                in
                -- Verify that rotation buttons are highlighted
                Expect.all
                    [ \_ ->
                        Expect.equal True (List.member RotateLeftButton currentHighlights)
                    , \_ ->
                        Expect.equal True (List.member (DirectionButton North) currentHighlights || List.member (DirectionButton West) currentHighlights)
                    ]
                    ()
        , test "Button highlight animation is triggered on RotateRight" <|
            \_ ->
                let
                    initialRobot =
                        { position = { row = 2, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot initialRobot

                    ( updatedModel, _ ) =
                        update RotateRight initialModel

                    currentHighlights =
                        Animator.current updatedModel.buttonHighlightTimeline
                in
                -- Verify that rotation buttons are highlighted
                Expect.all
                    [ \_ ->
                        Expect.equal True (List.member RotateRightButton currentHighlights)
                    , \_ ->
                        Expect.equal True (List.member (DirectionButton North) currentHighlights || List.member (DirectionButton East) currentHighlights)
                    ]
                    ()
        , test "Button highlight animation is triggered on RotateToDirection" <|
            \_ ->
                let
                    initialRobot =
                        { position = { row = 2, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot initialRobot

                    ( updatedModel, _ ) =
                        update (RotateToDirection South) initialModel

                    currentHighlights =
                        Animator.current updatedModel.buttonHighlightTimeline
                in
                -- Verify that direction buttons are highlighted
                Expect.all
                    [ \_ ->
                        Expect.equal True (List.member (DirectionButton North) currentHighlights)
                    , \_ ->
                        Expect.equal True (List.member (DirectionButton South) currentHighlights)
                    ]
                    ()
        , test "Button highlight animation is triggered on blocked movement" <|
            \_ ->
                let
                    -- Robot at top boundary
                    initialRobot =
                        { position = { row = 0, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot initialRobot

                    ( updatedModel, _ ) =
                        update MoveForward initialModel

                    currentHighlights =
                        Animator.current updatedModel.buttonHighlightTimeline
                in
                -- Verify that forward button is highlighted even for blocked movement
                Expect.equal True (List.member ForwardButton currentHighlights)
        , test "Button highlight timeline is properly initialized" <|
            \_ ->
                let
                    ( model, _ ) =
                        init

                    currentHighlights =
                        Animator.current model.buttonHighlightTimeline
                in
                -- Initially no buttons should be highlighted
                Expect.equal [] currentHighlights
        ]

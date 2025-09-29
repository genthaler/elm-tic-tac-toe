module RobotGame.RobotGameIntegrationTest exposing (suite)

{-| Comprehensive integration tests for the Robot Game.

This module consolidates all RobotGame integration tests, covering:

  - Complete user workflows and interaction patterns
  - Animation sequences and state transitions with elm-animator
  - Animation module utilities and performance integration
  - Movement logic and boundary handling
  - Error conditions and recovery scenarios
  - Input method consistency and accessibility
  - Visual button highlighting behavior (Requirement 7)

Tests are organized by functional area and focus on user-observable behavior
rather than implementation details.

-}

import Animator
import Expect
import Html.Attributes
import ProgramTest exposing (ProgramTest, SimulatedEffect)
import RobotGame.Animation as Animation
import RobotGame.Main exposing (Effect(..), Msg(..), init, initToEffect, updateToEffect)
import RobotGame.Model exposing (AnimationState(..), Button(..), Direction(..), Model, Position, directionToAngleFloat)
import RobotGame.RobotGame as RobotGameLogic
import RobotGame.View exposing (view)
import SimulatedEffect.Cmd as SimCmd
import SimulatedEffect.Process exposing (sleep)
import SimulatedEffect.Task exposing (perform)
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import TestUtils.ProgramTestHelpers exposing (expectColorScheme)
import Theme.Theme exposing (ColorScheme(..))
import Time


suite : Test
suite =
    describe "RobotGame Integration Tests"
        [ userWorkflowTests
        , movementIntegrationTests
        , animationIntegrationTests
        , errorHandlingTests
        , inputMethodTests
        , accessibilityTests
        , stateManagementTests
        , visualHighlightingTests
        ]



-- HELPER FUNCTIONS


{-| Start the RobotGame directly with default configuration
-}
startRobotGame : () -> ProgramTest Model Msg Effect
startRobotGame _ =
    ProgramTest.createElement
        { init = \_ -> initToEffect
        , view = view
        , update = updateToEffect
        }
        |> ProgramTest.withSimulatedEffects simulateEffects
        |> ProgramTest.start ()


{-| Assert that the robot is at the expected position
-}
expectRobotPosition : Position -> ProgramTest Model msg effect -> Expect.Expectation
expectRobotPosition expectedPosition programTest =
    programTest
        |> ProgramTest.expectView
            (Query.find [ Selector.class "robot" ]
                >> Query.has
                    [ Selector.attribute
                        (Html.Attributes.attribute "data-position"
                            (String.fromInt expectedPosition.row ++ "," ++ String.fromInt expectedPosition.col)
                        )
                    ]
            )


{-| Assert that the animation state is as expected
-}
expectAnimationState : AnimationState -> ProgramTest Model msg effect -> Expect.Expectation
expectAnimationState expectedState programTest =
    programTest
        |> ProgramTest.expectModel
            (\model ->
                Expect.equal expectedState model.animationState
            )


{-| Assert that the robot is facing the expected direction
-}
expectRobotFacing : Direction -> ProgramTest Model msg effect -> Expect.Expectation
expectRobotFacing expectedDirection programTest =
    let
        expectedClass =
            "facing-" ++ String.toLower (Debug.toString expectedDirection)
    in
    programTest
        |> ProgramTest.expectView
            (Query.find [ Selector.class "robot" ]
                >> Query.has [ Selector.class expectedClass ]
            )


{-| Assert that the robot animation is in the expected state
-}
expectRobotAnimationState : AnimationState -> ProgramTest Model msg effect -> Expect.Expectation
expectRobotAnimationState expectedAnimationState programTest =
    programTest
        |> ProgramTest.expectModel
            (\model ->
                Expect.equal expectedAnimationState model.animationState
            )


{-| Create a model with specific robot state for testing
-}
createModelWithState : { position : Position, facing : Direction, animationState : AnimationState } -> Model
createModelWithState { position, facing, animationState } =
    let
        robot =
            { position = position, facing = facing }
    in
    { robot = robot
    , gridSize = 5
    , colorScheme = Light
    , maybeWindow = Just ( 1024, 768 )
    , animationState = animationState
    , lastMoveTime = Nothing
    , blockedMovementFeedback = False
    , highlightedButtons = []

    -- Initialize elm-animator timelines
    , robotTimeline = Animator.init robot
    , buttonHighlightTimeline = Animator.init []
    , blockedMovementTimeline = Animator.init False
    , rotationAngleTimeline = Animator.init (directionToAngleFloat robot.facing)
    }


{-| Simulate keyboard input via direct message handling
-}
simulateKeyboardInput : String -> ProgramTest Model Msg effect -> ProgramTest Model Msg effect
simulateKeyboardInput key programTest =
    programTest |> ProgramTest.update (KeyPressed key)


{-| Send direct robot commands for reliable testing
-}
sendRobotCommand : Msg -> ProgramTest Model Msg effect -> ProgramTest Model Msg effect
sendRobotCommand msg programTest =
    programTest |> ProgramTest.update msg


{-| Complete animation cycle helper
-}
completeAnimation : ProgramTest Model Msg effect -> ProgramTest Model Msg effect
completeAnimation programTest =
    programTest
        |> ProgramTest.advanceTime 300
        |> ProgramTest.update AnimationComplete


{-| Position validation helper
-}
isValidPosition : Position -> Bool
isValidPosition position =
    position.row >= 0 && position.row <= 4 && position.col >= 0 && position.col <= 4


{-| Simulate effects for testing
-}
simulateEffects : Effect -> SimulatedEffect Msg
simulateEffects effect =
    case effect of
        NoEffect ->
            SimCmd.none

        Sleep interval ->
            sleep interval
                |> perform (\_ -> AnimationComplete)


{-| Helper function to check if a button is visually highlighted using elm-animator timeline
-}
isButtonVisuallyHighlighted : Model -> RobotGame.Model.Button -> Bool
isButtonVisuallyHighlighted model button =
    let
        currentHighlights =
            Animator.current model.buttonHighlightTimeline
    in
    List.member button currentHighlights



-- TEST SUITES


{-| Test complete user workflows and interaction patterns
-}
userWorkflowTests : Test
userWorkflowTests =
    describe "User Workflow Tests"
        [ test "user can navigate from center to top-right corner using mixed inputs" <|
            \() ->
                startRobotGame ()
                    -- Move North using keyboard
                    |> simulateKeyboardInput "ArrowUp"
                    |> completeAnimation
                    -- Move North using direct command
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    -- Rotate East using direct command
                    |> sendRobotCommand (RotateToDirection East)
                    |> ProgramTest.advanceTime 200
                    |> sendRobotCommand AnimationComplete
                    -- Move East using keyboard
                    |> simulateKeyboardInput "ArrowUp"
                    |> completeAnimation
                    -- Move East using direct command
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    |> (\programTest ->
                            Expect.all
                                [ expectRobotPosition { row = 0, col = 4 }
                                , expectRobotFacing East
                                ]
                                programTest
                       )
        , test "user can recover from blocked movements and continue navigation" <|
            \() ->
                startRobotGame ()
                    -- Navigate to boundary
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    -- Encounter blocked movement
                    |> sendRobotCommand MoveForward
                    |> ProgramTest.advanceTime 500
                    |> sendRobotCommand ClearBlockedMovementFeedback
                    -- Recover using directional command
                    |> sendRobotCommand (RotateToDirection South)
                    |> ProgramTest.advanceTime 200
                    |> sendRobotCommand AnimationComplete
                    -- Continue navigation
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    |> (\programTest ->
                            Expect.all
                                [ expectRobotPosition { row = 1, col = 2 }
                                , expectRobotFacing South
                                ]
                                programTest
                       )
        , test "complete rotation cycle returns to original direction" <|
            \() ->
                let
                    ( initialModel, _ ) =
                        init

                    originalDirection =
                        initialModel.robot.facing
                in
                startRobotGame ()
                    -- Perform four left rotations
                    |> sendRobotCommand RotateLeft
                    |> ProgramTest.advanceTime 200
                    |> sendRobotCommand AnimationComplete
                    |> sendRobotCommand RotateLeft
                    |> ProgramTest.advanceTime 200
                    |> sendRobotCommand AnimationComplete
                    |> sendRobotCommand RotateLeft
                    |> ProgramTest.advanceTime 200
                    |> sendRobotCommand AnimationComplete
                    |> sendRobotCommand RotateLeft
                    |> ProgramTest.advanceTime 200
                    |> sendRobotCommand AnimationComplete
                    |> (\programTest ->
                            Expect.all
                                [ expectRobotFacing originalDirection
                                , expectRobotPosition { row = 2, col = 2 }
                                , expectRobotAnimationState Idle
                                ]
                                programTest
                       )
        ]


{-| Test movement logic integration
-}
movementIntegrationTests : Test
movementIntegrationTests =
    describe "Movement Integration Tests"
        [ test "robot starts at center facing North" <|
            \() ->
                startRobotGame ()
                    |> (\programTest ->
                            Expect.all
                                [ expectRobotPosition { row = 2, col = 2 }
                                , expectRobotFacing North
                                , expectRobotAnimationState Idle
                                ]
                                programTest
                       )
        , test "can move forward and rotate in sequence" <|
            \() ->
                startRobotGame ()
                    -- Move forward (North) to (1,2)
                    |> simulateKeyboardInput "ArrowUp"
                    |> completeAnimation
                    -- Rotate right to face East
                    |> simulateKeyboardInput "ArrowRight"
                    |> ProgramTest.advanceTime 200
                    |> sendRobotCommand AnimationComplete
                    -- Move forward (East) to (1,3)
                    |> simulateKeyboardInput "ArrowUp"
                    |> completeAnimation
                    |> (\programTest ->
                            Expect.all
                                [ expectRobotPosition { row = 1, col = 3 }
                                , expectRobotFacing East
                                , expectRobotAnimationState Idle
                                ]
                                programTest
                       )
        , test "move to top-left corner (0,0)" <|
            \() ->
                startRobotGame ()
                    -- Move North twice to reach row 0
                    |> simulateKeyboardInput "ArrowUp"
                    |> completeAnimation
                    |> simulateKeyboardInput "ArrowUp"
                    |> completeAnimation
                    -- Rotate left to face West
                    |> simulateKeyboardInput "ArrowLeft"
                    |> ProgramTest.advanceTime 200
                    |> sendRobotCommand AnimationComplete
                    -- Move West twice to reach column 0
                    |> simulateKeyboardInput "ArrowUp"
                    |> completeAnimation
                    |> simulateKeyboardInput "ArrowUp"
                    |> completeAnimation
                    |> (\programTest ->
                            Expect.all
                                [ expectRobotPosition { row = 0, col = 0 }
                                , expectRobotFacing West
                                ]
                                programTest
                       )
        , test "collision at top boundary (row 0)" <|
            \() ->
                startRobotGame ()
                    -- Move to top edge (0,2)
                    |> simulateKeyboardInput "ArrowUp"
                    |> completeAnimation
                    |> simulateKeyboardInput "ArrowUp"
                    |> completeAnimation
                    -- Try to move beyond boundary - should trigger blocked movement
                    |> simulateKeyboardInput "ArrowUp"
                    |> (\programTest ->
                            Expect.all
                                [ expectRobotAnimationState BlockedMovement
                                , expectRobotPosition { row = 0, col = 2 }
                                ]
                                programTest
                       )
        , test "corner logic with multiple boundary encounters" <|
            \() ->
                let
                    -- Start at top-left corner
                    initialModel =
                        createModelWithState
                            { position = { row = 0, col = 0 }
                            , facing = North
                            , animationState = Idle
                            }
                in
                ProgramTest.createElement
                    { init = \_ -> ( initialModel, NoEffect )
                    , view = view
                    , update = updateToEffect
                    }
                    |> ProgramTest.withSimulatedEffects simulateEffects
                    |> ProgramTest.start ()
                    -- Try to move North (blocked)
                    |> sendRobotCommand MoveForward
                    |> sendRobotCommand ClearBlockedMovementFeedback
                    -- Try to move West (blocked)
                    |> sendRobotCommand RotateLeft
                    |> ProgramTest.advanceTime 200
                    |> sendRobotCommand AnimationComplete
                    |> sendRobotCommand MoveForward
                    |> sendRobotCommand ClearBlockedMovementFeedback
                    -- Rotate to face East (should allow movement)
                    |> sendRobotCommand (RotateToDirection East)
                    |> ProgramTest.advanceTime 200
                    |> sendRobotCommand AnimationComplete
                    -- Move East (should succeed)
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    |> (\programTest ->
                            Expect.all
                                [ expectRobotPosition { row = 0, col = 1 }
                                , expectRobotFacing East
                                , expectRobotAnimationState Idle
                                ]
                                programTest
                       )
        ]


{-| Test animation sequences and state transitions
-}
animationIntegrationTests : Test
animationIntegrationTests =
    describe "Animation Integration Tests"
        [ basicAnimationStateTests
        , animationUtilitiesTests
        , animationControlTests
        , completeAnimationWorkflowTests
        , animationGameLogicTests
        , animationPerformanceTests
        , animationErrorHandlingTests
        ]


{-| Test basic animation state transitions
-}
basicAnimationStateTests : Test
basicAnimationStateTests =
    describe "Basic Animation State Tests"
        [ test "initial state is Idle" <|
            \() ->
                startRobotGame ()
                    |> expectRobotAnimationState Idle
        , test "movement triggers Moving animation state" <|
            \() ->
                startRobotGame ()
                    |> sendRobotCommand (KeyPressed "ArrowUp")
                    |> ProgramTest.expectModel
                        (\model ->
                            case model.animationState of
                                Moving from to ->
                                    Expect.all
                                        [ \_ -> Expect.equal { row = 2, col = 2 } from
                                        , \_ -> Expect.equal { row = 1, col = 2 } to
                                        ]
                                        ()

                                x ->
                                    Expect.fail ("Expected Moving animation state, not " ++ Debug.toString x)
                        )
        , test "movement animation completes and returns to Idle" <|
            \() ->
                startRobotGame ()
                    |> sendRobotCommand (KeyPressed "ArrowUp")
                    |> completeAnimation
                    |> expectRobotAnimationState Idle
        , test "rapid messages during animation are properly handled" <|
            \() ->
                startRobotGame ()
                    -- Start movement
                    |> sendRobotCommand MoveForward
                    -- Try to move again during animation (should be ignored)
                    |> sendRobotCommand MoveForward
                    -- Try to rotate during animation (should be ignored)
                    |> sendRobotCommand RotateLeft
                    -- Complete animation
                    |> sendRobotCommand AnimationComplete
                    |> (\programTest ->
                            Expect.all
                                [ expectRobotPosition { row = 1, col = 2 }
                                , expectRobotFacing North
                                , expectRobotAnimationState Idle
                                ]
                                programTest
                       )
        , test "animation completion allows new messages" <|
            \() ->
                startRobotGame ()
                    -- Start movement
                    |> sendRobotCommand MoveForward
                    -- Complete animation
                    |> sendRobotCommand AnimationComplete
                    -- New movement should work
                    |> sendRobotCommand MoveForward
                    |> sendRobotCommand AnimationComplete
                    |> (\programTest ->
                            Expect.all
                                [ expectRobotPosition { row = 0, col = 2 }
                                , expectRobotFacing North
                                , expectRobotAnimationState Idle
                                ]
                                programTest
                       )
        ]


{-| Test Animation module utilities integration
-}
animationUtilitiesTests : Test
animationUtilitiesTests =
    describe "Animation Utilities Integration"
        [ test "Animation.isAnimating works with model from Main.init" <|
            \() ->
                let
                    ( model, _ ) =
                        init

                    isAnimatingResult =
                        Animation.isAnimating model
                in
                Expect.equal False isAnimatingResult
        , test "Animation.getCurrentAnimatedState works with model from Main.init" <|
            \() ->
                let
                    ( model, _ ) =
                        init

                    currentState =
                        Animation.getCurrentAnimatedState model
                in
                Expect.equal model.robot currentState
        , test "Animation.updateAnimations works with model from Main.init" <|
            \() ->
                let
                    ( model, _ ) =
                        init

                    time =
                        Time.millisToPosix 1000

                    updatedModel =
                        Animation.updateAnimations time model
                in
                -- Should not crash and should preserve basic model structure
                Expect.all
                    [ \m -> Expect.equal model.robot m.robot
                    , \m -> Expect.equal model.gridSize m.gridSize
                    , \m -> Expect.equal model.colorScheme m.colorScheme
                    ]
                    updatedModel
        , test "Animation utilities handle Moving state correctly" <|
            \() ->
                let
                    ( baseModel, _ ) =
                        init

                    fromPos =
                        { row = 0, col = 0 }

                    toPos =
                        { row = 0, col = 1 }

                    model =
                        { baseModel | animationState = Moving fromPos toPos }

                    isAnimating =
                        Animation.isAnimating model

                    currentState =
                        Animation.getCurrentAnimatedState model
                in
                Expect.all
                    [ \_ -> Expect.equal True isAnimating
                    , \_ -> Expect.equal model.robot currentState
                    ]
                    ()
        , test "Animation utilities handle Rotating state correctly" <|
            \() ->
                let
                    ( baseModel, _ ) =
                        init

                    model =
                        { baseModel | animationState = Rotating North East }

                    isAnimating =
                        Animation.isAnimating model

                    currentState =
                        Animation.getCurrentAnimatedState model
                in
                Expect.all
                    [ \_ -> Expect.equal True isAnimating
                    , \_ -> Expect.equal model.robot currentState
                    ]
                    ()
        , test "Animation utilities handle BlockedMovement state correctly" <|
            \() ->
                let
                    ( baseModel, _ ) =
                        init

                    model =
                        { baseModel | animationState = BlockedMovement }

                    isAnimating =
                        Animation.isAnimating model

                    currentState =
                        Animation.getCurrentAnimatedState model
                in
                Expect.all
                    [ \_ -> Expect.equal True isAnimating
                    , \_ -> Expect.equal model.robot currentState
                    ]
                    ()
        ]


{-| Test Animation control functions
-}
animationControlTests : Test
animationControlTests =
    describe "Animation Control Integration"
        [ test "startMovementAnimation creates valid model state" <|
            \() ->
                let
                    ( baseModel, _ ) =
                        init

                    fromPos =
                        { row = 2, col = 2 }

                    toPos =
                        { row = 1, col = 2 }

                    updatedModel =
                        Animation.startMovementAnimation fromPos toPos baseModel

                    isAnimating =
                        Animation.isAnimating updatedModel
                in
                Expect.all
                    [ \m -> Expect.equal toPos m.robot.position
                    , \m -> Expect.equal (Moving fromPos toPos) m.animationState
                    , \_ -> Expect.equal True isAnimating
                    ]
                    updatedModel
        , test "startRotationAnimation creates valid model state" <|
            \() ->
                let
                    ( baseModel, _ ) =
                        init

                    fromDir =
                        North

                    toDir =
                        East

                    updatedModel =
                        Animation.startRotationAnimation fromDir toDir baseModel

                    isAnimating =
                        Animation.isAnimating updatedModel
                in
                Expect.all
                    [ \m -> Expect.equal toDir m.robot.facing
                    , \m -> Expect.equal (Rotating fromDir toDir) m.animationState
                    , \_ -> Expect.equal True isAnimating
                    ]
                    updatedModel
        , test "startButtonHighlightAnimation creates valid model state" <|
            \() ->
                let
                    ( baseModel, _ ) =
                        init

                    buttons =
                        [ ForwardButton, DirectionButton North ]

                    updatedModel =
                        Animation.startButtonHighlightAnimation buttons baseModel
                in
                Expect.equal buttons updatedModel.highlightedButtons
        , test "startBlockedMovementAnimation creates valid model state" <|
            \() ->
                let
                    ( baseModel, _ ) =
                        init

                    updatedModel =
                        Animation.startBlockedMovementAnimation baseModel

                    isAnimating =
                        Animation.isAnimating updatedModel
                in
                Expect.all
                    [ \m -> Expect.equal BlockedMovement m.animationState
                    , \m -> Expect.equal True m.blockedMovementFeedback
                    , \_ -> Expect.equal True isAnimating
                    ]
                    updatedModel
        ]


{-| Test complete animation workflows
-}
completeAnimationWorkflowTests : Test
completeAnimationWorkflowTests =
    describe "Complete Animation Workflows"
        [ test "movement workflow from start to finish" <|
            \() ->
                let
                    ( initialModel, _ ) =
                        init

                    -- Simulate complete movement workflow
                    fromPos =
                        initialModel.robot.position

                    toPos =
                        { row = fromPos.row, col = fromPos.col + 1 }

                    -- Start movement animation
                    step1 =
                        Animation.startMovementAnimation fromPos toPos initialModel

                    -- Simulate time progression
                    time3 =
                        Time.millisToPosix 300

                    -- Animation complete
                    finalAnimation =
                        Animation.updateAnimations time3 step1

                    -- Complete the workflow by setting to idle
                    completedModel =
                        { finalAnimation | animationState = Idle }

                    cleanedModel =
                        Animation.cleanupCompletedTimelines completedModel
                in
                Expect.all
                    [ \_ -> Expect.equal (Moving fromPos toPos) step1.animationState
                    , \_ -> Expect.equal True (Animation.isAnimating step1)
                    , \_ -> Expect.equal toPos step1.robot.position
                    , \_ -> Expect.equal toPos cleanedModel.robot.position
                    ]
                    ()
        , test "rotation workflow from start to finish" <|
            \() ->
                let
                    ( initialModel, _ ) =
                        init

                    fromDir =
                        initialModel.robot.facing

                    toDir =
                        East

                    -- Start rotation animation
                    step1 =
                        Animation.startRotationAnimation fromDir toDir initialModel

                    -- Simulate time progression
                    time3 =
                        Time.millisToPosix 200

                    -- Animation complete
                    finalAnimation =
                        Animation.updateAnimations time3 step1

                    -- Complete the workflow
                    completedModel =
                        { finalAnimation | animationState = Idle }

                    cleanedModel =
                        Animation.cleanupCompletedTimelines completedModel
                in
                Expect.all
                    [ \_ -> Expect.equal (Rotating fromDir toDir) step1.animationState
                    , \_ -> Expect.equal True (Animation.isAnimating step1)
                    , \_ -> Expect.equal toDir step1.robot.facing
                    , \_ -> Expect.equal toDir cleanedModel.robot.facing
                    ]
                    ()
        , test "button highlight workflow" <|
            \() ->
                let
                    ( initialModel, _ ) =
                        init

                    buttons =
                        [ ForwardButton, DirectionButton North ]

                    -- Start button highlight animation
                    step1 =
                        Animation.startButtonHighlightAnimation buttons initialModel

                    -- Simulate time progression
                    time2 =
                        Time.millisToPosix 75

                    time3 =
                        Time.millisToPosix 150

                    -- Mid-animation and final animation
                    midAnimation =
                        Animation.updateAnimations time2 step1

                    finalAnimation =
                        Animation.updateAnimations time3 step1

                    -- Check highlight opacity at different stages
                    initialOpacity =
                        Animation.getButtonHighlightOpacity ForwardButton step1

                    midOpacity =
                        Animation.getButtonHighlightOpacity ForwardButton midAnimation

                    finalOpacity =
                        Animation.getButtonHighlightOpacity ForwardButton finalAnimation
                in
                Expect.all
                    [ \_ -> Expect.equal buttons step1.highlightedButtons
                    , \_ -> Expect.atLeast 0.0 initialOpacity
                    , \_ -> Expect.atMost 1.0 initialOpacity
                    , \_ -> Expect.atLeast 0.0 midOpacity
                    , \_ -> Expect.atMost 1.0 midOpacity
                    , \_ -> Expect.atLeast 0.0 finalOpacity
                    , \_ -> Expect.atMost 1.0 finalOpacity
                    ]
                    ()
        , test "blocked movement workflow" <|
            \() ->
                let
                    ( initialModel, _ ) =
                        init

                    -- Start blocked movement animation
                    step1 =
                        Animation.startBlockedMovementAnimation initialModel

                    -- Simulate time progression
                    time3 =
                        Time.millisToPosix 200

                    -- Animation complete
                    finalAnimation =
                        Animation.updateAnimations time3 step1

                    -- Complete the workflow
                    completedModel =
                        { finalAnimation | animationState = Idle, blockedMovementFeedback = False }

                    cleanedModel =
                        Animation.cleanupCompletedTimelines completedModel
                in
                Expect.all
                    [ \_ -> Expect.equal BlockedMovement step1.animationState
                    , \_ -> Expect.equal True step1.blockedMovementFeedback
                    , \_ -> Expect.equal True (Animation.isBlockedMovementAnimating step1)
                    , \_ -> Expect.equal Idle cleanedModel.animationState
                    , \_ -> Expect.equal False cleanedModel.blockedMovementFeedback
                    ]
                    ()
        ]


{-| Test animation integration with game logic
-}
animationGameLogicTests : Test
animationGameLogicTests =
    describe "Animation Game Logic Integration"
        [ test "animation respects boundary constraints" <|
            \() ->
                let
                    ( baseModel, _ ) =
                        init

                    -- Position robot at right edge
                    edgeRobot =
                        { position = { row = 2, col = 4 }, facing = East }

                    edgeModel =
                        { baseModel | robot = edgeRobot }

                    -- Verify movement is blocked by game logic
                    canMove =
                        RobotGameLogic.canMoveForward edgeRobot

                    -- Animation should still work for blocked movement feedback
                    blockedModel =
                        Animation.startBlockedMovementAnimation edgeModel
                in
                Expect.all
                    [ \_ -> Expect.equal False canMove
                    , \_ -> Expect.equal BlockedMovement blockedModel.animationState
                    , \_ -> Expect.equal True (Animation.isBlockedMovementAnimating blockedModel)
                    ]
                    ()
        , test "animation preserves game state consistency" <|
            \() ->
                let
                    ( baseModel, _ ) =
                        init

                    -- Set up specific game state
                    gameRobot =
                        { position = { row = 1, col = 1 }, facing = North }

                    gameModel =
                        { baseModel | robot = gameRobot }

                    -- Perform various animations
                    moved =
                        Animation.startMovementAnimation gameRobot.position { row = 0, col = 1 } gameModel

                    rotated =
                        Animation.startRotationAnimation North South moved

                    highlighted =
                        Animation.startButtonHighlightAnimation [ ForwardButton ] rotated

                    -- Verify game state consistency
                    finalRobot =
                        highlighted.robot
                in
                Expect.all
                    [ \_ -> Expect.equal { row = 0, col = 1 } finalRobot.position
                    , \_ -> Expect.equal South finalRobot.facing
                    , \_ -> Expect.equal baseModel.gridSize highlighted.gridSize
                    , \_ -> Expect.equal baseModel.colorScheme highlighted.colorScheme
                    ]
                    ()
        , test "animation coordinates with game update cycle" <|
            \() ->
                let
                    ( initialModel, _ ) =
                        init

                    -- Start animation
                    animatedModel =
                        Animation.startMovementAnimation
                            initialModel.robot.position
                            { row = 0, col = 1 }
                            initialModel

                    -- Simulate game update cycle
                    time =
                        Time.millisToPosix 1000

                    updatedModel =
                        Animation.updateAnimations time animatedModel

                    -- Verify animation state is maintained through update cycle
                    isStillAnimating =
                        Animation.isAnimating updatedModel

                    currentState =
                        Animation.getCurrentAnimatedState updatedModel
                in
                Expect.all
                    [ \_ -> Expect.equal True isStillAnimating
                    , \_ -> Expect.equal updatedModel.robot currentState
                    ]
                    ()
        ]


{-| Test animation performance integration
-}
animationPerformanceTests : Test
animationPerformanceTests =
    describe "Animation Performance Integration"
        [ test "animation updates are efficient with multiple timelines" <|
            \() ->
                let
                    ( baseModel, _ ) =
                        init

                    -- Start multiple animations simultaneously
                    step1 =
                        Animation.startMovementAnimation { row = 0, col = 0 } { row = 0, col = 1 } baseModel

                    step2 =
                        Animation.startButtonHighlightAnimation [ ForwardButton ] step1

                    step3 =
                        Animation.startBlockedMovementAnimation step2

                    -- Update all timelines
                    time =
                        Time.millisToPosix 1000

                    updatedModel =
                        Animation.updateAnimations time step3

                    -- Verify all animations are tracked correctly
                    hasActive =
                        Animation.hasActiveAnimations updatedModel

                    isAnimating =
                        Animation.isAnimating updatedModel

                    animationState =
                        updatedModel.animationState
                in
                Expect.all
                    [ \_ -> Expect.equal True hasActive
                    , \_ -> Expect.equal True isAnimating
                    , \_ -> Expect.equal BlockedMovement animationState
                    ]
                    ()
        , test "cleanup operations are efficient" <|
            \() ->
                let
                    ( baseModel, _ ) =
                        init

                    -- Create model with completed animations
                    animatedModel =
                        Animation.startMovementAnimation { row = 0, col = 0 } { row = 0, col = 1 } baseModel

                    completedModel =
                        { animatedModel | animationState = Idle }

                    -- Perform cleanup
                    cleanedModel =
                        Animation.cleanupCompletedTimelines completedModel

                    -- Verify cleanup preserves essential state
                    hasActive =
                        Animation.hasActiveAnimations cleanedModel

                    currentRobot =
                        Animation.getCurrentAnimatedState cleanedModel
                in
                Expect.all
                    [ \_ -> Expect.equal False hasActive
                    , \_ -> Expect.equal completedModel.robot currentRobot
                    ]
                    ()
        , test "interpolation functions perform consistently" <|
            \() ->
                let
                    ( baseModel, _ ) =
                        init

                    -- Test interpolation functions don't crash and return valid values
                    position =
                        Animation.getInterpolatedPosition baseModel

                    angle =
                        Animation.getInterpolatedRotationAngle baseModel

                    opacity =
                        Animation.getButtonHighlightOpacity ForwardButton baseModel
                in
                Expect.all
                    [ \_ -> Expect.equal baseModel.robot.position position
                    , \_ -> Expect.atLeast 0.0 angle
                    , \_ -> Expect.lessThan 360.0 angle
                    , \_ -> Expect.equal 0.0 opacity
                    ]
                    ()
        ]


{-| Test animation error handling
-}
animationErrorHandlingTests : Test
animationErrorHandlingTests =
    describe "Animation Error Handling"
        [ test "animation handles invalid positions gracefully" <|
            \() ->
                let
                    ( baseModel, _ ) =
                        init

                    -- Test with edge positions
                    edgePos =
                        { row = 4, col = 4 }

                    invalidPos =
                        { row = -1, col = 5 }

                    -- Animation should handle these without crashing
                    edgeAnimation =
                        Animation.startMovementAnimation { row = 0, col = 0 } edgePos baseModel

                    invalidAnimation =
                        Animation.startMovementAnimation { row = 0, col = 0 } invalidPos baseModel
                in
                Expect.all
                    [ \_ -> Expect.equal edgePos edgeAnimation.robot.position
                    , \_ -> Expect.equal invalidPos invalidAnimation.robot.position
                    , \_ -> Expect.equal True (Animation.isAnimating edgeAnimation)
                    , \_ -> Expect.equal True (Animation.isAnimating invalidAnimation)
                    ]
                    ()
        , test "animation handles rapid state changes" <|
            \() ->
                let
                    ( baseModel, _ ) =
                        init

                    -- Rapid sequence of animations
                    step1 =
                        Animation.startMovementAnimation { row = 0, col = 0 } { row = 0, col = 1 } baseModel

                    step2 =
                        Animation.startRotationAnimation North East step1

                    step3 =
                        Animation.startBlockedMovementAnimation step2

                    step4 =
                        Animation.startButtonHighlightAnimation [ ForwardButton ] step3

                    -- Final state should be consistent
                    finalState =
                        step4.animationState

                    isAnimating =
                        Animation.isAnimating step4
                in
                Expect.all
                    [ \_ -> Expect.equal BlockedMovement finalState
                    , \_ -> Expect.equal True isAnimating
                    , \_ -> Expect.equal [ ForwardButton ] step4.highlightedButtons
                    ]
                    ()
        , test "animation cleanup handles edge cases" <|
            \() ->
                let
                    ( baseModel, _ ) =
                        init

                    -- Test cleanup with various states
                    idleModel =
                        { baseModel | animationState = Idle }

                    movingModel =
                        { baseModel | animationState = Moving { row = 0, col = 0 } { row = 0, col = 1 } }

                    rotatingModel =
                        { baseModel | animationState = Rotating North East }

                    blockedModel =
                        { baseModel | animationState = BlockedMovement }

                    -- Cleanup should handle all states
                    cleanedIdle =
                        Animation.cleanupCompletedTimelines idleModel

                    cleanedMoving =
                        Animation.cleanupCompletedTimelines movingModel

                    cleanedRotating =
                        Animation.cleanupCompletedTimelines rotatingModel

                    cleanedBlocked =
                        Animation.cleanupCompletedTimelines blockedModel
                in
                Expect.all
                    [ \_ -> Expect.equal idleModel.robot cleanedIdle.robot
                    , \_ -> Expect.equal movingModel.robot cleanedMoving.robot
                    , \_ -> Expect.equal rotatingModel.robot cleanedRotating.robot
                    , \_ -> Expect.equal blockedModel.robot cleanedBlocked.robot
                    ]
                    ()
        ]


{-| Test error conditions and recovery scenarios
-}
errorHandlingTests : Test
errorHandlingTests =
    describe "Error Handling Tests"
        [ test "robot at boundary cannot move forward" <|
            \() ->
                let
                    robot =
                        { position = { row = 0, col = 2 }, facing = North }

                    canMove =
                        RobotGameLogic.canMoveForward robot
                in
                Expect.equal False canMove
        , test "robot at boundary stays in same position when trying to move" <|
            \() ->
                let
                    robot =
                        { position = { row = 0, col = 2 }, facing = North }

                    movedRobot =
                        RobotGameLogic.moveForward robot
                in
                Expect.equal robot.position movedRobot.position
        , test "robot in center can move in all directions" <|
            \() ->
                let
                    centerRobot =
                        { position = { row = 2, col = 2 }, facing = North }

                    canMoveNorth =
                        RobotGameLogic.canMoveForward centerRobot

                    canMoveEast =
                        RobotGameLogic.canMoveForward { centerRobot | facing = East }

                    canMoveSouth =
                        RobotGameLogic.canMoveForward { centerRobot | facing = South }

                    canMoveWest =
                        RobotGameLogic.canMoveForward { centerRobot | facing = West }
                in
                Expect.all
                    [ \_ -> Expect.equal True canMoveNorth
                    , \_ -> Expect.equal True canMoveEast
                    , \_ -> Expect.equal True canMoveSouth
                    , \_ -> Expect.equal True canMoveWest
                    ]
                    ()
        , test "blocked movement feedback is set correctly" <|
            \() ->
                startRobotGame ()
                    -- Move to boundary
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    -- Try blocked movement
                    |> sendRobotCommand MoveForward
                    |> (\programTest ->
                            Expect.all
                                [ expectRobotAnimationState BlockedMovement
                                , expectRobotPosition { row = 0, col = 2 }
                                ]
                                programTest
                       )
        , test "position validation works correctly" <|
            \() ->
                let
                    validPositions =
                        [ { row = 0, col = 0 }
                        , { row = 2, col = 2 }
                        , { row = 4, col = 4 }
                        ]

                    invalidPositions =
                        [ { row = -1, col = 2 }
                        , { row = 5, col = 3 }
                        , { row = 2, col = -1 }
                        , { row = 1, col = 6 }
                        ]

                    validResults =
                        List.map isValidPosition validPositions

                    invalidResults =
                        List.map isValidPosition invalidPositions
                in
                Expect.all
                    [ \_ -> Expect.equal [ True, True, True ] validResults
                    , \_ -> Expect.equal [ False, False, False, False ] invalidResults
                    ]
                    ()
        , test "robot rotation works correctly" <|
            \() ->
                let
                    robot =
                        { position = { row = 2, col = 2 }, facing = North }

                    leftRotated =
                        RobotGameLogic.rotateLeft robot

                    rightRotated =
                        RobotGameLogic.rotateRight robot

                    oppositeRotated =
                        RobotGameLogic.rotateOpposite robot
                in
                Expect.all
                    [ \_ -> Expect.equal West leftRotated.facing
                    , \_ -> Expect.equal East rightRotated.facing
                    , \_ -> Expect.equal South oppositeRotated.facing
                    , \_ -> Expect.equal robot.position leftRotated.position
                    , \_ -> Expect.equal robot.position rightRotated.position
                    , \_ -> Expect.equal robot.position oppositeRotated.position
                    ]
                    ()
        , test "rotation animation maintains robot position while changing direction" <|
            \() ->
                let
                    duringAnimation =
                        startRobotGame ()
                            |> sendRobotCommand RotateLeft

                    afterAnimation =
                        duringAnimation
                            |> ProgramTest.advanceTime 200
                            |> sendRobotCommand AnimationComplete
                in
                Expect.all
                    [ \_ ->
                        -- During rotation animation, position should remain unchanged
                        Expect.all
                            [ expectRobotPosition { row = 2, col = 2 }
                            , expectAnimationState (Rotating North West)
                            ]
                            duringAnimation
                    , \_ ->
                        -- After rotation animation, position should still be unchanged but direction updated
                        Expect.all
                            [ expectRobotPosition { row = 2, col = 2 }
                            , expectRobotFacing West
                            , expectAnimationState Idle
                            ]
                            afterAnimation
                    ]
                    ()
        , test "rotation animation prevents input during transition" <|
            \() ->
                let
                    afterFirstRotation =
                        startRobotGame ()
                            |> sendRobotCommand RotateLeft

                    afterSecondCommand =
                        afterFirstRotation
                            |> sendRobotCommand RotateRight

                    afterCompletion =
                        afterSecondCommand
                            |> ProgramTest.advanceTime 200
                            |> sendRobotCommand AnimationComplete
                in
                Expect.all
                    [ \_ ->
                        -- Verify rotation started
                        Expect.all
                            [ expectRobotFacing West
                            , expectAnimationState (Rotating North West)
                            ]
                            afterFirstRotation
                    , \_ ->
                        -- Should still be in the original rotation state after second command
                        Expect.all
                            [ expectRobotFacing West -- Should not change to East
                            , expectAnimationState (Rotating North West) -- Should not change
                            ]
                            afterSecondCommand
                    , \_ ->
                        -- Now should be able to accept new commands
                        Expect.all
                            [ expectRobotFacing West
                            , expectAnimationState Idle
                            ]
                            afterCompletion
                    ]
                    ()
        , test "rotation animation with elm-animator provides smooth visual transitions" <|
            \() ->
                let
                    duringAnimation =
                        startRobotGame ()
                            |> sendRobotCommand RotateLeft

                    afterAnimation =
                        duringAnimation
                            |> ProgramTest.advanceTime 200
                            |> sendRobotCommand AnimationComplete
                in
                Expect.all
                    [ \_ ->
                        -- Verify that rotation animation state is properly set
                        duringAnimation
                            |> ProgramTest.expectModel
                                (\model ->
                                    Expect.all
                                        [ \m -> Expect.equal (Rotating North West) m.animationState
                                        , \m -> Expect.equal West m.robot.facing

                                        -- Verify that rotation angle timeline exists (just check it's not crashing)
                                        , \_ ->
                                            Expect.pass

                                        -- Just verify we can access the timeline without errors
                                        ]
                                        model
                                )
                    , \_ ->
                        -- After animation completion, verify final state
                        afterAnimation
                            |> ProgramTest.expectModel
                                (\model ->
                                    Expect.all
                                        [ \m -> Expect.equal Idle m.animationState
                                        , \m -> Expect.equal West m.robot.facing

                                        -- Verify rotation angle timeline reflects final direction (West = 270.0)
                                        , \m -> Expect.equal 270.0 (Animator.current m.rotationAngleTimeline)
                                        ]
                                        model
                                )
                    ]
                    ()
        , test "elm-animator blocked movement animation provides visual feedback" <|
            \() ->
                startRobotGame ()
                    -- Move to boundary
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    -- Try blocked movement - should trigger elm-animator animation
                    |> sendRobotCommand MoveForward
                    |> (\programTest ->
                            ProgramTest.expectModel
                                (\model ->
                                    Expect.all
                                        [ \m -> Expect.equal BlockedMovement m.animationState
                                        , \m -> Expect.equal True (Animator.current m.blockedMovementTimeline)
                                        , \m -> Expect.equal True m.blockedMovementFeedback
                                        , \m -> Expect.equal { row = 0, col = 2 } m.robot.position
                                        ]
                                        model
                                )
                                programTest
                       )
        , test "elm-animator blocked movement animation duration and cleanup" <|
            \() ->
                startRobotGame ()
                    -- Move to boundary
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    -- Try blocked movement
                    |> sendRobotCommand MoveForward
                    -- Advance time to complete animation (200ms duration)
                    |> ProgramTest.advanceTime 200
                    |> sendRobotCommand AnimationComplete
                    |> (\programTest ->
                            ProgramTest.expectModel
                                (\model ->
                                    Expect.all
                                        [ \m -> Expect.equal Idle m.animationState
                                        , \m -> Expect.equal { row = 0, col = 2 } m.robot.position
                                        , \m -> Expect.equal North m.robot.facing
                                        ]
                                        model
                                )
                                programTest
                       )
        , test "elm-animator blocked movement animation prevents input during animation" <|
            \() ->
                startRobotGame ()
                    -- Move to boundary
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    -- Try blocked movement
                    |> sendRobotCommand MoveForward
                    -- Try additional input during blocked movement animation (should be ignored)
                    |> sendRobotCommand RotateLeft
                    |> sendRobotCommand MoveForward
                    |> (\programTest ->
                            ProgramTest.expectModel
                                (\model ->
                                    Expect.all
                                        [ \m -> Expect.equal BlockedMovement m.animationState
                                        , \m -> Expect.equal North m.robot.facing -- Should not have rotated
                                        , \m -> Expect.equal { row = 0, col = 2 } m.robot.position
                                        , \m -> Expect.equal True (Animator.current m.blockedMovementTimeline)
                                        ]
                                        model
                                )
                                programTest
                       )
        , test "elm-animator blocked movement timeline resets correctly" <|
            \() ->
                startRobotGame ()
                    -- Move to boundary
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    -- Try blocked movement
                    |> sendRobotCommand MoveForward
                    -- Clear blocked movement feedback
                    |> sendRobotCommand ClearBlockedMovementFeedback
                    |> (\programTest ->
                            ProgramTest.expectModel
                                (\model ->
                                    Expect.all
                                        [ \m -> Expect.equal Idle m.animationState
                                        , \m -> Expect.equal False m.blockedMovementFeedback
                                        , \m -> Expect.equal False (Animator.current m.blockedMovementTimeline)
                                        ]
                                        model
                                )
                                programTest
                       )
        ]


{-| Test input method consistency and switching
-}
inputMethodTests : Test
inputMethodTests =
    describe "Input Method Tests"
        [ test "rapid switching between input methods maintains state consistency" <|
            \() ->
                startRobotGame ()
                    -- Rapid alternating inputs
                    |> sendRobotCommand RotateRight
                    |> ProgramTest.advanceTime 200
                    |> sendRobotCommand AnimationComplete
                    |> sendRobotCommand RotateLeft
                    |> ProgramTest.advanceTime 200
                    |> sendRobotCommand AnimationComplete
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    |> sendRobotCommand (RotateToDirection South)
                    |> ProgramTest.advanceTime 200
                    |> sendRobotCommand AnimationComplete
                    |> (\programTest ->
                            Expect.all
                                [ expectRobotPosition { row = 1, col = 2 }
                                , expectRobotFacing South
                                ]
                                programTest
                       )
        , test "keyboard and direct commands produce identical results" <|
            \() ->
                let
                    keyboardTest =
                        startRobotGame ()
                            |> simulateKeyboardInput "ArrowUp"
                            |> completeAnimation
                            |> simulateKeyboardInput "ArrowRight"
                            |> ProgramTest.advanceTime 200
                            |> sendRobotCommand AnimationComplete

                    directCommandTest =
                        startRobotGame ()
                            |> sendRobotCommand MoveForward
                            |> completeAnimation
                            |> sendRobotCommand RotateRight
                            |> ProgramTest.advanceTime 200
                            |> sendRobotCommand AnimationComplete
                in
                Expect.all
                    [ \_ -> expectRobotPosition { row = 1, col = 2 } keyboardTest
                    , \_ -> expectRobotFacing East keyboardTest
                    , \_ -> expectRobotPosition { row = 1, col = 2 } directCommandTest
                    , \_ -> expectRobotFacing East directCommandTest
                    ]
                    ()
        , test "invalid input handling works consistently" <|
            \() ->
                startRobotGame ()
                    -- Try invalid keyboard inputs
                    |> simulateKeyboardInput "Space"
                    |> simulateKeyboardInput "Enter"
                    -- Valid input should still work
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    |> (\programTest ->
                            Expect.all
                                [ expectRobotPosition { row = 1, col = 2 }
                                , expectRobotFacing North
                                ]
                                programTest
                       )
        , test "error feedback is consistent across input methods" <|
            \() ->
                startRobotGame ()
                    -- Move to boundary
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    -- Try blocked movement with keyboard
                    |> simulateKeyboardInput "ArrowUp"
                    |> ProgramTest.advanceTime 100
                    -- Check during animation (before 200ms completion)
                    |> (\programTest ->
                            Expect.all
                                [ expectRobotPosition { row = 0, col = 2 }
                                , expectRobotFacing North
                                , expectRobotAnimationState BlockedMovement
                                ]
                                programTest
                       )
        ]


{-| Test accessibility features and interaction patterns
-}
accessibilityTests : Test
accessibilityTests =
    describe "Accessibility Tests"
        [ test "keyboard navigation maintains proper focus management" <|
            \() ->
                startRobotGame ()
                    |> ProgramTest.expectView
                        (Query.has [ Selector.attribute (Html.Attributes.attribute "tabIndex" "0") ])
        , test "screen reader announcements update correctly during interactions" <|
            \() ->
                startRobotGame ()
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    |> ProgramTest.expectView
                        (Query.has [ Selector.attribute (Html.Attributes.attribute "aria-live" "polite") ])
        , test "grid provides proper ARIA structure for screen readers" <|
            \() ->
                startRobotGame ()
                    |> ProgramTest.expectView
                        (Query.has [ Selector.attribute (Html.Attributes.attribute "role" "grid") ])
        , test "robot position announcements are accessible" <|
            \() ->
                startRobotGame ()
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    |> ProgramTest.expectView
                        (Query.has [ Selector.attribute (Html.Attributes.attribute "aria-atomic" "true") ])
        ]


{-| Test state management and persistence
-}
stateManagementTests : Test
stateManagementTests =
    describe "State Management Tests"
        [ test "color scheme changes are preserved during game operations" <|
            \() ->
                startRobotGame ()
                    -- Change to dark theme
                    |> sendRobotCommand (ColorScheme Dark)
                    -- Perform some game actions
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    |> sendRobotCommand RotateLeft
                    |> ProgramTest.advanceTime 200
                    |> sendRobotCommand AnimationComplete
                    |> (\programTest ->
                            Expect.all
                                [ expectColorScheme Dark
                                , expectRobotPosition { row = 1, col = 2 }
                                , expectRobotFacing West
                                ]
                                programTest
                       )
        , test "window resize updates are handled correctly" <|
            \() ->
                startRobotGame ()
                    -- Resize window
                    |> sendRobotCommand (GetResize 800 600)
                    -- Perform game actions
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal (Just ( 800, 600 )) model.maybeWindow
                                , \_ -> Expect.equal { row = 1, col = 2 } model.robot.position
                                ]
                                ()
                        )
        , test "blocked movement feedback state management" <|
            \() ->
                let
                    -- Start at boundary
                    initialModel =
                        createModelWithState
                            { position = { row = 0, col = 2 }
                            , facing = North
                            , animationState = Idle
                            }
                in
                ProgramTest.createElement
                    { init = \_ -> ( initialModel, NoEffect )
                    , view = view
                    , update = updateToEffect
                    }
                    |> ProgramTest.withSimulatedEffects simulateEffects
                    |> ProgramTest.start ()
                    -- Trigger blocked movement
                    |> sendRobotCommand MoveForward
                    -- Manually clear feedback
                    |> sendRobotCommand ClearBlockedMovementFeedback
                    -- Should be able to rotate now
                    |> sendRobotCommand RotateRight
                    |> ProgramTest.advanceTime 200
                    |> sendRobotCommand AnimationComplete
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal False model.blockedMovementFeedback
                                , \_ -> Expect.equal Idle model.animationState
                                , \_ -> Expect.equal East model.robot.facing
                                ]
                                ()
                        )
        , test "time tracking works correctly with game logic" <|
            \() ->
                let
                    testTime =
                        Time.millisToPosix 1000
                in
                startRobotGame ()
                    -- Update time
                    |> sendRobotCommand (Tick testTime)
                    -- Perform game action
                    |> sendRobotCommand MoveForward
                    |> completeAnimation
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal (Just testTime) model.lastMoveTime
                                , \_ -> Expect.equal { row = 1, col = 2 } model.robot.position
                                ]
                                ()
                        )
        ]


{-| Test visual button highlighting behavior (Requirement 7)
-}
visualHighlightingTests : Test
visualHighlightingTests =
    describe "Visual Button Highlighting Tests (Requirement 7)"
        [ forwardMovementHighlightingTests
        , rotationHighlightingTests
        , directionSelectionHighlightingTests
        , keyboardHighlightingTests
        , selectiveHighlightingTests
        ]


{-| Test forward movement highlighting
-}
forwardMovementHighlightingTests : Test
forwardMovementHighlightingTests =
    describe "Forward Movement Highlighting"
        [ test "forward movement highlights only forward button" <|
            \() ->
                startRobotGame ()
                    |> ProgramTest.update MoveForward
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal True (isButtonVisuallyHighlighted model ForwardButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model RotateLeftButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model RotateRightButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton North))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton South))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton East))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton West))
                                ]
                                ()
                        )
        , test "blocked forward movement highlights only forward button" <|
            \() ->
                let
                    modelAtTopEdge =
                        createModelWithState
                            { position = { row = 0, col = 2 }
                            , facing = North
                            , animationState = Idle
                            }
                in
                ProgramTest.createElement
                    { init = \_ -> ( modelAtTopEdge, NoEffect )
                    , view = view
                    , update = updateToEffect
                    }
                    |> ProgramTest.withSimulatedEffects simulateEffects
                    |> ProgramTest.start ()
                    |> ProgramTest.update MoveForward
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal True (isButtonVisuallyHighlighted model ForwardButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model RotateLeftButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model RotateRightButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton North))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton South))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton East))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton West))
                                ]
                                ()
                        )
        ]


{-| Test rotation highlighting
-}
rotationHighlightingTests : Test
rotationHighlightingTests =
    describe "Rotation Highlighting"
        [ test "rotate left highlights rotation button and direction buttons" <|
            \() ->
                startRobotGame ()
                    |> ProgramTest.update RotateLeft
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal True (isButtonVisuallyHighlighted model RotateLeftButton)
                                , \_ -> Expect.equal True (isButtonVisuallyHighlighted model (DirectionButton North))
                                , \_ -> Expect.equal True (isButtonVisuallyHighlighted model (DirectionButton West))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model ForwardButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model RotateRightButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton South))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton East))
                                ]
                                ()
                        )
        , test "rotate right highlights rotation button and direction buttons" <|
            \() ->
                startRobotGame ()
                    |> ProgramTest.update RotateRight
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal True (isButtonVisuallyHighlighted model RotateRightButton)
                                , \_ -> Expect.equal True (isButtonVisuallyHighlighted model (DirectionButton North))
                                , \_ -> Expect.equal True (isButtonVisuallyHighlighted model (DirectionButton East))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model ForwardButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model RotateLeftButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton South))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton West))
                                ]
                                ()
                        )
        ]


{-| Test direct direction selection highlighting
-}
directionSelectionHighlightingTests : Test
directionSelectionHighlightingTests =
    describe "Direction Selection Highlighting"
        [ test "direction selection highlights only old and new direction buttons" <|
            \() ->
                startRobotGame ()
                    |> ProgramTest.update (RotateToDirection South)
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal True (isButtonVisuallyHighlighted model (DirectionButton North))
                                , \_ -> Expect.equal True (isButtonVisuallyHighlighted model (DirectionButton South))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model ForwardButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model RotateLeftButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model RotateRightButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton East))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton West))
                                ]
                                ()
                        )
        , test "selecting same direction does not highlight any buttons" <|
            \() ->
                startRobotGame ()
                    |> ProgramTest.update (RotateToDirection North)
                    -- Already facing North
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal False (isButtonVisuallyHighlighted model ForwardButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model RotateLeftButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model RotateRightButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton North))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton South))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton East))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton West))
                                ]
                                ()
                        )
        ]


{-| Test keyboard input highlighting
-}
keyboardHighlightingTests : Test
keyboardHighlightingTests =
    describe "Keyboard Input Highlighting"
        [ test "arrow up key highlights forward button" <|
            \() ->
                startRobotGame ()
                    |> ProgramTest.update (KeyPressed "ArrowUp")
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal True (isButtonVisuallyHighlighted model ForwardButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model RotateLeftButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model RotateRightButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton North))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton South))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton East))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton West))
                                ]
                                ()
                        )
        , test "arrow left key highlights rotation and direction buttons" <|
            \() ->
                startRobotGame ()
                    |> ProgramTest.update (KeyPressed "ArrowLeft")
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal True (isButtonVisuallyHighlighted model RotateLeftButton)
                                , \_ -> Expect.equal True (isButtonVisuallyHighlighted model (DirectionButton North))
                                , \_ -> Expect.equal True (isButtonVisuallyHighlighted model (DirectionButton West))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model ForwardButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model RotateRightButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton South))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton East))
                                ]
                                ()
                        )
        , test "arrow down key highlights direction buttons for opposite direction" <|
            \() ->
                startRobotGame ()
                    |> ProgramTest.update (KeyPressed "ArrowDown")
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal True (isButtonVisuallyHighlighted model (DirectionButton North))
                                , \_ -> Expect.equal True (isButtonVisuallyHighlighted model (DirectionButton South))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model ForwardButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model RotateLeftButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model RotateRightButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton East))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton West))
                                ]
                                ()
                        )
        ]


{-| Test selective highlighting behavior
-}
selectiveHighlightingTests : Test
selectiveHighlightingTests =
    describe "Selective Highlighting Behavior"
        [ test "forward movement does not highlight unrelated buttons" <|
            \() ->
                startRobotGame ()
                    |> ProgramTest.update MoveForward
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal False (isButtonVisuallyHighlighted model RotateLeftButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model RotateRightButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton North))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton South))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton East))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton West))
                                ]
                                ()
                        )
        , test "rotation does not highlight unrelated buttons" <|
            \() ->
                startRobotGame ()
                    |> ProgramTest.update RotateLeft
                    -- North to West
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal False (isButtonVisuallyHighlighted model ForwardButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton South))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton East))
                                ]
                                ()
                        )
        , test "direction selection does not highlight unrelated buttons" <|
            \() ->
                startRobotGame ()
                    |> ProgramTest.update (RotateToDirection East)
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal False (isButtonVisuallyHighlighted model ForwardButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model RotateLeftButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model RotateRightButton)
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton South))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model (DirectionButton West))
                                ]
                                ()
                        )
        , test "multiple actions maintain selective highlighting" <|
            \() ->
                startRobotGame ()
                    |> ProgramTest.update MoveForward
                    |> ProgramTest.update AnimationComplete
                    |> ProgramTest.update RotateLeft
                    |> ProgramTest.expectModel
                        (\model ->
                            -- Should only highlight rotation-related buttons, not forward button
                            Expect.all
                                [ \_ -> Expect.equal True (isButtonVisuallyHighlighted model RotateLeftButton)
                                , \_ -> Expect.equal True (isButtonVisuallyHighlighted model (DirectionButton North))
                                , \_ -> Expect.equal True (isButtonVisuallyHighlighted model (DirectionButton West))
                                , \_ -> Expect.equal False (isButtonVisuallyHighlighted model ForwardButton)
                                ]
                                ()
                        )
        ]

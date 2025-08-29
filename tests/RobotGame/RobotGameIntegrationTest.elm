module RobotGame.RobotGameIntegrationTest exposing (suite)

{-| Comprehensive integration tests for the Robot Game.

This module consolidates all RobotGame integration tests, covering:

  - Complete user workflows and interaction patterns
  - Animation sequences and state transitions
  - Movement logic and boundary handling
  - Error conditions and recovery scenarios
  - Input method consistency and accessibility

Tests are organized by functional area and focus on user-observable behavior
rather than implementation details.

-}

import Expect
import Html.Attributes
import ProgramTest exposing (ProgramTest, SimulatedEffect)
import RobotGame.Main exposing (Effect(..), Msg(..), init, initToEffect, updateToEffect)
import RobotGame.Model exposing (AnimationState(..), Direction(..), Model, Position)
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
        |> ProgramTest.expectModel
            (\model ->
                Expect.equal expectedPosition model.robot.position
            )


{-| Assert that the robot is facing the expected direction
-}
expectRobotFacing : Direction -> ProgramTest Model msg effect -> Expect.Expectation
expectRobotFacing expectedDirection programTest =
    programTest
        |> ProgramTest.expectModel
            (\model ->
                Expect.equal expectedDirection model.robot.facing
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
    { robot = { position = position, facing = facing }
    , gridSize = 5
    , colorScheme = Light
    , maybeWindow = Just ( 1024, 768 )
    , animationState = animationState
    , lastMoveTime = Nothing
    , blockedMovementFeedback = False
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
                    |> ProgramTest.advanceTime 500
                    -- Try blocked movement with direct command
                    |> sendRobotCommand MoveForward
                    |> ProgramTest.advanceTime 500
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

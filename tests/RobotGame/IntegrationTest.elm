module RobotGame.IntegrationTest exposing (suite)

{-| Logic integration tests for the Robot Game.

These tests verify that the game logic components work together correctly,
focusing on message handling, state transitions, and business logic integration
without UI interaction.

-}

import Expect
import RobotGame.Main exposing (Msg(..), init, update)
import RobotGame.Model exposing (AnimationState(..), Direction(..), Model)
import Test exposing (Test, describe, test)
import Theme.Theme exposing (ColorScheme(..))
import Time


{-| Helper function to create a model with specific state
-}
createModelWithState : { position : { row : Int, col : Int }, facing : Direction, animationState : AnimationState } -> Model
createModelWithState { position, facing, animationState } =
    { robot = { position = position, facing = facing }
    , gridSize = 5
    , colorScheme = Light
    , maybeWindow = Just ( 1024, 768 )
    , animationState = animationState
    , lastMoveTime = Nothing
    , blockedMovementFeedback = False
    }


suite : Test
suite =
    describe "Robot Game Logic Integration Tests"
        [ messageIntegrationTests
        , animationSequenceTests
        , boundaryLogicTests
        , stateManagementTests
        ]


messageIntegrationTests : Test
messageIntegrationTests =
    describe "Message Integration"
        [ test "message sequence produces expected state transitions" <|
            \_ ->
                let
                    ( initialModel, _ ) =
                        init

                    -- Direct message handling (not keyboard events)
                    ( afterMove, _ ) =
                        update MoveForward initialModel

                    ( afterMoveAnim, _ ) =
                        update AnimationComplete afterMove

                    -- Direct rotation message
                    ( afterRotate, _ ) =
                        update RotateRight afterMoveAnim

                    ( afterRotateAnim, _ ) =
                        update AnimationComplete afterRotate

                    -- Another move
                    ( afterMove2, _ ) =
                        update MoveForward afterRotateAnim

                    ( finalModel, _ ) =
                        update AnimationComplete afterMove2
                in
                Expect.all
                    [ \m -> Expect.equal { row = 1, col = 3 } m.robot.position
                    , \m -> Expect.equal East m.robot.facing
                    ]
                    finalModel
        , test "direct rotation to direction message works correctly" <|
            \_ ->
                let
                    ( initialModel, _ ) =
                        init

                    -- Direct rotation to South
                    ( afterRotate, _ ) =
                        update (RotateToDirection South) initialModel

                    ( finalModel, _ ) =
                        update AnimationComplete afterRotate
                in
                Expect.all
                    [ \m -> Expect.equal South m.robot.facing
                    , \m -> Expect.equal { row = 2, col = 2 } m.robot.position
                    ]
                    finalModel
        , test "complete rotation cycle returns to original direction" <|
            \_ ->
                let
                    ( initialModel, _ ) =
                        init

                    originalDirection =
                        initialModel.robot.facing

                    -- Perform four left rotations
                    ( afterRotate1, _ ) =
                        update RotateLeft initialModel

                    ( afterAnim1, _ ) =
                        update AnimationComplete afterRotate1

                    ( afterRotate2, _ ) =
                        update RotateLeft afterAnim1

                    ( afterAnim2, _ ) =
                        update AnimationComplete afterRotate2

                    ( afterRotate3, _ ) =
                        update RotateLeft afterAnim2

                    ( afterAnim3, _ ) =
                        update AnimationComplete afterRotate3

                    ( afterRotate4, _ ) =
                        update RotateLeft afterAnim3

                    ( finalModel, _ ) =
                        update AnimationComplete afterRotate4
                in
                Expect.all
                    [ \m -> Expect.equal originalDirection m.robot.facing
                    , \m -> Expect.equal { row = 2, col = 2 } m.robot.position
                    , \m -> Expect.equal Idle m.animationState
                    ]
                    finalModel
        ]


animationSequenceTests : Test
animationSequenceTests =
    describe "Animation Sequence Logic"
        [ test "rapid messages during animation are properly queued/ignored" <|
            \_ ->
                let
                    ( initialModel, _ ) =
                        init

                    -- Start movement
                    ( afterMove, _ ) =
                        update MoveForward initialModel

                    -- Try to move again during animation (should be ignored)
                    ( afterSecondMove, _ ) =
                        update MoveForward afterMove

                    -- Try to rotate during animation (should be ignored)
                    ( afterRotate, _ ) =
                        update RotateLeft afterSecondMove

                    -- Complete animation
                    ( finalModel, _ ) =
                        update AnimationComplete afterRotate
                in
                Expect.all
                    [ \m -> Expect.equal { row = 1, col = 2 } m.robot.position
                    , \m -> Expect.equal North m.robot.facing
                    , \m -> Expect.equal Idle m.animationState
                    ]
                    finalModel
        , test "animation completion allows new messages" <|
            \_ ->
                let
                    ( initialModel, _ ) =
                        init

                    -- Start movement
                    ( afterMove1, _ ) =
                        update MoveForward initialModel

                    -- Complete animation
                    ( afterAnim1, _ ) =
                        update AnimationComplete afterMove1

                    -- New movement should work
                    ( afterMove2, _ ) =
                        update MoveForward afterAnim1

                    ( finalModel, _ ) =
                        update AnimationComplete afterMove2
                in
                Expect.all
                    [ \m -> Expect.equal { row = 0, col = 2 } m.robot.position
                    , \m -> Expect.equal North m.robot.facing
                    , \m -> Expect.equal Idle m.animationState
                    ]
                    finalModel
        ]


boundaryLogicTests : Test
boundaryLogicTests =
    describe "Boundary Logic Integration"
        [ test "blocked movement logic followed by successful rotation and movement" <|
            \_ ->
                let
                    -- Start at top edge
                    initialModel =
                        createModelWithState
                            { position = { row = 0, col = 2 }
                            , facing = North
                            , animationState = Idle
                            }

                    -- Try to move forward (should be blocked)
                    ( afterBlockedMove, _ ) =
                        update MoveForward initialModel

                    -- Clear blocked feedback
                    ( afterClear, _ ) =
                        update ClearBlockedMovementFeedback afterBlockedMove

                    -- Rotate to face East
                    ( afterRotate, _ ) =
                        update RotateRight afterClear

                    ( afterRotateAnim, _ ) =
                        update AnimationComplete afterRotate

                    -- Move forward (should succeed)
                    ( afterMove, _ ) =
                        update MoveForward afterRotateAnim

                    ( finalModel, _ ) =
                        update AnimationComplete afterMove
                in
                Expect.all
                    [ \m -> Expect.equal { row = 0, col = 3 } m.robot.position
                    , \m -> Expect.equal East m.robot.facing
                    , \m -> Expect.equal Idle m.animationState
                    , \m -> Expect.equal False m.blockedMovementFeedback
                    ]
                    finalModel
        , test "corner logic with multiple boundary encounters" <|
            \_ ->
                let
                    -- Start at top-left corner
                    initialModel =
                        createModelWithState
                            { position = { row = 0, col = 0 }
                            , facing = North
                            , animationState = Idle
                            }

                    -- Try to move North (blocked)
                    ( afterNorthBlock, _ ) =
                        update MoveForward initialModel

                    ( afterNorthClear, _ ) =
                        update ClearBlockedMovementFeedback afterNorthBlock

                    -- Try to move West (blocked)
                    ( afterRotateWest, _ ) =
                        update RotateLeft afterNorthClear

                    ( afterRotateWestAnim, _ ) =
                        update AnimationComplete afterRotateWest

                    ( afterWestBlock, _ ) =
                        update MoveForward afterRotateWestAnim

                    ( afterWestClear, _ ) =
                        update ClearBlockedMovementFeedback afterWestBlock

                    -- Rotate to face East (should allow movement)
                    ( afterRotateEast, _ ) =
                        update (RotateToDirection East) afterWestClear

                    ( afterRotateEastAnim, _ ) =
                        update AnimationComplete afterRotateEast

                    -- Move East (should succeed)
                    ( afterMove, _ ) =
                        update MoveForward afterRotateEastAnim

                    ( finalModel, _ ) =
                        update AnimationComplete afterMove
                in
                Expect.all
                    [ \m -> Expect.equal { row = 0, col = 1 } m.robot.position
                    , \m -> Expect.equal East m.robot.facing
                    , \m -> Expect.equal Idle m.animationState
                    ]
                    finalModel
        ]


stateManagementTests : Test
stateManagementTests =
    describe "State Management Integration"
        [ test "color scheme changes are preserved during game logic operations" <|
            \_ ->
                let
                    ( initialModel, _ ) =
                        init

                    -- Change to dark theme
                    ( afterThemeChange, _ ) =
                        update (ColorScheme Dark) initialModel

                    -- Perform some game actions
                    ( afterMove, _ ) =
                        update MoveForward afterThemeChange

                    ( afterAnim, _ ) =
                        update AnimationComplete afterMove

                    ( afterRotate, _ ) =
                        update RotateLeft afterAnim

                    ( finalModel, _ ) =
                        update AnimationComplete afterRotate
                in
                Expect.all
                    [ \m -> Expect.equal Dark m.colorScheme
                    , \m -> Expect.equal { row = 1, col = 2 } m.robot.position
                    , \m -> Expect.equal West m.robot.facing
                    ]
                    finalModel
        , test "window resize updates are handled correctly in game logic" <|
            \_ ->
                let
                    ( initialModel, _ ) =
                        init

                    -- Resize window
                    ( afterResize, _ ) =
                        update (GetResize 800 600) initialModel

                    -- Perform game actions
                    ( afterMove, _ ) =
                        update MoveForward afterResize

                    ( finalModel, _ ) =
                        update AnimationComplete afterMove
                in
                Expect.all
                    [ \m -> Expect.equal (Just ( 800, 600 )) m.maybeWindow
                    , \m -> Expect.equal { row = 1, col = 2 } m.robot.position
                    ]
                    finalModel
        , test "blocked movement feedback state management" <|
            \_ ->
                let
                    -- Start at boundary
                    initialModel =
                        createModelWithState
                            { position = { row = 0, col = 2 }
                            , facing = North
                            , animationState = Idle
                            }

                    -- Trigger blocked movement
                    ( afterBlocked, _ ) =
                        update MoveForward initialModel

                    -- Manually clear feedback
                    ( afterClear, _ ) =
                        update ClearBlockedMovementFeedback afterBlocked

                    -- Should be able to rotate now
                    ( afterRotate, _ ) =
                        update RotateRight afterClear

                    ( finalModel, _ ) =
                        update AnimationComplete afterRotate
                in
                Expect.all
                    [ \m -> Expect.equal False m.blockedMovementFeedback
                    , \m -> Expect.equal Idle m.animationState
                    , \m -> Expect.equal East m.robot.facing
                    ]
                    finalModel
        , test "time tracking works correctly with game logic" <|
            \_ ->
                let
                    ( initialModel, _ ) =
                        init

                    testTime =
                        Time.millisToPosix 1000

                    -- Update time
                    ( afterTick, _ ) =
                        update (Tick testTime) initialModel

                    -- Perform game action
                    ( afterMove, _ ) =
                        update MoveForward afterTick

                    ( finalModel, _ ) =
                        update AnimationComplete afterMove
                in
                Expect.all
                    [ \m -> Expect.equal (Just testTime) m.lastMoveTime
                    , \m -> Expect.equal { row = 1, col = 2 } m.robot.position
                    ]
                    finalModel
        ]

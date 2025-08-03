module RobotGame.IntegrationTest exposing (suite)

{-| Integration tests for complete user interaction flows in the Robot Game.

These tests verify that the entire system works together correctly,
from user input through game logic to state updates.

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
    describe "Robot Game Integration Tests"
        [ completeGameFlowTests
        , keyboardInputIntegrationTests
        , animationSequenceTests
        , boundaryInteractionTests
        , themeIntegrationTests
        , errorRecoveryTests
        ]


completeGameFlowTests : Test
completeGameFlowTests =
    describe "Complete Game Flow Integration"
        [ test "full navigation sequence: move, rotate, move again" <|
            \_ ->
                let
                    -- Start with initial state
                    ( initialModel, _ ) =
                        init

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
        , test "navigate to all four corners of the grid" <|
            \_ ->
                let
                    -- Start at center
                    ( initialModel, _ ) =
                        init

                    -- Go to top-left corner (0,0)
                    ( afterNorth1, _ ) =
                        update MoveForward initialModel

                    ( afterNorthAnim1, _ ) =
                        update AnimationComplete afterNorth1

                    ( afterNorth2, _ ) =
                        update MoveForward afterNorthAnim1

                    ( afterNorthAnim2, _ ) =
                        update AnimationComplete afterNorth2

                    ( afterRotateWest, _ ) =
                        update RotateLeft afterNorthAnim2

                    ( afterRotateWestAnim, _ ) =
                        update AnimationComplete afterRotateWest

                    ( afterWest1, _ ) =
                        update MoveForward afterRotateWestAnim

                    ( afterWestAnim1, _ ) =
                        update AnimationComplete afterWest1

                    ( afterWest2, _ ) =
                        update MoveForward afterWestAnim1

                    ( topLeftModel, _ ) =
                        update AnimationComplete afterWest2
                in
                Expect.all
                    [ \m -> Expect.equal { row = 0, col = 0 } m.robot.position
                    , \m -> Expect.equal West m.robot.facing
                    , \m -> Expect.equal Idle m.animationState
                    ]
                    topLeftModel
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


keyboardInputIntegrationTests : Test
keyboardInputIntegrationTests =
    describe "Keyboard Input Integration"
        [ test "arrow key sequence produces expected movement" <|
            \_ ->
                let
                    ( initialModel, _ ) =
                        init

                    -- Up arrow (move forward)
                    ( afterUp, _ ) =
                        update (KeyPressed "ArrowUp") initialModel

                    ( afterUpAnim, _ ) =
                        update AnimationComplete afterUp

                    -- Right arrow (rotate right)
                    ( afterRight, _ ) =
                        update (KeyPressed "ArrowRight") afterUpAnim

                    ( afterRightAnim, _ ) =
                        update AnimationComplete afterRight

                    -- Up arrow again (move forward in new direction)
                    ( afterUp2, _ ) =
                        update (KeyPressed "ArrowUp") afterRightAnim

                    ( finalModel, _ ) =
                        update AnimationComplete afterUp2
                in
                Expect.all
                    [ \m -> Expect.equal { row = 1, col = 3 } m.robot.position
                    , \m -> Expect.equal East m.robot.facing
                    ]
                    finalModel
        , test "down arrow performs 180-degree rotation" <|
            \_ ->
                let
                    ( initialModel, _ ) =
                        init

                    -- Down arrow (rotate to opposite)
                    ( afterDown, _ ) =
                        update (KeyPressed "ArrowDown") initialModel

                    ( finalModel, _ ) =
                        update AnimationComplete afterDown
                in
                Expect.all
                    [ \m -> Expect.equal South m.robot.facing
                    , \m -> Expect.equal { row = 2, col = 2 } m.robot.position
                    ]
                    finalModel
        , test "invalid keys are ignored without affecting state" <|
            \_ ->
                let
                    ( initialModel, _ ) =
                        init

                    -- Try various invalid keys
                    ( afterSpace, _ ) =
                        update (KeyPressed "Space") initialModel

                    ( afterEnter, _ ) =
                        update (KeyPressed "Enter") afterSpace

                    ( afterEscape, _ ) =
                        update (KeyPressed "Escape") afterEnter

                    ( finalModel, _ ) =
                        update (KeyPressed "a") afterEscape
                in
                Expect.equal initialModel finalModel
        ]


animationSequenceTests : Test
animationSequenceTests =
    describe "Animation Sequence Integration"
        [ test "rapid input during animation is properly queued/ignored" <|
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
        , test "animation completion allows new input" <|
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


boundaryInteractionTests : Test
boundaryInteractionTests =
    describe "Boundary Interaction Integration"
        [ test "blocked movement followed by successful rotation and movement" <|
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
        , test "corner navigation with multiple boundary encounters" <|
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
                    -- From West, rotate right twice to get to East
                    ( afterRotateNorth, _ ) =
                        update RotateRight afterWestClear

                    ( afterRotateNorthAnim, _ ) =
                        update AnimationComplete afterRotateNorth

                    ( afterRotateEast, _ ) =
                        update RotateRight afterRotateNorthAnim

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


themeIntegrationTests : Test
themeIntegrationTests =
    describe "Theme Integration"
        [ test "color scheme changes are preserved during gameplay" <|
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
        , test "window resize updates are handled correctly" <|
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
        ]


errorRecoveryTests : Test
errorRecoveryTests =
    describe "Error Recovery Integration"
        [ test "blocked movement feedback clears automatically" <|
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
        , test "time tracking works correctly" <|
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

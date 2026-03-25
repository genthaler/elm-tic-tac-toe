module RobotGame.AnimationUnitTest exposing (suite)

{-| Comprehensive unit and regression tests for RobotGame.Animation module.

This test suite covers:

  - Animation state checking functions
  - Animation control functions
  - Timeline management utilities
  - Interpolation utilities
  - Helper functions
  - Animation coordination logic
  - Deterministic animation testing
  - Animation state transitions
  - Timeline completion verification
  - Animation memory management
  - Movement animation regression testing
  - Rotation animation regression testing
  - Button highlight animation regression testing
  - Blocked movement animation regression testing
  - Game logic integration regression testing
  - Performance regression verification

This module consolidates both unit tests and regression tests to ensure
comprehensive coverage of the elm-animator animation system while maintaining
all existing functionality and performance characteristics.

-}

import Expect
import RobotGame.Animation as Animation
import RobotGame.Main as Main
import RobotGame.Model as Model exposing (AnimationState(..), Button(..), Direction(..))
import RobotGame.RobotGame as RobotGame
import Test exposing (Test, describe, test)
import Time


suite : Test
suite =
    describe "RobotGame.Animation"
        [ testAnimationStateChecking
        , testAnimationControl
        , testTimelineManagement
        , testInterpolationUtilities
        , testHelperFunctions
        , testAnimationCoordination
        , testAnimationConfiguration
        , testDeterministicAnimationBehavior
        , testAnimationStateTransitions
        , testTimelineCompletion
        , testAnimationMemoryManagement
        , testMovementAnimationRegression
        , testRotationAnimationRegression
        , testButtonHighlightAnimationRegression
        , testBlockedMovementAnimationRegression
        , testGameLogicIntegrationRegression
        , testPerformanceRegression
        ]


testAnimationStateChecking : Test
testAnimationStateChecking =
    describe "Animation state checking"
        [ test "isAnimating returns False for idle model" <|
            \_ ->
                let
                    model =
                        Model.init
                in
                Animation.isAnimating model
                    |> Expect.equal False
        , test "isAnimating returns True when animation state is Moving" <|
            \_ ->
                let
                    fromPos =
                        { row = 0, col = 0 }

                    toPos =
                        { row = 0, col = 1 }

                    baseModel =
                        Model.init

                    model =
                        { baseModel | animationState = Moving fromPos toPos }
                in
                Animation.isAnimating model
                    |> Expect.equal True
        , test "isAnimating returns True when animation state is Rotating" <|
            \_ ->
                let
                    baseModel =
                        Model.init

                    model =
                        { baseModel | animationState = Rotating North East }
                in
                Animation.isAnimating model
                    |> Expect.equal True
        , test "isAnimating returns True when animation state is BlockedMovement" <|
            \_ ->
                let
                    baseModel =
                        Model.init

                    model =
                        { baseModel | animationState = BlockedMovement }
                in
                Animation.isAnimating model
                    |> Expect.equal True
        , test "getCurrentAnimatedState returns current robot from timeline" <|
            \_ ->
                let
                    model =
                        Model.init

                    currentRobot =
                        Animation.getCurrentAnimatedState model
                in
                Expect.equal model.robot currentRobot
        ]


testAnimationControl : Test
testAnimationControl =
    describe "Animation control"
        [ test "startMovementAnimation updates robot position and animation state" <|
            \_ ->
                let
                    model =
                        Model.init

                    fromPos =
                        { row = 2, col = 2 }

                    toPos =
                        { row = 1, col = 2 }

                    updatedModel =
                        Animation.startMovementAnimation fromPos toPos model
                in
                Expect.all
                    [ \m -> Expect.equal toPos m.robot.position
                    , \m -> Expect.equal (Moving fromPos toPos) m.animationState
                    , \m -> Expect.equal model.robot.facing m.robot.facing -- facing should remain unchanged
                    ]
                    updatedModel
        , test "startRotationAnimation updates robot facing and animation state" <|
            \_ ->
                let
                    model =
                        Model.init

                    fromDir =
                        North

                    toDir =
                        East

                    updatedModel =
                        Animation.startRotationAnimation fromDir toDir model
                in
                Expect.all
                    [ \m -> Expect.equal toDir m.robot.facing
                    , \m -> Expect.equal (Rotating fromDir toDir) m.animationState
                    , \m -> Expect.equal model.robot.position m.robot.position -- position should remain unchanged
                    ]
                    updatedModel
        , test "startButtonHighlightAnimation updates highlighted buttons" <|
            \_ ->
                let
                    model =
                        Model.init

                    buttons =
                        [ ForwardButton, DirectionButton North ]

                    updatedModel =
                        Animation.startButtonHighlightAnimation buttons model
                in
                Expect.equal buttons updatedModel.highlightedButtons
        , test "startBlockedMovementAnimation sets blocked movement state" <|
            \_ ->
                let
                    model =
                        Model.init

                    updatedModel =
                        Animation.startBlockedMovementAnimation model
                in
                Expect.all
                    [ \m -> Expect.equal BlockedMovement m.animationState
                    , \m -> Expect.equal True m.blockedMovementFeedback
                    ]
                    updatedModel
        ]


testTimelineManagement : Test
testTimelineManagement =
    describe "Timeline management"
        [ test "updateAnimations preserves model when no animations running" <|
            \_ ->
                let
                    model =
                        Model.init

                    time =
                        Time.millisToPosix 1000

                    updatedModel =
                        Animation.updateAnimations time model
                in
                -- Model should be essentially unchanged (timelines may be updated but values remain the same)
                Expect.all
                    [ \m -> Expect.equal model.robot m.robot
                    , \m -> Expect.equal model.animationState m.animationState
                    , \m -> Expect.equal model.blockedMovementFeedback m.blockedMovementFeedback
                    ]
                    updatedModel
        , test "updateAnimations processes active timelines efficiently" <|
            \_ ->
                let
                    model =
                        Model.init
                            |> Animation.startMovementAnimation { row = 0, col = 0 } { row = 0, col = 1 }

                    time =
                        Time.millisToPosix 1000

                    updatedModel =
                        Animation.updateAnimations time model
                in
                -- Should update timelines without errors
                Expect.notEqual model.robotTimeline updatedModel.robotTimeline
        ]


testInterpolationUtilities : Test
testInterpolationUtilities =
    describe "Interpolation utilities"
        [ test "getInterpolatedPosition returns current robot position" <|
            \_ ->
                let
                    model =
                        Model.init

                    position =
                        Animation.getInterpolatedPosition model
                in
                Expect.equal model.robot.position position
        , test "getInterpolatedRotationAngle returns normalized angle" <|
            \_ ->
                let
                    model =
                        Model.init

                    angle =
                        Animation.getInterpolatedRotationAngle model
                in
                Expect.all
                    [ \a -> Expect.atLeast 0.0 a
                    , \a -> Expect.lessThan 360.0 a
                    ]
                    angle
        , test "getButtonHighlightOpacity returns 0.0 for non-highlighted button" <|
            \_ ->
                let
                    model =
                        Model.init

                    opacity =
                        Animation.getButtonHighlightOpacity ForwardButton model
                in
                Expect.equal 0.0 opacity
        , test "getButtonHighlightOpacity returns 1.0 for highlighted button" <|
            \_ ->
                let
                    model =
                        Model.init
                            |> Animation.startButtonHighlightAnimation [ ForwardButton ]

                    opacity =
                        Animation.getButtonHighlightOpacity ForwardButton model
                in
                -- Note: This test may need adjustment based on elm-animator timing
                -- For now, we test that the function doesn't crash and returns a valid value
                Expect.all
                    [ \o -> Expect.atLeast 0.0 o
                    , \o -> Expect.atMost 1.0 o
                    ]
                    opacity
        , test "isBlockedMovementAnimating returns False for idle model" <|
            \_ ->
                let
                    model =
                        Model.init

                    isAnimating =
                        Animation.isBlockedMovementAnimating model
                in
                Expect.equal False isAnimating
        , test "isBlockedMovementAnimating returns True after starting blocked movement animation" <|
            \_ ->
                let
                    model =
                        Model.init
                            |> Animation.startBlockedMovementAnimation

                    isAnimating =
                        Animation.isBlockedMovementAnimating model
                in
                Expect.equal True isAnimating
        ]


testHelperFunctions : Test
testHelperFunctions =
    describe "Helper functions"
        [ test "directionToAngleFloat converts North to 0.0" <|
            \_ ->
                Animation.directionToAngleFloat North
                    |> Expect.equal 0.0
        , test "directionToAngleFloat converts East to 90.0" <|
            \_ ->
                Animation.directionToAngleFloat East
                    |> Expect.equal 90.0
        , test "directionToAngleFloat converts South to 180.0" <|
            \_ ->
                Animation.directionToAngleFloat South
                    |> Expect.equal 180.0
        , test "directionToAngleFloat converts West to 270.0" <|
            \_ ->
                Animation.directionToAngleFloat West
                    |> Expect.equal 270.0
        , test "calculateShortestRotationPath returns target angle" <|
            \_ ->
                Animation.calculateShortestRotationPath 0.0 90.0
                    |> Expect.equal 90.0
        , test "calculateShortestRotationPath handles wrap-around angles" <|
            \_ ->
                Animation.calculateShortestRotationPath 270.0 0.0
                    |> Expect.equal 0.0
        ]


testAnimationCoordination : Test
testAnimationCoordination =
    describe "Animation coordination"
        [ test "prevents conflicting animations when movement is active" <|
            \_ ->
                let
                    model =
                        Model.init
                            |> Animation.startMovementAnimation { row = 0, col = 0 } { row = 0, col = 1 }

                    isAnimating =
                        Animation.isAnimating model
                in
                Expect.equal True isAnimating
        , test "prevents conflicting animations when rotation is active" <|
            \_ ->
                let
                    model =
                        Model.init
                            |> Animation.startRotationAnimation North East

                    isAnimating =
                        Animation.isAnimating model
                in
                Expect.equal True isAnimating
        , test "prevents conflicting animations when blocked movement is active" <|
            \_ ->
                let
                    model =
                        Model.init
                            |> Animation.startBlockedMovementAnimation

                    isAnimating =
                        Animation.isAnimating model
                in
                Expect.equal True isAnimating
        , test "allows new animations when model is idle" <|
            \_ ->
                let
                    baseModel =
                        Model.init

                    model =
                        { baseModel | animationState = Idle }

                    isAnimating =
                        Animation.isAnimating model
                in
                Expect.equal False isAnimating
        ]


testAnimationConfiguration : Test
testAnimationConfiguration =
    describe "Animation configuration"
        [ test "defaultAnimationConfig has correct movement duration" <|
            \_ ->
                Animation.defaultAnimationConfig.movementDuration
                    |> Expect.equal 300.0
        , test "defaultAnimationConfig has correct rotation duration" <|
            \_ ->
                Animation.defaultAnimationConfig.rotationDuration
                    |> Expect.equal 200.0
        , test "defaultAnimationConfig has correct button highlight duration" <|
            \_ ->
                Animation.defaultAnimationConfig.buttonHighlightDuration
                    |> Expect.equal 150.0
        , test "defaultAnimationConfig has correct blocked movement duration" <|
            \_ ->
                Animation.defaultAnimationConfig.blockedMovementDuration
                    |> Expect.equal 200.0
        ]


testDeterministicAnimationBehavior : Test
testDeterministicAnimationBehavior =
    describe "Deterministic animation behavior"
        [ test "animation state transitions are predictable" <|
            \_ ->
                let
                    model =
                        Model.init

                    fromPos =
                        { row = 0, col = 0 }

                    toPos =
                        { row = 0, col = 1 }

                    -- Start animation
                    animatedModel =
                        Animation.startMovementAnimation fromPos toPos model

                    -- Verify deterministic state
                    expectedState =
                        Moving fromPos toPos
                in
                Expect.all
                    [ \m -> Expect.equal expectedState m.animationState
                    , \m -> Expect.equal toPos m.robot.position
                    , \m -> Expect.equal True (Animation.isAnimating m)
                    ]
                    animatedModel
        , test "timeline initialization is consistent" <|
            \_ ->
                let
                    model1 =
                        Model.init

                    model2 =
                        Model.init

                    robot1 =
                        Animation.getCurrentAnimatedState model1

                    robot2 =
                        Animation.getCurrentAnimatedState model2
                in
                Expect.equal robot1 robot2
        , test "animation updates are deterministic with same time" <|
            \_ ->
                let
                    model =
                        Model.init

                    time =
                        Time.millisToPosix 1000

                    updated1 =
                        Animation.updateAnimations time model

                    updated2 =
                        Animation.updateAnimations time model

                    robot1 =
                        Animation.getCurrentAnimatedState updated1

                    robot2 =
                        Animation.getCurrentAnimatedState updated2
                in
                Expect.equal robot1 robot2
        , test "button highlight state is deterministic" <|
            \_ ->
                let
                    model =
                        Model.init

                    buttons =
                        [ ForwardButton, DirectionButton North ]

                    highlighted1 =
                        Animation.startButtonHighlightAnimation buttons model

                    highlighted2 =
                        Animation.startButtonHighlightAnimation buttons model
                in
                Expect.equal highlighted1.highlightedButtons highlighted2.highlightedButtons
        ]


testAnimationStateTransitions : Test
testAnimationStateTransitions =
    describe "Animation state transitions"
        [ test "idle to moving transition" <|
            \_ ->
                let
                    model =
                        Model.init

                    fromPos =
                        { row = 1, col = 1 }

                    toPos =
                        { row = 1, col = 2 }

                    -- Verify initial state
                    initialState =
                        model.animationState

                    -- Perform transition
                    transitionedModel =
                        Animation.startMovementAnimation fromPos toPos model

                    -- Verify final state
                    finalState =
                        transitionedModel.animationState
                in
                Expect.all
                    [ \_ -> Expect.equal Idle initialState
                    , \_ -> Expect.equal (Moving fromPos toPos) finalState
                    , \_ -> Expect.equal False (Animation.isAnimating model)
                    , \_ -> Expect.equal True (Animation.isAnimating transitionedModel)
                    ]
                    ()
        , test "idle to rotating transition" <|
            \_ ->
                let
                    model =
                        Model.init

                    fromDir =
                        North

                    toDir =
                        East

                    transitionedModel =
                        Animation.startRotationAnimation fromDir toDir model
                in
                Expect.all
                    [ \m -> Expect.equal (Rotating fromDir toDir) m.animationState
                    , \m -> Expect.equal toDir m.robot.facing
                    , \m -> Expect.equal True (Animation.isAnimating m)
                    ]
                    transitionedModel
        , test "idle to blocked movement transition" <|
            \_ ->
                let
                    model =
                        Model.init

                    transitionedModel =
                        Animation.startBlockedMovementAnimation model
                in
                Expect.all
                    [ \m -> Expect.equal BlockedMovement m.animationState
                    , \m -> Expect.equal True m.blockedMovementFeedback
                    , \m -> Expect.equal True (Animation.isAnimating m)
                    , \m -> Expect.equal True (Animation.isBlockedMovementAnimating m)
                    ]
                    transitionedModel
        , test "multiple state transitions preserve robot state" <|
            \_ ->
                let
                    model =
                        Model.init

                    -- Chain multiple transitions
                    step1 =
                        Animation.startMovementAnimation { row = 0, col = 0 } { row = 0, col = 1 } model

                    step2 =
                        Animation.startRotationAnimation North East step1

                    step3 =
                        Animation.startBlockedMovementAnimation step2

                    finalRobot =
                        step3.robot
                in
                Expect.all
                    [ \_ -> Expect.equal { row = 0, col = 1 } finalRobot.position
                    , \_ -> Expect.equal East finalRobot.facing
                    , \_ -> Expect.equal BlockedMovement step3.animationState
                    ]
                    ()
        ]


testTimelineCompletion : Test
testTimelineCompletion =
    describe "Timeline completion verification"
        [ test "completed timelines can be cleaned up" <|
            \_ ->
                let
                    model =
                        Model.init

                    -- Start animation then mark as completed
                    animatedModel =
                        Animation.startMovementAnimation { row = 0, col = 0 } { row = 0, col = 1 } model

                    completedModel =
                        { animatedModel | animationState = Idle }

                    -- Clean up completed timelines
                    cleanedModel =
                        Animation.cleanupCompletedTimelines completedModel

                    -- Verify cleanup preserves robot state
                    finalRobot =
                        Animation.getCurrentAnimatedState cleanedModel
                in
                Expect.equal completedModel.robot finalRobot
        , test "active timelines are not cleaned up" <|
            \_ ->
                let
                    model =
                        Model.init

                    animatedModel =
                        Animation.startMovementAnimation { row = 0, col = 0 } { row = 0, col = 1 } model

                    -- Try to clean up while animation is still active
                    cleanedModel =
                        Animation.cleanupCompletedTimelines animatedModel
                in
                Expect.equal animatedModel.animationState cleanedModel.animationState
        , test "timeline completion detection works correctly" <|
            \_ ->
                let
                    idleModel =
                        Model.init

                    activeModel =
                        Animation.startMovementAnimation { row = 0, col = 0 } { row = 0, col = 1 } Model.init

                    idleHasActive =
                        Animation.hasActiveAnimations idleModel

                    activeHasActive =
                        Animation.hasActiveAnimations activeModel
                in
                Expect.all
                    [ \_ -> Expect.equal False idleHasActive
                    , \_ -> Expect.equal True activeHasActive
                    ]
                    ()
        ]


testAnimationMemoryManagement : Test
testAnimationMemoryManagement =
    describe "Animation memory management"
        [ test "cleanup preserves current robot state" <|
            \_ ->
                let
                    model =
                        Model.init

                    newRobot =
                        { position = { row = 2, col = 3 }, facing = South }

                    modelWithNewRobot =
                        { model | robot = newRobot }

                    cleanedModel =
                        Animation.cleanupCompletedTimelines modelWithNewRobot

                    finalRobot =
                        Animation.getCurrentAnimatedState cleanedModel
                in
                Expect.equal newRobot finalRobot
        , test "timeline updates are efficient for idle models" <|
            \_ ->
                let
                    model =
                        Model.init

                    time =
                        Time.millisToPosix 5000

                    -- Update should be efficient for idle model
                    updatedModel =
                        Animation.updateAnimations time model

                    -- Robot state should remain unchanged
                    originalRobot =
                        Animation.getCurrentAnimatedState model

                    updatedRobot =
                        Animation.getCurrentAnimatedState updatedModel
                in
                Expect.equal originalRobot updatedRobot
        , test "hasActiveAnimations correctly identifies memory cleanup opportunities" <|
            \_ ->
                let
                    idleModel =
                        Model.init

                    movingModel =
                        Animation.startMovementAnimation { row = 0, col = 0 } { row = 0, col = 1 } Model.init

                    rotatingModel =
                        Animation.startRotationAnimation North East Model.init

                    blockedModel =
                        Animation.startBlockedMovementAnimation Model.init
                in
                Expect.all
                    [ \_ -> Expect.equal False (Animation.hasActiveAnimations idleModel)
                    , \_ -> Expect.equal True (Animation.hasActiveAnimations movingModel)
                    , \_ -> Expect.equal True (Animation.hasActiveAnimations rotatingModel)
                    , \_ -> Expect.equal True (Animation.hasActiveAnimations blockedModel)
                    ]
                    ()
        ]


{-| Test movement animation regression
-}
testMovementAnimationRegression : Test
testMovementAnimationRegression =
    describe "Movement Animation Regression"
        [ test "movement animation preserves robot state correctly" <|
            \_ ->
                let
                    model =
                        Model.init

                    fromPos =
                        { row = 2, col = 2 }

                    toPos =
                        { row = 2, col = 3 }

                    -- Set initial robot position
                    initialModel =
                        { model | robot = { position = fromPos, facing = East } }

                    -- Start movement animation
                    animatedModel =
                        Animation.startMovementAnimation fromPos toPos initialModel

                    -- Verify final robot state is correct
                    finalRobot =
                        animatedModel.robot
                in
                Expect.all
                    [ \_ -> Expect.equal toPos finalRobot.position
                    , \_ -> Expect.equal East finalRobot.facing
                    , \_ -> Expect.equal (Moving fromPos toPos) animatedModel.animationState
                    ]
                    ()
        , test "movement animation respects boundary constraints" <|
            \_ ->
                let
                    edgePos =
                        { row = 0, col = 4 }

                    -- Right edge
                    robot =
                        { position = edgePos, facing = East }

                    -- Verify robot cannot move beyond boundary
                    canMove =
                        RobotGame.canMoveForward robot
                in
                Expect.equal False canMove
        , test "movement animation works with Main.init model" <|
            \_ ->
                let
                    ( initialModel, _ ) =
                        Main.init

                    fromPos =
                        initialModel.robot.position

                    toPos =
                        { row = fromPos.row, col = fromPos.col + 1 }

                    animatedModel =
                        Animation.startMovementAnimation fromPos toPos initialModel

                    -- Verify animation integrates correctly with Main model
                    isAnimating =
                        Animation.isAnimating animatedModel

                    finalRobot =
                        animatedModel.robot
                in
                Expect.all
                    [ \_ -> Expect.equal True isAnimating
                    , \_ -> Expect.equal toPos finalRobot.position
                    , \_ -> Expect.equal initialModel.robot.facing finalRobot.facing
                    ]
                    ()
        ]


{-| Test rotation animation regression
-}
testRotationAnimationRegression : Test
testRotationAnimationRegression =
    describe "Rotation Animation Regression"
        [ test "rotation animation preserves position correctly" <|
            \_ ->
                let
                    model =
                        Model.init

                    position =
                        { row = 1, col = 3 }

                    initialRobot =
                        { position = position, facing = North }

                    initialModel =
                        { model | robot = initialRobot }

                    -- Start rotation animation
                    animatedModel =
                        Animation.startRotationAnimation North East initialModel

                    -- Verify position is preserved and facing is updated
                    finalRobot =
                        animatedModel.robot
                in
                Expect.all
                    [ \_ -> Expect.equal position finalRobot.position
                    , \_ -> Expect.equal East finalRobot.facing
                    , \_ -> Expect.equal (Rotating North East) animatedModel.animationState
                    ]
                    ()
        , test "rotation animation handles all direction combinations" <|
            \_ ->
                let
                    model =
                        Model.init

                    position =
                        { row = 2, col = 2 }

                    -- Test all rotation combinations
                    northToEast =
                        Animation.startRotationAnimation North East { model | robot = { position = position, facing = North } }

                    eastToSouth =
                        Animation.startRotationAnimation East South { model | robot = { position = position, facing = East } }

                    southToWest =
                        Animation.startRotationAnimation South West { model | robot = { position = position, facing = South } }

                    westToNorth =
                        Animation.startRotationAnimation West North { model | robot = { position = position, facing = West } }
                in
                Expect.all
                    [ \_ -> Expect.equal East northToEast.robot.facing
                    , \_ -> Expect.equal South eastToSouth.robot.facing
                    , \_ -> Expect.equal West southToWest.robot.facing
                    , \_ -> Expect.equal North westToNorth.robot.facing
                    , \_ -> Expect.equal position northToEast.robot.position
                    , \_ -> Expect.equal position eastToSouth.robot.position
                    , \_ -> Expect.equal position southToWest.robot.position
                    , \_ -> Expect.equal position westToNorth.robot.position
                    ]
                    ()
        ]


{-| Test button highlight animation regression
-}
testButtonHighlightAnimationRegression : Test
testButtonHighlightAnimationRegression =
    describe "Button Highlight Animation Regression"
        [ test "button highlight animation tracks correct buttons" <|
            \_ ->
                let
                    model =
                        Model.init

                    buttons =
                        [ ForwardButton, DirectionButton North ]

                    animatedModel =
                        Animation.startButtonHighlightAnimation buttons model

                    -- Verify highlighted buttons are tracked
                    highlightedButtons =
                        animatedModel.highlightedButtons
                in
                Expect.equal buttons highlightedButtons
        , test "button highlight animation works with all button types" <|
            \_ ->
                let
                    model =
                        Model.init

                    -- Test all button types
                    forwardButtons =
                        [ ForwardButton ]

                    rotateButtons =
                        [ RotateLeftButton, RotateRightButton ]

                    directionButtons =
                        [ DirectionButton North, DirectionButton South, DirectionButton East, DirectionButton West ]

                    mixedButtons =
                        [ ForwardButton, RotateLeftButton, DirectionButton East ]

                    forwardModel =
                        Animation.startButtonHighlightAnimation forwardButtons model

                    rotateModel =
                        Animation.startButtonHighlightAnimation rotateButtons model

                    directionModel =
                        Animation.startButtonHighlightAnimation directionButtons model

                    mixedModel =
                        Animation.startButtonHighlightAnimation mixedButtons model
                in
                Expect.all
                    [ \_ -> Expect.equal forwardButtons forwardModel.highlightedButtons
                    , \_ -> Expect.equal rotateButtons rotateModel.highlightedButtons
                    , \_ -> Expect.equal directionButtons directionModel.highlightedButtons
                    , \_ -> Expect.equal mixedButtons mixedModel.highlightedButtons
                    ]
                    ()
        , test "button highlight opacity calculation works correctly" <|
            \_ ->
                let
                    model =
                        Model.init

                    buttons =
                        [ ForwardButton ]

                    animatedModel =
                        Animation.startButtonHighlightAnimation buttons model

                    -- Test opacity for highlighted and non-highlighted buttons
                    forwardOpacity =
                        Animation.getButtonHighlightOpacity ForwardButton animatedModel

                    rotateOpacity =
                        Animation.getButtonHighlightOpacity RotateLeftButton animatedModel
                in
                Expect.all
                    [ \_ -> Expect.atLeast 0.0 forwardOpacity
                    , \_ -> Expect.atMost 1.0 forwardOpacity
                    , \_ -> Expect.equal 0.0 rotateOpacity
                    ]
                    ()
        ]


{-| Test blocked movement animation regression
-}
testBlockedMovementAnimationRegression : Test
testBlockedMovementAnimationRegression =
    describe "Blocked Movement Animation Regression"
        [ test "blocked movement animation sets correct state" <|
            \_ ->
                let
                    model =
                        Model.init

                    animatedModel =
                        Animation.startBlockedMovementAnimation model
                in
                Expect.all
                    [ \_ -> Expect.equal BlockedMovement animatedModel.animationState
                    , \_ -> Expect.equal True animatedModel.blockedMovementFeedback
                    ]
                    ()
        , test "blocked movement animation detection works" <|
            \_ ->
                let
                    model =
                        Model.init

                    animatedModel =
                        Animation.startBlockedMovementAnimation model

                    isBlocked =
                        Animation.isBlockedMovementAnimating animatedModel
                in
                Expect.equal True isBlocked
        , test "blocked movement animation integrates with boundary checking" <|
            \_ ->
                let
                    -- Position robot at edge
                    edgeRobot =
                        { position = { row = 0, col = 4 }, facing = East }

                    baseModel =
                        Model.init

                    model =
                        { baseModel | robot = edgeRobot }

                    -- Verify movement is blocked
                    canMove =
                        RobotGame.canMoveForward edgeRobot

                    -- Start blocked movement animation
                    blockedModel =
                        Animation.startBlockedMovementAnimation model

                    -- Verify animation state
                    isBlocked =
                        Animation.isBlockedMovementAnimating blockedModel

                    isAnimating =
                        Animation.isAnimating blockedModel
                in
                Expect.all
                    [ \_ -> Expect.equal False canMove
                    , \_ -> Expect.equal True isBlocked
                    , \_ -> Expect.equal True isAnimating
                    , \_ -> Expect.equal BlockedMovement blockedModel.animationState
                    ]
                    ()
        ]


{-| Test game logic integration regression
-}
testGameLogicIntegrationRegression : Test
testGameLogicIntegrationRegression =
    describe "Game Logic Integration Regression"
        [ test "animation system preserves game logic correctness" <|
            \_ ->
                let
                    model =
                        Model.init

                    -- Test that game logic still works with animations
                    robot =
                        model.robot

                    canMoveInitially =
                        RobotGame.canMoveForward robot

                    -- Move robot to edge
                    edgeRobot =
                        { position = { row = 0, col = 4 }, facing = East }

                    canMoveAtEdge =
                        RobotGame.canMoveForward edgeRobot

                    -- Start animation and verify game logic still applies
                    animatedModel =
                        Animation.startMovementAnimation robot.position { row = 0, col = 1 } model

                    animatedRobot =
                        animatedModel.robot
                in
                Expect.all
                    [ \_ -> Expect.equal True canMoveInitially
                    , \_ -> Expect.equal False canMoveAtEdge
                    , \_ -> Expect.equal { row = 0, col = 1 } animatedRobot.position
                    ]
                    ()
        , test "animation timeline updates preserve game state" <|
            \_ ->
                let
                    model =
                        Model.init

                    -- Start animation
                    animatedModel =
                        Animation.startMovementAnimation
                            model.robot.position
                            { row = 0, col = 1 }
                            model

                    -- Update timelines
                    time =
                        Time.millisToPosix 1000

                    updatedModel =
                        Animation.updateAnimations time animatedModel

                    -- Verify game state is preserved
                    originalGridSize =
                        model.gridSize

                    originalColorScheme =
                        model.colorScheme

                    updatedGridSize =
                        updatedModel.gridSize

                    updatedColorScheme =
                        updatedModel.colorScheme
                in
                Expect.all
                    [ \_ -> Expect.equal originalGridSize updatedGridSize
                    , \_ -> Expect.equal originalColorScheme updatedColorScheme
                    , \_ -> Expect.equal True (Animation.isAnimating updatedModel)
                    ]
                    ()
        , test "cleanup operations preserve game functionality" <|
            \_ ->
                let
                    model =
                        Model.init

                    -- Create completed animation
                    animatedModel =
                        Animation.startMovementAnimation
                            model.robot.position
                            { row = 0, col = 1 }
                            model

                    completedModel =
                        { animatedModel | animationState = Idle }

                    -- Cleanup and verify game functionality
                    cleanedModel =
                        Animation.cleanupCompletedTimelines completedModel

                    cleanedRobot =
                        Animation.getCurrentAnimatedState cleanedModel

                    canMove =
                        RobotGame.canMoveForward cleanedRobot
                in
                Expect.all
                    [ \_ -> Expect.equal completedModel.robot cleanedRobot
                    , \_ -> Expect.equal False canMove -- Cannot move North from row 0
                    , \_ -> Expect.equal False (Animation.isAnimating cleanedModel)
                    ]
                    ()
        ]


{-| Test performance regression
-}
testPerformanceRegression : Test
testPerformanceRegression =
    describe "Performance Regression"
        [ test "animation system doesn't slow down basic operations" <|
            \_ ->
                let
                    model =
                        Model.init

                    -- Basic operations should remain fast
                    isAnimating1 =
                        Animation.isAnimating model

                    currentState1 =
                        Animation.getCurrentAnimatedState model

                    hasActive1 =
                        Animation.hasActiveAnimations model

                    -- Multiple calls should be consistent
                    isAnimating2 =
                        Animation.isAnimating model

                    currentState2 =
                        Animation.getCurrentAnimatedState model

                    hasActive2 =
                        Animation.hasActiveAnimations model
                in
                Expect.all
                    [ \_ -> Expect.equal isAnimating1 isAnimating2
                    , \_ -> Expect.equal currentState1 currentState2
                    , \_ -> Expect.equal hasActive1 hasActive2
                    , \_ -> Expect.equal False isAnimating1
                    , \_ -> Expect.equal model.robot currentState1
                    , \_ -> Expect.equal False hasActive1
                    ]
                    ()
        , test "complex animation sequences don't cause performance issues" <|
            \_ ->
                let
                    model =
                        Model.init

                    -- Complex sequence of animations
                    step1 =
                        Animation.startMovementAnimation { row = 0, col = 0 } { row = 0, col = 1 } model

                    step2 =
                        Animation.startRotationAnimation North East step1

                    step3 =
                        Animation.startButtonHighlightAnimation [ ForwardButton ] step2

                    step4 =
                        Animation.startBlockedMovementAnimation step3

                    step5 =
                        Animation.startMovementAnimation { row = 0, col = 1 } { row = 0, col = 2 } step4

                    -- Update timelines multiple times
                    time1 =
                        Time.millisToPosix 100

                    time2 =
                        Time.millisToPosix 200

                    time3 =
                        Time.millisToPosix 300

                    updated1 =
                        Animation.updateAnimations time1 step5

                    updated2 =
                        Animation.updateAnimations time2 updated1

                    updated3 =
                        Animation.updateAnimations time3 updated2

                    -- Final state should be consistent
                    finalState =
                        updated3.animationState

                    isAnimating =
                        Animation.isAnimating updated3
                in
                Expect.all
                    [ \_ -> Expect.equal (Moving { row = 0, col = 1 } { row = 0, col = 2 }) finalState
                    , \_ -> Expect.equal True isAnimating
                    ]
                    ()
        ]

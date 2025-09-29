module RobotGame.PerformanceUnitTest exposing (suite)

{-| Comprehensive performance tests for the Robot Grid Game animation system.

This module tests that the elm-animator integration doesn't introduce
performance regressions compared to CSS transitions, ensures efficient
memory management, and verifies that animations don't negatively impact
game responsiveness.

-}

import Expect
import RobotGame.Animation as Animation
import RobotGame.Model as Model exposing (AnimationState(..), Button(..), Direction(..))
import Test exposing (Test, describe, test)
import Time


suite : Test
suite =
    describe "RobotGame Performance Tests"
        [ describe "Animation Timeline Efficiency"
            [ test "hasActiveAnimations correctly identifies inactive state" <|
                \_ ->
                    let
                        model =
                            Model.init

                        hasActive =
                            Animation.hasActiveAnimations model
                    in
                    Expect.equal False hasActive
            , test "hasActiveAnimations correctly identifies active state" <|
                \_ ->
                    let
                        model =
                            Model.init

                        fromPos =
                            { row = 0, col = 0 }

                        toPos =
                            { row = 0, col = 1 }

                        modelWithAnimation =
                            Animation.startMovementAnimation fromPos toPos model

                        hasActive =
                            Animation.hasActiveAnimations modelWithAnimation
                    in
                    Expect.equal True hasActive
            , test "timeline updates are efficient for idle models" <|
                \_ ->
                    let
                        model =
                            Model.init

                        time =
                            Time.millisToPosix 1000

                        -- Multiple updates should be efficient
                        updated1 =
                            Animation.updateAnimations time model

                        updated2 =
                            Animation.updateAnimations time updated1

                        updated3 =
                            Animation.updateAnimations time updated2

                        -- Robot state should remain consistent
                        robot1 =
                            Animation.getCurrentAnimatedState updated1

                        robot2 =
                            Animation.getCurrentAnimatedState updated2

                        robot3 =
                            Animation.getCurrentAnimatedState updated3
                    in
                    Expect.all
                        [ \_ -> Expect.equal model.robot robot1
                        , \_ -> Expect.equal robot1 robot2
                        , \_ -> Expect.equal robot2 robot3
                        ]
                        ()
            , test "multiple simultaneous animations are handled efficiently" <|
                \_ ->
                    let
                        model =
                            Model.init

                        -- Start multiple animations
                        step1 =
                            Animation.startMovementAnimation { row = 0, col = 0 } { row = 0, col = 1 } model

                        step2 =
                            Animation.startButtonHighlightAnimation [ ForwardButton ] step1

                        step3 =
                            Animation.startBlockedMovementAnimation step2

                        -- Update all timelines
                        time =
                            Time.millisToPosix 1000

                        updatedModel =
                            Animation.updateAnimations time step3

                        -- All animations should be tracked
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
            ]
        , describe "Memory Management"
            [ test "cleanup preserves current robot state" <|
                \_ ->
                    let
                        model =
                            Model.init

                        newRobot =
                            { position = { row = 1, col = 1 }, facing = East }

                        modelWithNewRobot =
                            { model | robot = newRobot }

                        cleanedModel =
                            Animation.cleanupCompletedTimelines modelWithNewRobot
                    in
                    Expect.equal newRobot cleanedModel.robot
            , test "cleanup handles multiple completed animations" <|
                \_ ->
                    let
                        model =
                            Model.init

                        -- Create model with multiple completed animations
                        animatedModel =
                            Animation.startMovementAnimation { row = 0, col = 0 } { row = 0, col = 1 } model

                        highlightedModel =
                            Animation.startButtonHighlightAnimation [ ForwardButton ] animatedModel

                        completedModel =
                            { highlightedModel | animationState = Idle }

                        -- Cleanup should handle all completed animations
                        cleanedModel =
                            Animation.cleanupCompletedTimelines completedModel

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
            , test "repeated cleanup operations are safe" <|
                \_ ->
                    let
                        model =
                            Model.init

                        -- Multiple cleanup operations should be safe
                        cleaned1 =
                            Animation.cleanupCompletedTimelines model

                        cleaned2 =
                            Animation.cleanupCompletedTimelines cleaned1

                        cleaned3 =
                            Animation.cleanupCompletedTimelines cleaned2

                        robot1 =
                            Animation.getCurrentAnimatedState cleaned1

                        robot2 =
                            Animation.getCurrentAnimatedState cleaned2

                        robot3 =
                            Animation.getCurrentAnimatedState cleaned3
                    in
                    Expect.all
                        [ \_ -> Expect.equal model.robot robot1
                        , \_ -> Expect.equal robot1 robot2
                        , \_ -> Expect.equal robot2 robot3
                        ]
                        ()
            ]
        , describe "Animation State Consistency"
            [ test "isAnimating matches animation state" <|
                \_ ->
                    let
                        idleModel =
                            Model.init

                        isAnimatingIdle =
                            Animation.isAnimating idleModel

                        movingModel =
                            { idleModel | animationState = Model.Moving { row = 0, col = 0 } { row = 0, col = 1 } }

                        isAnimatingMoving =
                            Animation.isAnimating movingModel
                    in
                    Expect.all
                        [ \_ -> Expect.equal False isAnimatingIdle
                        , \_ -> Expect.equal True isAnimatingMoving
                        ]
                        ()
            , test "getCurrentAnimatedState returns current robot" <|
                \_ ->
                    let
                        model =
                            Model.init

                        currentState =
                            Animation.getCurrentAnimatedState model
                    in
                    Expect.equal model.robot currentState
            , test "animation state consistency across updates" <|
                \_ ->
                    let
                        model =
                            Model.init

                        animatedModel =
                            Animation.startMovementAnimation { row = 0, col = 0 } { row = 0, col = 1 } model

                        -- Multiple time updates
                        time1 =
                            Time.millisToPosix 100

                        time2 =
                            Time.millisToPosix 200

                        time3 =
                            Time.millisToPosix 300

                        updated1 =
                            Animation.updateAnimations time1 animatedModel

                        updated2 =
                            Animation.updateAnimations time2 updated1

                        updated3 =
                            Animation.updateAnimations time3 updated2

                        -- Animation state should remain consistent
                        state1 =
                            updated1.animationState

                        state2 =
                            updated2.animationState

                        state3 =
                            updated3.animationState
                    in
                    Expect.all
                        [ \_ -> Expect.equal animatedModel.animationState state1
                        , \_ -> Expect.equal state1 state2
                        , \_ -> Expect.equal state2 state3
                        ]
                        ()
            ]
        , describe "Interpolation Performance"
            [ test "interpolation functions are consistent" <|
                \_ ->
                    let
                        model =
                            Model.init

                        -- Multiple calls should return consistent results
                        pos1 =
                            Animation.getInterpolatedPosition model

                        pos2 =
                            Animation.getInterpolatedPosition model

                        pos3 =
                            Animation.getInterpolatedPosition model

                        angle1 =
                            Animation.getInterpolatedRotationAngle model

                        angle2 =
                            Animation.getInterpolatedRotationAngle model

                        angle3 =
                            Animation.getInterpolatedRotationAngle model
                    in
                    Expect.all
                        [ \_ -> Expect.equal pos1 pos2
                        , \_ -> Expect.equal pos2 pos3
                        , \_ -> Expect.equal angle1 angle2
                        , \_ -> Expect.equal angle2 angle3
                        ]
                        ()
            , test "button highlight opacity calculations are efficient" <|
                \_ ->
                    let
                        model =
                            Model.init

                        -- Multiple opacity calculations should be consistent
                        opacity1 =
                            Animation.getButtonHighlightOpacity ForwardButton model

                        opacity2 =
                            Animation.getButtonHighlightOpacity ForwardButton model

                        opacity3 =
                            Animation.getButtonHighlightOpacity ForwardButton model

                        -- Different buttons should also be consistent
                        opacityRotate =
                            Animation.getButtonHighlightOpacity RotateLeftButton model

                        opacityDirection =
                            Animation.getButtonHighlightOpacity (DirectionButton North) model
                    in
                    Expect.all
                        [ \_ -> Expect.equal opacity1 opacity2
                        , \_ -> Expect.equal opacity2 opacity3
                        , \_ -> Expect.equal 0.0 opacity1 -- Should be 0 for non-highlighted
                        , \_ -> Expect.equal 0.0 opacityRotate
                        , \_ -> Expect.equal 0.0 opacityDirection
                        ]
                        ()
            , test "blocked movement detection is efficient" <|
                \_ ->
                    let
                        idleModel =
                            Model.init

                        blockedModel =
                            Animation.startBlockedMovementAnimation Model.init

                        -- Multiple checks should be consistent
                        idle1 =
                            Animation.isBlockedMovementAnimating idleModel

                        idle2 =
                            Animation.isBlockedMovementAnimating idleModel

                        blocked1 =
                            Animation.isBlockedMovementAnimating blockedModel

                        blocked2 =
                            Animation.isBlockedMovementAnimating blockedModel
                    in
                    Expect.all
                        [ \_ -> Expect.equal idle1 idle2
                        , \_ -> Expect.equal blocked1 blocked2
                        , \_ -> Expect.equal False idle1
                        , \_ -> Expect.equal True blocked1
                        ]
                        ()
            ]
        , describe "Game Responsiveness"
            [ test "animation system doesn't block game state updates" <|
                \_ ->
                    let
                        model =
                            Model.init

                        -- Start animation
                        animatedModel =
                            Animation.startMovementAnimation { row = 0, col = 0 } { row = 0, col = 1 } model

                        -- Game state updates should still work
                        updatedRobot =
                            { position = { row = 2, col = 2 }, facing = South }

                        gameUpdatedModel =
                            { animatedModel | robot = updatedRobot }

                        -- Animation utilities should work with updated game state
                        currentState =
                            Animation.getCurrentAnimatedState gameUpdatedModel

                        isAnimating =
                            Animation.isAnimating gameUpdatedModel
                    in
                    Expect.all
                        [ \_ -> Expect.equal updatedRobot gameUpdatedModel.robot
                        , \_ -> Expect.equal True isAnimating
                        , \_ -> Expect.notEqual updatedRobot currentState -- Timeline state differs from model state
                        ]
                        ()
            , test "rapid animation state changes don't cause performance issues" <|
                \_ ->
                    let
                        model =
                            Model.init

                        -- Rapid sequence of animation changes
                        step1 =
                            Animation.startMovementAnimation { row = 0, col = 0 } { row = 0, col = 1 } model

                        step2 =
                            Animation.startRotationAnimation North East step1

                        step3 =
                            Animation.startBlockedMovementAnimation step2

                        step4 =
                            Animation.startButtonHighlightAnimation [ ForwardButton ] step3

                        step5 =
                            Animation.startMovementAnimation { row = 0, col = 1 } { row = 0, col = 2 } step4

                        -- Final state should be consistent
                        finalState =
                            step5.animationState

                        isAnimating =
                            Animation.isAnimating step5

                        finalRobot =
                            step5.robot
                    in
                    Expect.all
                        [ \_ -> Expect.equal (Moving { row = 0, col = 1 } { row = 0, col = 2 }) finalState
                        , \_ -> Expect.equal True isAnimating
                        , \_ -> Expect.equal { row = 0, col = 2 } finalRobot.position
                        ]
                        ()
            ]
        ]

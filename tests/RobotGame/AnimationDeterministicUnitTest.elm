module RobotGame.AnimationDeterministicUnitTest exposing (suite)

import Expect
import RobotGame.Animation as Animation
import RobotGame.Model exposing (AnimationState(..), Direction(..))
import RobotGame.TestUtils.AnimationTestHelpers as Helpers
import RobotGame.TestUtils.DeterministicAnimator as DeterministicAnimator
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "RobotGame deterministic animation framework"
        [ baseModelTests
        , movementSequenceTests
        , rotationSequenceTests
        , blockedMovementSequenceTests
        ]


baseModelTests : Test
baseModelTests =
    describe "Base model helpers"
        [ test "baseModel seeds deterministic timeline state" <|
            \_ ->
                Helpers.baseModel
                    |> Expect.all
                        [ Helpers.expectAnimationState Idle
                        , Helpers.expectRobotMatchesTimeline
                        , Helpers.expectNoActiveAnimations
                        , \model -> Expect.equal 0.0 (Animation.getInterpolatedRotationAngle model)
                        ]
        , test "modelWithState seeds matching robot and rotation timelines" <|
            \_ ->
                let
                    model =
                        Helpers.modelWithState { row = 1, col = 3 } East Idle
                in
                model
                    |> Expect.all
                        [ Helpers.expectRobotPosition { row = 1, col = 3 }
                        , Helpers.expectRobotFacing East
                        , Helpers.expectAnimationState Idle
                        , Helpers.expectRobotMatchesTimeline
                        , \m -> Expect.equal 90.0 (Animation.getInterpolatedRotationAngle m)
                        ]
        ]


movementSequenceTests : Test
movementSequenceTests =
    describe "Movement sequence helpers"
        [ test "same movement frame sequence always settles to the same final state" <|
            \_ ->
                let
                    fromPos =
                        { row = 2, col = 2 }

                    toPos =
                        { row = 2, col = 3 }

                    animated =
                        Animation.startMovementAnimation fromPos toPos (Helpers.modelWithState fromPos East Idle)

                    firstRun =
                        animated
                            |> DeterministicAnimator.frames [ 0, 150, 300 ]
                            |> DeterministicAnimator.finish

                    secondRun =
                        animated
                            |> DeterministicAnimator.frames [ 0, 150, 300 ]
                            |> DeterministicAnimator.finish
                in
                firstRun
                    |> Expect.all
                        [ Helpers.expectRobotPosition toPos
                        , Helpers.expectAnimationState Idle
                        , Helpers.expectRobotMatchesTimeline
                        , Helpers.expectNoActiveAnimations
                        , \model -> Expect.equal toPos model.robot.position
                        , \_ -> Expect.equal firstRun.robot secondRun.robot
                        ]
        ]


rotationSequenceTests : Test
rotationSequenceTests =
    describe "Rotation sequence helpers"
        [ test "rotation frames preserve position while settling deterministically" <|
            \_ ->
                let
                    startPosition =
                        { row = 1, col = 1 }

                    animated =
                        Animation.startRotationAnimation North East (Helpers.modelWithState startPosition North Idle)

                    settled =
                        animated
                            |> DeterministicAnimator.frames [ 0, 100, 200 ]
                            |> DeterministicAnimator.finish
                in
                settled
                    |> Expect.all
                        [ Helpers.expectRobotPosition startPosition
                        , Helpers.expectRobotFacing East
                        , Helpers.expectAnimationState Idle
                        , Helpers.expectRobotMatchesTimeline
                        , Helpers.expectNoActiveAnimations
                        , \model -> Expect.equal 90.0 (Animation.getInterpolatedRotationAngle model)
                        ]
        ]


blockedMovementSequenceTests : Test
blockedMovementSequenceTests =
    describe "Blocked movement sequence helpers"
        [ test "blocked movement frames clear the legacy feedback state deterministically" <|
            \_ ->
                let
                    settled =
                        Animation.startBlockedMovementAnimation Helpers.baseModel
                            |> DeterministicAnimator.frames [ 0, 100, 200 ]
                            |> DeterministicAnimator.finish
                in
                settled
                    |> Expect.all
                        [ Helpers.expectAnimationState Idle
                        , Helpers.expectRobotMatchesTimeline
                        , Helpers.expectNoActiveAnimations
                        , \model -> Expect.equal False model.blockedMovementFeedback
                        , \model -> Expect.equal False (Animation.isBlockedMovementAnimating model)
                        ]
        ]

module RobotGame.TestUtils.AnimationTestHelpers exposing
    ( baseModel
    , expectAnimationState
    , expectHighlightedButtons
    , expectNoActiveAnimations
    , expectRobotFacing
    , expectRobotMatchesTimeline
    , expectRobotPosition
    , modelWithRobot
    , modelWithState
    )

import Animator
import Expect exposing (Expectation)
import RobotGame.Animation as Animation
import RobotGame.Model as Model exposing (AnimationState, Button, Direction, Model, Position, Robot)


baseModel : Model
baseModel =
    Model.init


modelWithRobot : Robot -> Model
modelWithRobot robot =
    { baseModel
        | robot = robot
        , robotTimeline = Animator.init robot
        , rotationAngleTimeline = Animator.init (Model.directionToAngleFloat robot.facing)
    }


modelWithState : Position -> Direction -> AnimationState -> Model
modelWithState position facing animationState =
    let
        robotModel =
            modelWithRobot { position = position, facing = facing }
    in
    { robotModel | animationState = animationState }


expectRobotPosition : Position -> Model -> Expectation
expectRobotPosition expected model =
    Expect.equal expected model.robot.position


expectRobotFacing : Direction -> Model -> Expectation
expectRobotFacing expected model =
    Expect.equal expected model.robot.facing


expectAnimationState : AnimationState -> Model -> Expectation
expectAnimationState expected model =
    Expect.equal expected model.animationState


expectHighlightedButtons : List Button -> Model -> Expectation
expectHighlightedButtons expected model =
    Expect.equal expected model.highlightedButtons


expectRobotMatchesTimeline : Model -> Expectation
expectRobotMatchesTimeline model =
    Expect.equal model.robot (Animation.getCurrentAnimatedState model)


expectNoActiveAnimations : Model -> Expectation
expectNoActiveAnimations model =
    Expect.equal False (Animation.hasActiveAnimations model)

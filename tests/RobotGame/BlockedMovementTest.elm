module RobotGame.BlockedMovementTest exposing (suite)

import Expect
import RobotGame.Main exposing (Msg(..), update)
import RobotGame.Model exposing (AnimationState(..), Direction(..), Model, Robot)
import Test exposing (..)
import Theme.Theme exposing (ColorScheme(..))


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


suite : Test
suite =
    describe "Blocked Movement Validation and Visual Feedback"
        [ boundaryValidationTests
        , visualFeedbackTests
        , statePreservationTests
        , animationStateTests
        ]


boundaryValidationTests : Test
boundaryValidationTests =
    describe "Boundary Validation"
        [ test "Robot cannot move North from top edge (row 0)" <|
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
        , test "Robot cannot move South from bottom edge (row 4)" <|
            \_ ->
                let
                    robot =
                        { position = { row = 4, col = 2 }, facing = South }

                    initialModel =
                        createModelWithRobot robot

                    ( updatedModel, _ ) =
                        update MoveForward initialModel
                in
                Expect.all
                    [ \m -> Expect.equal { row = 4, col = 2 } m.robot.position
                    , \m -> Expect.equal South m.robot.facing
                    , \m -> Expect.equal BlockedMovement m.animationState
                    , \m -> Expect.equal True m.blockedMovementFeedback
                    ]
                    updatedModel
        , test "Robot cannot move East from right edge (col 4)" <|
            \_ ->
                let
                    robot =
                        { position = { row = 2, col = 4 }, facing = East }

                    initialModel =
                        createModelWithRobot robot

                    ( updatedModel, _ ) =
                        update MoveForward initialModel
                in
                Expect.all
                    [ \m -> Expect.equal { row = 2, col = 4 } m.robot.position
                    , \m -> Expect.equal East m.robot.facing
                    , \m -> Expect.equal BlockedMovement m.animationState
                    , \m -> Expect.equal True m.blockedMovementFeedback
                    ]
                    updatedModel
        , test "Robot cannot move West from left edge (col 0)" <|
            \_ ->
                let
                    robot =
                        { position = { row = 2, col = 0 }, facing = West }

                    initialModel =
                        createModelWithRobot robot

                    ( updatedModel, _ ) =
                        update MoveForward initialModel
                in
                Expect.all
                    [ \m -> Expect.equal { row = 2, col = 0 } m.robot.position
                    , \m -> Expect.equal West m.robot.facing
                    , \m -> Expect.equal BlockedMovement m.animationState
                    , \m -> Expect.equal True m.blockedMovementFeedback
                    ]
                    updatedModel
        , test "Robot can move when not at boundary" <|
            \_ ->
                let
                    robot =
                        { position = { row = 2, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot robot

                    ( updatedModel, _ ) =
                        update MoveForward initialModel
                in
                Expect.all
                    [ \m -> Expect.equal { row = 1, col = 2 } m.robot.position
                    , \m -> Expect.equal North m.robot.facing
                    , \m -> Expect.equal (Moving { row = 2, col = 2 } { row = 1, col = 2 }) m.animationState
                    , \m -> Expect.equal False m.blockedMovementFeedback
                    ]
                    updatedModel
        ]


visualFeedbackTests : Test
visualFeedbackTests =
    describe "Visual Feedback"
        [ test "Blocked movement sets blockedMovementFeedback to True" <|
            \_ ->
                let
                    robot =
                        { position = { row = 0, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot robot

                    ( updatedModel, _ ) =
                        update MoveForward initialModel
                in
                Expect.equal True updatedModel.blockedMovementFeedback
        , test "Successful movement sets blockedMovementFeedback to False" <|
            \_ ->
                let
                    robot =
                        { position = { row = 2, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot robot

                    ( updatedModel, _ ) =
                        update MoveForward initialModel
                in
                Expect.equal False updatedModel.blockedMovementFeedback
        , test "ClearBlockedMovementFeedback resets feedback and animation state" <|
            \_ ->
                let
                    robot =
                        { position = { row = 0, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot robot

                    -- First, trigger blocked movement
                    ( blockedModel, _ ) =
                        update MoveForward initialModel

                    -- Then clear the feedback
                    ( clearedModel, _ ) =
                        update ClearBlockedMovementFeedback blockedModel
                in
                Expect.all
                    [ \m -> Expect.equal False m.blockedMovementFeedback
                    , \m -> Expect.equal Idle m.animationState
                    ]
                    clearedModel
        ]


statePreservationTests : Test
statePreservationTests =
    describe "State Preservation During Blocked Movement"
        [ test "Robot position remains unchanged during blocked movement" <|
            \_ ->
                let
                    robot =
                        { position = { row = 0, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot robot

                    ( updatedModel, _ ) =
                        update MoveForward initialModel
                in
                Expect.equal robot.position updatedModel.robot.position
        , test "Robot facing direction remains unchanged during blocked movement" <|
            \_ ->
                let
                    robot =
                        { position = { row = 0, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot robot

                    ( updatedModel, _ ) =
                        update MoveForward initialModel
                in
                Expect.equal robot.facing updatedModel.robot.facing
        , test "All corner positions are properly blocked" <|
            \_ ->
                let
                    testCornerBlocked position direction =
                        let
                            robot =
                                { position = position, facing = direction }

                            initialModel =
                                createModelWithRobot robot

                            ( updatedModel, _ ) =
                                update MoveForward initialModel
                        in
                        Expect.all
                            [ \m -> Expect.equal position m.robot.position
                            , \m -> Expect.equal direction m.robot.facing
                            , \m -> Expect.equal BlockedMovement m.animationState
                            , \m -> Expect.equal True m.blockedMovementFeedback
                            ]
                            updatedModel
                in
                Expect.all
                    [ \_ -> testCornerBlocked { row = 0, col = 0 } North
                    , \_ -> testCornerBlocked { row = 0, col = 0 } West
                    , \_ -> testCornerBlocked { row = 0, col = 4 } North
                    , \_ -> testCornerBlocked { row = 0, col = 4 } East
                    , \_ -> testCornerBlocked { row = 4, col = 0 } South
                    , \_ -> testCornerBlocked { row = 4, col = 0 } West
                    , \_ -> testCornerBlocked { row = 4, col = 4 } South
                    , \_ -> testCornerBlocked { row = 4, col = 4 } East
                    ]
                    ()
        ]


animationStateTests : Test
animationStateTests =
    describe "Animation State Management"
        [ test "Blocked movement ignores additional move attempts" <|
            \_ ->
                let
                    robot =
                        { position = { row = 0, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot robot

                    -- First blocked movement attempt
                    ( firstAttempt, _ ) =
                        update MoveForward initialModel

                    -- Second blocked movement attempt (should be ignored)
                    ( secondAttempt, _ ) =
                        update MoveForward firstAttempt
                in
                Expect.equal firstAttempt secondAttempt
        , test "Rotation is blocked during blocked movement state" <|
            \_ ->
                let
                    robot =
                        { position = { row = 0, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot robot

                    -- Trigger blocked movement
                    ( blockedModel, _ ) =
                        update MoveForward initialModel

                    -- Try to rotate (should be ignored)
                    ( afterRotateAttempt, _ ) =
                        update RotateLeft blockedModel
                in
                Expect.equal blockedModel afterRotateAttempt
        , test "Movement is allowed after clearing blocked feedback" <|
            \_ ->
                let
                    robot =
                        { position = { row = 1, col = 2 }, facing = North }

                    initialModel =
                        createModelWithRobot robot

                    -- Move to boundary
                    ( atBoundary, _ ) =
                        update MoveForward initialModel

                    ( afterAnimation, _ ) =
                        update AnimationComplete atBoundary

                    -- Try to move beyond boundary (should be blocked)
                    ( blockedModel, _ ) =
                        update MoveForward afterAnimation

                    -- Clear blocked feedback
                    ( clearedModel, _ ) =
                        update ClearBlockedMovementFeedback blockedModel

                    -- Rotate to face a valid direction
                    ( rotatedModel, _ ) =
                        update RotateRight clearedModel

                    ( afterRotation, _ ) =
                        update AnimationComplete rotatedModel

                    -- Now movement should work
                    ( finalModel, _ ) =
                        update MoveForward afterRotation
                in
                Expect.all
                    [ \m -> Expect.equal { row = 0, col = 3 } m.robot.position
                    , \m -> Expect.equal East m.robot.facing
                    , \m -> Expect.equal (Moving { row = 0, col = 2 } { row = 0, col = 3 }) m.animationState
                    , \m -> Expect.equal False m.blockedMovementFeedback
                    ]
                    finalModel
        ]

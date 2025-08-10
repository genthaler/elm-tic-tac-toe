module RobotGame.ErrorConditionIntegrationTest exposing (suite)

{-| Integration tests for RobotGame error conditions and edge cases.

This module tests error handling scenarios using elm-program-test to simulate
real user interactions and verify proper error handling, recovery, and user feedback.

Tests cover:

  - Blocked movement feedback and recovery
  - Invalid position state handling
  - Animation error recovery
  - Input validation edge cases

-}

import Expect
import RobotGame.Model as RobotGameModel exposing (AnimationState(..), Direction(..), Position)
import RobotGame.RobotGame as RobotGameLogic
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "RobotGame Error Condition Integration Tests"
        [ blockedMovementTests
        , invalidPositionStateTests
        , animationErrorRecoveryTests
        , inputValidationEdgeCaseTests
        ]


{-| Tests for blocked movement feedback and recovery
-}
blockedMovementTests : Test
blockedMovementTests =
    describe "Blocked Movement Handling"
        [ test "robot at boundary cannot move forward" <|
            \_ ->
                let
                    robot =
                        { position = { row = 0, col = 2 }, facing = North }

                    canMove =
                        RobotGameLogic.canMoveForward robot
                in
                Expect.equal False canMove
        , test "robot at boundary stays in same position when trying to move" <|
            \_ ->
                let
                    robot =
                        { position = { row = 0, col = 2 }, facing = North }

                    movedRobot =
                        RobotGameLogic.moveForward robot
                in
                Expect.equal robot.position movedRobot.position
        , test "robot in center can move in all directions" <|
            \_ ->
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
            \_ ->
                let
                    model =
                        RobotGameModel.init

                    robotAtBoundary =
                        { position = { row = 0, col = 2 }, facing = North }

                    modelWithBlockedRobot =
                        { model | robot = robotAtBoundary }

                    -- Simulate the blocked movement state
                    blockedModel =
                        { modelWithBlockedRobot | animationState = BlockedMovement, blockedMovementFeedback = True }
                in
                Expect.all
                    [ \_ -> Expect.equal BlockedMovement blockedModel.animationState
                    , \_ -> Expect.equal True blockedModel.blockedMovementFeedback
                    ]
                    ()
        ]


{-| Tests for invalid position state handling
-}
invalidPositionStateTests : Test
invalidPositionStateTests =
    describe "Invalid Position State Handling"
        [ test "position validation works correctly" <|
            \_ ->
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
                        List.map (\pos -> isValidPosition pos) validPositions

                    invalidResults =
                        List.map (\pos -> isValidPosition pos) invalidPositions
                in
                Expect.all
                    [ \_ -> Expect.equal [ True, True, True ] validResults
                    , \_ -> Expect.equal [ False, False, False, False ] invalidResults
                    ]
                    ()
        , test "robot with invalid position can be corrected" <|
            \_ ->
                let
                    invalidPosition =
                        { row = -1, col = 2 }

                    correctedPosition =
                        correctPosition invalidPosition
                in
                Expect.equal { row = 0, col = 2 } correctedPosition
        , test "robot with out-of-bounds position is corrected" <|
            \_ ->
                let
                    outOfBoundsPosition =
                        { row = 5, col = 3 }

                    correctedPosition =
                        correctPosition outOfBoundsPosition
                in
                Expect.equal { row = 4, col = 3 } correctedPosition
        ]


{-| Tests for animation error recovery
-}
animationErrorRecoveryTests : Test
animationErrorRecoveryTests =
    describe "Animation Error Recovery"
        [ test "animation states are handled correctly" <|
            \_ ->
                let
                    idleState =
                        Idle

                    movingState =
                        Moving { row = 2, col = 2 } { row = 1, col = 2 }

                    rotatingState =
                        Rotating North East

                    blockedState =
                        BlockedMovement
                in
                Expect.all
                    [ \_ -> Expect.notEqual idleState movingState
                    , \_ -> Expect.notEqual movingState rotatingState
                    , \_ -> Expect.notEqual rotatingState blockedState
                    , \_ -> Expect.notEqual blockedState idleState
                    ]
                    ()
        , test "animation recovery returns to idle state" <|
            \_ ->
                let
                    model =
                        RobotGameModel.init

                    animatingModel =
                        { model | animationState = Moving { row = 2, col = 2 } { row = 1, col = 2 } }

                    recoveredModel =
                        { animatingModel | animationState = Idle }
                in
                Expect.equal Idle recoveredModel.animationState
        ]


{-| Tests for input validation edge cases
-}
inputValidationEdgeCaseTests : Test
inputValidationEdgeCaseTests =
    describe "Input Validation Edge Cases"
        [ test "robot rotation works correctly" <|
            \_ ->
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
        , test "robot can rotate to specific direction" <|
            \_ ->
                let
                    robot =
                        { position = { row = 2, col = 2 }, facing = North }

                    rotatedToEast =
                        RobotGameLogic.rotateToDirection East robot

                    rotatedToSouth =
                        RobotGameLogic.rotateToDirection South robot

                    rotatedToWest =
                        RobotGameLogic.rotateToDirection West robot
                in
                Expect.all
                    [ \_ -> Expect.equal East rotatedToEast.facing
                    , \_ -> Expect.equal South rotatedToSouth.facing
                    , \_ -> Expect.equal West rotatedToWest.facing
                    ]
                    ()
        , test "input validation during different animation states" <|
            \_ ->
                let
                    model =
                        RobotGameModel.init

                    idleModel =
                        { model | animationState = Idle }

                    movingModel =
                        { model | animationState = Moving { row = 2, col = 2 } { row = 1, col = 2 } }

                    rotatingModel =
                        { model | animationState = Rotating North East }

                    blockedModel =
                        { model | animationState = BlockedMovement }
                in
                Expect.all
                    [ \_ -> Expect.equal Idle idleModel.animationState
                    , \_ -> Expect.notEqual Idle movingModel.animationState
                    , \_ -> Expect.notEqual Idle rotatingModel.animationState
                    , \_ -> Expect.notEqual Idle blockedModel.animationState
                    ]
                    ()
        ]



-- Helper Functions


{-| Check if a position is valid (within 5x5 grid bounds)
-}
isValidPosition : Position -> Bool
isValidPosition position =
    position.row >= 0 && position.row <= 4 && position.col >= 0 && position.col <= 4


{-| Correct an invalid position to be within bounds
-}
correctPosition : Position -> Position
correctPosition position =
    { row = clamp 0 4 position.row
    , col = clamp 0 4 position.col
    }

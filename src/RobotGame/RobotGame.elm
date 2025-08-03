module RobotGame.RobotGame exposing
    ( moveForward, canMoveForward
    , rotateLeft, rotateRight, rotateOpposite, rotateToDirection
    )

{-| Core game logic for the Robot Grid Game.

This module provides functions for robot movement and rotation with proper
boundary checking and validation for a 5x5 grid.


# Movement

@docs moveForward, canMoveForward


# Rotation

@docs rotateLeft, rotateRight, rotateOpposite, rotateToDirection

-}

import RobotGame.Model exposing (Direction(..), Position, Robot)



-- MOVEMENT FUNCTIONS


{-| Check if the robot can move forward in its current facing direction
without going outside the 5x5 grid boundaries.

    robot = { position = { row = 0, col = 2 }, facing = North }
    canMoveForward robot --> False

    robot = { position = { row = 1, col = 2 }, facing = North }
    canMoveForward robot --> True

-}
canMoveForward : Robot -> Bool
canMoveForward robot =
    let
        newPosition =
            getNextPosition robot.position robot.facing
    in
    isValidPosition newPosition


{-| Move the robot forward one cell in its current facing direction.
Returns the robot unchanged if the move would go outside grid boundaries.

    robot = { position = { row = 2, col = 2 }, facing = North }
    moveForward robot --> { position = { row = 1, col = 2 }, facing = North }

    robot = { position = { row = 0, col = 2 }, facing = North }
    moveForward robot --> { position = { row = 0, col = 2 }, facing = North }

-}
moveForward : Robot -> Robot
moveForward robot =
    if canMoveForward robot then
        { robot | position = getNextPosition robot.position robot.facing }

    else
        robot



-- ROTATION FUNCTIONS


{-| Rotate the robot 90 degrees to the left (counterclockwise).
The robot's position remains unchanged.

    robot = { position = { row = 2, col = 2 }, facing = North }
    rotateLeft robot --> { position = { row = 2, col = 2 }, facing = West }

    robot = { position = { row = 2, col = 2 }, facing = West }
    rotateLeft robot --> { position = { row = 2, col = 2 }, facing = South }

-}
rotateLeft : Robot -> Robot
rotateLeft robot =
    { robot | facing = getLeftDirection robot.facing }


{-| Rotate the robot 90 degrees to the right (clockwise).
The robot's position remains unchanged.

    robot = { position = { row = 2, col = 2 }, facing = North }
    rotateRight robot --> { position = { row = 2, col = 2 }, facing = East }

    robot = { position = { row = 2, col = 2 }, facing = East }
    rotateRight robot --> { position = { row = 2, col = 2 }, facing = South }

-}
rotateRight : Robot -> Robot
rotateRight robot =
    { robot | facing = getRightDirection robot.facing }


{-| Rotate the robot 180 degrees to face the opposite direction.
The robot's position remains unchanged.

    robot = { position = { row = 2, col = 2 }, facing = North }
    rotateOpposite robot --> { position = { row = 2, col = 2 }, facing = South }

    robot = { position = { row = 2, col = 2 }, facing = East }
    rotateOpposite robot --> { position = { row = 2, col = 2 }, facing = West }

-}
rotateOpposite : Robot -> Robot
rotateOpposite robot =
    { robot | facing = getOppositeDirection robot.facing }


{-| Rotate the robot to face a specific direction.
The robot's position remains unchanged.

    robot = { position = { row = 2, col = 2 }, facing = North }
    rotateToDirection East robot --> { position = { row = 2, col = 2 }, facing = East }

-}
rotateToDirection : Direction -> Robot -> Robot
rotateToDirection newDirection robot =
    { robot | facing = newDirection }



-- HELPER FUNCTIONS


{-| Get the next position when moving forward from the current position
in the given direction.
-}
getNextPosition : Position -> Direction -> Position
getNextPosition position direction =
    case direction of
        North ->
            { position | row = position.row - 1 }

        South ->
            { position | row = position.row + 1 }

        East ->
            { position | col = position.col + 1 }

        West ->
            { position | col = position.col - 1 }


{-| Check if a position is within the valid 5x5 grid boundaries (0,0) to (4,4).
-}
isValidPosition : Position -> Bool
isValidPosition position =
    position.row >= 0 && position.row <= 4 && position.col >= 0 && position.col <= 4


{-| Get the direction that is 90 degrees to the left (counterclockwise).
-}
getLeftDirection : Direction -> Direction
getLeftDirection direction =
    case direction of
        North ->
            West

        West ->
            South

        South ->
            East

        East ->
            North


{-| Get the direction that is 90 degrees to the right (clockwise).
-}
getRightDirection : Direction -> Direction
getRightDirection direction =
    case direction of
        North ->
            East

        East ->
            South

        South ->
            West

        West ->
            North


{-| Get the direction that is 180 degrees opposite.
-}
getOppositeDirection : Direction -> Direction
getOppositeDirection direction =
    case direction of
        North ->
            South

        South ->
            North

        East ->
            West

        West ->
            East

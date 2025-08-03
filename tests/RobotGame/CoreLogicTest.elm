module RobotGame.CoreLogicTest exposing (suite)

{-| Comprehensive unit tests for core game logic edge cases and boundary conditions.

These tests focus on testing every possible scenario and edge case in the
core game logic functions to ensure complete coverage.

-}

import Expect
import RobotGame.Model exposing (Direction(..))
import RobotGame.RobotGame as RobotGame
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Core Game Logic Edge Cases"
        [ exhaustiveMovementTests
        , exhaustiveRotationTests
        , boundaryEdgeCases
        , positionValidationTests
        ]


exhaustiveMovementTests : Test
exhaustiveMovementTests =
    describe "Exhaustive Movement Testing"
        [ test "movement from all positions facing North" <|
            \_ ->
                let
                    testPositions =
                        [ { row = 0, col = 0 }
                        , { row = 0, col = 1 }
                        , { row = 0, col = 2 }
                        , { row = 0, col = 3 }
                        , { row = 0, col = 4 }
                        , { row = 1, col = 0 }
                        , { row = 1, col = 1 }
                        , { row = 1, col = 2 }
                        , { row = 1, col = 3 }
                        , { row = 1, col = 4 }
                        , { row = 2, col = 0 }
                        , { row = 2, col = 1 }
                        , { row = 2, col = 2 }
                        , { row = 2, col = 3 }
                        , { row = 2, col = 4 }
                        , { row = 3, col = 0 }
                        , { row = 3, col = 1 }
                        , { row = 3, col = 2 }
                        , { row = 3, col = 3 }
                        , { row = 3, col = 4 }
                        , { row = 4, col = 0 }
                        , { row = 4, col = 1 }
                        , { row = 4, col = 2 }
                        , { row = 4, col = 3 }
                        , { row = 4, col = 4 }
                        ]

                    testMovement position =
                        let
                            robot =
                                { position = position, facing = North }

                            result =
                                RobotGame.moveForward robot

                            canMove =
                                RobotGame.canMoveForward robot

                            expectedPosition =
                                if position.row > 0 then
                                    { position | row = position.row - 1 }

                                else
                                    position
                        in
                        Expect.all
                            [ \_ -> Expect.equal expectedPosition result.position
                            , \_ -> Expect.equal North result.facing
                            , \_ -> Expect.equal (position.row > 0) canMove
                            ]
                            ()
                in
                testPositions
                    |> List.map testMovement
                    |> List.all (\test -> test == Expect.pass)
                    |> Expect.equal True
        , test "movement from all edge positions" <|
            \_ ->
                let
                    edgeTests =
                        [ -- Top edge - can't move North
                          ( { row = 0, col = 2 }, North, False )
                        , ( { row = 0, col = 2 }, South, True )

                        -- Bottom edge - can't move South
                        , ( { row = 4, col = 2 }, South, False )
                        , ( { row = 4, col = 2 }, North, True )

                        -- Left edge - can't move West
                        , ( { row = 2, col = 0 }, West, False )
                        , ( { row = 2, col = 0 }, East, True )

                        -- Right edge - can't move East
                        , ( { row = 2, col = 4 }, East, False )
                        , ( { row = 2, col = 4 }, West, True )
                        ]

                    testEdgeMovement ( position, direction, expectedCanMove ) =
                        let
                            robot =
                                { position = position, facing = direction }

                            canMove =
                                RobotGame.canMoveForward robot
                        in
                        Expect.equal expectedCanMove canMove
                in
                edgeTests
                    |> List.map testEdgeMovement
                    |> List.all (\result -> result == Expect.pass)
                    |> Expect.equal True
        ]


exhaustiveRotationTests : Test
exhaustiveRotationTests =
    describe "Exhaustive Rotation Testing"
        [ test "all rotation combinations preserve position" <|
            \_ ->
                let
                    testPosition =
                        { row = 2, col = 3 }

                    allDirections =
                        [ North, South, East, West ]

                    testRotationPreservesPosition direction =
                        let
                            robot =
                                { position = testPosition, facing = direction }

                            afterLeft =
                                RobotGame.rotateLeft robot

                            afterRight =
                                RobotGame.rotateRight robot

                            afterOpposite =
                                RobotGame.rotateOpposite robot

                            afterDirect =
                                RobotGame.rotateToDirection East robot
                        in
                        Expect.all
                            [ \_ -> Expect.equal testPosition afterLeft.position
                            , \_ -> Expect.equal testPosition afterRight.position
                            , \_ -> Expect.equal testPosition afterOpposite.position
                            , \_ -> Expect.equal testPosition afterDirect.position
                            ]
                            ()
                in
                allDirections
                    |> List.map testRotationPreservesPosition
                    |> List.all (\result -> result == Expect.pass)
                    |> Expect.equal True
        , test "rotation consistency - four left rotations return to original" <|
            \_ ->
                let
                    testDirections =
                        [ North, South, East, West ]

                    testRotationConsistency direction =
                        let
                            robot =
                                { position = { row = 2, col = 2 }, facing = direction }

                            afterFourLeft =
                                robot
                                    |> RobotGame.rotateLeft
                                    |> RobotGame.rotateLeft
                                    |> RobotGame.rotateLeft
                                    |> RobotGame.rotateLeft
                        in
                        Expect.equal direction afterFourLeft.facing
                in
                testDirections
                    |> List.map testRotationConsistency
                    |> List.all (\result -> result == Expect.pass)
                    |> Expect.equal True
        ]


boundaryEdgeCases : Test
boundaryEdgeCases =
    describe "Boundary Edge Cases"
        [ test "corner positions have correct movement restrictions" <|
            \_ ->
                let
                    cornerTests =
                        [ -- Top-left corner
                          ( { row = 0, col = 0 }, North, False )
                        , ( { row = 0, col = 0 }, West, False )
                        , ( { row = 0, col = 0 }, South, True )
                        , ( { row = 0, col = 0 }, East, True )

                        -- Top-right corner
                        , ( { row = 0, col = 4 }, North, False )
                        , ( { row = 0, col = 4 }, East, False )
                        , ( { row = 0, col = 4 }, South, True )
                        , ( { row = 0, col = 4 }, West, True )

                        -- Bottom-left corner
                        , ( { row = 4, col = 0 }, South, False )
                        , ( { row = 4, col = 0 }, West, False )
                        , ( { row = 4, col = 0 }, North, True )
                        , ( { row = 4, col = 0 }, East, True )

                        -- Bottom-right corner
                        , ( { row = 4, col = 4 }, South, False )
                        , ( { row = 4, col = 4 }, East, False )
                        , ( { row = 4, col = 4 }, North, True )
                        , ( { row = 4, col = 4 }, West, True )
                        ]

                    testCornerMovement ( position, direction, expectedCanMove ) =
                        let
                            robot =
                                { position = position, facing = direction }

                            canMove =
                                RobotGame.canMoveForward robot
                        in
                        Expect.equal expectedCanMove canMove
                in
                cornerTests
                    |> List.map testCornerMovement
                    |> List.all (\result -> result == Expect.pass)
                    |> Expect.equal True
        ]


positionValidationTests : Test
positionValidationTests =
    describe "Position Validation Edge Cases"
        [ test "all valid grid positions allow movement in at least one direction" <|
            \_ ->
                let
                    allValidPositions =
                        List.range 0 4
                            |> List.concatMap (\row -> List.range 0 4 |> List.map (\col -> { row = row, col = col }))

                    testPosition position =
                        let
                            allDirections =
                                [ North, South, East, West ]

                            canMoveInAnyDirection =
                                allDirections
                                    |> List.map (\direction -> RobotGame.canMoveForward { position = position, facing = direction })
                                    |> List.any identity
                        in
                        Expect.equal True canMoveInAnyDirection
                in
                allValidPositions
                    |> List.map testPosition
                    |> List.all (\result -> result == Expect.pass)
                    |> Expect.equal True
        , test "blocked movements at boundaries preserve robot state" <|
            \_ ->
                let
                    boundaryTests =
                        [ ( { row = 0, col = 2 }, North )
                        , ( { row = 4, col = 2 }, South )
                        , ( { row = 2, col = 0 }, West )
                        , ( { row = 2, col = 4 }, East )
                        ]

                    testBoundaryMovement ( position, direction ) =
                        let
                            robot =
                                { position = position, facing = direction }

                            result =
                                RobotGame.moveForward robot
                        in
                        Expect.equal robot result
                in
                boundaryTests
                    |> List.map testBoundaryMovement
                    |> List.all (\result -> result == Expect.pass)
                    |> Expect.equal True
        ]

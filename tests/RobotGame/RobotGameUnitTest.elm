module RobotGame.RobotGameUnitTest exposing (suite)

{-| Comprehensive unit tests for the core RobotGame logic.

This module consolidates all core game logic tests including movement,
rotation, boundary validation, and edge cases.

-}

import Expect
import RobotGame.Model exposing (Direction(..))
import RobotGame.RobotGame as RobotGame
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "RobotGame Core Logic"
        [ movementTests
        , rotationTests
        , boundaryTests
        , edgeCaseTests
        , exhaustiveTests
        ]


movementTests : Test
movementTests =
    describe "Movement Functions"
        [ describe "moveForward"
            [ test "moves north correctly" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 2 }, facing = North }

                        expected =
                            { position = { row = 1, col = 2 }, facing = North }
                    in
                    RobotGame.moveForward robot
                        |> Expect.equal expected
            , test "moves south correctly" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 2 }, facing = South }

                        expected =
                            { position = { row = 3, col = 2 }, facing = South }
                    in
                    RobotGame.moveForward robot
                        |> Expect.equal expected
            , test "moves east correctly" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 2 }, facing = East }

                        expected =
                            { position = { row = 2, col = 3 }, facing = East }
                    in
                    RobotGame.moveForward robot
                        |> Expect.equal expected
            , test "moves west correctly" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 2 }, facing = West }

                        expected =
                            { position = { row = 2, col = 1 }, facing = West }
                    in
                    RobotGame.moveForward robot
                        |> Expect.equal expected
            ]
        , describe "canMoveForward"
            [ test "returns true when move is valid" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 2 }, facing = North }
                    in
                    RobotGame.canMoveForward robot
                        |> Expect.equal True
            , test "returns false when move would go outside grid" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 0, col = 2 }, facing = North }
                    in
                    RobotGame.canMoveForward robot
                        |> Expect.equal False
            ]
        ]


rotationTests : Test
rotationTests =
    describe "Rotation Functions"
        [ describe "rotateLeft"
            [ test "rotates from North to West" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 2 }, facing = North }

                        expected =
                            { position = { row = 2, col = 2 }, facing = West }
                    in
                    RobotGame.rotateLeft robot
                        |> Expect.equal expected
            , test "rotates from West to South" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 2 }, facing = West }

                        expected =
                            { position = { row = 2, col = 2 }, facing = South }
                    in
                    RobotGame.rotateLeft robot
                        |> Expect.equal expected
            , test "rotates from South to East" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 2 }, facing = South }

                        expected =
                            { position = { row = 2, col = 2 }, facing = East }
                    in
                    RobotGame.rotateLeft robot
                        |> Expect.equal expected
            , test "rotates from East to North" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 2 }, facing = East }

                        expected =
                            { position = { row = 2, col = 2 }, facing = North }
                    in
                    RobotGame.rotateLeft robot
                        |> Expect.equal expected
            ]
        , describe "rotateRight"
            [ test "rotates from North to East" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 2 }, facing = North }

                        expected =
                            { position = { row = 2, col = 2 }, facing = East }
                    in
                    RobotGame.rotateRight robot
                        |> Expect.equal expected
            , test "rotates from East to South" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 2 }, facing = East }

                        expected =
                            { position = { row = 2, col = 2 }, facing = South }
                    in
                    RobotGame.rotateRight robot
                        |> Expect.equal expected
            , test "rotates from South to West" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 2 }, facing = South }

                        expected =
                            { position = { row = 2, col = 2 }, facing = West }
                    in
                    RobotGame.rotateRight robot
                        |> Expect.equal expected
            , test "rotates from West to North" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 2 }, facing = West }

                        expected =
                            { position = { row = 2, col = 2 }, facing = North }
                    in
                    RobotGame.rotateRight robot
                        |> Expect.equal expected
            ]
        , describe "rotateOpposite"
            [ test "rotates from North to South" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 2 }, facing = North }

                        expected =
                            { position = { row = 2, col = 2 }, facing = South }
                    in
                    RobotGame.rotateOpposite robot
                        |> Expect.equal expected
            , test "rotates from South to North" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 2 }, facing = South }

                        expected =
                            { position = { row = 2, col = 2 }, facing = North }
                    in
                    RobotGame.rotateOpposite robot
                        |> Expect.equal expected
            , test "rotates from East to West" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 2 }, facing = East }

                        expected =
                            { position = { row = 2, col = 2 }, facing = West }
                    in
                    RobotGame.rotateOpposite robot
                        |> Expect.equal expected
            , test "rotates from West to East" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 2 }, facing = West }

                        expected =
                            { position = { row = 2, col = 2 }, facing = East }
                    in
                    RobotGame.rotateOpposite robot
                        |> Expect.equal expected
            ]
        , describe "rotateToDirection"
            [ test "rotates to North" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 2 }, facing = South }

                        expected =
                            { position = { row = 2, col = 2 }, facing = North }
                    in
                    RobotGame.rotateToDirection North robot
                        |> Expect.equal expected
            , test "rotates to East" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 2 }, facing = West }

                        expected =
                            { position = { row = 2, col = 2 }, facing = East }
                    in
                    RobotGame.rotateToDirection East robot
                        |> Expect.equal expected
            , test "keeps position unchanged when rotating" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 1, col = 3 }, facing = North }

                        result =
                            RobotGame.rotateToDirection South robot
                    in
                    result.position
                        |> Expect.equal { row = 1, col = 3 }
            ]
        ]


boundaryTests : Test
boundaryTests =
    describe "Boundary Validation"
        [ describe "North boundary (row 0)"
            [ test "cannot move north from top edge" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 0, col = 2 }, facing = North }
                    in
                    RobotGame.moveForward robot
                        |> Expect.equal robot
            , test "canMoveForward returns false at north boundary" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 0, col = 2 }, facing = North }
                    in
                    RobotGame.canMoveForward robot
                        |> Expect.equal False
            ]
        , describe "South boundary (row 4)"
            [ test "cannot move south from bottom edge" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 4, col = 2 }, facing = South }
                    in
                    RobotGame.moveForward robot
                        |> Expect.equal robot
            , test "canMoveForward returns false at south boundary" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 4, col = 2 }, facing = South }
                    in
                    RobotGame.canMoveForward robot
                        |> Expect.equal False
            ]
        , describe "East boundary (col 4)"
            [ test "cannot move east from right edge" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 4 }, facing = East }
                    in
                    RobotGame.moveForward robot
                        |> Expect.equal robot
            , test "canMoveForward returns false at east boundary" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 4 }, facing = East }
                    in
                    RobotGame.canMoveForward robot
                        |> Expect.equal False
            ]
        , describe "West boundary (col 0)"
            [ test "cannot move west from left edge" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 0 }, facing = West }
                    in
                    RobotGame.moveForward robot
                        |> Expect.equal robot
            , test "canMoveForward returns false at west boundary" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 2, col = 0 }, facing = West }
                    in
                    RobotGame.canMoveForward robot
                        |> Expect.equal False
            ]
        , describe "Corner positions"
            [ test "cannot move from top-left corner facing north" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 0, col = 0 }, facing = North }
                    in
                    RobotGame.canMoveForward robot
                        |> Expect.equal False
            , test "cannot move from top-left corner facing west" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 0, col = 0 }, facing = West }
                    in
                    RobotGame.canMoveForward robot
                        |> Expect.equal False
            , test "can move from top-left corner facing south" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 0, col = 0 }, facing = South }
                    in
                    RobotGame.canMoveForward robot
                        |> Expect.equal True
            , test "can move from top-left corner facing east" <|
                \_ ->
                    let
                        robot =
                            { position = { row = 0, col = 0 }, facing = East }
                    in
                    RobotGame.canMoveForward robot
                        |> Expect.equal True
            ]
        ]


edgeCaseTests : Test
edgeCaseTests =
    describe "Edge Cases"
        [ test "center position allows movement in all directions" <|
            \_ ->
                let
                    robot =
                        { position = { row = 2, col = 2 }, facing = North }
                in
                [ North, South, East, West ]
                    |> List.map (\direction -> RobotGame.canMoveForward { robot | facing = direction })
                    |> Expect.equal [ True, True, True, True ]
        , test "all corner positions allow some movement" <|
            \_ ->
                let
                    corners =
                        [ { row = 0, col = 0 }
                        , { row = 0, col = 4 }
                        , { row = 4, col = 0 }
                        , { row = 4, col = 4 }
                        ]

                    canMoveInAnyDirection position =
                        [ North, South, East, West ]
                            |> List.map (\direction -> RobotGame.canMoveForward { position = position, facing = direction })
                            |> List.any identity
                in
                corners
                    |> List.map canMoveInAnyDirection
                    |> Expect.equal [ True, True, True, True ]
        ]


exhaustiveTests : Test
exhaustiveTests =
    describe "Exhaustive Testing"
        [ test "four left rotations return to original direction" <|
            \_ ->
                let
                    robot =
                        { position = { row = 2, col = 2 }, facing = North }

                    result =
                        robot
                            |> RobotGame.rotateLeft
                            |> RobotGame.rotateLeft
                            |> RobotGame.rotateLeft
                            |> RobotGame.rotateLeft
                in
                result.facing
                    |> Expect.equal North
        , test "four right rotations return to original direction" <|
            \_ ->
                let
                    robot =
                        { position = { row = 2, col = 2 }, facing = East }

                    result =
                        robot
                            |> RobotGame.rotateRight
                            |> RobotGame.rotateRight
                            |> RobotGame.rotateRight
                            |> RobotGame.rotateRight
                in
                result.facing
                    |> Expect.equal East
        , test "two opposite rotations return to original direction" <|
            \_ ->
                let
                    robot =
                        { position = { row = 2, col = 2 }, facing = West }

                    result =
                        robot
                            |> RobotGame.rotateOpposite
                            |> RobotGame.rotateOpposite
                in
                result.facing
                    |> Expect.equal West
        , test "left then right rotation returns to original direction" <|
            \_ ->
                let
                    robot =
                        { position = { row = 2, col = 2 }, facing = South }

                    result =
                        robot
                            |> RobotGame.rotateLeft
                            |> RobotGame.rotateRight
                in
                result.facing
                    |> Expect.equal South
        , test "movement from all positions facing North" <|
            \_ ->
                let
                    allPositions =
                        List.range 0 4
                            |> List.concatMap (\row -> List.range 0 4 |> List.map (\col -> { row = row, col = col }))

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
                allPositions
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
        , test "all rotation combinations preserve position" <|
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
        , test "corner positions have correct movement restrictions" <|
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

module RobotGame.RobotGameTest exposing (suite)

import Expect
import RobotGame.Model exposing (Direction(..))
import RobotGame.RobotGame as RobotGame
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "RobotGame.RobotGame"
        [ movementTests
        , rotationTests
        , boundaryTests
        , helperFunctionTests
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


helperFunctionTests : Test
helperFunctionTests =
    describe "Helper Functions"
        [ describe "Position validation edge cases"
            [ test "center position is valid" <|
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
        , describe "Rotation consistency"
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
            ]
        ]

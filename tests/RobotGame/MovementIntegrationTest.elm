module RobotGame.MovementIntegrationTest exposing (suite)

import Expect
import ProgramTest
import RobotGame.Main exposing (Msg(..))
import RobotGame.Model exposing (AnimationState(..), Direction(..))
import RobotGame.ProgramTestHelpers as RobotGameProgramTestHelpers
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "RobotGame Movement Integration Tests"
        [ testBasicMovement
        , testMovementSequence
        , testCornerMovement
        , testBoundaryCollision
        ]


testBasicMovement : Test
testBasicMovement =
    test "robot starts at center facing North" <|
        \_ ->
            RobotGameProgramTestHelpers.startRobotGame ()
                |> ProgramTest.expectModel
                    (\model ->
                        Expect.all
                            [ \_ -> Expect.equal { row = 2, col = 2 } model.robot.position
                            , \_ -> Expect.equal North model.robot.facing
                            , \_ -> Expect.equal Idle model.animationState
                            ]
                            ()
                    )


testMovementSequence : Test
testMovementSequence =
    test "can move forward and rotate in sequence" <|
        \_ ->
            RobotGameProgramTestHelpers.startRobotGame ()
                -- Move forward (North) to (1,2)
                |> ProgramTest.update (KeyPressed "ArrowUp")
                |> ProgramTest.advanceTime 300
                -- Rotate right to face East
                |> ProgramTest.update (KeyPressed "ArrowRight")
                |> ProgramTest.advanceTime 300
                -- Move forward (East) to (1,3)
                |> ProgramTest.update (KeyPressed "ArrowUp")
                |> ProgramTest.advanceTime 300
                |> ProgramTest.expectModel
                    (\model ->
                        Expect.all
                            [ \_ -> Expect.equal { row = 1, col = 3 } model.robot.position
                            , \_ -> Expect.equal East model.robot.facing
                            , \_ -> Expect.equal Idle model.animationState
                            ]
                            ()
                    )


testCornerMovement : Test
testCornerMovement =
    test "move to top-left corner (0,0)" <|
        \_ ->
            RobotGameProgramTestHelpers.startRobotGame ()
                -- Move North twice to reach row 0
                |> ProgramTest.update (KeyPressed "ArrowUp")
                |> ProgramTest.advanceTime 300
                |> ProgramTest.update (KeyPressed "ArrowUp")
                |> ProgramTest.advanceTime 300
                -- Rotate left to face West
                |> ProgramTest.update (KeyPressed "ArrowLeft")
                |> ProgramTest.advanceTime 300
                -- Move West twice to reach column 0
                |> ProgramTest.update (KeyPressed "ArrowUp")
                |> ProgramTest.advanceTime 300
                |> ProgramTest.update (KeyPressed "ArrowUp")
                |> ProgramTest.advanceTime 300
                |> ProgramTest.expectModel
                    (\model ->
                        Expect.all
                            [ \_ -> Expect.equal { row = 0, col = 0 } model.robot.position
                            , \_ -> Expect.equal West model.robot.facing
                            ]
                            ()
                    )


testBoundaryCollision : Test
testBoundaryCollision =
    test "collision at top boundary (row 0)" <|
        \_ ->
            RobotGameProgramTestHelpers.startRobotGame ()
                -- Move to top edge (0,2)
                |> ProgramTest.update (KeyPressed "ArrowUp")
                |> ProgramTest.advanceTime 300
                |> ProgramTest.update (KeyPressed "ArrowUp")
                |> ProgramTest.advanceTime 300
                -- Try to move beyond boundary - should trigger blocked movement
                |> ProgramTest.update (KeyPressed "ArrowUp")
                |> ProgramTest.expectModel
                    (\model ->
                        Expect.all
                            [ \_ -> Expect.equal BlockedMovement model.animationState
                            , \_ -> Expect.equal { row = 0, col = 2 } model.robot.position
                            ]
                            ()
                    )

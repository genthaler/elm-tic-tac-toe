module RobotGame.AnimationIntegrationTest exposing (suite)

import Expect
import ProgramTest
import RobotGame.Main exposing (Msg(..))
import RobotGame.Model exposing (AnimationState(..))
import RobotGame.ProgramTestHelpers as RobotGameProgramTestHelpers
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "RobotGame Animation Integration Tests"
        [ testAnimationStateTransitions
        ]


testAnimationStateTransitions : Test
testAnimationStateTransitions =
    describe "Animation state transitions during movement"
        [ test "Initial state is Idle" <|
            \_ ->
                RobotGameProgramTestHelpers.startRobotGame ()
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.equal Idle model.animationState
                        )
        , test "Movement triggers Moving animation state" <|
            \_ ->
                RobotGameProgramTestHelpers.startRobotGame ()
                    |> ProgramTest.update (KeyPressed "ArrowUp")
                    |> ProgramTest.expectModel
                        (\model ->
                            case model.animationState of
                                Moving from to ->
                                    Expect.all
                                        [ \_ -> Expect.equal { row = 2, col = 2 } from
                                        , \_ -> Expect.equal { row = 1, col = 2 } to
                                        ]
                                        ()

                                x ->
                                    Expect.fail ("Expected Moving animation state, not " ++ Debug.toString x)
                        )
        , test "Movement animation completes and returns to Idle" <|
            \_ ->
                RobotGameProgramTestHelpers.startRobotGame ()
                    |> ProgramTest.update (KeyPressed "ArrowUp")
                    |> ProgramTest.advanceTime 300
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.equal Idle model.animationState
                        )
        ]

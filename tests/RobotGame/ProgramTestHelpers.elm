module RobotGame.ProgramTestHelpers exposing
    ( startRobotGame
    , expectRobotPosition
    , expectRobotFacing, expectRobotAnimationState
    )

{-| Test utilities for elm-program-test integration testing.

This module provides common setup functions and helpers for testing the main
application components with elm-program-test.


# Application Starter

@docs startRobotGame


# Assertion Helpers

@docs expectRobotPosition

This module provides custom assertion functions for verifying game states,
UI element presence and content, and model state verification.


# Robot Game Assertions

@docs expectRobotPosition, expectRobotFacing, expectRobotAnimationState

-}

import Expect exposing (Expectation)
import ProgramTest exposing (ProgramTest, SimulatedEffect)
import RobotGame.Main exposing (Effect(..), Msg(..), initToEffect, updateToEffect)
import RobotGame.Model exposing (AnimationState, Direction, Model, Position)
import RobotGame.View exposing (view)
import SimulatedEffect.Cmd exposing (none)
import SimulatedEffect.Process exposing (sleep)
import SimulatedEffect.Task exposing (perform)


{-| Start the RobotGame directly with default configuration
-}
startRobotGame : () -> ProgramTest Model Msg Effect
startRobotGame _ =
    ProgramTest.createElement
        { init = \_ -> initToEffect
        , view = view
        , update = updateToEffect
        }
        |> ProgramTest.withSimulatedEffects simulateEffects
        |> ProgramTest.start ()


simulateEffects : Effect -> SimulatedEffect Msg
simulateEffects effect =
    case effect of
        NoEffect ->
            none

        Sleep interval ->
            sleep interval
                |> perform (\_ -> AnimationComplete)


{-| Assert that the robot is at the expected position
-}
expectRobotPosition : Position -> ProgramTest Model msg effect -> Expectation
expectRobotPosition expectedPosition programTest =
    programTest
        |> ProgramTest.expectModel
            (\model ->
                Expect.equal expectedPosition model.robot.position
            )


{-| Assert that the robot is facing the expected direction
-}
expectRobotFacing : Direction -> ProgramTest Model msg effect -> Expectation
expectRobotFacing expectedDirection programTest =
    programTest
        |> ProgramTest.expectModel
            (\model ->
                Expect.equal expectedDirection model.robot.facing
            )


{-| Assert that the robot animation is in the expected state
-}
expectRobotAnimationState : AnimationState -> ProgramTest Model msg effect -> Expectation
expectRobotAnimationState expectedAnimationState programTest =
    programTest
        |> ProgramTest.expectModel
            (\model ->
                Expect.equal expectedAnimationState model.animationState
            )

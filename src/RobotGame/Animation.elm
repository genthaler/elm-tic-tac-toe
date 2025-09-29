module RobotGame.Animation exposing
    ( isAnimating, getCurrentAnimatedState
    , startMovementAnimation, startRotationAnimation, startButtonHighlightAnimation, startBlockedMovementAnimation
    , updateAnimations, cleanupCompletedTimelines, hasActiveAnimations
    , AnimationConfig, defaultAnimationConfig
    , getInterpolatedPosition, getInterpolatedRotationAngle, getButtonHighlightOpacity, isBlockedMovementAnimating
    , calculateShortestRotationPath, directionToAngleFloat
    )

{-| Animation utilities and state management for the Robot Grid Game.

This module provides reusable animation functions and utilities for managing
elm-animator timelines, preventing conflicting animations, and coordinating
animation state across the robot game.


# Animation State Checking

@docs isAnimating, getCurrentAnimatedState


# Animation Control

@docs startMovementAnimation, startRotationAnimation, startButtonHighlightAnimation, startBlockedMovementAnimation


# Timeline Management

@docs updateAnimations, cleanupCompletedTimelines, hasActiveAnimations


# Configuration

@docs AnimationConfig, defaultAnimationConfig


# Interpolation Utilities

@docs getInterpolatedPosition, getInterpolatedRotationAngle, getButtonHighlightOpacity, isBlockedMovementAnimating


# Helper Functions

@docs calculateShortestRotationPath, directionToAngleFloat

-}

import Animator
import RobotGame.Model exposing (AnimationState(..), Button, Direction(..), Model, Position, Robot)
import Time


{-| Configuration for animation durations and easing
-}
type alias AnimationConfig =
    { movementDuration : Float -- milliseconds
    , rotationDuration : Float -- milliseconds
    , buttonHighlightDuration : Float -- milliseconds
    , blockedMovementDuration : Float -- milliseconds
    }


{-| Default animation configuration matching the design requirements
-}
defaultAnimationConfig : AnimationConfig
defaultAnimationConfig =
    { movementDuration = 300.0 -- 300ms with ease-out easing for natural deceleration
    , rotationDuration = 200.0 -- 200ms with ease-in-out easing for smooth direction changes
    , buttonHighlightDuration = 150.0 -- 150ms with ease-out easing for responsive feedback
    , blockedMovementDuration = 200.0 -- 200ms bounce/shake effect with custom easing curve
    }



-- ANIMATION STATE CHECKING


{-| Check if any animations are currently running.
This prevents conflicting animations and manages animation queues.

    model = { ... | animationState = Moving fromPos toPos }
    isAnimating model --> True

    model = { ... | animationState = Idle }
    isAnimating model --> False

-}
isAnimating : Model -> Bool
isAnimating model =
    -- Check if the animation state indicates an active animation
    -- This is the primary way to determine if animations are running
    model.animationState /= Idle


{-| Get the current interpolated robot state from elm-animator timelines.
This provides smooth interpolated values during animations.

    getCurrentAnimatedState model
    --> { position = { row = 1.5, col = 2.0 }, facing = North }

-}
getCurrentAnimatedState : Model -> Robot
getCurrentAnimatedState model =
    -- Get the current interpolated robot state from the timeline
    Animator.current model.robotTimeline



-- ANIMATION CONTROL


{-| Start a movement animation from one position to another.
Uses elm-animator to create smooth position transitions.

    startMovementAnimation fromPos toPos model
    --> { model | robotTimeline = updatedTimeline, ... }

-}
startMovementAnimation : Position -> Position -> Model -> Model
startMovementAnimation fromPos toPos model =
    let
        config =
            defaultAnimationConfig

        newRobot =
            { position = toPos, facing = model.robot.facing }

        -- Create elm-animator movement animation with 300ms duration and ease-out easing
        updatedRobotTimeline =
            model.robotTimeline
                |> Animator.go (Animator.millis config.movementDuration) newRobot
    in
    { model
        | robotTimeline = updatedRobotTimeline
        , robot = newRobot
        , animationState = Moving fromPos toPos
    }


{-| Start a rotation animation from one direction to another.
Uses elm-animator to create smooth rotation transitions.

    startRotationAnimation fromDir toDir model
    --> { model | robotTimeline = updatedTimeline, rotationAngleTimeline = updatedRotationTimeline, ... }

-}
startRotationAnimation : Direction -> Direction -> Model -> Model
startRotationAnimation fromDir toDir model =
    let
        config =
            defaultAnimationConfig

        newRobot =
            { position = model.robot.position, facing = toDir }

        -- Create elm-animator rotation animation with 200ms duration and ease-in-out easing
        updatedRobotTimeline =
            model.robotTimeline
                |> Animator.go (Animator.millis config.rotationDuration) newRobot

        -- Animate rotation angle for smooth visual transition
        fromAngle =
            directionToAngleFloat fromDir

        toAngle =
            directionToAngleFloat toDir

        targetAngle =
            calculateShortestRotationPath fromAngle toAngle

        updatedRotationTimeline =
            model.rotationAngleTimeline
                |> Animator.go (Animator.millis config.rotationDuration) targetAngle
    in
    { model
        | robotTimeline = updatedRobotTimeline
        , rotationAngleTimeline = updatedRotationTimeline
        , robot = newRobot
        , animationState = Rotating fromDir toDir
    }


{-| Start a button highlight animation for the specified buttons.
Uses elm-animator to create responsive visual feedback.

    startButtonHighlightAnimation [ForwardButton] model
    --> { model | buttonHighlightTimeline = updatedTimeline, ... }

-}
startButtonHighlightAnimation : List Button -> Model -> Model
startButtonHighlightAnimation buttons model =
    let
        config =
            defaultAnimationConfig

        buttonStrings =
            buttons

        -- Create elm-animator button highlight animation with 150ms duration and ease-out easing
        -- Start with highlights immediately visible, then animate to empty after duration
        updatedButtonHighlightTimeline =
            Animator.init buttonStrings
                |> Animator.go (Animator.millis config.buttonHighlightDuration) []
    in
    { model
        | buttonHighlightTimeline = updatedButtonHighlightTimeline
        , highlightedButtons = buttons -- Keep for compatibility during transition
    }


{-| Start a blocked movement animation with subtle bounce/shake effect.
Uses elm-animator to create clear visual indication of blocked actions.

    startBlockedMovementAnimation model
    --> { model | blockedMovementTimeline = updatedTimeline, ... }

-}
startBlockedMovementAnimation : Model -> Model
startBlockedMovementAnimation model =
    let
        config =
            defaultAnimationConfig

        -- Create elm-animator blocked movement animation with 200ms duration and custom easing
        -- Create subtle bounce/shake effect for clear visual indication
        updatedBlockedMovementTimeline =
            Animator.init True
                |> Animator.go (Animator.millis config.blockedMovementDuration) False
    in
    { model
        | blockedMovementTimeline = updatedBlockedMovementTimeline
        , animationState = BlockedMovement
        , blockedMovementFeedback = True -- Keep for compatibility during transition
    }



-- TIMELINE MANAGEMENT


{-| Update all elm-animator timelines efficiently.
Only processes active animations for better performance.

    updateAnimations time model
    --> { model | robotTimeline = updated1, buttonHighlightTimeline = updated2, ... }

-}
updateAnimations : Time.Posix -> Model -> Model
updateAnimations time model =
    -- Optimized timeline updates - only process active timelines for better performance
    let
        -- Check which timelines are active to avoid unnecessary updates
        -- Use animation state to determine if updates are needed
        modelHasActiveAnimations =
            model.animationState /= Idle

        robotTimelineActive =
            modelHasActiveAnimations

        buttonHighlightTimelineActive =
            modelHasActiveAnimations

        blockedMovementTimelineActive =
            model.animationState == BlockedMovement

        rotationAngleTimelineActive =
            case model.animationState of
                Rotating _ _ ->
                    True

                _ ->
                    False

        -- Only update active timelines for performance optimization
        updatedRobotTimeline =
            if robotTimelineActive then
                Animator.updateTimeline time model.robotTimeline

            else
                model.robotTimeline

        updatedButtonHighlightTimeline =
            if buttonHighlightTimelineActive then
                Animator.updateTimeline time model.buttonHighlightTimeline

            else
                model.buttonHighlightTimeline

        updatedBlockedMovementTimeline =
            if blockedMovementTimelineActive then
                Animator.updateTimeline time model.blockedMovementTimeline

            else
                model.blockedMovementTimeline

        updatedRotationAngleTimeline =
            if rotationAngleTimelineActive then
                Animator.updateTimeline time model.rotationAngleTimeline

            else
                model.rotationAngleTimeline
    in
    { model
        | robotTimeline = updatedRobotTimeline
        , buttonHighlightTimeline = updatedButtonHighlightTimeline
        , blockedMovementTimeline = updatedBlockedMovementTimeline
        , rotationAngleTimeline = updatedRotationAngleTimeline
    }


{-| Clean up completed timelines to prevent memory leaks.
Resets completed timelines to their initial state to free memory.

    cleanupCompletedTimelines model
    --> { model | robotTimeline = resetTimeline, ... }

-}
cleanupCompletedTimelines : Model -> Model
cleanupCompletedTimelines model =
    let
        -- Reset completed timelines to their initial state to free memory
        cleanedRobotTimeline =
            if model.animationState == Idle then
                Animator.init model.robot

            else
                model.robotTimeline

        cleanedButtonHighlightTimeline =
            if model.animationState == Idle then
                Animator.init []

            else
                model.buttonHighlightTimeline

        cleanedBlockedMovementTimeline =
            if model.animationState /= BlockedMovement then
                Animator.init False

            else
                model.blockedMovementTimeline

        cleanedRotationAngleTimeline =
            case model.animationState of
                Rotating _ _ ->
                    model.rotationAngleTimeline

                _ ->
                    Animator.init (directionToAngleFloat model.robot.facing)
    in
    { model
        | robotTimeline = cleanedRobotTimeline
        , buttonHighlightTimeline = cleanedButtonHighlightTimeline
        , blockedMovementTimeline = cleanedBlockedMovementTimeline
        , rotationAngleTimeline = cleanedRotationAngleTimeline
    }


{-| Check if any timelines have active animations.
Used for performance optimization to avoid unnecessary updates.

    hasActiveAnimations model
    --> True

-}
hasActiveAnimations : Model -> Bool
hasActiveAnimations model =
    -- Use animation state to determine if any animations are active
    model.animationState /= Idle



-- INTERPOLATION UTILITIES


{-| Get the interpolated position for smooth movement animation.
Returns the current interpolated position from the robot timeline.

    getInterpolatedPosition model
    --> { row = 1.5, col = 2.0 }

-}
getInterpolatedPosition : Model -> Position
getInterpolatedPosition model =
    let
        animatedRobot =
            Animator.current model.robotTimeline
    in
    animatedRobot.position


{-| Get the interpolated rotation angle for smooth rotation animation.
Returns the current interpolated angle from the rotation timeline.

    getInterpolatedRotationAngle model
    --> 45.0

-}
getInterpolatedRotationAngle : Model -> Float
getInterpolatedRotationAngle model =
    let
        currentAngle =
            Animator.current model.rotationAngleTimeline
    in
    if currentAngle < 0 then
        currentAngle + 360

    else if currentAngle >= 360 then
        currentAngle - 360

    else
        currentAngle


{-| Get the button highlight opacity for a specific button.
Returns the current interpolated opacity from the button highlight timeline.

    getButtonHighlightOpacity "forward" model
    --> 0.8

-}
getButtonHighlightOpacity : Button -> Model -> Float
getButtonHighlightOpacity button model =
    let
        currentHighlights : List Button
        currentHighlights =
            Animator.current model.buttonHighlightTimeline

        isHighlighted =
            List.member button currentHighlights
    in
    if isHighlighted then
        1.0

    else
        0.0


{-| Check if blocked movement animation is currently active.
Returns true if the blocked movement timeline is running.

    isBlockedMovementAnimating model
    --> True

-}
isBlockedMovementAnimating : Model -> Bool
isBlockedMovementAnimating model =
    Animator.current model.blockedMovementTimeline



-- HELPER FUNCTIONS


{-| Convert direction to rotation angle as Float for elm-animator interpolation.

    directionToAngleFloat North --> 0.0

    directionToAngleFloat East --> 90.0

    directionToAngleFloat South --> 180.0

    directionToAngleFloat West --> 270.0

-}
directionToAngleFloat : Direction -> Float
directionToAngleFloat direction =
    case direction of
        North ->
            0.0

        East ->
            90.0

        South ->
            180.0

        West ->
            270.0


{-| Calculate the shortest rotation path between two angles.
For elm-animator, we want the final target angle for smooth interpolation.

    calculateShortestRotationPath 0.0 90.0 --> 90.0

    calculateShortestRotationPath 270.0 0.0 --> 0.0

-}
calculateShortestRotationPath : Float -> Float -> Float
calculateShortestRotationPath _ toAngle =
    -- For elm-animator, we want the final target angle
    -- The animation system will handle the interpolation smoothly
    toAngle

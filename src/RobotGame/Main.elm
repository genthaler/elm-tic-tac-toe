module RobotGame.Main exposing (Effect(..), Msg(..), init, initToEffect, subscriptions, update, updateToEffect)

{-| Main application module for the Robot Grid Game.

This module implements the core game initialization, update logic, and subscriptions
for a robot navigation game on a 5x5 grid.


# Architecture

The application follows Elm's Model-View-Update (MVU) architecture:

  - **Model**: Game state including robot position, facing direction, and UI state
  - **Update**: Pure functions handling movement, rotation, and state transitions
  - **Subscriptions**: Keyboard input handling and window resize events


# Game Features

  - **Robot Movement**: Forward movement with boundary checking
  - **Robot Rotation**: Left, right, opposite, and direct direction rotation
  - **Keyboard Controls**: Arrow key support for movement and rotation
  - **Animation Support**: Smooth transitions for movement and rotation
  - **Theme Integration**: Light and dark color scheme support


# Usage

The game initializes with a robot at the center of a 5x5 grid facing North.
Players can move the robot forward or rotate it using keyboard controls or
visual buttons.

-}

import Animator
import Browser.Events
import Json.Decode as Decode
import Process
import RobotGame.Model as Model exposing (AnimationState(..), Direction(..), Model)
import RobotGame.RobotGame as RobotGame
import Route
import Task
import Theme.Theme exposing (ColorScheme)
import Time


type Effect
    = NoEffect
    | Sleep Float


{-| Messages that can be sent to update the game state
-}
type Msg
    = MoveForward
    | RotateLeft
    | RotateRight
    | RotateToDirection Direction
    | KeyPressed String
    | AnimationComplete
    | ColorScheme ColorScheme
    | GetResize Int Int
    | Tick Time.Posix
    | ClearBlockedMovementFeedback
    | ButtonHighlightComplete
    | NavigateToRoute Route.Route
      -- elm-animator messages
    | AnimationFrame Time.Posix


initToEffect : ( Model, Effect )
initToEffect =
    ( Model.init, NoEffect )


{-| Initialize the game with default state
-}
init : ( Model, Cmd Msg )
init =
    initToEffect
        |> Tuple.mapSecond perform


{-| Update the game state based on received messages
-}
updateToEffect : Msg -> Model -> ( Model, Effect )
updateToEffect msg model =
    case msg of
        MoveForward ->
            handleMoveForward model

        RotateLeft ->
            handleRotateLeft model

        RotateRight ->
            handleRotateRight model

        RotateToDirection direction ->
            handleRotateToDirection direction model

        KeyPressed key ->
            case key of
                "ArrowUp" ->
                    handleMoveForward model

                "ArrowLeft" ->
                    handleRotateLeft model

                "ArrowRight" ->
                    handleRotateRight model

                "ArrowDown" ->
                    -- Rotate to opposite direction
                    let
                        oppositeDirection =
                            case model.robot.facing of
                                North ->
                                    South

                                South ->
                                    North

                                East ->
                                    West

                                West ->
                                    East
                    in
                    handleRotateToDirection oppositeDirection model

                _ ->
                    -- Ignore other keys
                    ( model, NoEffect )

        AnimationComplete ->
            handleAnimationComplete model
                |> Tuple.mapFirst cleanupCompletedTimelines

        ColorScheme colorScheme ->
            ( { model | colorScheme = colorScheme }, NoEffect )

        GetResize width height ->
            ( { model | maybeWindow = Just ( width, height ) }, NoEffect )

        Tick now ->
            ( { model | lastMoveTime = Just now }, NoEffect )

        ClearBlockedMovementFeedback ->
            -- Clear blocked movement feedback and reset timeline
            ( { model
                | blockedMovementFeedback = False
                , animationState = Idle
                , blockedMovementTimeline = Animator.init False
              }
            , NoEffect
            )

        ButtonHighlightComplete ->
            -- Clear both elm-animator timeline and legacy field for compatibility
            ( { model
                | highlightedButtons = []
                , buttonHighlightTimeline = Animator.init []
              }
            , NoEffect
            )

        NavigateToRoute _ ->
            -- Navigation is handled by the parent App module
            ( model, NoEffect )

        AnimationFrame time ->
            -- Optimized animation frame updates - only process active timelines for better performance
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
            ( { model
                | robotTimeline = updatedRobotTimeline
                , buttonHighlightTimeline = updatedButtonHighlightTimeline
                , blockedMovementTimeline = updatedBlockedMovementTimeline
                , rotationAngleTimeline = updatedRotationAngleTimeline
              }
            , NoEffect
            )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    updateToEffect msg model
        |> Tuple.mapSecond perform


perform : Effect -> Cmd Msg
perform effect =
    case effect of
        NoEffect ->
            Cmd.none

        Sleep interval ->
            Process.sleep interval
                |> Task.perform (\_ -> AnimationComplete)


{-| Create button highlight animation using elm-animator
-}
animateButtonHighlight : List Model.Button -> Model -> Model
animateButtonHighlight buttons model =
    let
        -- Start elm-animator button highlight animation with 150ms duration
        -- First set the highlights immediately, then animate to empty after 150ms
        updatedButtonHighlightTimeline =
            Animator.init buttons
                -- Start with highlights immediately visible
                |> Animator.go (Animator.millis 150) []

        -- Clear highlights after 150ms
    in
    { model | buttonHighlightTimeline = updatedButtonHighlightTimeline }


{-| Handle forward movement with elm-animator animation
-}
handleMoveForward : Model -> ( Model, Effect )
handleMoveForward model =
    -- Check if any animations are currently running
    if isAnimating model then
        -- Animation in progress - ignore input
        ( model, NoEffect )

    else if RobotGame.canMoveForward model.robot then
        let
            newRobot =
                RobotGame.moveForward model.robot

            animationState =
                Moving model.robot.position newRobot.position

            highlightedButtons =
                getForwardMovementHighlights

            -- Start elm-animator movement animation with 300ms duration
            -- Use elm-animator to create smooth movement transition
            updatedRobotTimeline =
                model.robotTimeline
                    |> Animator.go Animator.quickly newRobot

            -- Apply button highlight animation using elm-animator
            modelWithHighlights =
                animateButtonHighlight highlightedButtons model
        in
        ( { modelWithHighlights
            | robot = newRobot
            , animationState = animationState
            , blockedMovementFeedback = False
            , highlightedButtons = highlightedButtons -- Keep for compatibility during transition
            , robotTimeline = updatedRobotTimeline
          }
        , -- Use elm-animator duration instead of Process.sleep
          Sleep 300
        )

    else
        -- Cannot move forward - show blocked movement animation with elm-animator
        let
            highlightedButtons =
                getForwardMovementHighlights

            -- Apply button highlight animation using elm-animator
            modelWithHighlights =
                animateButtonHighlight highlightedButtons model

            -- Start elm-animator blocked movement animation with 200ms duration
            -- Create subtle bounce/shake effect with custom easing
            updatedBlockedMovementTimeline =
                Animator.init True
                    |> Animator.go (Animator.millis 200) False
        in
        ( { modelWithHighlights
            | animationState = BlockedMovement
            , blockedMovementFeedback = True -- Keep for compatibility during transition
            , highlightedButtons = highlightedButtons -- Keep for compatibility during transition
            , blockedMovementTimeline = updatedBlockedMovementTimeline
          }
        , Sleep 200
          -- Duration matches elm-animator timeline
        )


{-| Handle left rotation with elm-animator animation
-}
handleRotateLeft : Model -> ( Model, Effect )
handleRotateLeft model =
    -- Check if any animations are currently running
    if isAnimating model then
        -- Animation in progress - ignore input
        ( model, NoEffect )

    else
        let
            newRobot =
                RobotGame.rotateLeft model.robot

            animationState =
                Rotating model.robot.facing newRobot.facing

            highlightedButtons =
                getRotationHighlights model.robot.facing newRobot.facing Model.RotateLeftButton

            -- Start elm-animator rotation animation with 200ms duration
            updatedRobotTimeline =
                model.robotTimeline
                    |> Animator.go Animator.quickly newRobot

            -- Animate rotation angle for smooth visual transition
            fromAngle =
                directionToAngleFloat model.robot.facing

            toAngle =
                directionToAngleFloat newRobot.facing

            targetAngle =
                calculateShortestRotationPath fromAngle toAngle

            updatedRotationTimeline =
                model.rotationAngleTimeline
                    |> Animator.go Animator.quickly targetAngle

            -- Apply button highlight animation using elm-animator
            modelWithHighlights =
                animateButtonHighlight highlightedButtons model
        in
        ( { modelWithHighlights
            | robot = newRobot
            , animationState = animationState
            , highlightedButtons = highlightedButtons -- Keep for compatibility during transition
            , robotTimeline = updatedRobotTimeline
            , rotationAngleTimeline = updatedRotationTimeline
          }
        , -- Use elm-animator duration instead of Process.sleep
          Sleep 200
        )


{-| Handle right rotation with elm-animator animation
-}
handleRotateRight : Model -> ( Model, Effect )
handleRotateRight model =
    -- Check if any animations are currently running
    if isAnimating model then
        -- Animation in progress - ignore input
        ( model, NoEffect )

    else
        let
            newRobot =
                RobotGame.rotateRight model.robot

            animationState =
                Rotating model.robot.facing newRobot.facing

            highlightedButtons =
                getRotationHighlights model.robot.facing newRobot.facing Model.RotateRightButton

            -- Start elm-animator rotation animation with 200ms duration
            updatedRobotTimeline =
                model.robotTimeline
                    |> Animator.go Animator.quickly newRobot

            -- Animate rotation angle for smooth visual transition
            fromAngle =
                directionToAngleFloat model.robot.facing

            toAngle =
                directionToAngleFloat newRobot.facing

            targetAngle =
                calculateShortestRotationPath fromAngle toAngle

            updatedRotationTimeline =
                model.rotationAngleTimeline
                    |> Animator.go Animator.quickly targetAngle

            -- Apply button highlight animation using elm-animator
            modelWithHighlights =
                animateButtonHighlight highlightedButtons model
        in
        ( { modelWithHighlights
            | robot = newRobot
            , animationState = animationState
            , highlightedButtons = highlightedButtons -- Keep for compatibility during transition
            , robotTimeline = updatedRobotTimeline
            , rotationAngleTimeline = updatedRotationTimeline
          }
        , -- Use elm-animator duration instead of Process.sleep
          Sleep 200
        )


{-| Handle rotation to a specific direction with elm-animator animation
-}
handleRotateToDirection : Direction -> Model -> ( Model, Effect )
handleRotateToDirection direction model =
    -- Check if any animations are currently running
    if isAnimating model then
        -- Animation in progress - ignore input
        ( model, NoEffect )

    else if model.robot.facing /= direction then
        let
            newRobot =
                RobotGame.rotateToDirection direction model.robot

            animationState =
                Rotating model.robot.facing newRobot.facing

            highlightedButtons =
                getDirectionHighlights model.robot.facing newRobot.facing

            -- Calculate animation duration based on rotation amount
            animationDuration =
                case ( model.robot.facing, direction ) of
                    -- 180-degree rotations take longer
                    ( North, South ) ->
                        300

                    ( South, North ) ->
                        300

                    ( East, West ) ->
                        300

                    ( West, East ) ->
                        300

                    -- 90-degree rotations are faster
                    _ ->
                        200

            -- Start elm-animator rotation animation with calculated duration
            updatedRobotTimeline =
                model.robotTimeline
                    |> Animator.go Animator.quickly newRobot

            -- Animate rotation angle for smooth visual transition
            fromAngle =
                directionToAngleFloat model.robot.facing

            toAngle =
                directionToAngleFloat newRobot.facing

            targetAngle =
                calculateShortestRotationPath fromAngle toAngle

            updatedRotationTimeline =
                model.rotationAngleTimeline
                    |> Animator.go Animator.quickly targetAngle

            -- Apply button highlight animation using elm-animator
            modelWithHighlights =
                animateButtonHighlight highlightedButtons model
        in
        ( { modelWithHighlights
            | robot = newRobot
            , animationState = animationState
            , highlightedButtons = highlightedButtons -- Keep for compatibility during transition
            , robotTimeline = updatedRobotTimeline
            , rotationAngleTimeline = updatedRotationTimeline
          }
        , -- Use elm-animator duration instead of Process.sleep
          Sleep animationDuration
        )

    else
        -- Already facing the requested direction
        ( model, NoEffect )


{-| Handle animation completion and return to idle state
-}
handleAnimationComplete : Model -> ( Model, Effect )
handleAnimationComplete model =
    let
        -- Ensure rotation angle timeline reflects the current robot direction after animation completes
        finalRotationAngle =
            directionToAngleFloat model.robot.facing

        updatedRotationTimeline =
            Animator.init finalRotationAngle

        -- Reset blocked movement timeline when animation completes
        resetBlockedMovementTimeline =
            if model.animationState == BlockedMovement then
                Animator.init False

            else
                model.blockedMovementTimeline
    in
    ( { model
        | animationState = Idle
        , rotationAngleTimeline = updatedRotationTimeline
        , blockedMovementTimeline = resetBlockedMovementTimeline
        , blockedMovementFeedback = False -- Clear feedback when animation completes
      }
    , NoEffect
    )


{-| Subscriptions for keyboard input and other events
-}
subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Browser.Events.onKeyDown keyDecoder

        -- Blocked movement feedback is now managed by elm-animator timeline, no separate subscription needed
        -- elm-animator subscription for smooth animation updates
        , Browser.Events.onAnimationFrame AnimationFrame
        ]


{-| Decode keyboard events and filter for relevant keys
-}
keyDecoder : Decode.Decoder Msg
keyDecoder =
    Decode.field "key" Decode.string
        |> Decode.andThen
            (\key ->
                case key of
                    "ArrowUp" ->
                        Decode.succeed (KeyPressed "ArrowUp")

                    "ArrowDown" ->
                        Decode.succeed (KeyPressed "ArrowDown")

                    "ArrowLeft" ->
                        Decode.succeed (KeyPressed "ArrowLeft")

                    "ArrowRight" ->
                        Decode.succeed (KeyPressed "ArrowRight")

                    _ ->
                        Decode.fail "Not a relevant key"
            )


{-| Helper function to determine which buttons should be highlighted for forward movement
-}
getForwardMovementHighlights : List Model.Button
getForwardMovementHighlights =
    [ Model.ForwardButton ]


{-| Helper function to determine which buttons should be highlighted for rotation
-}
getRotationHighlights : Direction -> Direction -> Model.Button -> List Model.Button
getRotationHighlights fromDirection toDirection rotationButton =
    [ rotationButton
    , Model.DirectionButton fromDirection
    , Model.DirectionButton toDirection
    ]


{-| Helper function to determine which buttons should be highlighted for direct direction selection
-}
getDirectionHighlights : Direction -> Direction -> List Model.Button
getDirectionHighlights fromDirection toDirection =
    [ Model.DirectionButton fromDirection
    , Model.DirectionButton toDirection
    ]


{-| Convert direction to rotation angle as Float for elm-animator interpolation
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


{-| Calculate the shortest rotation path between two angles
For elm-animator, we want the final target angle, not the adjusted path
-}
calculateShortestRotationPath : Float -> Float -> Float
calculateShortestRotationPath _ toAngle =
    -- For elm-animator, we want the final target angle
    -- The animation system will handle the interpolation
    toAngle


{-| Check if any elm-animator animations are currently running
-}
isAnimating : Model -> Bool
isAnimating model =
    -- Check if elm-animator timelines are currently animating
    -- We can check if the timeline has upcoming events or if we're in a non-idle animation state
    model.animationState /= Idle


{-| Clean up completed timelines to prevent memory leaks
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

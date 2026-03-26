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

import Browser.Events
import Json.Decode as Decode
import Process
import RobotGame.Animation as Animation
import RobotGame.Model as Model exposing (Direction(..), Model)
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
            ( Animation.completeAnimation model
                |> Animation.cleanupCompletedTimelines
            , NoEffect
            )

        ColorScheme colorScheme ->
            ( { model | colorScheme = colorScheme }, NoEffect )

        GetResize width height ->
            ( { model | maybeWindow = Just ( width, height ) }, NoEffect )

        Tick now ->
            ( { model | lastMoveTime = Just now }, NoEffect )

        ClearBlockedMovementFeedback ->
            ( Animation.clearBlockedMovementFeedback model, NoEffect )

        ButtonHighlightComplete ->
            ( Animation.clearButtonHighlightFeedback model, NoEffect )

        NavigateToRoute _ ->
            -- Navigation is handled by the parent App module
            ( model, NoEffect )

        AnimationFrame time ->
            ( Animation.updateAnimationFrame time model, NoEffect )


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


{-| Handle forward movement with elm-animator animation
-}
handleMoveForward : Model -> ( Model, Effect )
handleMoveForward model =
    -- Check if any animations are currently running
    if Animation.isAnimating model then
        -- Animation in progress - ignore input
        ( model, NoEffect )

    else if RobotGame.canMoveForward model.robot then
        let
            newRobot =
                RobotGame.moveForward model.robot

            highlightedButtons =
                Animation.getForwardMovementHighlights

            modelWithHighlights =
                Animation.startButtonHighlightAnimation highlightedButtons model

            workflow =
                Animation.startMovementWorkflow model.robot.position newRobot.position modelWithHighlights
        in
        ( workflow.model, Sleep workflow.delay )

    else
        -- Cannot move forward - show blocked movement animation with elm-animator
        let
            highlightedButtons =
                Animation.getForwardMovementHighlights

            modelWithHighlights =
                Animation.startButtonHighlightAnimation highlightedButtons model

            workflow =
                Animation.startBlockedMovementWorkflow modelWithHighlights
        in
        ( workflow.model, Sleep workflow.delay )


{-| Handle left rotation with elm-animator animation
-}
handleRotateLeft : Model -> ( Model, Effect )
handleRotateLeft model =
    -- Check if any animations are currently running
    if Animation.isAnimating model then
        -- Animation in progress - ignore input
        ( model, NoEffect )

    else
        let
            newRobot =
                RobotGame.rotateLeft model.robot

            highlightedButtons =
                Animation.getRotationHighlights model.robot.facing newRobot.facing Model.RotateLeftButton

            modelWithHighlights =
                Animation.startButtonHighlightAnimation highlightedButtons model

            workflow =
                Animation.startRotationWorkflow model.robot.facing newRobot.facing modelWithHighlights
        in
        ( workflow.model, Sleep workflow.delay )


{-| Handle right rotation with elm-animator animation
-}
handleRotateRight : Model -> ( Model, Effect )
handleRotateRight model =
    -- Check if any animations are currently running
    if Animation.isAnimating model then
        -- Animation in progress - ignore input
        ( model, NoEffect )

    else
        let
            newRobot =
                RobotGame.rotateRight model.robot

            highlightedButtons =
                Animation.getRotationHighlights model.robot.facing newRobot.facing Model.RotateRightButton

            modelWithHighlights =
                Animation.startButtonHighlightAnimation highlightedButtons model

            workflow =
                Animation.startRotationWorkflow model.robot.facing newRobot.facing modelWithHighlights
        in
        ( workflow.model, Sleep workflow.delay )


{-| Handle rotation to a specific direction with elm-animator animation
-}
handleRotateToDirection : Direction -> Model -> ( Model, Effect )
handleRotateToDirection direction model =
    -- Check if any animations are currently running
    if Animation.isAnimating model then
        -- Animation in progress - ignore input
        ( model, NoEffect )

    else if model.robot.facing /= direction then
        let
            newRobot =
                RobotGame.rotateToDirection direction model.robot

            highlightedButtons =
                Animation.getDirectionHighlights model.robot.facing newRobot.facing

            modelWithHighlights =
                Animation.startButtonHighlightAnimation highlightedButtons model

            workflow =
                Animation.startRotationWorkflow model.robot.facing newRobot.facing modelWithHighlights
        in
        ( workflow.model, Sleep workflow.delay )

    else
        -- Already facing the requested direction
        ( model, NoEffect )


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

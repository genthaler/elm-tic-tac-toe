module RobotGame.Main exposing (Msg(..), init, subscriptions, update)

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
import RobotGame.Model as Model exposing (AnimationState(..), Direction(..), Model)
import RobotGame.RobotGame as RobotGame
import Route
import Task
import Theme.Theme exposing (ColorScheme)
import Time


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
    | NavigateToRoute Route.Route


{-| Initialize the game with default state
-}
init : ( Model, Cmd Msg )
init =
    ( Model.init, Cmd.none )


{-| Update the game state based on received messages
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
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
            handleKeyPressed key model

        AnimationComplete ->
            handleAnimationComplete model

        ColorScheme colorScheme ->
            ( { model | colorScheme = colorScheme }, Cmd.none )

        GetResize width height ->
            ( { model | maybeWindow = Just ( width, height ) }, Cmd.none )

        Tick now ->
            ( { model | lastMoveTime = Just now }, Cmd.none )

        ClearBlockedMovementFeedback ->
            ( { model | blockedMovementFeedback = False, animationState = Idle }, Cmd.none )

        NavigateToRoute _ ->
            -- Navigation is handled by the parent App module
            ( model, Cmd.none )


{-| Handle forward movement with animation state management
-}
handleMoveForward : Model -> ( Model, Cmd Msg )
handleMoveForward model =
    case model.animationState of
        Idle ->
            if RobotGame.canMoveForward model.robot then
                let
                    newRobot =
                        RobotGame.moveForward model.robot

                    animationState =
                        Moving model.robot.position newRobot.position
                in
                ( { model
                    | robot = newRobot
                    , animationState = animationState
                    , blockedMovementFeedback = False
                  }
                , -- Start animation timer (300ms for smooth movement)
                  Process.sleep 300
                    |> Task.perform (\_ -> AnimationComplete)
                )

            else
                -- Cannot move forward - show blocked movement feedback
                ( { model
                    | animationState = BlockedMovement
                    , blockedMovementFeedback = True
                  }
                , Cmd.none
                )

        BlockedMovement ->
            -- Already showing blocked feedback - ignore additional attempts
            ( model, Cmd.none )

        _ ->
            -- Animation in progress - ignore input
            ( model, Cmd.none )


{-| Handle left rotation with animation state management
-}
handleRotateLeft : Model -> ( Model, Cmd Msg )
handleRotateLeft model =
    case model.animationState of
        Idle ->
            let
                newRobot =
                    RobotGame.rotateLeft model.robot

                animationState =
                    Rotating model.robot.facing newRobot.facing
            in
            ( { model
                | robot = newRobot
                , animationState = animationState
              }
            , -- Start animation timer (200ms for smooth rotation)
              Process.sleep 200
                |> Task.perform (\_ -> AnimationComplete)
            )

        _ ->
            -- Animation in progress - ignore input
            ( model, Cmd.none )


{-| Handle right rotation with animation state management
-}
handleRotateRight : Model -> ( Model, Cmd Msg )
handleRotateRight model =
    case model.animationState of
        Idle ->
            let
                newRobot =
                    RobotGame.rotateRight model.robot

                animationState =
                    Rotating model.robot.facing newRobot.facing
            in
            ( { model
                | robot = newRobot
                , animationState = animationState
              }
            , -- Start animation timer (200ms for smooth rotation)
              Process.sleep 200
                |> Task.perform (\_ -> AnimationComplete)
            )

        _ ->
            -- Animation in progress - ignore input
            ( model, Cmd.none )


{-| Handle rotation to a specific direction with animation state management
-}
handleRotateToDirection : Direction -> Model -> ( Model, Cmd Msg )
handleRotateToDirection direction model =
    case model.animationState of
        Idle ->
            if model.robot.facing /= direction then
                let
                    newRobot =
                        RobotGame.rotateToDirection direction model.robot

                    animationState =
                        Rotating model.robot.facing newRobot.facing

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
                in
                ( { model
                    | robot = newRobot
                    , animationState = animationState
                  }
                , -- Start animation timer with calculated duration
                  Process.sleep animationDuration
                    |> Task.perform (\_ -> AnimationComplete)
                )

            else
                -- Already facing the requested direction
                ( model, Cmd.none )

        _ ->
            -- Animation in progress - ignore input
            ( model, Cmd.none )


{-| Handle keyboard input and translate to game actions
-}
handleKeyPressed : String -> Model -> ( Model, Cmd Msg )
handleKeyPressed key model =
    case key of
        "ArrowUp" ->
            update MoveForward model

        "ArrowLeft" ->
            update RotateLeft model

        "ArrowRight" ->
            update RotateRight model

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
            update (RotateToDirection oppositeDirection) model

        _ ->
            -- Ignore other keys
            ( model, Cmd.none )


{-| Handle animation completion and return to idle state
-}
handleAnimationComplete : Model -> ( Model, Cmd Msg )
handleAnimationComplete model =
    ( { model | animationState = Idle }, Cmd.none )


{-| Subscriptions for keyboard input and other events
-}
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Browser.Events.onKeyDown keyDecoder
        , case model.animationState of
            BlockedMovement ->
                -- Clear blocked movement feedback after a short delay
                Time.every 500 (\_ -> ClearBlockedMovementFeedback)

            _ ->
                Sub.none
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

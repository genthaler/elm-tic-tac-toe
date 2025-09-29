module RobotGame.Model exposing
    ( AnimationState(..)
    , Button(..)
    , Direction(..)
    , Model
    , Position
    , Robot
      -- Used by Main for elm-animator button highlighting
    , decodeAnimationState
      -- Used by tests
    , decodeDirection
    , decodeModel
    , decodePosition
    , decodeRobot
    , directionToAngleFloat
      -- Used by tests and Main
    , encodeAnimationState
      -- Used by tests
    , encodeDirection
    , encodeModel
    , encodePosition
    , encodeRobot
    , init
    )

import Animator
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as DecodePipeline
import Json.Encode as Encode exposing (Value)
import Theme.Theme exposing (ColorScheme(..), decodeColorScheme, encodeColorScheme)
import Time



-- TYPES


{-| Position on the 5x5 grid with coordinates (0,0) to (4,4)
-}
type alias Position =
    { row : Int
    , col : Int
    }


{-| Cardinal directions the robot can face
-}
type Direction
    = North
    | South
    | East
    | West


{-| Robot state with position and facing direction
-}
type alias Robot =
    { position : Position
    , facing : Direction
    }


{-| Animation states for smooth transitions
-}
type AnimationState
    = Idle
    | Moving Position Position -- from, to
    | Rotating Direction Direction -- from, to
    | BlockedMovement -- indicates a blocked movement attempt


{-| Button types that can be highlighted
-}
type Button
    = ForwardButton
    | RotateLeftButton
    | RotateRightButton
    | DirectionButton Direction


{-| Main game model with elm-animator timelines
-}
type alias Model =
    { robot : Robot
    , gridSize : Int
    , colorScheme : ColorScheme
    , maybeWindow : Maybe ( Int, Int )
    , animationState : AnimationState
    , lastMoveTime : Maybe Time.Posix
    , blockedMovementFeedback : Bool -- indicates if we should show blocked movement feedback
    , highlightedButtons : List Button -- tracks which buttons should be highlighted

    -- elm-animator timelines
    , robotTimeline : Animator.Timeline Robot
    , buttonHighlightTimeline : Animator.Timeline (List Button) -- for button highlight animations
    , blockedMovementTimeline : Animator.Timeline Bool
    , rotationAngleTimeline : Animator.Timeline Float -- for smooth rotation animation
    }



-- HELPER FUNCTIONS


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



-- INITIALIZATION


{-| Initialize the game model with default values and elm-animator timelines
-}
init : Model
init =
    let
        initialRobot =
            { position = { row = 2, col = 2 } -- Center of 5x5 grid
            , facing = North
            }
    in
    { robot = initialRobot
    , gridSize = 5
    , colorScheme = Light
    , maybeWindow = Nothing
    , animationState = Idle
    , lastMoveTime = Nothing
    , blockedMovementFeedback = False
    , highlightedButtons = []

    -- Initialize elm-animator timelines
    , robotTimeline = Animator.init initialRobot
    , buttonHighlightTimeline = Animator.init []
    , blockedMovementTimeline = Animator.init False
    , rotationAngleTimeline = Animator.init 0.0 -- North = 0 degrees
    }



-- JSON ENCODING


{-| Encode the entire model to JSON for state persistence
-}
encodeModel : Model -> Value
encodeModel model =
    Encode.object
        [ ( "robot", encodeRobot model.robot )
        , ( "gridSize", Encode.int model.gridSize )
        , ( "colorScheme", encodeColorScheme model.colorScheme )
        , ( "animationState", encodeAnimationState model.animationState )
        , ( "blockedMovementFeedback", Encode.bool model.blockedMovementFeedback )
        , ( "highlightedButtons", Encode.list encodeButton model.highlightedButtons )
        ]


{-| Encode a position to JSON
-}
encodePosition : Position -> Value
encodePosition position =
    Encode.object
        [ ( "row", Encode.int position.row )
        , ( "col", Encode.int position.col )
        ]


{-| Encode a direction to JSON
-}
encodeDirection : Direction -> Value
encodeDirection direction =
    case direction of
        North ->
            Encode.string "North"

        South ->
            Encode.string "South"

        East ->
            Encode.string "East"

        West ->
            Encode.string "West"


{-| Encode a robot to JSON
-}
encodeRobot : Robot -> Value
encodeRobot robot =
    Encode.object
        [ ( "position", encodePosition robot.position )
        , ( "facing", encodeDirection robot.facing )
        ]


{-| Encode animation state to JSON
-}
encodeAnimationState : AnimationState -> Value
encodeAnimationState state =
    case state of
        Idle ->
            Encode.object [ ( "type", Encode.string "Idle" ) ]

        Moving from to ->
            Encode.object
                [ ( "type", Encode.string "Moving" )
                , ( "from", encodePosition from )
                , ( "to", encodePosition to )
                ]

        Rotating from to ->
            Encode.object
                [ ( "type", Encode.string "Rotating" )
                , ( "from", encodeDirection from )
                , ( "to", encodeDirection to )
                ]

        BlockedMovement ->
            Encode.object [ ( "type", Encode.string "BlockedMovement" ) ]


{-| Encode a button to JSON
-}
encodeButton : Button -> Value
encodeButton button =
    case button of
        ForwardButton ->
            Encode.object [ ( "type", Encode.string "ForwardButton" ) ]

        RotateLeftButton ->
            Encode.object [ ( "type", Encode.string "RotateLeftButton" ) ]

        RotateRightButton ->
            Encode.object [ ( "type", Encode.string "RotateRightButton" ) ]

        DirectionButton direction ->
            Encode.object
                [ ( "type", Encode.string "DirectionButton" )
                , ( "direction", encodeDirection direction )
                ]



-- JSON DECODING


{-| Decode the entire model from JSON
-}
decodeModel : Decoder Model
decodeModel =
    Decode.succeed
        (\robot gridSize colorScheme animationState blockedMovementFeedback highlightedButtons ->
            { robot = robot
            , gridSize = gridSize
            , colorScheme = colorScheme
            , maybeWindow = Nothing
            , animationState = animationState
            , lastMoveTime = Nothing
            , blockedMovementFeedback = blockedMovementFeedback
            , highlightedButtons = highlightedButtons

            -- Initialize elm-animator timelines (can't be serialized/deserialized)
            , robotTimeline = Animator.init robot
            , buttonHighlightTimeline = Animator.init []
            , blockedMovementTimeline = Animator.init False
            , rotationAngleTimeline = Animator.init (directionToAngleFloat robot.facing)
            }
        )
        |> DecodePipeline.required "robot" decodeRobot
        |> DecodePipeline.optional "gridSize" Decode.int 5
        |> DecodePipeline.optional "colorScheme" decodeColorScheme Light
        |> DecodePipeline.optional "animationState" decodeAnimationState Idle
        |> DecodePipeline.optional "blockedMovementFeedback" Decode.bool False
        |> DecodePipeline.optional "highlightedButtons" (Decode.list decodeButton) []



-- placeholder for lastMoveTime


{-| Decode a position from JSON
-}
decodePosition : Decoder Position
decodePosition =
    Decode.map2 Position
        (Decode.field "row" Decode.int)
        (Decode.field "col" Decode.int)


{-| Decode a direction from JSON
-}
decodeDirection : Decoder Direction
decodeDirection =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "North" ->
                        Decode.succeed North

                    "South" ->
                        Decode.succeed South

                    "East" ->
                        Decode.succeed East

                    "West" ->
                        Decode.succeed West

                    _ ->
                        Decode.fail ("Invalid direction: " ++ str)
            )


{-| Decode a robot from JSON
-}
decodeRobot : Decoder Robot
decodeRobot =
    Decode.map2 Robot
        (Decode.field "position" decodePosition)
        (Decode.field "facing" decodeDirection)


{-| Decode animation state from JSON
-}
decodeAnimationState : Decoder AnimationState
decodeAnimationState =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\type_ ->
                case type_ of
                    "Idle" ->
                        Decode.succeed Idle

                    "Moving" ->
                        Decode.map2 Moving
                            (Decode.field "from" decodePosition)
                            (Decode.field "to" decodePosition)

                    "Rotating" ->
                        Decode.map2 Rotating
                            (Decode.field "from" decodeDirection)
                            (Decode.field "to" decodeDirection)

                    "BlockedMovement" ->
                        Decode.succeed BlockedMovement

                    _ ->
                        Decode.fail ("Invalid animation state type: " ++ type_)
            )


{-| Decode a button from JSON
-}
decodeButton : Decoder Button
decodeButton =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\type_ ->
                case type_ of
                    "ForwardButton" ->
                        Decode.succeed ForwardButton

                    "RotateLeftButton" ->
                        Decode.succeed RotateLeftButton

                    "RotateRightButton" ->
                        Decode.succeed RotateRightButton

                    "DirectionButton" ->
                        Decode.map DirectionButton
                            (Decode.field "direction" decodeDirection)

                    _ ->
                        Decode.fail ("Invalid button type: " ++ type_)
            )

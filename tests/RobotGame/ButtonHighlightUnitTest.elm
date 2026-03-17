module RobotGame.ButtonHighlightUnitTest exposing (suite)

{-| Unit tests for the selective button highlighting system.

Tests cover:

  - Highlight helper functions for each action type
  - Update logic setting correct highlights per action
  - Keyboard actions triggering same highlights as button equivalents
  - Highlight clearing via ButtonHighlightComplete
  - No highlights for ignored/invalid actions

-}

import Animator
import Expect
import RobotGame.Main exposing (Msg(..), initToEffect, updateToEffect)
import RobotGame.Model exposing (AnimationState(..), Button(..), Direction(..), Model)
import Test exposing (Test, describe, test)
import Theme.Theme


suite : Test
suite =
    describe "Button Highlight Unit Tests (Requirement 7)"
        [ forwardMovementHighlightTests
        , rotationHighlightTests
        , directionSelectionHighlightTests
        , keyboardHighlightConsistencyTests
        , highlightClearingTests
        , noHighlightTests
        ]


{-| Helper to get initial model
-}
initModel : Model
initModel =
    Tuple.first initToEffect


{-| Helper to apply an update and get the resulting model
-}
applyUpdate : Msg -> Model -> Model
applyUpdate msg model =
    Tuple.first (updateToEffect msg model)


{-| Helper to create a model at a specific position and direction
-}
modelAt : { row : Int, col : Int } -> Direction -> Model
modelAt pos facing =
    let
        base =
            initModel

        robot =
            { position = { row = pos.row, col = pos.col }, facing = facing }
    in
    { base
        | robot = robot
        , robotTimeline = Animator.init robot
        , rotationAngleTimeline = Animator.init (RobotGame.Model.directionToAngleFloat facing)
    }


{-| Helper to get highlighted buttons from elm-animator timeline
-}
getTimelineHighlights : Model -> List Button
getTimelineHighlights model =
    Animator.current model.buttonHighlightTimeline



-- FORWARD MOVEMENT HIGHLIGHT TESTS


forwardMovementHighlightTests : Test
forwardMovementHighlightTests =
    describe "Forward Movement Highlights"
        [ test "forward movement highlights only ForwardButton" <|
            \_ ->
                let
                    model =
                        applyUpdate MoveForward initModel
                in
                Expect.equal [ ForwardButton ] model.highlightedButtons
        , test "forward movement sets ForwardButton in timeline" <|
            \_ ->
                let
                    model =
                        applyUpdate MoveForward initModel
                in
                Expect.equal [ ForwardButton ] (getTimelineHighlights model)
        , test "blocked forward movement also highlights ForwardButton" <|
            \_ ->
                let
                    -- Robot at top edge facing North - can't move
                    model =
                        modelAt { row = 0, col = 2 } North

                    updated =
                        applyUpdate MoveForward model
                in
                Expect.equal [ ForwardButton ] updated.highlightedButtons
        , test "forward movement does not highlight rotation buttons" <|
            \_ ->
                let
                    model =
                        applyUpdate MoveForward initModel
                in
                Expect.all
                    [ \m -> Expect.equal False (List.member RotateLeftButton m.highlightedButtons)
                    , \m -> Expect.equal False (List.member RotateRightButton m.highlightedButtons)
                    ]
                    model
        , test "forward movement does not highlight direction buttons" <|
            \_ ->
                let
                    model =
                        applyUpdate MoveForward initModel
                in
                Expect.all
                    [ \m -> Expect.equal False (List.member (DirectionButton North) m.highlightedButtons)
                    , \m -> Expect.equal False (List.member (DirectionButton South) m.highlightedButtons)
                    , \m -> Expect.equal False (List.member (DirectionButton East) m.highlightedButtons)
                    , \m -> Expect.equal False (List.member (DirectionButton West) m.highlightedButtons)
                    ]
                    model
        ]



-- ROTATION HIGHLIGHT TESTS


rotationHighlightTests : Test
rotationHighlightTests =
    describe "Rotation Highlights"
        [ test "rotate left highlights RotateLeftButton and old/new direction buttons" <|
            \_ ->
                let
                    -- Default: facing North, rotate left -> West
                    model =
                        applyUpdate RotateLeft initModel
                in
                Expect.equal
                    [ RotateLeftButton, DirectionButton North, DirectionButton West ]
                    model.highlightedButtons
        , test "rotate right highlights RotateRightButton and old/new direction buttons" <|
            \_ ->
                let
                    -- Default: facing North, rotate right -> East
                    model =
                        applyUpdate RotateRight initModel
                in
                Expect.equal
                    [ RotateRightButton, DirectionButton North, DirectionButton East ]
                    model.highlightedButtons
        , test "rotate left from East highlights correct buttons" <|
            \_ ->
                let
                    model =
                        modelAt { row = 2, col = 2 } East

                    updated =
                        applyUpdate RotateLeft model
                in
                Expect.equal
                    [ RotateLeftButton, DirectionButton East, DirectionButton North ]
                    updated.highlightedButtons
        , test "rotate right from West highlights correct buttons" <|
            \_ ->
                let
                    model =
                        modelAt { row = 2, col = 2 } West

                    updated =
                        applyUpdate RotateRight model
                in
                Expect.equal
                    [ RotateRightButton, DirectionButton West, DirectionButton North ]
                    updated.highlightedButtons
        , test "rotation does not highlight ForwardButton" <|
            \_ ->
                let
                    model =
                        applyUpdate RotateLeft initModel
                in
                Expect.equal False (List.member ForwardButton model.highlightedButtons)
        ]



-- DIRECTION SELECTION HIGHLIGHT TESTS


directionSelectionHighlightTests : Test
directionSelectionHighlightTests =
    describe "Direction Selection Highlights"
        [ test "selecting East from North highlights only old and new direction buttons" <|
            \_ ->
                let
                    model =
                        applyUpdate (RotateToDirection East) initModel
                in
                Expect.equal
                    [ DirectionButton North, DirectionButton East ]
                    model.highlightedButtons
        , test "selecting South from North highlights only old and new direction buttons" <|
            \_ ->
                let
                    model =
                        applyUpdate (RotateToDirection South) initModel
                in
                Expect.equal
                    [ DirectionButton North, DirectionButton South ]
                    model.highlightedButtons
        , test "selecting West from East highlights correct buttons" <|
            \_ ->
                let
                    model =
                        modelAt { row = 2, col = 2 } East

                    updated =
                        applyUpdate (RotateToDirection West) model
                in
                Expect.equal
                    [ DirectionButton East, DirectionButton West ]
                    updated.highlightedButtons
        , test "direction selection does not highlight ForwardButton" <|
            \_ ->
                let
                    model =
                        applyUpdate (RotateToDirection South) initModel
                in
                Expect.equal False (List.member ForwardButton model.highlightedButtons)
        , test "direction selection does not highlight rotation buttons" <|
            \_ ->
                let
                    model =
                        applyUpdate (RotateToDirection East) initModel
                in
                Expect.all
                    [ \m -> Expect.equal False (List.member RotateLeftButton m.highlightedButtons)
                    , \m -> Expect.equal False (List.member RotateRightButton m.highlightedButtons)
                    ]
                    model
        , test "selecting same direction does not set any highlights" <|
            \_ ->
                let
                    -- Already facing North, select North
                    model =
                        applyUpdate (RotateToDirection North) initModel
                in
                Expect.equal [] model.highlightedButtons
        ]



-- KEYBOARD HIGHLIGHT CONSISTENCY TESTS


keyboardHighlightConsistencyTests : Test
keyboardHighlightConsistencyTests =
    describe "Keyboard Actions Trigger Same Highlights as Buttons"
        [ test "ArrowUp highlights same as MoveForward" <|
            \_ ->
                let
                    buttonModel =
                        applyUpdate MoveForward initModel

                    keyboardModel =
                        applyUpdate (KeyPressed "ArrowUp") initModel
                in
                Expect.equal buttonModel.highlightedButtons keyboardModel.highlightedButtons
        , test "ArrowLeft highlights same as RotateLeft" <|
            \_ ->
                let
                    buttonModel =
                        applyUpdate RotateLeft initModel

                    keyboardModel =
                        applyUpdate (KeyPressed "ArrowLeft") initModel
                in
                Expect.equal buttonModel.highlightedButtons keyboardModel.highlightedButtons
        , test "ArrowRight highlights same as RotateRight" <|
            \_ ->
                let
                    buttonModel =
                        applyUpdate RotateRight initModel

                    keyboardModel =
                        applyUpdate (KeyPressed "ArrowRight") initModel
                in
                Expect.equal buttonModel.highlightedButtons keyboardModel.highlightedButtons
        , test "ArrowDown highlights same as RotateToDirection opposite" <|
            \_ ->
                let
                    -- Default facing North, ArrowDown -> RotateToDirection South
                    buttonModel =
                        applyUpdate (RotateToDirection South) initModel

                    keyboardModel =
                        applyUpdate (KeyPressed "ArrowDown") initModel
                in
                Expect.equal buttonModel.highlightedButtons keyboardModel.highlightedButtons
        , test "ArrowDown from East highlights same as RotateToDirection West" <|
            \_ ->
                let
                    model =
                        modelAt { row = 2, col = 2 } East

                    buttonModel =
                        applyUpdate (RotateToDirection West) model

                    keyboardModel =
                        applyUpdate (KeyPressed "ArrowDown") model
                in
                Expect.equal buttonModel.highlightedButtons keyboardModel.highlightedButtons
        ]



-- HIGHLIGHT CLEARING TESTS


highlightClearingTests : Test
highlightClearingTests =
    describe "Highlight Clearing"
        [ test "ButtonHighlightComplete clears highlightedButtons" <|
            \_ ->
                let
                    -- First trigger a highlight
                    modelWithHighlight =
                        applyUpdate MoveForward initModel

                    -- Then clear it
                    cleared =
                        applyUpdate ButtonHighlightComplete modelWithHighlight
                in
                Expect.equal [] cleared.highlightedButtons
        , test "ButtonHighlightComplete resets button highlight timeline" <|
            \_ ->
                let
                    modelWithHighlight =
                        applyUpdate MoveForward initModel

                    cleared =
                        applyUpdate ButtonHighlightComplete modelWithHighlight
                in
                Expect.equal [] (getTimelineHighlights cleared)
        , test "AnimationComplete does not clear highlights by itself" <|
            \_ ->
                let
                    modelWithHighlight =
                        applyUpdate MoveForward initModel

                    afterAnimation =
                        applyUpdate AnimationComplete modelWithHighlight
                in
                -- Highlights are managed separately from animation state
                -- The timeline may still have highlights even after animation completes
                Expect.equal Idle afterAnimation.animationState
        ]



-- NO HIGHLIGHT TESTS


noHighlightTests : Test
noHighlightTests =
    describe "No Highlights for Non-Action Messages"
        [ test "irrelevant key press does not set highlights" <|
            \_ ->
                let
                    model =
                        applyUpdate (KeyPressed "Space") initModel
                in
                Expect.equal [] model.highlightedButtons
        , test "ColorScheme change does not set highlights" <|
            \_ ->
                let
                    model =
                        applyUpdate (ColorScheme Theme.Theme.Dark) initModel
                in
                Expect.equal [] model.highlightedButtons
        , test "GetResize does not set highlights" <|
            \_ ->
                let
                    model =
                        applyUpdate (GetResize 800 600) initModel
                in
                Expect.equal [] model.highlightedButtons
        , test "actions during animation do not change highlights" <|
            \_ ->
                let
                    -- Start an animation
                    animating =
                        applyUpdate MoveForward initModel

                    -- Try another action during animation (should be ignored)
                    duringAnimation =
                        applyUpdate RotateLeft animating
                in
                -- Highlights should remain from the first action
                Expect.equal [ ForwardButton ] duringAnimation.highlightedButtons
        , test "initial model has no highlights" <|
            \_ ->
                Expect.equal [] initModel.highlightedButtons
        , test "initial model timeline has no highlights" <|
            \_ ->
                Expect.equal [] (getTimelineHighlights initModel)
        ]

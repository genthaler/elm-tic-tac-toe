module RobotGame.SelectiveHighlightingUnitTest exposing (suite)

{-| Unit tests for selective button highlighting functionality in the Robot Grid Game.

This module tests the selective button highlighting system that ensures only buttons
corresponding to actual state changes are highlighted with animations.

-}

import Animator
import Expect
import RobotGame.Main as Main
import RobotGame.Model exposing (AnimationState(..), Button(..), Direction(..), Model, directionToAngleFloat)
import Test exposing (Test, describe, test)
import Theme.Theme exposing (ColorScheme(..))


{-| Helper function to create a test model
-}
createTestModel : Model
createTestModel =
    let
        robot =
            { position = { row = 2, col = 2 }
            , facing = North
            }
    in
    { robot = robot
    , gridSize = 5
    , colorScheme = Light
    , maybeWindow = Just ( 1024, 768 )
    , animationState = Idle
    , lastMoveTime = Nothing
    , blockedMovementFeedback = False
    , highlightedButtons = []

    -- Initialize elm-animator timelines
    , robotTimeline = Animator.init robot
    , buttonHighlightTimeline = Animator.init []
    , blockedMovementTimeline = Animator.init False
    , rotationAngleTimeline = Animator.init (directionToAngleFloat robot.facing)
    }


{-| Helper function to convert Button to string for comparison
-}
buttonToString : Button -> String
buttonToString button =
    case button of
        ForwardButton ->
            "ForwardButton"

        RotateLeftButton ->
            "RotateLeftButton"

        RotateRightButton ->
            "RotateRightButton"

        DirectionButton direction ->
            "DirectionButton(" ++ directionToString direction ++ ")"


{-| Helper function to convert Direction to string
-}
directionToString : Direction -> String
directionToString direction =
    case direction of
        North ->
            "North"

        South ->
            "South"

        East ->
            "East"

        West ->
            "West"


{-| Helper function to sort buttons by converting to strings first
-}
sortButtons : List Button -> List Button
sortButtons buttons =
    buttons
        |> List.map (\button -> ( buttonToString button, button ))
        |> List.sortBy Tuple.first
        |> List.map Tuple.second


suite : Test
suite =
    describe "Selective Button Highlighting Tests"
        [ forwardMovementHighlightingTests
        , rotationHighlightingTests
        , directionSelectionHighlightingTests
        , keyboardHighlightingTests
        , highlightClearingTests
        ]


{-| Test forward movement highlighting
-}
forwardMovementHighlightingTests : Test
forwardMovementHighlightingTests =
    describe "Forward Movement Highlighting"
        [ test "forward movement highlights only forward button" <|
            \_ ->
                let
                    model =
                        createTestModel

                    ( updatedModel, _ ) =
                        Main.updateToEffect Main.MoveForward model
                in
                Expect.equal [ ForwardButton ] updatedModel.highlightedButtons
        , test "blocked forward movement highlights only forward button" <|
            \_ ->
                let
                    -- Robot at top edge cannot move forward (facing North)
                    model =
                        { createTestModel | robot = { position = { row = 0, col = 2 }, facing = North } }

                    ( updatedModel, _ ) =
                        Main.updateToEffect Main.MoveForward model
                in
                Expect.equal [ ForwardButton ] updatedModel.highlightedButtons
        ]


{-| Test rotation highlighting
-}
rotationHighlightingTests : Test
rotationHighlightingTests =
    describe "Rotation Highlighting"
        [ test "rotate left highlights rotation button and direction buttons" <|
            \_ ->
                let
                    model =
                        createTestModel

                    -- Robot facing North
                    ( updatedModel, _ ) =
                        Main.updateToEffect Main.RotateLeft model

                    expectedHighlights =
                        [ RotateLeftButton, DirectionButton North, DirectionButton West ]

                    -- From North to West
                in
                Expect.equal (sortButtons expectedHighlights) (sortButtons updatedModel.highlightedButtons)
        , test "rotate right highlights rotation button and direction buttons" <|
            \_ ->
                let
                    model =
                        createTestModel

                    -- Robot facing North
                    ( updatedModel, _ ) =
                        Main.updateToEffect Main.RotateRight model

                    expectedHighlights =
                        [ RotateRightButton, DirectionButton North, DirectionButton East ]

                    -- From North to East
                in
                Expect.equal (sortButtons expectedHighlights) (sortButtons updatedModel.highlightedButtons)
        , test "rotate from East to South highlights correct buttons" <|
            \_ ->
                let
                    model =
                        { createTestModel | robot = { position = { row = 2, col = 2 }, facing = East } }

                    ( updatedModel, _ ) =
                        Main.updateToEffect Main.RotateRight model

                    expectedHighlights =
                        [ RotateRightButton, DirectionButton East, DirectionButton South ]

                    -- From East to South
                in
                Expect.equal (sortButtons expectedHighlights) (sortButtons updatedModel.highlightedButtons)
        ]


{-| Test direct direction selection highlighting
-}
directionSelectionHighlightingTests : Test
directionSelectionHighlightingTests =
    describe "Direction Selection Highlighting"
        [ test "direct direction selection highlights only old and new direction buttons" <|
            \_ ->
                let
                    model =
                        createTestModel

                    -- Robot facing North
                    ( updatedModel, _ ) =
                        Main.updateToEffect (Main.RotateToDirection South) model

                    expectedHighlights =
                        [ DirectionButton North, DirectionButton South ]

                    -- From North to South
                in
                Expect.equal (sortButtons expectedHighlights) (sortButtons updatedModel.highlightedButtons)
        , test "direction selection from West to East highlights correct buttons" <|
            \_ ->
                let
                    model =
                        { createTestModel | robot = { position = { row = 2, col = 2 }, facing = West } }

                    ( updatedModel, _ ) =
                        Main.updateToEffect (Main.RotateToDirection East) model

                    expectedHighlights =
                        [ DirectionButton West, DirectionButton East ]

                    -- From West to East
                in
                Expect.equal (sortButtons expectedHighlights) (sortButtons updatedModel.highlightedButtons)
        , test "selecting same direction does not change highlights" <|
            \_ ->
                let
                    model =
                        createTestModel

                    -- Robot facing North
                    ( updatedModel, _ ) =
                        Main.updateToEffect (Main.RotateToDirection North) model
                in
                Expect.equal [] updatedModel.highlightedButtons
        ]


{-| Test keyboard input highlighting
-}
keyboardHighlightingTests : Test
keyboardHighlightingTests =
    describe "Keyboard Input Highlighting"
        [ test "arrow up key highlights forward button" <|
            \_ ->
                let
                    model =
                        createTestModel

                    ( updatedModel, _ ) =
                        Main.updateToEffect (Main.KeyPressed "ArrowUp") model
                in
                Expect.equal [ ForwardButton ] updatedModel.highlightedButtons
        , test "arrow left key highlights rotation and direction buttons" <|
            \_ ->
                let
                    model =
                        createTestModel

                    -- Robot facing North
                    ( updatedModel, _ ) =
                        Main.updateToEffect (Main.KeyPressed "ArrowLeft") model

                    expectedHighlights =
                        [ RotateLeftButton, DirectionButton North, DirectionButton West ]

                    -- From North to West
                in
                Expect.equal (sortButtons expectedHighlights) (sortButtons updatedModel.highlightedButtons)
        , test "arrow right key highlights rotation and direction buttons" <|
            \_ ->
                let
                    model =
                        createTestModel

                    -- Robot facing North
                    ( updatedModel, _ ) =
                        Main.updateToEffect (Main.KeyPressed "ArrowRight") model

                    expectedHighlights =
                        [ RotateRightButton, DirectionButton North, DirectionButton East ]

                    -- From North to East
                in
                Expect.equal (sortButtons expectedHighlights) (sortButtons updatedModel.highlightedButtons)
        , test "arrow down key highlights direction buttons for opposite direction" <|
            \_ ->
                let
                    model =
                        createTestModel

                    -- Robot facing North
                    ( updatedModel, _ ) =
                        Main.updateToEffect (Main.KeyPressed "ArrowDown") model

                    expectedHighlights =
                        [ DirectionButton North, DirectionButton South ]

                    -- From North to South (opposite)
                in
                Expect.equal (sortButtons expectedHighlights) (sortButtons updatedModel.highlightedButtons)
        ]


{-| Test highlight clearing
-}
highlightClearingTests : Test
highlightClearingTests =
    describe "Highlight Clearing"
        [ test "ButtonHighlightComplete clears all highlights" <|
            \_ ->
                let
                    modelWithHighlights =
                        { createTestModel | highlightedButtons = [ ForwardButton, DirectionButton North, DirectionButton South ] }

                    ( updatedModel, _ ) =
                        Main.updateToEffect Main.ButtonHighlightComplete modelWithHighlights
                in
                Expect.equal [] updatedModel.highlightedButtons
        , test "highlights are initially empty" <|
            \_ ->
                let
                    model =
                        createTestModel
                in
                Expect.equal [] model.highlightedButtons
        ]

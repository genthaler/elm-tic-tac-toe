module RobotGame.KeyboardInputTest exposing (suite)

{-| Comprehensive keyboard input testing for all control scenarios.

These tests verify that keyboard input is properly handled in all situations,
including edge cases, rapid input, and input during various game states.

-}

import Expect
import RobotGame.Main exposing (Msg(..), update)
import RobotGame.Model exposing (AnimationState(..), Direction(..), Model)
import Test exposing (Test, describe, test)
import Theme.Theme exposing (ColorScheme(..))


{-| Helper function to create a model with specific state
-}
createModelWithState : { position : { row : Int, col : Int }, facing : Direction, animationState : AnimationState } -> Model
createModelWithState { position, facing, animationState } =
    { robot = { position = position, facing = facing }
    , gridSize = 5
    , colorScheme = Light
    , maybeWindow = Just ( 1024, 768 )
    , animationState = animationState
    , lastMoveTime = Nothing
    , blockedMovementFeedback = False
    }


suite : Test
suite =
    describe "Comprehensive Keyboard Input Testing"
        [ basicKeyboardInputTests
        , keyboardInputDuringAnimationTests
        , keyboardInputAtBoundariesTests
        , rapidKeyboardInputTests
        , keyboardInputEdgeCasesTests
        , keyboardInputSequenceTests
        ]


basicKeyboardInputTests : Test
basicKeyboardInputTests =
    describe "Basic Keyboard Input"
        [ test "ArrowUp moves robot forward in current direction" <|
            \_ ->
                let
                    testDirections =
                        [ ( North, { row = 1, col = 2 } )
                        , ( South, { row = 3, col = 2 } )
                        , ( East, { row = 2, col = 3 } )
                        , ( West, { row = 2, col = 1 } )
                        ]

                    testDirection ( direction, expectedPosition ) =
                        let
                            initialModel =
                                createModelWithState
                                    { position = { row = 2, col = 2 }
                                    , facing = direction
                                    , animationState = Idle
                                    }

                            ( updatedModel, _ ) =
                                update (KeyPressed "ArrowUp") initialModel
                        in
                        Expect.all
                            [ \m -> Expect.equal expectedPosition m.robot.position
                            , \m -> Expect.equal direction m.robot.facing
                            ]
                            updatedModel
                in
                testDirections
                    |> List.map testDirection
                    |> List.all (\result -> result == Expect.pass)
                    |> Expect.equal True
        , test "ArrowLeft rotates robot counterclockwise" <|
            \_ ->
                let
                    testRotations =
                        [ ( North, West )
                        , ( West, South )
                        , ( South, East )
                        , ( East, North )
                        ]

                    testRotation ( fromDirection, toDirection ) =
                        let
                            initialModel =
                                createModelWithState
                                    { position = { row = 2, col = 2 }
                                    , facing = fromDirection
                                    , animationState = Idle
                                    }

                            ( updatedModel, _ ) =
                                update (KeyPressed "ArrowLeft") initialModel
                        in
                        Expect.all
                            [ \m -> Expect.equal { row = 2, col = 2 } m.robot.position
                            , \m -> Expect.equal toDirection m.robot.facing
                            , \m -> Expect.equal (Rotating fromDirection toDirection) m.animationState
                            ]
                            updatedModel
                in
                testRotations
                    |> List.map testRotation
                    |> List.all (\result -> result == Expect.pass)
                    |> Expect.equal True
        , test "ArrowRight rotates robot clockwise" <|
            \_ ->
                let
                    testRotations =
                        [ ( North, East )
                        , ( East, South )
                        , ( South, West )
                        , ( West, North )
                        ]

                    testRotation ( fromDirection, toDirection ) =
                        let
                            initialModel =
                                createModelWithState
                                    { position = { row = 2, col = 2 }
                                    , facing = fromDirection
                                    , animationState = Idle
                                    }

                            ( updatedModel, _ ) =
                                update (KeyPressed "ArrowRight") initialModel
                        in
                        Expect.all
                            [ \m -> Expect.equal { row = 2, col = 2 } m.robot.position
                            , \m -> Expect.equal toDirection m.robot.facing
                            , \m -> Expect.equal (Rotating fromDirection toDirection) m.animationState
                            ]
                            updatedModel
                in
                testRotations
                    |> List.map testRotation
                    |> List.all (\result -> result == Expect.pass)
                    |> Expect.equal True
        , test "ArrowDown rotates robot to opposite direction" <|
            \_ ->
                let
                    testRotations =
                        [ ( North, South )
                        , ( South, North )
                        , ( East, West )
                        , ( West, East )
                        ]

                    testRotation ( fromDirection, toDirection ) =
                        let
                            initialModel =
                                createModelWithState
                                    { position = { row = 2, col = 2 }
                                    , facing = fromDirection
                                    , animationState = Idle
                                    }

                            ( updatedModel, _ ) =
                                update (KeyPressed "ArrowDown") initialModel
                        in
                        Expect.all
                            [ \m -> Expect.equal { row = 2, col = 2 } m.robot.position
                            , \m -> Expect.equal toDirection m.robot.facing
                            , \m -> Expect.equal (Rotating fromDirection toDirection) m.animationState
                            ]
                            updatedModel
                in
                testRotations
                    |> List.map testRotation
                    |> List.all (\result -> result == Expect.pass)
                    |> Expect.equal True
        , test "Non-arrow keys are ignored" <|
            \_ ->
                let
                    initialModel =
                        createModelWithState
                            { position = { row = 2, col = 2 }
                            , facing = North
                            , animationState = Idle
                            }

                    ignoredKeys =
                        [ "Space"
                        , "Enter"
                        , "Escape"
                        , "Tab"
                        , "Shift"
                        , "Control"
                        , "Alt"
                        , "a"
                        , "b"
                        , "c"
                        , "w"
                        , "a"
                        , "s"
                        , "d"
                        , "1"
                        , "2"
                        , "3"
                        , "F1"
                        , "F2"
                        , "Home"
                        , "End"
                        , "PageUp"
                        , "PageDown"
                        ]

                    testIgnoredKey key =
                        let
                            ( updatedModel, _ ) =
                                update (KeyPressed key) initialModel
                        in
                        Expect.equal initialModel updatedModel
                in
                ignoredKeys
                    |> List.map testIgnoredKey
                    |> List.all (\result -> result == Expect.pass)
                    |> Expect.equal True
        ]


keyboardInputDuringAnimationTests : Test
keyboardInputDuringAnimationTests =
    describe "Keyboard Input During Animation"
        [ test "keyboard input is ignored during movement animation" <|
            \_ ->
                let
                    initialModel =
                        createModelWithState
                            { position = { row = 2, col = 2 }
                            , facing = North
                            , animationState = Moving { row = 2, col = 2 } { row = 1, col = 2 }
                            }

                    testKeys =
                        [ "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight" ]

                    testKeyDuringAnimation key =
                        let
                            ( updatedModel, _ ) =
                                update (KeyPressed key) initialModel
                        in
                        Expect.equal initialModel updatedModel
                in
                testKeys
                    |> List.map testKeyDuringAnimation
                    |> List.all (\result -> result == Expect.pass)
                    |> Expect.equal True
        , test "keyboard input is ignored during rotation animation" <|
            \_ ->
                let
                    initialModel =
                        createModelWithState
                            { position = { row = 2, col = 2 }
                            , facing = East
                            , animationState = Rotating North East
                            }

                    testKeys =
                        [ "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight" ]

                    testKeyDuringAnimation key =
                        let
                            ( updatedModel, _ ) =
                                update (KeyPressed key) initialModel
                        in
                        Expect.equal initialModel updatedModel
                in
                testKeys
                    |> List.map testKeyDuringAnimation
                    |> List.all (\result -> result == Expect.pass)
                    |> Expect.equal True
        , test "keyboard input is ignored during blocked movement state" <|
            \_ ->
                let
                    initialModel =
                        createModelWithState
                            { position = { row = 0, col = 2 }
                            , facing = North
                            , animationState = BlockedMovement
                            }

                    testKeys =
                        [ "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight" ]

                    testKeyDuringBlocked key =
                        let
                            ( updatedModel, _ ) =
                                update (KeyPressed key) initialModel
                        in
                        Expect.equal initialModel updatedModel
                in
                testKeys
                    |> List.map testKeyDuringBlocked
                    |> List.all (\result -> result == Expect.pass)
                    |> Expect.equal True
        , test "keyboard input works after animation completes" <|
            \_ ->
                let
                    animatingModel =
                        createModelWithState
                            { position = { row = 1, col = 2 }
                            , facing = North
                            , animationState = Moving { row = 2, col = 2 } { row = 1, col = 2 }
                            }

                    -- Complete animation
                    ( idleModel, _ ) =
                        update AnimationComplete animatingModel

                    -- Now keyboard input should work
                    ( afterKeyPress, _ ) =
                        update (KeyPressed "ArrowRight") idleModel
                in
                Expect.all
                    [ \m -> Expect.equal { row = 1, col = 2 } m.robot.position
                    , \m -> Expect.equal East m.robot.facing
                    , \m -> Expect.equal (Rotating North East) m.animationState
                    ]
                    afterKeyPress
        ]


keyboardInputAtBoundariesTests : Test
keyboardInputAtBoundariesTests =
    describe "Keyboard Input at Boundaries"
        [ test "ArrowUp at top boundary triggers blocked movement" <|
            \_ ->
                let
                    testPositions =
                        List.range 0 4 |> List.map (\col -> { row = 0, col = col })

                    testPosition position =
                        let
                            initialModel =
                                createModelWithState
                                    { position = position
                                    , facing = North
                                    , animationState = Idle
                                    }

                            ( updatedModel, _ ) =
                                update (KeyPressed "ArrowUp") initialModel
                        in
                        Expect.all
                            [ \m -> Expect.equal position m.robot.position
                            , \m -> Expect.equal North m.robot.facing
                            , \m -> Expect.equal BlockedMovement m.animationState
                            , \m -> Expect.equal True m.blockedMovementFeedback
                            ]
                            updatedModel
                in
                testPositions
                    |> List.map testPosition
                    |> List.all (\result -> result == Expect.pass)
                    |> Expect.equal True
        , test "ArrowUp at bottom boundary allows movement" <|
            \_ ->
                let
                    testPositions =
                        List.range 0 4 |> List.map (\col -> { row = 4, col = col })

                    testPosition position =
                        let
                            initialModel =
                                createModelWithState
                                    { position = position
                                    , facing = North
                                    , animationState = Idle
                                    }

                            ( updatedModel, _ ) =
                                update (KeyPressed "ArrowUp") initialModel

                            expectedPosition =
                                { position | row = position.row - 1 }
                        in
                        Expect.all
                            [ \m -> Expect.equal expectedPosition m.robot.position
                            , \m -> Expect.equal North m.robot.facing
                            , \m -> Expect.equal (Moving position expectedPosition) m.animationState
                            , \m -> Expect.equal False m.blockedMovementFeedback
                            ]
                            updatedModel
                in
                testPositions
                    |> List.map testPosition
                    |> List.all (\result -> result == Expect.pass)
                    |> Expect.equal True
        , test "rotation keys work at all boundaries" <|
            \_ ->
                let
                    boundaryPositions =
                        [ { row = 0, col = 0 }
                        , { row = 0, col = 4 }
                        , { row = 4, col = 0 }
                        , { row = 4, col = 4 }
                        , { row = 0, col = 2 }
                        , { row = 4, col = 2 }
                        , { row = 2, col = 0 }
                        , { row = 2, col = 4 }
                        ]

                    testRotationAtBoundary position =
                        let
                            initialModel =
                                createModelWithState
                                    { position = position
                                    , facing = North
                                    , animationState = Idle
                                    }

                            ( afterLeft, _ ) =
                                update (KeyPressed "ArrowLeft") initialModel

                            ( afterLeftAnim, _ ) =
                                update AnimationComplete afterLeft

                            ( afterRight, _ ) =
                                update (KeyPressed "ArrowRight") afterLeftAnim

                            ( afterRightAnim, _ ) =
                                update AnimationComplete afterRight

                            ( afterDown, _ ) =
                                update (KeyPressed "ArrowDown") afterRightAnim

                            ( finalModel, _ ) =
                                update AnimationComplete afterDown
                        in
                        Expect.all
                            [ \m -> Expect.equal position m.robot.position
                            , \m -> Expect.equal South m.robot.facing
                            , \m -> Expect.equal Idle m.animationState
                            ]
                            finalModel
                in
                boundaryPositions
                    |> List.map testRotationAtBoundary
                    |> List.all (\result -> result == Expect.pass)
                    |> Expect.equal True
        ]


rapidKeyboardInputTests : Test
rapidKeyboardInputTests =
    describe "Rapid Keyboard Input"
        [ test "rapid arrow key presses are properly queued/ignored" <|
            \_ ->
                let
                    initialModel =
                        createModelWithState
                            { position = { row = 2, col = 2 }
                            , facing = North
                            , animationState = Idle
                            }

                    -- Simulate rapid key presses
                    ( after1, _ ) =
                        update (KeyPressed "ArrowUp") initialModel

                    ( after2, _ ) =
                        update (KeyPressed "ArrowUp") after1

                    ( after3, _ ) =
                        update (KeyPressed "ArrowRight") after2

                    ( after4, _ ) =
                        update (KeyPressed "ArrowLeft") after3

                    -- Complete the first animation
                    ( afterComplete, _ ) =
                        update AnimationComplete after4
                in
                Expect.all
                    [ -- Only the first movement should have taken effect
                      \m -> Expect.equal { row = 1, col = 2 } m.robot.position
                    , \m -> Expect.equal North m.robot.facing
                    , \m -> Expect.equal Idle m.animationState
                    ]
                    afterComplete
        , test "alternating movement and rotation keys" <|
            \_ ->
                let
                    initialModel =
                        createModelWithState
                            { position = { row = 2, col = 2 }
                            , facing = North
                            , animationState = Idle
                            }

                    -- Move forward
                    ( afterMove1, _ ) =
                        update (KeyPressed "ArrowUp") initialModel

                    ( afterMoveComplete1, _ ) =
                        update AnimationComplete afterMove1

                    -- Rotate right
                    ( afterRotate1, _ ) =
                        update (KeyPressed "ArrowRight") afterMoveComplete1

                    ( afterRotateComplete1, _ ) =
                        update AnimationComplete afterRotate1

                    -- Move forward again
                    ( afterMove2, _ ) =
                        update (KeyPressed "ArrowUp") afterRotateComplete1

                    ( finalModel, _ ) =
                        update AnimationComplete afterMove2
                in
                Expect.all
                    [ \m -> Expect.equal { row = 1, col = 3 } m.robot.position
                    , \m -> Expect.equal East m.robot.facing
                    , \m -> Expect.equal Idle m.animationState
                    ]
                    finalModel
        ]


keyboardInputEdgeCasesTests : Test
keyboardInputEdgeCasesTests =
    describe "Keyboard Input Edge Cases"
        [ test "case sensitivity - keys are case sensitive" <|
            \_ ->
                let
                    initialModel =
                        createModelWithState
                            { position = { row = 2, col = 2 }
                            , facing = North
                            , animationState = Idle
                            }

                    -- Test lowercase arrow keys (should be ignored)
                    testCases =
                        [ "arrowup"
                        , "arrowdown"
                        , "arrowleft"
                        , "arrowright"
                        , "ARROWUP"
                        , "ARROWDOWN"
                        , "ARROWLEFT"
                        , "ARROWRIGHT"
                        ]

                    testCase key =
                        let
                            ( updatedModel, _ ) =
                                update (KeyPressed key) initialModel
                        in
                        Expect.equal initialModel updatedModel
                in
                testCases
                    |> List.map testCase
                    |> List.all (\result -> result == Expect.pass)
                    |> Expect.equal True
        , test "empty string and special characters are ignored" <|
            \_ ->
                let
                    initialModel =
                        createModelWithState
                            { position = { row = 2, col = 2 }
                            , facing = North
                            , animationState = Idle
                            }

                    specialKeys =
                        [ "", " ", "\n", "\t", "\u{000D}", "\\", "/", "?", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "-", "_", "=", "+", "[", "]", "{", "}", "|", ";", ":", "'", "\"", ",", ".", "<", ">", "`", "~" ]

                    testSpecialKey key =
                        let
                            ( updatedModel, _ ) =
                                update (KeyPressed key) initialModel
                        in
                        Expect.equal initialModel updatedModel
                in
                specialKeys
                    |> List.map testSpecialKey
                    |> List.all (\result -> result == Expect.pass)
                    |> Expect.equal True
        ]


keyboardInputSequenceTests : Test
keyboardInputSequenceTests =
    describe "Keyboard Input Sequences"
        [ test "complex navigation sequence using only keyboard" <|
            \_ ->
                let
                    initialModel =
                        createModelWithState
                            { position = { row = 2, col = 2 }
                            , facing = North
                            , animationState = Idle
                            }

                    -- Navigate to top-right corner using keyboard
                    -- Move North twice
                    ( afterUp1, _ ) =
                        update (KeyPressed "ArrowUp") initialModel

                    ( afterUp1Complete, _ ) =
                        update AnimationComplete afterUp1

                    ( afterUp2, _ ) =
                        update (KeyPressed "ArrowUp") afterUp1Complete

                    ( afterUp2Complete, _ ) =
                        update AnimationComplete afterUp2

                    -- Rotate to face East
                    ( afterRight, _ ) =
                        update (KeyPressed "ArrowRight") afterUp2Complete

                    ( afterRightComplete, _ ) =
                        update AnimationComplete afterRight

                    -- Move East twice
                    ( afterEast1, _ ) =
                        update (KeyPressed "ArrowUp") afterRightComplete

                    ( afterEast1Complete, _ ) =
                        update AnimationComplete afterEast1

                    ( afterEast2, _ ) =
                        update (KeyPressed "ArrowUp") afterEast1Complete

                    ( finalModel, _ ) =
                        update AnimationComplete afterEast2
                in
                Expect.all
                    [ \m -> Expect.equal { row = 0, col = 4 } m.robot.position
                    , \m -> Expect.equal East m.robot.facing
                    , \m -> Expect.equal Idle m.animationState
                    ]
                    finalModel
        , test "full rotation cycle using keyboard" <|
            \_ ->
                let
                    initialModel =
                        createModelWithState
                            { position = { row = 2, col = 2 }
                            , facing = North
                            , animationState = Idle
                            }

                    -- Perform full rotation using left arrow
                    ( afterLeft1, _ ) =
                        update (KeyPressed "ArrowLeft") initialModel

                    ( afterLeft1Complete, _ ) =
                        update AnimationComplete afterLeft1

                    ( afterLeft2, _ ) =
                        update (KeyPressed "ArrowLeft") afterLeft1Complete

                    ( afterLeft2Complete, _ ) =
                        update AnimationComplete afterLeft2

                    ( afterLeft3, _ ) =
                        update (KeyPressed "ArrowLeft") afterLeft2Complete

                    ( afterLeft3Complete, _ ) =
                        update AnimationComplete afterLeft3

                    ( afterLeft4, _ ) =
                        update (KeyPressed "ArrowLeft") afterLeft3Complete

                    ( finalModel, _ ) =
                        update AnimationComplete afterLeft4
                in
                Expect.all
                    [ \m -> Expect.equal { row = 2, col = 2 } m.robot.position
                    , \m -> Expect.equal North m.robot.facing
                    , \m -> Expect.equal Idle m.animationState
                    ]
                    finalModel
        , test "opposite direction navigation using ArrowDown" <|
            \_ ->
                let
                    initialModel =
                        createModelWithState
                            { position = { row = 2, col = 2 }
                            , facing = North
                            , animationState = Idle
                            }

                    -- Use ArrowDown to face South, then move
                    ( afterDown, _ ) =
                        update (KeyPressed "ArrowDown") initialModel

                    ( afterDownComplete, _ ) =
                        update AnimationComplete afterDown

                    ( afterMove, _ ) =
                        update (KeyPressed "ArrowUp") afterDownComplete

                    ( finalModel, _ ) =
                        update AnimationComplete afterMove
                in
                Expect.all
                    [ \m -> Expect.equal { row = 3, col = 2 } m.robot.position
                    , \m -> Expect.equal South m.robot.facing
                    , \m -> Expect.equal Idle m.animationState
                    ]
                    finalModel
        ]

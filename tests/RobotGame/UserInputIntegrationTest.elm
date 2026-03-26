module RobotGame.UserInputIntegrationTest exposing (suite)

{-| User-input integration tests for the Robot Grid Game.

These tests exercise actual button clicks, keyboard input, mixed workflows,
and accessibility feedback using elm-program-test.

-}

import Expect
import Html.Attributes
import ProgramTest exposing (ProgramTest, SimulatedEffect)
import RobotGame.Main exposing (Effect(..), Msg(..), initToEffect, updateToEffect)
import RobotGame.Model exposing (Direction(..), Model)
import RobotGame.View exposing (view)
import SimulatedEffect.Cmd as SimCmd
import SimulatedEffect.Process exposing (sleep)
import SimulatedEffect.Task exposing (perform)
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import TestUtils.ProgramTestHelpers
    exposing
        ( clickButtonByClass
        , expectButtonAriaLabel
        , expectButtonAriaPressed
        , expectButtonAriaKeyShortcut
        , expectButtonHighlighted
        , expectButtonNotHighlighted
        , expectNoHighlightedButtons
        )
import Time


suite : Test
suite =
    describe "RobotGame User Input Integration"
        [ buttonClickWorkflowTests
        , keyboardInputWorkflowTests
        , mixedInputWorkflowTests
        , accessibilityAndFeedbackTests
        , journeyTests
        ]


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
            SimCmd.none

        Sleep interval ->
            sleep interval
                |> perform (\_ -> AnimationComplete)


advanceAndComplete : Int -> ProgramTest Model Msg Effect -> ProgramTest Model Msg Effect
advanceAndComplete duration programTest =
    programTest
        |> ProgramTest.advanceTime duration
        |> ProgramTest.update AnimationComplete


advanceHighlightWindow : ProgramTest Model Msg Effect -> ProgramTest Model Msg Effect
advanceHighlightWindow programTest =
    programTest
        |> ProgramTest.advanceTime 160
        |> ProgramTest.update (AnimationFrame (Time.millisToPosix 160))


expectRobotPosition : { row : Int, col : Int } -> ProgramTest Model msg effect -> Expect.Expectation
expectRobotPosition expectedPosition programTest =
    programTest
        |> ProgramTest.expectView
            (Query.find [ Selector.class "robot" ]
                >> Query.has
                    [ Selector.attribute
                        (Html.Attributes.attribute "data-position"
                            (String.fromInt expectedPosition.row ++ "," ++ String.fromInt expectedPosition.col)
                        )
                    ]
            )


expectRobotFacing : Direction -> ProgramTest Model msg effect -> Expect.Expectation
expectRobotFacing direction programTest =
    let
        facingClass =
            "facing-"
                ++ String.toLower
                    (case direction of
                        North ->
                            "North"

                        South ->
                            "South"

                        East ->
                            "East"

                        West ->
                            "West"
                    )
    in
    programTest
        |> ProgramTest.expectView
            (Query.find [ Selector.class "robot" ]
                >> Query.has [ Selector.class facingClass ]
            )


expectRobotAriaLabel : String -> ProgramTest Model msg effect -> Expect.Expectation
expectRobotAriaLabel expectedLabel programTest =
    programTest
        |> ProgramTest.expectView
            (Query.find [ Selector.class "robot" ]
                >> Query.has [ Selector.attribute (Html.Attributes.attribute "aria-label" expectedLabel) ]
            )


expectGameStatusContains : String -> ProgramTest Model msg effect -> Expect.Expectation
expectGameStatusContains expectedText programTest =
    programTest
        |> ProgramTest.expectView
            (Query.find [ Selector.class "game-status" ]
                >> Query.has [ Selector.containing [ Selector.text expectedText ] ]
            )


clickForwardButton : ProgramTest Model Msg Effect -> ProgramTest Model Msg Effect
clickForwardButton =
    clickButtonByClass "forward-button"


clickRotateLeftButton : ProgramTest Model Msg Effect -> ProgramTest Model Msg Effect
clickRotateLeftButton =
    clickButtonByClass "rotate-left-button"


clickRotateRightButton : ProgramTest Model Msg Effect -> ProgramTest Model Msg Effect
clickRotateRightButton =
    clickButtonByClass "rotate-right-button"


clickDirectionButton : Direction -> ProgramTest Model Msg Effect -> ProgramTest Model Msg Effect
clickDirectionButton direction =
    case direction of
        North ->
            clickButtonByClass "direction-north-button"

        South ->
            clickButtonByClass "direction-south-button"

        East ->
            clickButtonByClass "direction-east-button"

        West ->
            clickButtonByClass "direction-west-button"


buttonClickWorkflowTests : Test
buttonClickWorkflowTests =
    describe "Button Click Workflow"
        [ test "forward button click highlights the control and completes the move" <|
            \() ->
                let
                    afterClick =
                        startRobotGame ()
                            |> clickForwardButton

                    afterHighlightWindow =
                        afterClick
                            |> advanceHighlightWindow

                    afterComplete =
                        afterClick
                            |> advanceAndComplete 300
                in
                Expect.all
                    [ \_ -> expectButtonHighlighted "forward-button" afterClick
                    , \_ -> expectGameStatusContains "Moving forward." afterClick
                    , \_ -> expectRobotAriaLabel "Robot facing North, currently moving" afterClick
                    , \_ -> expectButtonNotHighlighted "forward-button" afterHighlightWindow
                    , \_ -> expectRobotPosition { row = 1, col = 2 } afterComplete
                    , \_ -> expectRobotFacing North afterComplete
                    ]
                    ()
        , test "rotate left button click updates facing and pressed state" <|
            \() ->
                let
                    afterClick =
                        startRobotGame ()
                            |> clickRotateLeftButton

                    afterComplete =
                        afterClick
                            |> advanceAndComplete 200
                in
                Expect.all
                    [ \_ -> expectButtonHighlighted "rotate-left-button" afterClick
                    , \_ -> expectButtonHighlighted "direction-north-button" afterClick
                    , \_ -> expectButtonHighlighted "direction-west-button" afterClick
                    , \_ -> expectRobotFacing West afterComplete
                    , \_ -> expectButtonAriaPressed "direction-west-button" True afterComplete
                    , \_ -> expectButtonAriaLabel "direction-west-button" "Robot is currently facing West" afterComplete
                    ]
                    ()
        , test "direction button click rotates to the selected facing" <|
            \() ->
                let
                    afterClick =
                        startRobotGame ()
                            |> clickDirectionButton East

                    afterComplete =
                        afterClick
                            |> advanceAndComplete 200
                in
                Expect.all
                    [ \_ -> expectButtonHighlighted "direction-north-button" afterClick
                    , \_ -> expectButtonHighlighted "direction-east-button" afterClick
                    , \_ -> expectRobotFacing East afterComplete
                    , \_ -> expectButtonAriaPressed "direction-east-button" True afterComplete
                    ]
                    ()
        ]


keyboardInputWorkflowTests : Test
keyboardInputWorkflowTests =
    describe "Keyboard Input Workflow"
        [ test "ArrowUp behaves the same as clicking forward" <|
            \() ->
                let
                    buttonWorkflow =
                        startRobotGame ()
                            |> clickForwardButton

                    keyboardWorkflow =
                        startRobotGame ()
                            |> ProgramTest.update (KeyPressed "ArrowUp")
                in
                Expect.all
                    [ \_ -> expectButtonHighlighted "forward-button" buttonWorkflow
                    , \_ -> expectButtonHighlighted "forward-button" keyboardWorkflow
                    , \_ -> expectGameStatusContains "Moving forward." buttonWorkflow
                    , \_ -> expectGameStatusContains "Moving forward." keyboardWorkflow
                    ]
                    ()
        , test "invalid keys are ignored without changing button highlight state" <|
            \() ->
                startRobotGame ()
                    |> ProgramTest.update (KeyPressed "Space")
                    |> (\programTest ->
                            Expect.all
                                [ expectNoHighlightedButtons
                                , expectRobotPosition { row = 2, col = 2 }
                                , expectRobotFacing North
                                ]
                                programTest
                       )
        , test "rapid keyboard input during animation keeps the first action only" <|
            \() ->
                let
                    afterSequence =
                        startRobotGame ()
                            |> ProgramTest.update (KeyPressed "ArrowUp")
                            |> ProgramTest.update (KeyPressed "ArrowLeft")
                in
                Expect.all
                    [ \_ -> expectRobotPosition { row = 1, col = 2 } afterSequence
                    , \_ -> expectRobotFacing North afterSequence
                    , \_ -> expectButtonHighlighted "forward-button" afterSequence
                    , \_ -> expectButtonNotHighlighted "rotate-left-button" afterSequence
                    ]
                    ()
        ]


mixedInputWorkflowTests : Test
mixedInputWorkflowTests =
    describe "Mixed Input Workflow"
        [ test "button and keyboard inputs can be mixed across a complete journey" <|
            \() ->
                startRobotGame ()
                    |> clickForwardButton
                    |> advanceAndComplete 300
                    |> ProgramTest.update (KeyPressed "ArrowRight")
                    |> advanceAndComplete 200
                    |> clickDirectionButton South
                    |> advanceAndComplete 200
                    |> (\programTest ->
                            Expect.all
                                [ expectRobotPosition { row = 1, col = 2 }
                                , expectRobotFacing South
                                , expectNoHighlightedButtons
                                ]
                                programTest
                       )
        , test "keyboard and button rotation produce the same final state" <|
            \() ->
                let
                    keyboardWorkflow =
                        startRobotGame ()
                            |> ProgramTest.update (KeyPressed "ArrowRight")
                            |> advanceAndComplete 200

                    buttonWorkflow =
                        startRobotGame ()
                            |> clickRotateRightButton
                            |> advanceAndComplete 200
                in
                Expect.all
                    [ \_ -> expectRobotFacing East keyboardWorkflow
                    , \_ -> expectRobotFacing East buttonWorkflow
                    , \_ -> expectButtonAriaPressed "direction-east-button" True keyboardWorkflow
                    , \_ -> expectButtonAriaPressed "direction-east-button" True buttonWorkflow
                    ]
                    ()
        ]


accessibilityAndFeedbackTests : Test
accessibilityAndFeedbackTests =
    describe "Accessibility and Feedback"
        [ test "initial controls expose ARIA labels and shortcuts" <|
            \() ->
                startRobotGame ()
                    |> (\programTest ->
                            Expect.all
                                [ expectButtonAriaLabel "forward-button" "Move robot forward (Arrow Up key)"
                                , expectButtonAriaLabel "rotate-left-button" "Rotate robot left (Left Arrow key)"
                                , expectButtonAriaLabel "rotate-right-button" "Rotate robot right (Right Arrow key)"
                                , expectButtonAriaKeyShortcut "forward-button" "ArrowUp"
                                , expectButtonAriaKeyShortcut "rotate-left-button" "ArrowLeft"
                                , expectButtonAriaKeyShortcut "rotate-right-button" "ArrowRight"
                                , expectButtonAriaPressed "direction-north-button" True
                                , expectGameStatusContains "Ready for commands."
                                ]
                                programTest
                       )
        , test "blocked movement updates the live region and boundary label" <|
            \() ->
                startRobotGame ()
                    |> clickForwardButton
                    |> advanceAndComplete 300
                    |> clickForwardButton
                    |> advanceAndComplete 300
                    |> clickForwardButton
                    |> (\programTest ->
                            Expect.all
                                [ expectButtonAriaLabel "forward-button" "Cannot move forward - robot is at boundary"
                                , expectGameStatusContains "Movement blocked by boundary."
                                , expectRobotFacing North
                                ]
                                programTest
                       )
        , test "current direction button is announced as pressed after rotation" <|
            \() ->
                startRobotGame ()
                    |> clickRotateRightButton
                    |> advanceAndComplete 200
                    |> (\programTest ->
                            Expect.all
                                [ expectButtonAriaPressed "direction-east-button" True
                                , expectButtonAriaLabel "direction-east-button" "Robot is currently facing East"
                                ]
                                programTest
                       )
        ]


journeyTests : Test
journeyTests =
    describe "Complete User Journeys"
        [ test "button and keyboard controls can reach the upper-right corner" <|
            \() ->
                startRobotGame ()
                    |> clickForwardButton
                    |> advanceAndComplete 300
                    |> ProgramTest.update (KeyPressed "ArrowRight")
                    |> advanceAndComplete 200
                    |> clickForwardButton
                    |> advanceAndComplete 300
                    |> (\programTest ->
                            Expect.all
                                [ expectRobotPosition { row = 1, col = 3 }
                                , expectRobotFacing East
                                , expectNoHighlightedButtons
                                ]
                                programTest
                       )
        , test "blocked boundary attempt does not break subsequent navigation" <|
            \() ->
                startRobotGame ()
                    |> clickForwardButton
                    |> advanceAndComplete 300
                    |> clickForwardButton
                    |> advanceAndComplete 300
                    |> clickForwardButton
                    |> advanceAndComplete 200
                    |> clickRotateRightButton
                    |> advanceAndComplete 200
                    |> clickForwardButton
                    |> advanceAndComplete 300
                    |> (\programTest ->
                            Expect.all
                                [ expectRobotPosition { row = 0, col = 3 }
                                , expectRobotFacing East
                                , expectNoHighlightedButtons
                                ]
                                programTest
                       )
        ]

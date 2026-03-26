module RobotGame.SelectiveHighlightingIntegrationTest exposing (suite)

{-| Integration tests for selective button highlighting in the Robot Grid Game.

These tests focus specifically on the DOM-visible highlight state so they can
complement the existing unit coverage with user-observable behavior.

-}

import Expect
import ProgramTest exposing (ProgramTest, SimulatedEffect)
import RobotGame.Main exposing (Effect(..), Msg(..), initToEffect, updateToEffect)
import RobotGame.Model exposing (Direction(..), Model)
import RobotGame.View exposing (view)
import SimulatedEffect.Cmd as SimCmd
import SimulatedEffect.Process exposing (sleep)
import SimulatedEffect.Task exposing (perform)
import Test exposing (Test, describe, test)
import TestUtils.ProgramTestHelpers
    exposing
        ( clickButtonByClass
        , expectButtonHighlighted
        , expectButtonNotHighlighted
        , expectNoHighlightedButtons
        )
import Time


suite : Test
suite =
    describe "RobotGame Selective Highlighting Integration"
        [ forwardHighlightTests
        , rotationHighlightTests
        , directionHighlightTests
        , keyboardConsistencyTests
        , highlightTimingTests
        , rapidInputHighlightTests
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


forwardHighlightTests : Test
forwardHighlightTests =
    describe "Forward Highlighting"
        [ test "forward click highlights only the forward button" <|
            \() ->
                let
                    afterClick =
                        startRobotGame ()
                            |> clickForwardButton
                in
                Expect.all
                    [ \_ -> expectButtonHighlighted "forward-button" afterClick
                    , \_ -> expectButtonNotHighlighted "rotate-left-button" afterClick
                    , \_ -> expectButtonNotHighlighted "rotate-right-button" afterClick
                    , \_ -> expectButtonNotHighlighted "direction-north-button" afterClick
                    , \_ -> expectButtonNotHighlighted "direction-east-button" afterClick
                    , \_ -> expectButtonNotHighlighted "direction-south-button" afterClick
                    , \_ -> expectButtonNotHighlighted "direction-west-button" afterClick
                    ]
                    ()
        , test "forward highlight clears after the timing window" <|
            \() ->
                startRobotGame ()
                    |> clickForwardButton
                    |> advanceHighlightWindow
                    |> expectNoHighlightedButtons
        ]


rotationHighlightTests : Test
rotationHighlightTests =
    describe "Rotation Highlighting"
        [ test "rotate left click highlights the rotation source and target directions" <|
            \() ->
                let
                    afterClick =
                        startRobotGame ()
                            |> clickRotateLeftButton
                in
                Expect.all
                    [ \_ -> expectButtonHighlighted "rotate-left-button" afterClick
                    , \_ -> expectButtonHighlighted "direction-north-button" afterClick
                    , \_ -> expectButtonHighlighted "direction-west-button" afterClick
                    , \_ -> expectButtonNotHighlighted "forward-button" afterClick
                    , \_ -> expectButtonNotHighlighted "rotate-right-button" afterClick
                    ]
                    ()
        , test "rotate right click highlights the rotation source and target directions" <|
            \() ->
                let
                    afterClick =
                        startRobotGame ()
                            |> clickRotateRightButton
                in
                Expect.all
                    [ \_ -> expectButtonHighlighted "rotate-right-button" afterClick
                    , \_ -> expectButtonHighlighted "direction-north-button" afterClick
                    , \_ -> expectButtonHighlighted "direction-east-button" afterClick
                    , \_ -> expectButtonNotHighlighted "forward-button" afterClick
                    , \_ -> expectButtonNotHighlighted "rotate-left-button" afterClick
                    ]
                    ()
        ]


directionHighlightTests : Test
directionHighlightTests =
    describe "Directional Highlighting"
        [ test "direction click highlights only source and target direction buttons" <|
            \() ->
                let
                    afterClick =
                        startRobotGame ()
                            |> clickDirectionButton East
                in
                Expect.all
                    [ \_ -> expectButtonHighlighted "direction-north-button" afterClick
                    , \_ -> expectButtonHighlighted "direction-east-button" afterClick
                    , \_ -> expectButtonNotHighlighted "forward-button" afterClick
                    , \_ -> expectButtonNotHighlighted "rotate-left-button" afterClick
                    , \_ -> expectButtonNotHighlighted "rotate-right-button" afterClick
                    , \_ -> expectButtonNotHighlighted "direction-south-button" afterClick
                    , \_ -> expectButtonNotHighlighted "direction-west-button" afterClick
                    ]
                    ()
        , test "same-direction selection keeps the highlight set empty" <|
            \() ->
                startRobotGame ()
                    |> ProgramTest.update (RotateToDirection North)
                    |> expectNoHighlightedButtons
        ]


keyboardConsistencyTests : Test
keyboardConsistencyTests =
    describe "Keyboard Highlight Consistency"
        [ test "ArrowUp highlights the same button as the forward click" <|
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
                    ]
                    ()
        , test "ArrowLeft highlights the same buttons as rotate-left click" <|
            \() ->
                let
                    buttonWorkflow =
                        startRobotGame ()
                            |> clickRotateLeftButton

                    keyboardWorkflow =
                        startRobotGame ()
                            |> ProgramTest.update (KeyPressed "ArrowLeft")
                in
                Expect.all
                    [ \_ -> expectButtonHighlighted "rotate-left-button" buttonWorkflow
                    , \_ -> expectButtonHighlighted "rotate-left-button" keyboardWorkflow
                    , \_ -> expectButtonHighlighted "direction-north-button" keyboardWorkflow
                    , \_ -> expectButtonHighlighted "direction-west-button" keyboardWorkflow
                    ]
                    ()
        ]


highlightTimingTests : Test
highlightTimingTests =
    describe "Highlight Timing"
        [ test "highlight disappears before animation completes" <|
            \() ->
                let
                    afterClick =
                        startRobotGame ()
                            |> clickForwardButton

                    afterShortDelay =
                        afterClick
                            |> advanceHighlightWindow
                in
                Expect.all
                    [ \_ -> expectButtonNotHighlighted "forward-button" afterShortDelay
                    , \_ -> expectButtonNotHighlighted "rotate-left-button" afterShortDelay
                    ]
                    ()
        , test "highlight is cleared after completion cleanup" <|
            \() ->
                startRobotGame ()
                    |> clickForwardButton
                    |> advanceAndComplete 300
                    |> expectNoHighlightedButtons
        ]


rapidInputHighlightTests : Test
rapidInputHighlightTests =
    describe "Rapid Input Highlight State"
        [ test "a second action during animation does not replace the first highlight" <|
            \() ->
                let
                    afterSequence =
                        startRobotGame ()
                            |> clickForwardButton
                            |> ProgramTest.update RotateLeft
                in
                Expect.all
                    [ \_ -> expectButtonHighlighted "forward-button" afterSequence
                    , \_ -> expectButtonNotHighlighted "rotate-left-button" afterSequence
                    , \_ -> expectButtonNotHighlighted "rotate-right-button" afterSequence
                    ]
                    ()
        , test "blocked movement keeps the forward highlight only" <|
            \() ->
                let
                    afterBlockedClick =
                        startRobotGame ()
                            |> clickForwardButton
                            |> advanceAndComplete 300
                            |> clickForwardButton
                            |> advanceAndComplete 300
                            |> clickForwardButton
                in
                Expect.all
                    [ \_ -> expectButtonHighlighted "forward-button" afterBlockedClick
                    , \_ -> expectButtonNotHighlighted "rotate-left-button" afterBlockedClick
                    , \_ -> expectButtonNotHighlighted "rotate-right-button" afterBlockedClick
                    ]
                    ()
        ]

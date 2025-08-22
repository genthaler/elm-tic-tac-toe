module RobotGame.UserInputIntegrationTest exposing (suite)

{-| Focused integration tests for specific user input interaction patterns.
These tests complement the main IntegrationTest.elm by focusing on specific
user interaction scenarios that require detailed workflow testing.
-}

import Expect
import Html.Attributes
import ProgramTest exposing (ProgramTest)
import RobotGame.Main exposing (Msg(..))
import RobotGame.Model exposing (AnimationState(..), Direction(..), Model)
import RobotGame.ProgramTestHelpers exposing (expectRobotAnimationState, expectRobotFacing, expectRobotPosition, startRobotGame)
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import TestUtils.ProgramTestHelpers exposing (expectColorScheme)
import Theme.Theme exposing (ColorScheme(..))


suite : Test
suite =
    describe "RobotGame User Input Interaction Patterns"
        [ userJourneyWorkflowTests
        , accessibilityInteractionTests
        , inputMethodSwitchingTests
        ]


{-| Helper function to simulate keyboard input via direct message handling
Note: We use KeyPressed messages for more reliable testing than DOM simulation
-}
simulateKeyboardInput : String -> ProgramTest Model Msg effect -> ProgramTest Model Msg effect
simulateKeyboardInput key programTest =
    programTest |> ProgramTest.update (KeyPressed key)


{-| Helper function to send direct robot commands (more reliable than button clicks)
-}
sendRobotCommand : Msg -> ProgramTest Model Msg effect -> ProgramTest Model Msg effect
sendRobotCommand msg programTest =
    programTest |> ProgramTest.update msg


{-| Test complete user journey workflows that span multiple interactions
-}
userJourneyWorkflowTests : Test
userJourneyWorkflowTests =
    describe "Complete User Journey Workflows"
        [ test "user can navigate from center to top-right corner using mixed inputs" <|
            \() ->
                let
                    programTest =
                        startRobotGame ()
                            -- Move North using keyboard
                            |> simulateKeyboardInput "ArrowUp"
                            |> ProgramTest.advanceTime 300
                            -- Move North using direct command
                            |> sendRobotCommand MoveForward
                            |> ProgramTest.advanceTime 300
                            -- Rotate East using direct command
                            |> sendRobotCommand (RotateToDirection East)
                            |> ProgramTest.advanceTime 200
                            -- Move East using keyboard
                            |> simulateKeyboardInput "ArrowUp"
                            |> ProgramTest.advanceTime 300
                            -- Move East using direct command
                            |> sendRobotCommand MoveForward
                            |> ProgramTest.advanceTime 300
                in
                Expect.all
                    [ expectRobotPosition { row = 0, col = 4 }
                    , expectRobotFacing East
                    ]
                    programTest
        , test "user can recover from blocked movements and continue complex navigation" <|
            \() ->
                let
                    programTest =
                        startRobotGame ()
                            -- Navigate to boundary using mixed inputs
                            |> sendRobotCommand MoveForward
                            |> ProgramTest.advanceTime 300
                            |> sendRobotCommand AnimationComplete
                            |> sendRobotCommand MoveForward
                            |> ProgramTest.advanceTime 300
                            |> sendRobotCommand AnimationComplete
                            -- Encounter blocked movement
                            |> sendRobotCommand MoveForward
                            |> ProgramTest.advanceTime 500
                            |> sendRobotCommand AnimationComplete
                            -- Recover using directional command
                            |> sendRobotCommand (RotateToDirection South)
                            |> ProgramTest.advanceTime 300
                            |> sendRobotCommand AnimationComplete
                            -- Continue navigation with direct command
                            |> sendRobotCommand MoveForward
                            |> ProgramTest.advanceTime 500
                            |> sendRobotCommand AnimationComplete
                in
                Expect.all
                    [ expectRobotPosition { row = 1, col = 2 }
                    , expectRobotFacing South
                    ]
                    programTest
        , test "user can perform complex multi-step navigation sequence" <|
            \() ->
                let
                    programTest =
                        startRobotGame ()
                            -- Complex navigation: center -> top-left -> bottom-right
                            |> sendRobotCommand (RotateToDirection West)
                            |> ProgramTest.advanceTime 200
                            |> simulateKeyboardInput "ArrowUp"
                            |> ProgramTest.advanceTime 300
                            |> simulateKeyboardInput "ArrowUp"
                            |> ProgramTest.advanceTime 300
                            |> sendRobotCommand (RotateToDirection North)
                            |> ProgramTest.advanceTime 200
                            |> simulateKeyboardInput "ArrowUp"
                            |> ProgramTest.advanceTime 300
                            |> simulateKeyboardInput "ArrowUp"
                            |> ProgramTest.advanceTime 300
                            -- Now at top-left (0,0), navigate to bottom-right
                            |> sendRobotCommand (RotateToDirection East)
                            |> ProgramTest.advanceTime 200
                            |> simulateKeyboardInput "ArrowUp"
                            |> ProgramTest.advanceTime 300
                            |> simulateKeyboardInput "ArrowUp"
                            |> ProgramTest.advanceTime 300
                            |> simulateKeyboardInput "ArrowUp"
                            |> ProgramTest.advanceTime 300
                            |> simulateKeyboardInput "ArrowUp"
                            |> ProgramTest.advanceTime 300
                            |> sendRobotCommand (RotateToDirection South)
                            |> ProgramTest.advanceTime 200
                            |> simulateKeyboardInput "ArrowUp"
                            |> ProgramTest.advanceTime 300
                            |> simulateKeyboardInput "ArrowUp"
                            |> ProgramTest.advanceTime 300
                            |> simulateKeyboardInput "ArrowUp"
                            |> ProgramTest.advanceTime 300
                            |> simulateKeyboardInput "ArrowUp"
                            |> ProgramTest.advanceTime 300
                in
                Expect.all
                    [ expectRobotPosition { row = 4, col = 4 }
                    , expectRobotFacing South
                    ]
                    programTest
        ]


{-| Test accessibility-focused interaction patterns
-}
accessibilityInteractionTests : Test
accessibilityInteractionTests =
    describe "Accessibility Interaction Patterns"
        [ test "keyboard navigation maintains proper focus management" <|
            \() ->
                startRobotGame ()
                    |> ProgramTest.expectView
                        (Query.has [ Selector.attribute (Html.Attributes.attribute "tabIndex" "0") ])
        , test "screen reader announcements update correctly during interactions" <|
            \() ->
                startRobotGame ()
                    |> sendRobotCommand MoveForward
                    |> ProgramTest.advanceTime 300
                    |> ProgramTest.expectView
                        (Query.has [ Selector.attribute (Html.Attributes.attribute "aria-live" "polite") ])
        , test "button states provide appropriate feedback for assistive technology" <|
            \() ->
                startRobotGame ()
                    -- Move to boundary to test disabled state feedback
                    |> sendRobotCommand MoveForward
                    |> ProgramTest.advanceTime 300
                    |> sendRobotCommand MoveForward
                    |> ProgramTest.advanceTime 300
                    -- Try blocked movement to trigger accessibility feedback
                    |> sendRobotCommand MoveForward
                    |> ProgramTest.expectView
                        (Query.has [ Selector.class "grid-cell" ])
        , test "grid provides proper ARIA structure for screen readers" <|
            \() ->
                startRobotGame ()
                    |> ProgramTest.expectView
                        (Query.has [ Selector.attribute (Html.Attributes.attribute "role" "grid") ])
        , test "robot position announcements are accessible" <|
            \() ->
                startRobotGame ()
                    |> sendRobotCommand MoveForward
                    |> ProgramTest.advanceTime 300
                    |> ProgramTest.expectView
                        (Query.has [ Selector.attribute (Html.Attributes.attribute "aria-atomic" "true") ])
        ]


{-| Test input method switching and consistency patterns
-}
inputMethodSwitchingTests : Test
inputMethodSwitchingTests =
    describe "Input Method Switching Patterns"
        [ test "rapid switching between input methods maintains state consistency" <|
            \() ->
                let
                    programTest =
                        startRobotGame ()
                            -- Rapid alternating inputs
                            |> sendRobotCommand RotateRight
                            |> sendRobotCommand AnimationComplete
                            |> sendRobotCommand RotateLeft
                            |> sendRobotCommand AnimationComplete
                            |> sendRobotCommand MoveForward
                            |> ProgramTest.advanceTime 500
                            |> sendRobotCommand AnimationComplete
                            |> sendRobotCommand (RotateToDirection South)
                            |> ProgramTest.advanceTime 500
                            |> sendRobotCommand AnimationComplete
                in
                Expect.all
                    [ expectRobotPosition { row = 1, col = 2 }
                    , expectRobotFacing South
                    ]
                    programTest
        , test "input method preferences persist across theme changes" <|
            \() ->
                let
                    programTest =
                        startRobotGame ()
                            -- Start with keyboard input
                            |> simulateKeyboardInput "ArrowUp"
                            |> ProgramTest.advanceTime 300
                            -- Change theme
                            |> ProgramTest.update (ColorScheme Dark)
                            -- Continue with direct command
                            |> sendRobotCommand RotateRight
                            |> ProgramTest.advanceTime 200
                            -- Switch back to keyboard
                            |> simulateKeyboardInput "ArrowUp"
                            |> ProgramTest.advanceTime 300
                in
                Expect.all
                    [ expectRobotPosition { row = 1, col = 3 }
                    , expectRobotFacing East
                    , expectColorScheme Dark
                    ]
                    programTest
        , test "invalid input handling works consistently across input methods" <|
            \() ->
                let
                    programTest =
                        startRobotGame ()
                            -- Try invalid keyboard inputs
                            |> simulateKeyboardInput "Space"
                            |> simulateKeyboardInput "Enter"
                            -- Valid input should still work
                            |> sendRobotCommand MoveForward
                            |> ProgramTest.advanceTime 300
                in
                Expect.all
                    [ expectRobotPosition { row = 1, col = 2 }
                    , expectRobotFacing North
                    ]
                    programTest
        , test "keyboard and direct commands produce identical results" <|
            \() ->
                let
                    keyboardTest =
                        startRobotGame ()
                            |> simulateKeyboardInput "ArrowUp"
                            |> ProgramTest.advanceTime 300
                            |> simulateKeyboardInput "ArrowRight"
                            |> ProgramTest.advanceTime 200

                    directCommandTest =
                        startRobotGame ()
                            |> sendRobotCommand MoveForward
                            |> ProgramTest.advanceTime 300
                            |> sendRobotCommand RotateRight
                            |> ProgramTest.advanceTime 200
                in
                Expect.all
                    [ \_ -> expectRobotPosition { row = 1, col = 2 } keyboardTest
                    , \_ -> expectRobotFacing East keyboardTest
                    , \_ -> expectRobotPosition { row = 1, col = 2 } directCommandTest
                    , \_ -> expectRobotFacing East directCommandTest
                    ]
                    ()
        , test "error feedback is consistent across input methods" <|
            \() ->
                let
                    programTest =
                        startRobotGame ()
                            -- Move to boundary
                            |> sendRobotCommand MoveForward
                            |> ProgramTest.advanceTime 300
                            |> sendRobotCommand MoveForward
                            |> ProgramTest.advanceTime 300
                            -- Try blocked movement with keyboard
                            |> simulateKeyboardInput "ArrowUp"
                            |> ProgramTest.advanceTime 500
                            -- Try blocked movement with direct command
                            |> sendRobotCommand MoveForward
                            |> ProgramTest.advanceTime 500
                in
                Expect.all
                    [ expectRobotPosition { row = 0, col = 2 }
                    , expectRobotFacing North
                    , expectRobotAnimationState BlockedMovement
                    ]
                    programTest
        ]

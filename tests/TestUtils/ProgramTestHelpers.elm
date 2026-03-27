module TestUtils.ProgramTestHelpers exposing
    ( simulateClick
    , clickButtonByClass
    , clickButtonByText
    , expectTextPresent
    , expectColorScheme
    , clickCell
    , expectButtonHighlighted, expectButtonNotHighlighted, expectButtonAriaLabel, expectButtonAriaPressed, expectButtonAriaKeyShortcut, expectNoHighlightedButtons
    , clickButtonById
    )

{-| Test utilities for elm-program-test integration testing.

This module provides common setup functions and helpers for testing the
single-screen tic-tac-toe application with elm-program-test.


# Interaction Helpers

@docs simulateClick
@docs clickButtonByClass
@docs clickButtonByText
@docs expectTextPresent


# Assertion Helpers

@docs expectGameState

This module provides custom assertion functions for verifying game states,
UI element presence and content, and model state verification.


# UI Element Assertions

@docs expectUIElementVisible, expectUIElementHidden, expectUIElementText, expectUIElementAttribute


# Model State Assertions

@docs expectModelField, expectModelPredicate, expectColorScheme

This module provides utilities for simulating user interactions including
button clicks, keyboard input, touch events, and timing-related operations.


# Button and Click Interactions

@docs clickCell


# Keyboard Interactions

@docs pressKey, pressArrowKey


# Touch and Mobile Interactions


# Timing and Async Utilities

@docs waitForAnimation


# Element Verification Helpers

This module provides custom assertion functions for verifying game states,
UI element presence and content, and model state verification.


# TicTacToe Game Assertions

@docs expectTicTacToeGameState, expectTicTacToeBoard, expectTicTacToePlayer, expectTicTacToeWinner


# Robot Game Assertions

@docs expectRobotPosition, expectRobotFacing, expectRobotAnimationState


# UI Element Assertions


# Model State Assertions

@docs expectButtonHighlighted, expectButtonNotHighlighted, expectButtonAriaLabel, expectButtonAriaPressed, expectButtonAriaKeyShortcut, expectNoHighlightedButtons

@docs expectColorScheme

-}

import Expect exposing (Expectation)
import Html.Attributes
import Json.Encode
import ProgramTest exposing (ProgramTest)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Theme.Theme exposing (ColorScheme)


{-| Simulate a click on an element with the given test ID or selector
-}
simulateClick : String -> ProgramTest model msg effect -> ProgramTest model msg effect
simulateClick elementId programTest =
    programTest
        |> ProgramTest.clickButton elementId


{-| Simulate a click on a button selected by CSS class.
-}
clickButtonByClass : String -> ProgramTest model msg effect -> ProgramTest model msg effect
clickButtonByClass buttonClass programTest =
    programTest
        |> ProgramTest.simulateDomEvent
            (Query.find [ Selector.class buttonClass ])
            ( "click", Json.Encode.object [] )


{-| Simulate a click on a button selected by HTML id.
-}
clickButtonById : String -> ProgramTest model msg effect -> ProgramTest model msg effect
clickButtonById buttonId programTest =
    programTest
        |> ProgramTest.simulateDomEvent
            (Query.find [ Selector.id buttonId ])
            ( "click", Json.Encode.object [] )


{-| Simulate a click on a button selected by visible text.
-}
clickButtonByText : String -> ProgramTest model msg effect -> ProgramTest model msg effect
clickButtonByText buttonText programTest =
    programTest
        |> ProgramTest.simulateDomEvent
            (Query.find [ Selector.containing [ Selector.text buttonText ] ])
            ( "click", Json.Encode.object [] )


{-| Assert that the current view contains the given visible text.
-}
expectTextPresent : String -> ProgramTest model msg effect -> Expectation
expectTextPresent text programTest =
    programTest
        |> ProgramTest.expectView
            (Query.findAll [ Selector.containing [ Selector.text text ] ]
                >> Query.count (Expect.atLeast 1)
            )


{-| Click a specific cell in a grid (useful for tic-tac-toe)
Takes a record with row and column indices (0-based)
-}
clickCell : { row : Int, col : Int } -> ProgramTest model msg effect -> ProgramTest model msg effect
clickCell position programTest =
    let
        cellId =
            "cell-" ++ String.fromInt position.row ++ "-" ++ String.fromInt position.col
    in
    programTest
        |> ProgramTest.simulateDomEvent
            (Query.find [ Selector.attribute (Html.Attributes.attribute "aria-label" cellId) ])
            ( "click", Json.Encode.object [] )


{-| Assert that a button with the given class has the highlighted state.
-}
expectButtonHighlighted : String -> ProgramTest model msg effect -> Expectation
expectButtonHighlighted buttonClass programTest =
    programTest
        |> ProgramTest.expectView
            (Query.find [ Selector.class buttonClass ]
                >> Query.has [ Selector.class "highlighted" ]
            )


{-| Assert that a button with the given class does not have the highlighted state.
-}
expectButtonNotHighlighted : String -> ProgramTest model msg effect -> Expectation
expectButtonNotHighlighted buttonClass programTest =
    programTest
        |> ProgramTest.expectView
            (Query.find [ Selector.class buttonClass ]
                >> Query.hasNot [ Selector.class "highlighted" ]
            )


{-| Assert that a button has the expected aria-label.
-}
expectButtonAriaLabel : String -> String -> ProgramTest model msg effect -> Expectation
expectButtonAriaLabel buttonClass expectedAriaLabel programTest =
    programTest
        |> ProgramTest.expectView
            (Query.find [ Selector.class buttonClass ]
                >> Query.has [ Selector.attribute (Html.Attributes.attribute "aria-label" expectedAriaLabel) ]
            )


{-| Assert that a button has the expected aria-pressed state.
-}
expectButtonAriaPressed : String -> Bool -> ProgramTest model msg effect -> Expectation
expectButtonAriaPressed buttonClass isPressed programTest =
    programTest
        |> ProgramTest.expectView
            (Query.find [ Selector.class buttonClass ]
                >> Query.has
                    [ Selector.attribute
                        (Html.Attributes.attribute "aria-pressed"
                            (if isPressed then
                                "true"

                             else
                                "false"
                            )
                        )
                    ]
            )


{-| Assert that a button has the expected aria-keyshortcuts value.
-}
expectButtonAriaKeyShortcut : String -> String -> ProgramTest model msg effect -> Expectation
expectButtonAriaKeyShortcut buttonClass expectedShortcut programTest =
    programTest
        |> ProgramTest.expectView
            (Query.find [ Selector.class buttonClass ]
                >> Query.has [ Selector.attribute (Html.Attributes.attribute "aria-keyshortcuts" expectedShortcut) ]
            )


{-| Assert that there are no highlighted buttons in the current view.
-}
expectNoHighlightedButtons : ProgramTest model msg effect -> Expectation
expectNoHighlightedButtons programTest =
    programTest
        |> ProgramTest.expectView
            (Query.findAll [ Selector.class "highlighted" ]
                >> Query.count (Expect.equal 0)
            )


{-| Assert that the color scheme matches the expected value by checking the theme toggle button text.
-}
expectColorScheme : ColorScheme -> ProgramTest model msg effect -> Expectation
expectColorScheme expectedScheme programTest =
    let
        expectedToggleText =
            case expectedScheme of
                Theme.Theme.Light ->
                    "Dark"

                -- When in light mode, button shows "Dark" to switch to dark
                Theme.Theme.Dark ->
                    "Light"

        -- When in dark mode, button shows "Light" to switch to light
    in
    programTest
        |> ProgramTest.expectView
            (Query.find [ Selector.id "theme-toggle" ]
                >> Query.has [ Selector.containing [ Selector.text expectedToggleText ] ]
            )

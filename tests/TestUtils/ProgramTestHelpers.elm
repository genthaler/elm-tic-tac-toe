module TestUtils.ProgramTestHelpers exposing
    ( simulateClick
    , expectColorScheme
    , clickCell
    )

{-| Test utilities for elm-program-test integration testing.

This module provides common setup functions and helpers for testing the main
application components with elm-program-test.


# Interaction Helpers

@docs simulateClick


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


{-| Assert that the color scheme matches the expected value
Works with both TicTacToe and RobotGame models
-}
expectColorScheme : ColorScheme -> ProgramTest { model | colorScheme : ColorScheme } msg effect -> Expectation
expectColorScheme expectedScheme programTest =
    programTest
        |> ProgramTest.expectModel
            (\model ->
                Expect.equal expectedScheme model.colorScheme
            )

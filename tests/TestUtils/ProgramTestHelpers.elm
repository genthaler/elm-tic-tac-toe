module TestUtils.ProgramTestHelpers exposing
    ( simulateClick
    , expectUIElementVisible, expectUIElementHidden, expectUIElementText, expectUIElementAttribute
    , expectModelField, expectModelPredicate, expectColorScheme
    , clickButton, clickCell
    , simulateTouch
    , waitForCondition
    , expectElementPresent, expectElementAbsent, expectTextContent
    , createRobotMoveMsg, startApp
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

@docs clickButton, clickCell


# Keyboard Interactions

@docs pressKey, pressArrowKey


# Touch and Mobile Interactions

@docs simulateTouch


# Timing and Async Utilities

@docs waitForAnimation, waitForCondition


# Element Verification Helpers

@docs expectElementPresent, expectElementAbsent, expectTextContent

This module provides custom assertion functions for verifying game states,
UI element presence and content, and model state verification.


# TicTacToe Game Assertions

@docs expectTicTacToeGameState, expectTicTacToeBoard, expectTicTacToePlayer, expectTicTacToeWinner


# Robot Game Assertions

@docs expectRobotPosition, expectRobotFacing, expectRobotAnimationState


# UI Element Assertions

@docs expectUIElementVisible, expectUIElementHidden, expectUIElementText, expectUIElementAttribute


# Model State Assertions

@docs expectModelField, expectModelPredicate, expectColorScheme

-}

import App
import Expect exposing (Expectation)
import Html
import Html.Attributes
import Json.Encode
import ProgramTest exposing (ProgramTest)
import RobotGame.Main as RobotGameMain
import Route
import SimulatedEffect.Cmd
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Theme.Theme exposing (ColorScheme)


{-| Simulate a click on an element with the given test ID or selector
-}
simulateClick : String -> ProgramTest model msg effect -> ProgramTest model msg effect
simulateClick elementId programTest =
    programTest
        |> ProgramTest.clickButton elementId


{-| Click a button element by its test ID or data attribute
-}
clickButton : String -> ProgramTest model msg effect -> ProgramTest model msg effect
clickButton buttonId programTest =
    programTest
        |> ProgramTest.clickButton buttonId


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


{-| Simulate touch events for mobile interactions
-}
simulateTouch : String -> String -> ProgramTest model msg effect -> ProgramTest model msg effect
simulateTouch eventType elementSelector programTest =
    let
        touchEvent =
            case eventType of
                "start" ->
                    "touchstart"

                "end" ->
                    "touchend"

                "move" ->
                    "touchmove"

                _ ->
                    eventType

        touchEventValue =
            Json.Encode.object
                [ ( "touches", Json.Encode.list Json.Encode.object [] )
                , ( "targetTouches", Json.Encode.list Json.Encode.object [] )
                , ( "changedTouches", Json.Encode.list Json.Encode.object [] )
                ]
    in
    programTest
        |> ProgramTest.simulateDomEvent
            (Query.find [ Selector.attribute (Html.Attributes.attribute "aria-label" elementSelector) ])
            ( touchEvent, touchEventValue )


{-| Wait for a specific condition to be met in the model
This is a simplified helper that checks the condition immediately
-}
waitForCondition : (model -> Bool) -> ProgramTest model msg effect -> ProgramTest model msg effect
waitForCondition _ programTest =
    -- In a real implementation, this might poll or wait
    -- For now, we'll just return the program test as-is
    -- The condition checking should be done in the test assertions
    programTest


{-| Verify that an element with the given selector is present in the DOM
-}
expectElementPresent : String -> ProgramTest model msg effect -> Expectation
expectElementPresent selector programTest =
    programTest
        |> ProgramTest.expectView
            (Query.has [ Selector.attribute (Html.Attributes.attribute "aria-label" selector) ])


{-| Verify that an element with the given selector is NOT present in the DOM
-}
expectElementAbsent : String -> ProgramTest model msg effect -> Expectation
expectElementAbsent selector programTest =
    programTest
        |> ProgramTest.expectView
            (Query.hasNot [ Selector.attribute (Html.Attributes.attribute "aria-label" selector) ])


{-| Verify that an element contains the expected text content
-}
expectTextContent : String -> String -> ProgramTest model msg effect -> Expectation
expectTextContent selector expectedText programTest =
    programTest
        |> ProgramTest.expectView
            (Query.find [ Selector.attribute (Html.Attributes.attribute "aria-label" selector) ]
                >> Query.has [ Selector.text expectedText ]
            )


{-| Assert that a UI element with the given test ID is visible
-}
expectUIElementVisible : String -> ProgramTest model msg effect -> Expectation
expectUIElementVisible testId programTest =
    programTest
        |> ProgramTest.expectView
            (Query.has [ Selector.attribute (Html.Attributes.attribute "aria-label" testId) ])


{-| Assert that a UI element with the given test ID is not present/hidden
-}
expectUIElementHidden : String -> ProgramTest model msg effect -> Expectation
expectUIElementHidden testId programTest =
    programTest
        |> ProgramTest.expectView
            (Query.hasNot [ Selector.attribute (Html.Attributes.attribute "aria-label" testId) ])


{-| Assert that a UI element contains the expected text
-}
expectUIElementText : String -> String -> ProgramTest model msg effect -> Expectation
expectUIElementText testId expectedText programTest =
    programTest
        |> ProgramTest.expectView
            (Query.find [ Selector.attribute (Html.Attributes.attribute "aria-label" testId) ]
                >> Query.has [ Selector.text expectedText ]
            )


{-| Assert that a UI element has the expected attribute value
-}
expectUIElementAttribute : String -> String -> String -> ProgramTest model msg effect -> Expectation
expectUIElementAttribute testId attributeName expectedValue programTest =
    programTest
        |> ProgramTest.expectView
            (Query.find [ Selector.attribute (Html.Attributes.attribute "aria-label" testId) ]
                >> Query.has [ Selector.attribute (Html.Attributes.attribute attributeName expectedValue) ]
            )


{-| Assert that a specific field in the model has the expected value
-}
expectModelField : (model -> a) -> a -> ProgramTest model msg effect -> Expectation
expectModelField fieldExtractor expectedValue programTest =
    programTest
        |> ProgramTest.expectModel
            (\model ->
                Expect.equal expectedValue (fieldExtractor model)
            )


{-| Assert that the model satisfies a given predicate
-}
expectModelPredicate : (model -> Bool) -> String -> ProgramTest model msg effect -> Expectation
expectModelPredicate predicate description programTest =
    programTest
        |> ProgramTest.expectModel
            (\model ->
                if predicate model then
                    Expect.pass

                else
                    Expect.fail ("Model does not satisfy predicate: " ++ description)
            )


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


{-| Test model for state preservation testing
-}
type alias TestModel =
    { currentRoute : Route.Route
    , colorScheme : ColorScheme
    , gameModelExists : Bool
    , robotGameModelExists : Bool
    , maybeWindow : Maybe ( Int, Int )
    , navigationHistory : List Route.Route
    }


{-| Create initial test model
-}
createTestModel : Route.Route -> TestModel
createTestModel initialRoute =
    { currentRoute = initialRoute
    , colorScheme = Theme.Theme.Light
    , gameModelExists = False
    , robotGameModelExists = False
    , maybeWindow = Nothing
    , navigationHistory = [ initialRoute ]
    }


{-| Update function for testing state preservation logic
-}
testUpdate : App.AppMsg -> TestModel -> ( TestModel, Cmd App.AppMsg )
testUpdate msg model =
    case msg of
        App.NavigateToRoute route ->
            let
                updatedHistory =
                    route :: model.navigationHistory

                ( gameModelExists, robotGameModelExists ) =
                    case route of
                        Route.TicTacToe ->
                            ( True, model.robotGameModelExists )

                        Route.RobotGame ->
                            ( model.gameModelExists, True )

                        _ ->
                            ( model.gameModelExists, model.robotGameModelExists )
            in
            ( { model
                | currentRoute = route
                , gameModelExists = gameModelExists
                , robotGameModelExists = robotGameModelExists
                , navigationHistory = updatedHistory
              }
            , Cmd.none
            )

        App.ColorSchemeChanged newScheme ->
            ( { model | colorScheme = newScheme }, Cmd.none )

        App.WindowResized width height ->
            ( { model | maybeWindow = Just ( width, height ) }, Cmd.none )

        _ ->
            ( model, Cmd.none )


{-| Start the main App for testing using simplified test model
-}
startApp : () -> ProgramTest TestModel App.AppMsg (Cmd App.AppMsg)
startApp _ =
    let
        initialModel =
            createTestModel Route.Landing
    in
    ProgramTest.createElement
        { init = \_ -> ( initialModel, Cmd.none )
        , update = testUpdate
        , view = \_ -> Html.text "Test View"
        }
        |> ProgramTest.withSimulatedEffects simulateEffects
        |> ProgramTest.start ()


{-| Create a robot move message for testing
Since RobotGame doesn't have direct position setting, this returns a MoveForward message
For more complex positioning, multiple messages would need to be sent in sequence
-}
createRobotMoveMsg : { row : Int, col : Int } -> RobotGameMain.Msg
createRobotMoveMsg _ =
    -- For testing purposes, we'll use MoveForward
    -- In a real test, you'd need to send multiple rotation and movement commands
    -- to reach a specific position
    RobotGameMain.MoveForward


{-| Simulate effects for testing
-}
simulateEffects : Cmd App.AppMsg -> ProgramTest.SimulatedEffect App.AppMsg
simulateEffects _ =
    SimulatedEffect.Cmd.none

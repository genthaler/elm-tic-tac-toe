---
inclusion: fileMatch
fileMatchPattern: '*IntegrationTest.elm'
---

# elm-program-test Integration Testing Guide

This guide covers how to use elm-program-test for integration testing in this Elm project. elm-program-test allows you to test complete user workflows by simulating user interactions and verifying application behavior.

## Overview

elm-program-test enables end-to-end testing of Elm applications by:
- Simulating user interactions (clicks, keyboard input, etc.)
- Testing complete workflows across multiple components
- Verifying application state changes
- Testing navigation and routing
- Validating UI rendering and behavior

### Test Categories

Our test suite is organized into two main categories:

- **Unit Tests** (745 tests): Test individual functions and modules in isolation - files end with `UnitTest.elm`
- **Integration Tests** (220 tests): Test complete user workflows and component interactions - files end with `IntegrationTest.elm`

## Test Structure

Tests are organized by feature area with clear naming conventions:

```
tests/
├── GameTheory/                    # Algorithm unit tests
│   ├── AdversarialEagerUnitTest.elm
│   └── ExtendedOrderUnitTest.elm
├── Landing/                       # Landing page tests
│   └── LandingViewUnitTest.elm
├── RobotGame/                     # Robot game tests
│   ├── AnimationUnitTest.elm      # Animation system unit tests
│   ├── BlockedMovementUnitTest.elm # Boundary movement unit tests
│   ├── KeyboardInputUnitTest.elm  # Keyboard input unit tests
│   ├── MainUnitTest.elm           # Main module unit tests
│   ├── ModelUnitTest.elm          # Model functions unit tests
│   ├── PerformanceUnitTest.elm    # Performance optimization tests
│   ├── ResponsiveThemeUnitTest.elm # Responsive theme unit tests
│   ├── RobotGameIntegrationTest.elm # Comprehensive integration tests
│   ├── RobotGameUnitTest.elm      # Core game logic unit tests
│   ├── SelectiveHighlightingUnitTest.elm # UI highlighting unit tests
│   └── ViewUnitTest.elm           # View rendering unit tests
├── Theme/                         # Theme system tests
│   ├── ResponsiveUnitTest.elm     # Responsive design unit tests
│   ├── ThemeUnitTest.elm          # Theme functionality unit tests
│   └── ThemeVisualConsistencyUnitTest.elm # Visual consistency tests
├── TicTacToe/                     # TicTacToe game tests
│   ├── ModelUnitTest.elm          # Model functions unit tests
│   ├── TicTacToeIntegrationTest.elm # Game workflow integration tests
│   ├── TicTacToeUnitTest.elm      # Core game logic unit tests
│   └── ViewUnitTest.elm           # View rendering unit tests
├── TestUtils/                     # Shared test utilities
│   └── ProgramTestHelpers.elm     # Common test helpers and assertions
├── NavigationFlowIntegrationTest.elm # Navigation and routing integration tests
├── RouteUnitTest.elm              # Hash routing unit tests
└── elm-verify-examples.json       # Documentation testing configuration
```

## Helper Modules

### TestUtils.ProgramTestHelpers

Provides common utilities for interacting with ProgramTest instances and making assertions:

```elm
-- Interaction helpers
simulateClick : String -> ProgramTest model msg effect -> ProgramTest model msg effect
clickCell : { row : Int, col : Int } -> ProgramTest model msg effect -> ProgramTest model msg effect

-- Assertion helpers
expectColorScheme : ColorScheme -> ProgramTest { model | colorScheme : ColorScheme } msg effect -> Expectation
```

**Current Implementation Notes:**
- `simulateClick` wraps `ProgramTest.clickButton` for element interaction
- `clickCell` handles grid-based interactions using aria-label attributes
- `expectColorScheme` provides theme-specific assertions for models with colorScheme field
- Additional helpers are documented but not yet implemented (see module documentation for planned features)

**Planned Expansion:**
The module documentation indicates plans for additional helpers including:
- Application startup helpers for different game modules
- Keyboard interaction utilities (pressKey, pressArrowKey)
- Game-specific assertions (expectTicTacToeGameState, expectRobotPosition)
- Animation and timing utilities (waitForAnimation)
- UI element verification helpers

## Best Practices

### 1. Test User Behavior, Not Implementation

**Good**: Test what the user experiences
```elm
test "user can complete a game and see the winner" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            |> clickCell { row = 1, col = 1 }
            |> clickCell { row = 2, col = 2 }
            |> ProgramTest.expectViewHas [ text "Player X wins!" ]
```

**Bad**: Test internal implementation details
```elm
test "updateGameState function is called with correct parameters" <|
    \() ->
        -- This tests implementation, not user experience
        startTicTacToe ()
            |> ProgramTest.expectModel
                (\model ->
                    Expect.equal 0 model.updateGameStateCallCount
                )
```

### 2. One Behavior Per Test

Focus each test on a single user behavior or workflow:

```elm
-- Good - tests one specific interaction
test "theme toggle changes from light to dark"

-- Bad - tests multiple unrelated things
test "theme toggle and game reset and navigation"
```

### 3. Use Descriptive Test Names

```elm
-- Good
test "AI responds within reasonable time for simple position"

-- Bad  
test "AI test"
```

### 4. Test Both Model and View

Verify that changes are reflected in both state and UI:

```elm
test "theme change updates both model and appearance" <|
    \() ->
        startApp ()
            |> ProgramTest.clickButton "theme-toggle"
            -- Test view rendering shows dark theme
            |> ProgramTest.expectViewHas 
                [ Test.Html.Selector.class "dark-theme" ]
            -- Test that dark theme elements are visible
            |> ProgramTest.expectView
                (Test.Html.Query.find [ Test.Html.Selector.class "theme-indicator" ]
                    >> Test.Html.Query.has [ Test.Html.Selector.text "Dark Mode" ]
                )
```

### 5. Handle Async Operations Properly

For operations involving web workers or other async behavior:

```elm
test "AI move completes after human move" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            -- First verify the thinking state is visible
            |> ProgramTest.expectViewHas [ text "Player O is thinking..." ]
```

## Common Test Patterns

### 1. Complete Workflow Testing

Test entire user journeys from start to finish:

```elm
test "can start a game and make a move" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.expectView
                (Query.find [ Selector.class "game-status" ]
                    >> Query.has [ Selector.text "Player O is thinking..." ]
                )
```

### 2. Navigation Testing

```elm
test "browser back navigation from game to landing" <|
    \_ ->
        startApp ()
            |> ProgramTest.update (NavigateToRoute Route.TicTacToe)
            |> simulateBrowserBack [ Route.TicTacToe, Route.Landing ]
            |> ProgramTest.expectView
                (Test.Html.Query.find [ Test.Html.Selector.tag "body" ]
                    >> Test.Html.Query.has [ Test.Html.Selector.containing [ Test.Html.Selector.text "Welcome!" ] ]
                )
```

### 3. State Preservation Testing

Verify that state is maintained across different operations:

```elm
test "color scheme changes are preserved during game operations" <|
    \() ->
        startRobotGame ()
            |> ProgramTest.update (ColorSchemeChanged Dark)
            |> ProgramTest.update (MoveForward)
            |> expectColorScheme Dark
```

### 4. Error Handling Testing

Test how the application handles error conditions:

```elm
test "robot at boundary cannot move forward" <|
    \() ->
        startRobotGame ()
            |> ProgramTest.update (SetPosition { row = 0, col = 2 })  -- Top edge
            |> ProgramTest.update (SetDirection North)
            |> ProgramTest.update MoveForward
            |> expectRobotPosition { row = 0, col = 2 }  -- Should not move
```

### 5. Animation and State Testing

```elm
test "robot starts at center facing North" <|
    \() ->
        startRobotGame ()
            |> expectRobotPosition { row = 2, col = 2 }
            |> ProgramTest.expectView
                (Query.find [ Selector.class "robot" ]
                    >> Query.has [ Selector.attribute (Html.Attributes.attribute "data-direction" "North") ]
                )
```

## Helper Function Examples

### Domain-Specific Helpers

Build helpers that match your domain language:

```elm
-- Robot game position assertion (from actual codebase)
expectRobotPosition : Position -> ProgramTest Model msg effect -> Expect.Expectation
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

-- Color scheme assertion (from TestUtils.ProgramTestHelpers)
expectColorScheme : ColorScheme -> ProgramTest { model | colorScheme : ColorScheme } msg effect -> Expectation
expectColorScheme expectedScheme programTest =
    programTest
        |> ProgramTest.expectModel
            (\model ->
                Expect.equal expectedScheme model.colorScheme
            )

-- Game startup helper (from actual integration tests)
startRobotGame : () -> ProgramTest Model Msg Effect
startRobotGame _ =
    ProgramTest.createElement
        { init = \_ -> initToEffect
        , view = view
        , update = updateToEffect
        }
        |> ProgramTest.withSimulatedEffects simulateEffects
        |> ProgramTest.start ()
```

### Workflow Helpers

```elm
-- Browser navigation simulation (from NavigationFlowIntegrationTest)
simulateBrowserBack : List Route.Route -> ProgramTest TestModel AppMsg (Cmd AppMsg) -> ProgramTest TestModel AppMsg (Cmd AppMsg)
simulateBrowserBack history programTest =
    case List.drop 1 history of
        previousRoute :: _ ->
            let
                previousUrl =
                    { protocol = Url.Http
                    , host = "localhost"
                    , port_ = Just 3000
                    , path = Route.toString previousRoute
                    , query = Nothing
                    , fragment = Nothing
                    }
            in
            programTest
                |> ProgramTest.update (UrlChanged previousUrl)

        [] ->
            programTest

-- Effect simulation (from RobotGame integration tests)
simulateEffects : Effect -> ProgramTest.SimulatedEffect Msg
simulateEffects effect =
    case effect of
        AnimationEffect animationMsg ->
            SimCmd.none

        NoEffect ->
            SimCmd.none
```

## Web Worker Considerations

### Production Build Required

Web worker functionality **cannot be tested** using development servers. Development mode compilation removes the DOM nodes and worker compilation needed for proper web worker functionality.

**Correct Testing Procedure:**

1. **Build for production**: `npm run build`
2. **Serve the built files**: `npm run serve`
3. **Test in browser**: Navigate to `http://localhost:3000`

### Mock Worker Responses in Tests

For deterministic testing, mock worker behavior:

```elm
-- Create test helper that mocks worker behavior
startTicTacToeWithMockWorker : () -> ProgramTest Model Msg (Cmd Msg)
startTicTacToeWithMockWorker _ =
    ProgramTest.createElement
        { init = init
        , update = updateWithMockWorker  -- Use mock update function
        , view = view
        }
        |> ProgramTest.start ()

updateWithMockWorker : Msg -> Model -> ( Model, Cmd Msg )
updateWithMockWorker msg model =
    case msg of
        HumanMove position ->
            -- Immediately simulate AI response instead of using worker
            let
                ( modelAfterHuman, _ ) = update msg model
                aiMove = findBestMove modelAfterHuman.board O
            in
            case aiMove of
                Just move ->
                    update (AIMove move) modelAfterHuman
                Nothing ->
                    ( modelAfterHuman, Cmd.none )
        
        _ ->
            update msg model
```

## Performance Considerations

### 1. Minimize Test Setup

Only set up what's necessary for each test:

```elm
-- Good: Minimal setup
test "theme toggle works" <|
    \() ->
        startApp ()  -- Simple startup
            |> ProgramTest.clickButton "theme-toggle"
            |> ProgramTest.expectViewHas [ Test.Html.Selector.class "dark-theme" ]
```

### 2. Use Efficient Selectors

Prefer specific selectors over broad searches:

```elm
-- Good: Specific selector (from actual codebase)
|> ProgramTest.expectView
    (Query.find [ Selector.class "game-status" ]
        >> Query.has [ Selector.text "Player O is thinking..." ]
    )

-- Good: Attribute-based selection (from RobotGame tests)
|> ProgramTest.expectView
    (Query.find [ Selector.class "robot" ]
        >> Query.has [ Selector.attribute (Html.Attributes.attribute "data-direction" "North") ]
    )

-- Less efficient: Broad search
|> ProgramTest.expectViewHas [ text "Player X's turn" ]  -- Searches entire DOM
```

### 3. Group Related Tests

Use `describe` blocks to organize tests by functional area (from actual codebase):

```elm
suite : Test
suite =
    describe "RobotGame Integration Tests"
        [ userWorkflowTests
        , movementIntegrationTests
        , animationIntegrationTests
        , errorHandlingTests
        , inputMethodTests
        , accessibilityTests
        , stateManagementTests
        , visualHighlightingTests
        ]

-- Each test group focuses on a specific area
userWorkflowTests : Test
userWorkflowTests =
    describe "User Workflow Tests"
        [ test "user can navigate from center to top-right corner using mixed inputs" <|
            \() ->
                startRobotGame ()
                    |> -- test implementation
        ]
```

## Common Anti-Patterns to Avoid

### 1. Testing Implementation Details

**Avoid**: Testing internal function calls or data structures
```elm
-- Bad: Tests internal implementation
test "updateBoard function is called" <|
    \() ->
        startTicTacToe ()
            |> ProgramTest.expectModel
                (\model ->
                    Expect.equal 1 model.updateBoardCallCount
                )
```

**Instead**: Test user-observable behavior
```elm
-- Good: Tests user experience
test "clicking cell places player symbol" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.expectViewHas [ text "X" ]
```

### 2. Testing Multiple Behaviors in One Test

**Avoid**: Combining unrelated test scenarios
```elm
-- Bad: Multiple unrelated behaviors
test "game features work" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }  -- Test moves
            |> ProgramTest.clickButton "theme-toggle"  -- Test themes
            |> ProgramTest.clickButton "reset-game"  -- Test reset
```

**Instead**: One behavior per test
```elm
-- Good: Focused tests
test "user can make moves" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.expectViewHas [ text "X" ]

test "user can toggle theme" <|
    \() ->
        startTicTacToe ()
            |> ProgramTest.clickButton "theme-toggle"
            |> ProgramTest.expectViewHas [ Test.Html.Selector.class "dark-theme" ]
```

### 3. Ignoring Async Behavior

**Avoid**: Assuming immediate completion of async operations
```elm
-- Bad: Assumes AI move completes immediately
test "AI responds to human move" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.expectViewHas [ text "Player X's turn" ]  -- May not be true immediately
```

**Instead**: Test intermediate states and eventual outcomes
```elm
-- Good: Handles async properly
test "AI responds to human move" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.expectViewHas [ text "Player O is thinking..." ]  -- Immediate state
```

## Running Tests

### All Tests
```bash
npm run test
```

**Note:** The project currently uses `npm run test` for running the complete test suite. Additional test-specific scripts like integration-only tests, coverage reports, or watch mode are not currently configured but could be added to package.json as needed.

### Test Organization
Tests are automatically discovered by elm-test and organized by:
- **Unit Tests**: Files ending with `UnitTest.elm` (745 tests)
- **Integration Tests**: Files ending with `IntegrationTest.elm` (220 tests)
- **Documentation Tests**: Configured via `elm-verify-examples.json`

By following these patterns and best practices, your integration tests will be more reliable, maintainable, and valuable for ensuring your application works correctly from the user's perspective.
# elm-program-test Troubleshooting Guide

This guide covers common issues you might encounter when writing or running elm-program-test integration tests, along with their solutions.

## Test Execution Issues

### Issue: Tests fail with "elm-test command not found"

**Symptoms:**
```bash
elm-test: command not found
```

**Solution:**
```bash
# Install elm-test locally
npm install

# Or install globally
npm install -g elm-test
```

**Prevention:**
Always use npm scripts instead of calling elm-test directly:
```bash
npm run test
npm run test:integration
```

### Issue: Tests run but no integration tests are executed

**Symptoms:**
- Test count is lower than expected
- Only unit tests appear to run

**Solution:**
Check that integration test files are in the correct locations and follow naming conventions:

```bash
# Verify integration test files exist
ls tests/Integration/
ls tests/*/Integration*Test.elm
ls tests/*/*Integration*Test.elm
```

**Prevention:**
Use the provided npm scripts that explicitly include integration tests:
```bash
npm run test:integration  # Run only integration tests
npm run test             # Run all tests
```

## Element Selection Problems

### Issue: "Element not found" errors

**Symptoms:**
```
ProgramTest.clickButton failed: element not found
```

**Common Causes & Solutions:**

#### 1. Incorrect Selector
```elm
-- Problem: Wrong selector
|> ProgramTest.clickButton "submit"

-- Solution: Use correct selector
|> ProgramTest.clickButton "submit-button"
```

#### 2. Element Not Yet Rendered
```elm
-- Problem: Clicking before element exists
startTicTacToe ()
    |> ProgramTest.clickButton "reset-button"  -- May not exist initially

-- Solution: Ensure element exists first
startTicTacToe ()
    |> clickCell { row = 0, col = 0 }  -- Create game state where reset exists
    |> ProgramTest.clickButton "reset-button"
```

#### 3. Conditional Element Rendering
```elm
-- Problem: Element only shows in certain states
|> ProgramTest.clickButton "ai-thinking-indicator"  -- Only visible when AI thinking

-- Solution: Ensure correct state first
|> clickCell { row = 0, col = 0 }  -- Trigger AI thinking
|> ProgramTest.expectViewHas [ text "Player O is thinking..." ]
|> ProgramTest.clickButton "cancel-ai"  -- Now the element exists
```

### Issue: Multiple elements match selector

**Symptoms:**
```
Multiple elements found matching selector
```

**Solution:**
Use more specific selectors:

```elm
-- Problem: Generic selector
|> ProgramTest.clickButton "button"

-- Solution: Specific selector
|> ProgramTest.clickButton "game-reset-button"
```

### Issue: Element exists but click doesn't work

**Symptoms:**
- No error thrown
- Expected behavior doesn't occur

**Solution:**
Verify the element is actually clickable:

```elm
-- Debug: Check element properties
|> ProgramTest.expectView
    (Test.Html.Query.find [ Test.Html.Selector.id "my-button" ]
        >> Test.Html.Query.has [ Test.Html.Selector.attribute "disabled" ]
    )
```

## State and Model Issues

### Issue: Model state doesn't match expectations

**Symptoms:**
```
Expected: Waiting X
Actual: Thinking O
```

**Debugging Steps:**

#### 1. Add Debug Logging
```elm
|> ProgramTest.expectModel
    (\model ->
        let
            _ = Debug.log "Current game state" model.gameState
            _ = Debug.log "Current board" model.board
        in
        Expect.equal (Waiting X) model.gameState
    )
```

#### 2. Check Intermediate States
```elm
-- Instead of jumping to final state
test "game flow" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            -- Check intermediate state
            |> ProgramTest.expectModel
                (\model ->
                    case model.gameState of
                        Thinking O -> Expect.pass
                        other -> Expect.fail ("Expected Thinking O, got " ++ Debug.toString other)
                )
            -- Then check final state
            |> ProgramTest.expectModel
                (\model ->
                    case model.gameState of
                        Waiting X -> Expect.pass
                        other -> Expect.fail ("Expected Waiting X, got " ++ Debug.toString other)
                )
```

#### 3. Verify Message Flow
```elm
-- Add custom update function for debugging
debugUpdate : Msg -> Model -> ( Model, Cmd Msg )
debugUpdate msg model =
    let
        _ = Debug.log "Received message" msg
        ( newModel, cmd ) = update msg model
        _ = Debug.log "New model state" newModel.gameState
    in
    ( newModel, cmd )
```

### Issue: State changes don't persist

**Symptoms:**
- State appears to reset between operations
- Previous actions seem to be lost

**Solution:**
Ensure you're chaining operations correctly:

```elm
-- Problem: Not chaining properly
let
    programTest = startTicTacToe ()
in
programTest
    |> clickCell { row = 0, col = 0 }
    
programTest  -- This starts fresh, losing previous state
    |> ProgramTest.expectModel (...)

-- Solution: Chain all operations
startTicTacToe ()
    |> clickCell { row = 0, col = 0 }
    |> ProgramTest.expectModel (...)
```

## Timing and Async Issues

### Issue: Tests fail intermittently

**Symptoms:**
- Tests pass sometimes, fail other times
- Failures seem random

**Common Causes & Solutions:**

#### 1. Race Conditions with Async Operations
```elm
-- Problem: Assuming immediate completion
test "AI makes move" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.expectModel  -- May check before AI completes
                (\model ->
                    case model.gameState of
                        Waiting X -> Expect.pass
                        _ -> Expect.fail "AI didn't complete move"
                )

-- Solution: Test intermediate states
test "AI makes move" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.expectModel  -- First verify thinking state
                (\model ->
                    case model.gameState of
                        Thinking O -> Expect.pass
                        _ -> Expect.fail "AI should be thinking"
                )
```

#### 2. Time-Dependent Tests
```elm
-- Problem: Tests depend on specific timing
test "timeout triggers after 5 seconds" <|
    \() ->
        startTicTacToe ()
            |> ProgramTest.advanceTime 5000  -- Advance time
            |> ProgramTest.expectModel
                (\model ->
                    -- Test timeout behavior
                    Expect.equal True model.timeoutTriggered
                )
```

### Issue: Web worker operations don't complete

**Symptoms:**
- Tests hang waiting for worker responses
- Worker-related state changes don't occur

**Solution:**
Mock worker responses in tests:

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

## Web Worker Issues

### Issue: Worker tests fail in development mode

**Symptoms:**
- Worker-related tests fail with "worker not found" or similar errors
- Tests pass in production build but fail in development

**Solution:**
Web workers require production builds. For testing worker functionality:

```bash
# Build for production
npm run build

# Serve built files
npm run serve

# Test in browser at http://localhost:3000
```

**Alternative:** Mock worker behavior in tests (see above example).

### Issue: Worker communication timeouts

**Symptoms:**
- Tests hang waiting for worker responses
- Timeout errors in worker communication

**Solution:**
Implement proper timeout handling:

```elm
-- In your test
test "worker timeout handling" <|
    \() ->
        startTicTacToe ()
            |> clickCell { row = 0, col = 0 }
            |> ProgramTest.advanceTime 10000  -- Simulate timeout
            |> ProgramTest.expectModel
                (\model ->
                    case model.gameState of
                        Error _ -> Expect.pass  -- Should handle timeout gracefully
                        _ -> Expect.fail "Should handle worker timeout"
                )
```

## Performance Issues

### Issue: Tests run slowly

**Symptoms:**
- Test suite takes a long time to complete
- Individual tests are slow

**Solutions:**

#### 1. Optimize Test Setup
```elm
-- Problem: Expensive setup in every test
test "game behavior 1" <|
    \() ->
        startComplexGameState ()  -- Expensive setup
            |> testBehavior1

test "game behavior 2" <|
    \() ->
        startComplexGameState ()  -- Same expensive setup
            |> testBehavior2

-- Solution: Group related tests
suite : Test
suite =
    describe "Game behaviors"
        [ describe "with complex game state"
            (let
                baseTest = startComplexGameState ()
             in
             [ test "behavior 1" <|
                \() -> baseTest |> testBehavior1
             , test "behavior 2" <|
                \() -> baseTest |> testBehavior2
             ]
            )
        ]
```

#### 2. Use Specific Selectors
```elm
-- Problem: Slow, generic selectors
|> ProgramTest.expectViewHas [ text "some text" ]  -- Searches entire DOM

-- Solution: Specific selectors
|> ProgramTest.expectView
    (Test.Html.Query.find [ Test.Html.Selector.id "game-status" ]
        >> Test.Html.Query.has [ Test.Html.Selector.text "some text" ]
    )
```

#### 3. Reduce Fuzz Test Iterations
```elm
-- In elm-test.json, reduce fuzz iterations for faster tests
{
    "fuzz": 20  // Reduced from default 100
}
```

### Issue: Memory issues with large test suites

**Symptoms:**
- Tests fail with out-of-memory errors
- Performance degrades over time

**Solution:**
Ensure proper cleanup:

```elm
-- Make sure ProgramTest instances are properly disposed
test "my test" <|
    \() ->
        startApp ()
            |> performOperations
            |> ProgramTest.done  -- Explicit cleanup if needed
```

## Debugging Techniques

### 1. Visual Debugging

```elm
-- Debug what's actually in the view
|> ProgramTest.expectView
    (Test.Html.Query.fromHtml
        >> Debug.log "Current view HTML"
        >> always (Expect.pass)
    )
```

### 2. Model State Debugging

```elm
-- Log model state at any point
|> ProgramTest.expectModel
    (\model ->
        let
            _ = Debug.log "Model state" model
            _ = Debug.log "Game state" model.gameState
            _ = Debug.log "Board state" model.board
        in
        Expect.pass
    )
```

### 3. Message Flow Debugging

```elm
-- Create a debug version of your update function
debugUpdate : Msg -> Model -> ( Model, Cmd Msg )
debugUpdate msg model =
    let
        _ = Debug.log "Processing message" msg
        _ = Debug.log "Current model" model
        ( newModel, cmd ) = update msg model
        _ = Debug.log "New model" newModel
        _ = Debug.log "Commands" cmd
    in
    ( newModel, cmd )

-- Use in test setup
ProgramTest.createElement
    { init = init
    , update = debugUpdate  -- Use debug version
    , view = view
    }
```

### 4. Step-by-Step Debugging

```elm
-- Break complex tests into steps
test "complex workflow" <|
    \() ->
        let
            step1 = 
                startApp ()
                    |> simulateClick "start"
                    |> ProgramTest.expectModel
                        (\model ->
                            let
                                _ = Debug.log "After step 1" model
                            in
                            Expect.pass
                        )
            
            step2 =
                step1
                    |> simulateClick "next"
                    |> ProgramTest.expectModel
                        (\model ->
                            let
                                _ = Debug.log "After step 2" model
                            in
                            Expect.pass
                        )
        in
        step2
            |> finalAssertion
```

### 5. Isolation Testing

```elm
-- Test components in isolation to identify issues
test "isolated component test" <|
    \() ->
        -- Test just the component that's failing
        ProgramTest.createElement
            { init = \_ -> ( isolatedModel, Cmd.none )
            , update = isolatedUpdate
            , view = isolatedView
            }
            |> ProgramTest.start ()
            |> testSpecificBehavior
```

## Common Error Messages and Solutions

### "Cannot find variable 'ProgramTest'"

**Solution:** Add the import:
```elm
import ProgramTest
```

### "Type mismatch" in ProgramTest functions

**Solution:** Ensure your model, message, and effect types match:
```elm
-- Make sure types align
startApp : () -> ProgramTest App.Model App.Msg (Cmd App.Msg)
```

### "Element not found" with correct selector

**Solution:** Check element timing and state:
```elm
-- Ensure element exists before interacting
|> ProgramTest.expectViewHas [ Test.Html.Selector.id "my-element" ]
|> ProgramTest.clickButton "my-element"
```

### Tests hang indefinitely

**Solution:** Check for infinite loops or missing async completion:
```elm
-- Add timeouts for async operations
|> ProgramTest.expectModel
    (\model ->
        case model.asyncState of
            Loading -> Expect.pass  -- Allow loading state
            Complete -> Expect.pass
            Failed -> Expect.fail "Async operation failed"
    )
```

## Prevention Checklist

Before writing integration tests:

- [ ] Understand the user workflow you're testing
- [ ] Identify the key state changes that should occur
- [ ] Plan your test structure and helper functions
- [ ] Consider timing and async operations
- [ ] Think about error conditions and edge cases
- [ ] Plan for debugging and maintenance

During test development:

- [ ] Write descriptive test names
- [ ] Test one workflow per test
- [ ] Use helper functions for common operations
- [ ] Add intermediate assertions for complex workflows
- [ ] Handle async operations properly
- [ ] Include error condition testing

After writing tests:

- [ ] Run tests multiple times to check for flakiness
- [ ] Verify tests fail when they should
- [ ] Check test performance
- [ ] Document any special setup or considerations
- [ ] Review with team members

## Getting Help

If you're still experiencing issues:

1. **Check the logs**: Look for Debug.log output in the browser console
2. **Simplify the test**: Create a minimal reproduction case
3. **Check elm-program-test documentation**: [Package documentation](https://package.elm-lang.org/packages/avh4/elm-program-test/latest/)
4. **Review similar tests**: Look at working tests in the codebase for patterns
5. **Use the Elm community**: Ask questions on the Elm Slack or Discourse
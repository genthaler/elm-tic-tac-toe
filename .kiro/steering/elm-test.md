---
inclusion: fileMatch
fileMatchPattern: '*Test.elm'
---

# elm-test Development Guidelines

## Overview

This project uses elm-test as the primary testing framework for unit testing pure functions and components. elm-test provides a robust foundation for testing Elm applications with support for property-based testing (fuzz testing) and view testing.

## Testing Architecture

### Test Categories

Our test suite is organized into two main categories:

- **Unit Tests** (745 tests): Test individual functions and modules in isolation - files end with `UnitTest.elm`
- **Integration Tests** (220 tests): Test complete user workflows and component interactions - files end with `IntegrationTest.elm`

### Test Structure

Tests are organized by feature area with clear naming conventions:

```
tests/
├── GameTheory/                    # Algorithm unit tests
│   ├── AdversarialEagerUnitTest.elm
│   └── ExtendedOrderUnitTest.elm
├── TicTacToe/                     # TicTacToe game tests
│   ├── TicTacToeUnitTest.elm      # Unit tests for core logic
│   ├── ModelUnitTest.elm          # Unit tests for model functions
│   └── ViewUnitTest.elm           # Unit tests for view functions
├── RobotGame/                     # Robot game tests
│   ├── RobotGameUnitTest.elm      # Unit tests for core logic
│   ├── ModelUnitTest.elm          # Unit tests for model functions
│   └── ViewUnitTest.elm           # Unit tests for view functions
├── Theme/                         # Theme system unit tests
│   ├── ThemeUnitTest.elm
│   └── ResponsiveUnitTest.elm
├── RouteUnitTest.elm              # Hash routing unit tests
└── TestUtils/                     # Shared test utilities
    └── ProgramTestHelpers.elm
```

## elm-test Patterns

### Pure Function Testing

Start with pure function testing - it's the easiest and most valuable:

```elm
module TicTacToe.ModelUnitTest exposing (..)

import Expect
import Test exposing (..)
import TicTacToe.Model exposing (..)

suite : Test
suite =
    describe "TicTacToe.Model"
        [ describe "isValidMove"
            [ test "returns True for empty cell" <|
                \_ ->
                    let
                        board = emptyBoard
                        position = { row = 0, col = 0 }
                    in
                    isValidMove board position
                        |> Expect.equal True
            
            , test "returns False for occupied cell" <|
                \_ ->
                    let
                        board = emptyBoard
                            |> setCell { row = 0, col = 0 } (Just X)
                        position = { row = 0, col = 0 }
                    in
                    isValidMove board position
                        |> Expect.equal False
            ]
        ]
```

### Fuzz Testing

Use fuzz testing for property-based testing of encoders/decoders and mathematical functions:

```elm
import Fuzz
import Json.Decode as Decode
import Json.Encode as Encode

suite : Test
suite =
    describe "JSON encoding/decoding"
        [ fuzz Fuzz.int "position encoding round-trip" <|
            \row ->
                let
                    position = { row = row, col = row + 1 }
                    encoded = encodePosition position
                    decoded = Decode.decodeValue positionDecoder encoded
                in
                case decoded of
                    Ok decodedPosition ->
                        Expect.equal position decodedPosition
                    
                    Err _ ->
                        Expect.fail "Decoding should succeed"
        
        , fuzz (Fuzz.list Fuzz.int) "list operations preserve length" <|
            \numbers ->
                numbers
                    |> List.map (\n -> n * 2)
                    |> List.length
                    |> Expect.equal (List.length numbers)
        ]
```

### View Testing

Use Test.Html.Query for testing view logic:

```elm
import Test.Html.Query as Query
import Test.Html.Selector exposing (..)

suite : Test
suite =
    describe "TicTacToe.View"
        [ test "displays current player turn" <|
            \_ ->
                let
                    model = { initialModel | currentPlayer = X }
                    html = view model
                in
                html
                    |> Query.fromHtml
                    |> Query.find [ class "player-turn" ]
                    |> Query.has [ text "Player X's turn" ]
        
        , test "shows winner message when game ends" <|
            \_ ->
                let
                    model = { initialModel | gameState = Winner X }
                    html = view model
                in
                html
                    |> Query.fromHtml
                    |> Query.find [ class "game-status" ]
                    |> Query.has [ text "Player X wins!" ]
        ]
```

### Update Testing

Test state transitions with specific messages:

```elm
suite : Test
suite =
    describe "TicTacToe update function"
        [ test "HumanMove updates board and switches player" <|
            \_ ->
                let
                    initialModel = { emptyModel | currentPlayer = X }
                    position = { row = 0, col = 0 }
                    ( updatedModel, _ ) = update (HumanMove position) initialModel
                in
                Expect.all
                    [ \model -> 
                        getCell model.board position
                            |> Expect.equal (Just X)
                    , \model ->
                        model.currentPlayer
                            |> Expect.equal O
                    ]
                    updatedModel
        
        , test "invalid move doesn't change state" <|
            \_ ->
                let
                    board = emptyBoard |> setCell { row = 0, col = 0 } (Just X)
                    initialModel = { emptyModel | board = board }
                    position = { row = 0, col = 0 }  -- Already occupied
                    ( updatedModel, _ ) = update (HumanMove position) initialModel
                in
                updatedModel
                    |> Expect.equal initialModel
        ]
```

## Testing Best Practices

### 1. Test Behavior, Not Implementation

**Good**: Test what the function does
```elm
test "checkWinner detects horizontal win" <|
    \_ ->
        let
            board = emptyBoard
                |> setCell { row = 0, col = 0 } (Just X)
                |> setCell { row = 0, col = 1 } (Just X)
                |> setCell { row = 0, col = 2 } (Just X)
        in
        checkWinner board
            |> Expect.equal (Just X)
```

**Bad**: Test internal implementation details
```elm
test "checkWinner calls checkRows function" <|
    \_ ->
        -- This tests implementation, not behavior
        Expect.fail "Don't test internal function calls"
```

### 2. Use Descriptive Test Names

```elm
-- Good
test "robot moves north when facing north and moving forward"

-- Bad  
test "robot test"
```

### 3. Test Edge Cases

```elm
suite : Test
suite =
    describe "board boundary checking"
        [ test "position (0,0) is valid" <|
            \_ ->
                isValidPosition { row = 0, col = 0 }
                    |> Expect.equal True
        
        , test "negative row is invalid" <|
            \_ ->
                isValidPosition { row = -1, col = 0 }
                    |> Expect.equal False
        
        , test "position beyond board size is invalid" <|
            \_ ->
                isValidPosition { row = 3, col = 0 }  -- 3x3 board
                    |> Expect.equal False
        ]
```

### 4. Group Related Tests

Use `describe` blocks to organize related functionality:

```elm
suite : Test
suite =
    describe "Game state management"
        [ describe "move validation"
            [ test "accepts moves to empty cells" <|
                \_ -> -- test implementation
            
            , test "rejects moves to occupied cells" <|
                \_ -> -- test implementation
            ]
        
        , describe "win detection"
            [ test "detects horizontal wins" <|
                \_ -> -- test implementation
            
            , test "detects vertical wins" <|
                \_ -> -- test implementation
            
            , test "detects diagonal wins" <|
                \_ -> -- test implementation
            ]
        ]
```

## Testing Patterns for Different Scenarios

### Testing Custom Types

```elm
type GameState
    = Playing Player
    | Winner Player
    | Draw

suite : Test
suite =
    describe "GameState transitions"
        [ test "game starts in Playing state" <|
            \_ ->
                initialGameState
                    |> Expect.equal (Playing X)
        
        , test "winning move transitions to Winner state" <|
            \_ ->
                let
                    winningBoard = createWinningBoard X
                    newState = determineGameState winningBoard
                in
                newState
                    |> Expect.equal (Winner X)
        ]
```

### Testing Maybe and Result Types

```elm
suite : Test
suite =
    describe "Maybe and Result handling"
        [ test "parseMove returns Just for valid input" <|
            \_ ->
                parseMove "A1"
                    |> Expect.equal (Just { row = 0, col = 0 })
        
        , test "parseMove returns Nothing for invalid input" <|
            \_ ->
                parseMove "invalid"
                    |> Expect.equal Nothing
        
        , test "validateMove returns Ok for valid move" <|
            \_ ->
                validateMove emptyBoard { row = 0, col = 0 }
                    |> Expect.equal (Ok { row = 0, col = 0 })
        
        , test "validateMove returns Err for invalid move" <|
            \_ ->
                let
                    occupiedBoard = emptyBoard |> setCell { row = 0, col = 0 } (Just X)
                in
                validateMove occupiedBoard { row = 0, col = 0 }
                    |> Expect.err
        ]
```

### Testing List Operations

```elm
suite : Test
suite =
    describe "List operations"
        [ test "getAvailableMoves returns empty positions" <|
            \_ ->
                let
                    partialBoard = emptyBoard
                        |> setCell { row = 0, col = 0 } (Just X)
                        |> setCell { row = 1, col = 1 } (Just O)
                    
                    expected = 7  -- 9 total - 2 occupied
                in
                getAvailableMoves partialBoard
                    |> List.length
                    |> Expect.equal expected
        
        , fuzz (Fuzz.list Fuzz.int) "filtering preserves order" <|
            \numbers ->
                let
                    evens = List.filter (\n -> modBy 2 n == 0) numbers
                    evenIndices = List.indexedMap (\i n -> (i, n)) numbers
                        |> List.filter (\(_, n) -> modBy 2 n == 0)
                        |> List.map Tuple.second
                in
                evens
                    |> Expect.equal evenIndices
        ]
```

## Performance Testing Patterns

### Testing Algorithm Efficiency

```elm
suite : Test
suite =
    describe "Algorithm performance"
        [ test "minimax completes within reasonable time" <|
            \_ ->
                let
                    startTime = 0  -- In real tests, use Time.now
                    result = minimax emptyBoard 3 True
                    -- endTime = Time.now
                    -- duration = endTime - startTime
                in
                -- For unit tests, focus on correctness over timing
                result
                    |> Expect.notEqual Nothing
        
        , fuzz (Fuzz.intRange 1 100) "list operations scale linearly" <|
            \size ->
                let
                    largeList = List.range 1 size
                    processed = List.map (\n -> n * 2) largeList
                in
                List.length processed
                    |> Expect.equal size
        ]
```

## Mock and Stub Patterns

### Mocking External Dependencies

```elm
-- For testing functions that depend on external state
type alias TestModel =
    { board : Board
    , currentPlayer : Player
    , aiDifficulty : Difficulty
    }

-- Create test-specific models
createTestModel : Board -> Player -> TestModel
createTestModel board player =
    { board = board
    , currentPlayer = player
    , aiDifficulty = Easy  -- Predictable for testing
    }

suite : Test
suite =
    describe "AI decision making"
        [ test "AI chooses winning move when available" <|
            \_ ->
                let
                    nearWinBoard = createNearWinBoard O
                    testModel = createTestModel nearWinBoard O
                    aiMove = getBestMove testModel
                in
                case aiMove of
                    Just position ->
                        -- Verify this move would win
                        makeMove nearWinBoard position O
                            |> checkWinner
                            |> Expect.equal (Just O)
                    
                    Nothing ->
                        Expect.fail "AI should find winning move"
        ]
```

## Testing JSON Encoders/Decoders

```elm
import Json.Decode as Decode
import Json.Encode as Encode

suite : Test
suite =
    describe "JSON serialization"
        [ test "position encoder creates correct JSON" <|
            \_ ->
                let
                    position = { row = 1, col = 2 }
                    encoded = encodePosition position
                    expected = Encode.object
                        [ ( "row", Encode.int 1 )
                        , ( "col", Encode.int 2 )
                        ]
                in
                encoded
                    |> Expect.equal expected
        
        , test "position decoder handles valid JSON" <|
            \_ ->
                let
                    json = Encode.object
                        [ ( "row", Encode.int 1 )
                        , ( "col", Encode.int 2 )
                        ]
                    decoded = Decode.decodeValue positionDecoder json
                in
                case decoded of
                    Ok position ->
                        position
                            |> Expect.equal { row = 1, col = 2 }
                    
                    Err error ->
                        Expect.fail ("Decoding failed: " ++ Decode.errorToString error)
        
        , fuzz2 Fuzz.int Fuzz.int "position round-trip encoding" <|
            \row col ->
                let
                    position = { row = row, col = col }
                    encoded = encodePosition position
                    decoded = Decode.decodeValue positionDecoder encoded
                in
                case decoded of
                    Ok decodedPosition ->
                        decodedPosition
                            |> Expect.equal position
                    
                    Err _ ->
                        Expect.fail "Round-trip should preserve data"
        ]
```

## Project Commands

### Running Tests

```bash
# Run all tests (unit + integration)
npm run test

# Run tests in watch mode (recommended for development)
npm run test -- --watch
```

### Running Single Tests with Test.only

**NEVER use `npx elm-test` or command-line filtering.** Instead, use `Test.only` to focus on specific tests:

```elm
-- Run only a specific test
suite : Test
suite =
    describe "TicTacToe.Model"
        [ Test.only <|
            test "returns True for empty cell" <|
                \_ ->
                    let
                        board = emptyBoard
                        position = { row = 0, col = 0 }
                    in
                    isValidMove board position
                        |> Expect.equal True
        
        , test "returns False for occupied cell" <|
            \_ ->
                -- This test will be skipped
                Expect.pass
        ]

-- Run only a specific describe block
suite : Test
suite =
    Test.only <|
        describe "move validation"
            [ test "accepts moves to empty cells" <|
                \_ -> -- This will run
                    Expect.pass
            
            , test "rejects moves to occupied cells" <|
                \_ -> -- This will also run
                    Expect.pass
            ]

-- Multiple Test.only examples
suite : Test
suite =
    describe "Game logic"
        [ Test.only <|
            test "specific test I'm debugging" <|
                \_ ->
                    -- Only this test runs
                    Expect.pass
        
        , Test.only <|
            test "another test I want to run" <|
                \_ ->
                    -- This also runs
                    Expect.pass
        
        , test "this test is skipped" <|
            \_ ->
                -- This won't run
                Expect.pass
        ]
```

### Test.skip for Temporarily Disabling Tests

```elm
suite : Test
suite =
    describe "TicTacToe.Model"
        [ test "working test" <|
            \_ ->
                -- This runs normally
                Expect.pass
        
        , Test.skip <|
            test "broken test I'll fix later" <|
                \_ ->
                    -- This test is skipped
                    Expect.fail "Not implemented yet"
        ]
```

### Workflow for Focused Testing

1. **Add `Test.only`** to the specific test you want to run
2. **Run `npm run test`** - only the marked tests will execute
3. **Remove `Test.only`** before committing (elm-review will catch this)

```elm
-- Development: Focus on one test
suite : Test
suite =
    describe "Robot movement"
        [ Test.only <|  -- Add this temporarily
            test "robot moves north correctly" <|
                \_ ->
                    -- Debug this specific test
                    Expect.pass
        
        , test "other tests" <|
            \_ -> Expect.pass
        ]

-- Before commit: Remove Test.only
suite : Test
suite =
    describe "Robot movement"
        [ test "robot moves north correctly" <|  -- Remove Test.only
            \_ ->
                -- Now all tests run
                Expect.pass
        
        , test "other tests" <|
            \_ -> Expect.pass
        ]
```

### Code Quality Integration

```bash
# Run elm-review before testing
npm run review

# Auto-fix elm-review issues
npm run review:fix

# NEVER chain commands - run individually
npm run review
npm run test
```

### Important: elm-review catches Test.only

elm-review will flag any `Test.only` or `Test.skip` left in committed code:

```bash
# This will fail if Test.only is present
npm run review

# Remove Test.only before committing
# elm-review ensures no focused tests reach production
```

## Testing Requirements

### Project Standards

- All new functions must have corresponding unit tests
- Test coverage should be maintained for new functionality
- Tests must pass `npm run review` without errors
- Use descriptive test names that explain the behavior being tested
- Group related tests using `describe` blocks
- Test both happy path and edge cases

### Mock Web Worker Behavior

For deterministic testing, mock worker behavior in unit tests:

```elm
-- Create test-specific update function that doesn't use workers
updateForTesting : Msg -> Model -> ( Model, Cmd Msg )
updateForTesting msg model =
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

## Common Anti-Patterns to Avoid

### 1. Testing Implementation Details

**Avoid**: Testing internal function calls or data structures
```elm
-- Bad: Tests internal implementation
test "updateBoard function is called" <|
    \_ ->
        -- Don't test that internal functions are called
        Expect.fail "Test behavior, not implementation"
```

**Instead**: Test observable behavior
```elm
-- Good: Tests observable behavior
test "making move updates board state" <|
    \_ ->
        let
            initialBoard = emptyBoard
            position = { row = 0, col = 0 }
            updatedBoard = makeMove initialBoard position X
        in
        getCell updatedBoard position
            |> Expect.equal (Just X)
```

### 2. Overly Complex Test Setup

**Avoid**: Complex test setup that obscures what's being tested
```elm
-- Bad: Complex setup
test "complex scenario" <|
    \_ ->
        let
            -- 20 lines of setup code
            complexModel = buildComplexScenario
        in
        -- What are we actually testing?
        someFunction complexModel
            |> Expect.equal expectedResult
```

**Instead**: Simple, focused tests
```elm
-- Good: Clear, focused test
test "robot moves forward when facing north" <|
    \_ ->
        let
            robot = { position = { row = 1, col = 1 }, facing = North }
            newRobot = moveForward robot
        in
        newRobot.position
            |> Expect.equal { row = 0, col = 1 }
```

### 3. Testing Multiple Behaviors in One Test

**Avoid**: Combining unrelated test scenarios
```elm
-- Bad: Multiple behaviors
test "game features work" <|
    \_ ->
        let
            model = initialModel
        in
        Expect.all
            [ \m -> -- Test move validation
            , \m -> -- Test win detection  
            , \m -> -- Test AI behavior
            , \m -> -- Test theme changes
            ] model
```

**Instead**: One behavior per test
```elm
-- Good: Focused tests
test "validates moves correctly" <|
    \_ -> -- Test only move validation

test "detects wins correctly" <|
    \_ -> -- Test only win detection
```

## File References

When writing elm-test unit tests in this project, reference these key files:
- `tests/` - All test files and examples
- `tests/TestUtils/ProgramTestHelpers.elm` - Shared test utilities
- `elm.json` - Test dependencies and configuration
- Existing `*UnitTest.elm` files for patterns and examples

## Key Project Reminders

- **Follow established patterns**: Look at existing unit test files for guidance
- **Test pure functions first**: Start with the easiest and most valuable tests
- **Use fuzz testing**: For property-based testing of mathematical functions and encoders/decoders
- **Mock external dependencies**: Create predictable test scenarios
- **Test edge cases**: Don't just test the happy path
- **Use Test.only for focused testing**: NEVER use `npx elm-test` or command-line filtering
- **Remove Test.only before committing**: elm-review will catch any left in code
- **Code quality**: All tests must pass elm-review and maintain project standards
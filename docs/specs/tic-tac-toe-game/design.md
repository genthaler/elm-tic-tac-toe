# Design Document

## Overview

The tic-tac-toe application is a single-screen Elm program that boots directly into the game. `TicTacToe.Main` is the application entry point, there is no routing layer or app shell, and the UI is rendered with `elm-ui`. The game uses a shared theme module for color scheme state, responsive sizing, and persistence, while web workers keep the normal AI move path off the main thread. A separate inspection path can instrument Negamax or Alpha-Beta search so the user can step through the evaluation tree without changing the fast gameplay path.

## Architecture

### High-Level Architecture

```mermaid
graph TB
    Browser[Browser] --> Main[TicTacToe/Main.elm]
    Main --> Model[TicTacToe/Model.elm]
    Main --> View[TicTacToe/View.elm]
    Main --> Theme[Theme/Theme.elm]
    Main --> Worker[Web Worker]
    Worker --> GameWorker[TicTacToe/GameWorker.elm]
    GameWorker --> AI[GameTheory/AdversarialEager.elm]
    Main --> Logic[TicTacToe/TicTacToe.elm]
    Logic --> AI
    Main --> Trace[TicTacToe/SearchTrace*.elm]
    Trace --> Inspect[Inspection State]
```

### Core Modules

1. **TicTacToe/Main.elm** - Application entry point, handles initialization, updates, subscriptions, worker wiring, theme persistence, and inspection-mode coordination
2. **TicTacToe/Model.elm** - Defines the game model, board state, search-inspection state, status state, viewport state, and serialized theme preference
3. **TicTacToe/View.elm** - Renders the responsive single-screen game interface, tree diagram, explanation panel, and synchronized board annotations with `elm-ui`
4. **TicTacToe/TicTacToe.elm** - Core game logic, move validation, win detection, and round progression
5. **TicTacToe/GameWorker.elm** - Web worker for fast-play AI computations
6. **TicTacToe/SearchTrace*.elm** - Pure trace generation for instrumented Negamax and Alpha-Beta inspection
7. **GameTheory/AdversarialEager.elm** - Negamax-based fast-play AI decision making
8. **Theme/Theme.elm** - Shared color scheme, theme selection, responsive sizing, and JSON encoding/decoding

### Data Flow

```mermaid
sequenceDiagram
    participant User
    participant View
    participant Main
    participant Worker
    participant AI
    participant Trace

    User->>View: Click cell or theme toggle
    View->>Main: Msg
    Main->>Main: Update model
    Main->>View: Re-render
    alt Fast play
        Main->>Worker: Send model for AI move
        Worker->>AI: Calculate best move
        AI->>Worker: Return move
        Worker->>Main: Send result
        Main->>Main: Apply AI move
    else Inspect search
        Main->>Trace: Build instrumented trace
        Trace->>Main: Return trace and best move
        Main->>View: Render trace controls
        User->>View: Step through trace
        View->>Main: Step msg
        Main->>Main: Advance or rewind trace index
    end
    Main->>View: Re-render
```

## Components and Interfaces

### Core Data Types

```elm
type Player
    = X
    | O

type GameState
    = Waiting Player
    | Thinking Player
    | Inspecting SearchAlgorithm
    | Winner Player
    | Draw
    | Error String

type alias Position =
    { row : Int
    , col : Int
    }

type alias Board =
    List (List (Maybe Player))

type alias Model =
    { board : Board
    , gameState : GameState
    , lastMove : Maybe Time.Posix
    , now : Maybe Time.Posix
    , colorScheme : ColorScheme
    , maybeWindow : Maybe ( Int, Int )
    , maybeSearchInspection : Maybe SearchInspectionState
    }

type SearchAlgorithm
    = Negamax
    | AlphaBeta

type alias BranchColor =
    { primary : Color
    , muted : Color
    }

type NodeStatus
    = Unvisited
    | Active
    | Expanded
    | Finalized
    | Pruned

type alias SearchNodeId =
    Int

type alias SearchNode =
    { id : SearchNodeId
    , board : Board
    , player : Player
    , depth : Int
    , moveFromParent : Maybe Position
    , score : Maybe Int
    , alpha : Maybe Int
    , beta : Maybe Int
    , status : NodeStatus
    , children : List SearchNodeId
    }

type SearchEvent
    = EnteredNode SearchNodeId
    | ConsideredMove SearchNodeId Position
    | LeafEvaluated SearchNodeId Int
    | PropagatedScore SearchNodeId Int
    | AlphaUpdated SearchNodeId Int
    | BetaUpdated SearchNodeId Int
    | PrunedBranch SearchNodeId
    | FinalizedNode SearchNodeId

type alias SearchTrace =
    { algorithm : SearchAlgorithm
    , rootNodeId : SearchNodeId
    , nodes : Dict SearchNodeId SearchNode
    , events : List SearchEvent
    , bestMove : Maybe Position
    }

type alias SearchInspectionState =
    { trace : SearchTrace
    , eventIndex : Int
    , committed : Bool
    , selectedNode : Maybe SearchNodeId
    }
```

### Message Types

```elm
type Msg
    = MoveMade Position
    | ResetGame
    | GameError String
    | ColorSchemeChanged ColorScheme
    | GotViewport Browser.Dom.Viewport
    | GotResize Int Int
    | Tick Time.Posix
    | StartInspection SearchAlgorithm
    | StepInspectionBack
    | StepInspectionForward
    | SelectInspectionNode SearchNodeId
    | ApplyInspectionMove
    | AutoPlayComputerMove
```

### Game Logic Interface

The `TicTacToe.TicTacToe` module provides the core game behavior:

- `makeMove : Player -> Board -> Position -> Board`
- `checkWinner : Board -> Maybe GameWon`
- `findBestMove : Player -> Board -> Maybe Position`
- `scoreBoard : Player -> Board -> Int`

The instrumented search trace layer provides a separate pure API for teaching and inspection:

- `buildSearchTrace : SearchAlgorithm -> Board -> Player -> SearchTrace`
- `stepTraceForward : SearchTrace -> Int -> SearchInspectionState`
- `stepTraceBackward : SearchTrace -> Int -> SearchInspectionState`
- `currentInspectionSnapshot : SearchInspectionState -> { node : Maybe SearchNode, event : Maybe SearchEvent }`
- `rootMovePalette : SearchTrace -> Dict Position BranchColor`

### Inspection Layout

The inspection UI should use a three-region teaching layout on larger screens and a stacked layout on smaller screens:

1. **Tree panel** - The primary visualization surface showing the explored decision tree
2. **Board panel** - The main playable tic-tac-toe board with candidate-move annotations
3. **Explanation panel** - Controls, longhand narration, compact formulas, and current node facts

On mobile-sized layouts, the board remains first, the explanation panel remains immediately accessible, and the tree panel becomes stacked or horizontally scrollable rather than being removed.

### Tree Visualization

The tree diagram is the primary inspection surface rather than a secondary debug detail.

- The tree should be shown as a true branching structure
- Root candidate moves should receive stable distinct colors
- Descendants should inherit muted variants of the root color so the branch origin stays visible
- Nodes should show:
  - score
  - move label or compact board identity
  - node status
  - alpha and beta where relevant
- The current node should have a strong active treatment
- Traversed edges should be distinct from queued edges
- Pruned branches should remain visible as faded or dashed ghosts instead of disappearing

### Main Board Synchronization

The board panel remains the user's main point of reference for playable moves.

- Root candidate moves should be annotated directly on the main board
- Candidate annotations should reuse the same stable branch colors used in the tree
- The board should show current candidate scores near the root move positions
- The current best-so-far move should be emphasized distinctly
- Selecting or stepping to a tree node should update a synchronized board representation so the user can connect tree state to game state

### Explanation Panel

The explanation panel should explain both the current action and the algorithmic reason.

- Longhand explanation text should describe the current step in plain language
- A compact formula line should summarize the relevant calculation
- Current node facts should include score, depth, move path, and in alpha-beta mode the current bounds
- The panel should explain pruning explicitly rather than expecting the user to infer it from visuals alone

Recommended sentence patterns:

- "Exploring move top-left for O."
- "Reached terminal position: X wins, so this leaf scores -1 for O."
- "Returned from child center with score 3."
- "Negamax flips the child score, so this branch becomes -3."
- "Updated alpha from -inf to 3."
- "Beta is now less than or equal to alpha, so the remaining siblings are pruned."

### Visual Encoding

To keep the tree readable, the view should not rely on color alone.

- Root branch color identifies the candidate move
- Node status identifies activity:
  - active
  - evaluating
  - finalized
  - pruned
- Pruned branches should use reduced opacity and a non-solid stroke
- Best-so-far root moves should be emphasized in both the tree and board panels
- Alpha and beta values should be visually distinct from the node score itself

### Web Worker Communication

Communication between the main thread and the worker uses JSON encoding:

**Main -> Worker**: Encoded model for fast play only
```elm
encodeModel : Model -> Encode.Value
```

**Inspection path**: Pure trace data
```elm
buildSearchTrace : SearchAlgorithm -> Board -> Player -> SearchTrace
```

## Data Models

### Game Board Representation

The board is represented as a 3x3 grid using nested lists:

```elm
type alias Board =
    List (List (Maybe Player))
```

### Game State Management

Game states follow a clear progression:

- `Waiting Player` - Waiting for human or AI input
- `Thinking Player` - AI is calculating the next move
- `Inspecting SearchAlgorithm` - Search trace, selected node, and explanation state are available for stepping and review
- `Winner Player` - Game ended with a winner
- `Draw` - Game ended in a tie
- `Error String` - Error state with message

### Timeout Handling

The system tracks move timing to implement auto-play:

- `lastMove : Maybe Time.Posix` - Timestamp of the last move
- `now : Maybe Time.Posix` - Current time for calculations
- `idleTimeoutMillis : Int` - 5000ms timeout threshold

## Error Handling

### Error Categories

1. **Game Logic Errors**
   - Invalid moves on occupied cells
   - Moves after game end
   - Malformed positions

2. **Inspection Errors**
   - Trace generation failures
   - Invalid step indices
   - Attempting to apply a move before the trace has been inspected
   - Selected nodes that no longer match the current event position

3. **Communication Errors**
   - JSON encoding and decoding failures
   - Worker communication issues
   - Port message failures

4. **AI Computation Errors**
   - No valid moves found
   - Algorithm failures
   - Timeout issues

### Error Recovery

- Errors are represented in the `Error` game state
- Error messages are displayed to the player
- Reset functionality allows recovery from any error state
- Worker failure degrades gracefully without blocking the interface
- Inspection mode can always fall back to the normal fast-play path

## Testing Strategy

### Unit Testing Approach

1. **Game Logic Testing**
   - Win condition detection for all scenarios
   - Move validation edge cases
   - Board state transitions
   - AI move quality verification
   - Trace generation for Negamax and Alpha-Beta
   - Stepping forward and backward through trace events
   - Alpha/beta bound updates and pruning metadata
   - Root branch color stability and candidate-score annotations
   - Tree node selection and synchronized board-preview behavior
   - Explanation text generation for leaf evaluation, score propagation, and pruning

2. **Model Testing**
   - JSON encoding and decoding round trips
   - State transition validation
   - Message handling correctness

3. **Integration Testing**
   - Full game flow scenarios
   - Worker communication
   - UI interaction flows
   - Inspection mode workflows
   - Applying the final move from an inspected trace
   - Tree, board, and explanation panel staying synchronized through step changes

### Test Structure

Tests are organized in the `tests/` directory:

- `tests/TicTacToe/TicTacToeUnitTest.elm` - Core game logic tests
- `tests/GameTheory/AdversarialEagerUnitTest.elm` - AI algorithm tests
- `tests/TicTacToe/TicTacToeIntegrationTest.elm` - Integration tests for complete game scenarios
- `tests/TicTacToe/ViewUnitTest.elm` - UI rendering tests
- `tests/TicTacToe/ModelUnitTest.elm` - Model and transition tests

### Property-Based Testing

Key properties to test:

- The game always ends in a finite number of moves
- AI never makes invalid moves
- Board state remains consistent after operations
- JSON serialization preserves data integrity

## Performance Considerations

### Web Worker Benefits

- AI calculations run on a separate thread
- UI remains responsive during AI thinking
- User interactions are never blocked by move search
- The implementation stays scalable for future AI improvements
- Instrumented inspection uses a separate pure trace path so the fast-play worker path stays unchanged

### Optimization Strategies

1. **Algorithm Efficiency**
   - Negamax search with pruning support for fast play
   - Early termination for obvious moves
   - Minimal recomputation between turns
   - Deterministic trace generation for teaching and inspection

2. **Memory Management**
   - Immutable data structures prevent memory leaks
   - Elm's garbage collector handles cleanup
   - Minimal state retention between rounds

3. **Rendering Optimization**
   - SVG-based pieces for crisp scaling
   - Efficient `elm-ui` layout composition
   - Responsive layout adapts to viewport changes
   - Inspection controls, tree panel, and explanation panel remain legible on mobile and desktop
   - Tree rendering should keep pruned nodes visible without overwhelming the main board

## Accessibility and Usability

- High-contrast color schemes for light and dark themes
- Clear visual feedback for game states
- Scalable graphics for all screen sizes
- Touch-friendly cell sizes on mobile devices
- Persistent theme preference across reloads
- Pruned branches and active nodes are visually distinct in Alpha-Beta inspection

# Design Document

## Overview

The Robot Grid Game will be implemented as a new game module within the existing Elm application architecture. Following the established patterns from the TicTacToe game, it will integrate seamlessly with the current routing system, theme management, and responsive design framework. The game features a robot that can be controlled on a 5x5 grid using both keyboard and visual controls, with smooth animations and clear visual feedback.

## Architecture

### Integration with Existing App Structure

The robot game will follow the same architectural patterns as the existing TicTacToe game:

- **App.elm**: Extended to include a new `RobotGamePage` route and handle robot game navigation
- **Landing Page**: Updated to include a "Play Robot Game" option alongside the existing TicTacToe game
- **Theme System**: Leverages the existing `ColorScheme` (Light/Dark) theme system
- **Responsive Design**: Uses the existing window size management for responsive layouts

### Module Structure

```
src/RobotGame/
├── Main.elm          # Game initialization and update logic
├── Model.elm         # Core data types and game state
├── View.elm          # UI rendering and visual components
└── RobotGame.elm     # Core game logic and movement validation
```

### State Management

The game will use Elm's Model-View-Update (MVU) architecture:

- **Model**: Contains grid state, robot position, facing direction, and UI state
- **Update**: Handles movement commands, rotation commands, and keyboard input
- **View**: Renders the grid, robot, controls, and animations

## Components and Interfaces

### Core Data Types

```elm
-- Robot position and orientation
type alias Position = { row : Int, col : Int }

type Direction = North | South | East | West

type alias Robot = 
    { position : Position
    , facing : Direction
    }

-- Game state
type alias Model =
    { robot : Robot
    , gridSize : Int  -- Always 5 for this game
    , colorScheme : ColorScheme
    , maybeWindow : Maybe (Int, Int)
    , animationState : AnimationState
    }

-- Animation support for smooth transitions
type AnimationState
    = Idle
    | Moving Position Position  -- from, to
    | Rotating Direction Direction  -- from, to

-- Game messages
type Msg
    = MoveForward
    | RotateLeft
    | RotateRight
    | RotateToDirection Direction
    | KeyPressed String
    | AnimationComplete
    | ColorScheme ColorScheme
```

### Grid System

- **5x5 Grid**: Fixed size grid with coordinates (0,0) to (4,4)
- **Boundary Detection**: Prevents robot from moving outside grid boundaries
- **Visual Representation**: Each cell clearly distinguished with borders and hover states

### Robot Representation

- **Visual Design**: Distinct robot icon with clear directional indicator (arrow or similar)
- **Facing Direction**: Visual arrow or orientation marker showing North/South/East/West
- **Animation**: Smooth transitions for movement and rotation

### Control Interface

#### Keyboard Controls
- **Arrow Up**: Move forward in current facing direction
- **Arrow Left**: Rotate left (counterclockwise)
- **Arrow Right**: Rotate right (clockwise)  
- **Arrow Down**: Rotate to opposite direction (180° turn)

#### Visual Controls
- **Forward Button**: Large, prominent button for forward movement
- **Rotation Buttons**: Four directional buttons (N, S, E, W) or left/right rotation buttons
- **Touch-Friendly**: Appropriately sized for mobile/tablet interaction
- **Visual Feedback**: Button press animations and disabled states

## Data Models

### Position Model
```elm
type alias Position = 
    { row : Int  -- 0 to 4
    , col : Int  -- 0 to 4
    }
```

### Direction Model
```elm
type Direction 
    = North  -- Decreases row (moves up)
    | South  -- Increases row (moves down)  
    | East   -- Increases col (moves right)
    | West   -- Decreases col (moves left)
```

### Robot Model
```elm
type alias Robot =
    { position : Position
    , facing : Direction
    }
```

### Game Model
```elm
type alias Model =
    { robot : Robot
    , gridSize : Int
    , colorScheme : ColorScheme
    , maybeWindow : Maybe (Int, Int)
    , animationState : AnimationState
    , lastMoveTime : Maybe Time.Posix
    }
```

## Error Handling

### Boundary Validation
- **Movement Validation**: Check if forward movement would exceed grid boundaries
- **Visual Feedback**: Show blocked movement with subtle animation or color change
- **State Preservation**: Robot remains in current position when movement is blocked

### Input Validation
- **Keyboard Events**: Filter and validate keyboard input to prevent invalid commands
- **Button States**: Disable forward button when movement is blocked
- **Error Recovery**: All errors are recoverable - game continues normally

### Animation Handling
- **Animation Conflicts**: Prevent new commands during active animations
- **Animation Completion**: Ensure animations complete before accepting new input
- **Fallback States**: Graceful degradation if animations fail

## Testing Strategy

### Unit Tests
- **Movement Logic**: Test forward movement in all directions
- **Rotation Logic**: Test all rotation combinations (left, right, 180°)
- **Boundary Detection**: Test movement blocking at all grid edges
- **Direction Calculations**: Test direction changes for all rotation types

### Integration Tests
- **Keyboard Input**: Test keyboard event handling and command translation
- **Visual Controls**: Test button click handling and state updates
- **Animation System**: Test animation state transitions and completion
- **Theme Integration**: Test appearance in both light and dark themes

### Visual Tests
- **Grid Rendering**: Verify 5x5 grid displays correctly at different screen sizes
- **Robot Visualization**: Verify robot and direction indicator display clearly
- **Control Layout**: Verify controls are accessible and appropriately sized
- **Responsive Design**: Test layout on mobile, tablet, and desktop viewports

### User Experience Tests
- **Control Responsiveness**: Verify immediate feedback for all user actions
- **Animation Smoothness**: Verify smooth transitions for movement and rotation
- **Visual Clarity**: Verify robot position and facing direction are always clear
- **Accessibility**: Verify keyboard navigation and screen reader compatibility

## Implementation Approach

### Phase 1: Core Game Logic
- Implement basic data models (Position, Direction, Robot)
- Create movement and rotation logic with boundary checking
- Build unit tests for core functionality

### Phase 2: Basic UI
- Create 5x5 grid visualization using elm-ui
- Implement robot rendering with direction indicator
- Add basic visual controls (buttons)

### Phase 3: Enhanced Interaction
- Add keyboard event handling
- Implement smooth animations for movement and rotation
- Add visual feedback for blocked movements

### Phase 4: Integration & Polish
- Integrate with existing app routing and theme system
- Add responsive design support
- Implement comprehensive testing
- Polish animations and visual design
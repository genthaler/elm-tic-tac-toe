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
    | ButtonHighlightComplete String  -- For managing selective button highlighting
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
- **Selective Visual Feedback**: Only buttons corresponding to actual state changes are highlighted with animations
  - Forward movement: Only forward button highlighted
  - Rotation actions: Only rotation button and affected direction buttons highlighted
  - Direct direction selection: Only old and new direction buttons highlighted

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
    , highlightedButtons : Set String  -- Track which buttons should be highlighted
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

### Selective Button Highlighting System
- **Highlight Tracking**: Model maintains a set of button IDs that should be highlighted
- **Action-Specific Highlighting**: Different actions trigger highlighting of specific button combinations:
  - Forward movement: Only "forward" button
  - Rotation (left/right): Only the rotation button ("rotate-left" or "rotate-right") plus old and new direction buttons
  - Direct direction selection: Only old and new direction buttons
- **Highlight Duration**: Button highlights persist for a brief animation period then automatically clear
- **Keyboard Integration**: Keyboard actions trigger the same selective highlighting as their button equivalents

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

## elm-animator Integration Architecture

### Animation System Design

The elm-animator integration will replace the current CSS-based transitions with a more sophisticated animation system that provides better control over timing, easing, and state management.

#### Timeline Management

```elm
-- Enhanced Model with elm-animator timelines
type alias Model =
    { robot : Robot
    , gridSize : Int
    , colorScheme : ColorScheme
    , maybeWindow : Maybe (Int, Int)
    , animationState : AnimationState
    , lastMoveTime : Maybe Time.Posix
    , highlightedButtons : Set String
    -- elm-animator timelines
    , robotTimeline : Animator.Timeline Robot
    , buttonHighlightTimeline : Animator.Timeline (Set String)
    , blockedMovementTimeline : Animator.Timeline Bool
    }

-- Animation-aware robot state
type alias AnimatedRobot =
    { position : Animator.Timeline Position
    , facing : Animator.Timeline Direction
    }
```

#### Animation Types and Durations

- **Robot Movement**: 300ms with ease-out easing for natural deceleration
- **Robot Rotation**: 200ms with ease-in-out easing for smooth direction changes
- **Button Highlights**: 150ms with ease-out easing for responsive feedback
- **Blocked Movement**: 200ms bounce/shake effect with custom easing curve

#### Timeline Coordination

```elm
-- Animation coordination messages
type Msg
    = MoveForward
    | RotateLeft
    | RotateRight
    | RotateToDirection Direction
    | KeyPressed String
    | ColorScheme ColorScheme
    -- elm-animator messages
    | Tick Time.Posix
    | AnimationFrame Time.Posix
    | StartMovementAnimation Position Position
    | StartRotationAnimation Direction Direction
    | StartButtonHighlight (Set String)
    | StartBlockedMovementFeedback
```

### Animation State Management

#### Robot Position Animation

```elm
-- Animate robot movement between grid cells
animateMovement : Position -> Position -> Model -> Model
animateMovement fromPos toPos model =
    { model
        | robotTimeline = 
            model.robotTimeline
                |> Animator.go (Animator.ms 300) 
                    { position = toPos, facing = model.robot.facing }
                |> Animator.with (Animator.easeOut)
    }
```

#### Robot Rotation Animation

```elm
-- Animate robot rotation with smooth directional transitions
animateRotation : Direction -> Direction -> Model -> Model
animateRotation fromDir toDir model =
    { model
        | robotTimeline = 
            model.robotTimeline
                |> Animator.go (Animator.ms 200)
                    { position = model.robot.position, facing = toDir }
                |> Animator.with (Animator.easeInOut)
    }
```

#### Button Highlight Animation

```elm
-- Animate selective button highlighting
animateButtonHighlight : Set String -> Model -> Model
animateButtonHighlight buttonIds model =
    { model
        | buttonHighlightTimeline =
            model.buttonHighlightTimeline
                |> Animator.go (Animator.ms 150) buttonIds
                |> Animator.with (Animator.easeOut)
    }
```

### View Integration

#### Animated Robot Rendering

```elm
-- Render robot with elm-animator interpolated values
viewAnimatedRobot : Model -> Element Main.Msg
viewAnimatedRobot model =
    let
        currentRobot = Animator.current model.robotTimeline
        
        -- Interpolate position for smooth movement
        animatedPosition = 
            if Animator.isRunning model.robotTimeline then
                Animator.linear model.robotTimeline .position
            else
                currentRobot.position
                
        -- Interpolate rotation for smooth direction changes
        animatedFacing =
            if Animator.isRunning model.robotTimeline then
                Animator.linear model.robotTimeline .facing
            else
                currentRobot.facing
    in
    viewRobotAtPosition animatedPosition animatedFacing model
```

#### Animated Button Highlights

```elm
-- Render buttons with elm-animator controlled highlights
viewAnimatedButton : String -> Model -> Element Main.Msg
viewAnimatedButton buttonId model =
    let
        isHighlighted = 
            Animator.current model.buttonHighlightTimeline
                |> Set.member buttonId
                
        highlightOpacity =
            if isHighlighted then
                Animator.linear model.buttonHighlightTimeline 
                    (\highlights -> if Set.member buttonId highlights then 1.0 else 0.0)
            else
                0.0
    in
    viewButtonWithHighlight buttonId highlightOpacity model
```

### Animation Utilities

#### Reusable Animation Functions

```elm
-- Utility module for common animation patterns
module RobotGame.Animation exposing
    ( startMovementAnimation
    , startRotationAnimation
    , startButtonHighlightAnimation
    , startBlockedMovementAnimation
    , isAnimating
    , getCurrentAnimatedState
    )

-- Check if any animations are currently running
isAnimating : Model -> Bool
isAnimating model =
    Animator.isRunning model.robotTimeline ||
    Animator.isRunning model.buttonHighlightTimeline ||
    Animator.isRunning model.blockedMovementTimeline

-- Get current interpolated robot state
getCurrentAnimatedState : Model -> Robot
getCurrentAnimatedState model =
    if Animator.isRunning model.robotTimeline then
        { position = Animator.linear model.robotTimeline .position
        , facing = Animator.linear model.robotTimeline .facing
        }
    else
        Animator.current model.robotTimeline
```

### Performance Considerations

#### Efficient Timeline Updates

- **Selective Updates**: Only update timelines that are actively animating
- **Frame Rate Management**: Use `AnimationFrame` subscription for smooth 60fps updates
- **Memory Management**: Clean up completed timelines to prevent memory leaks

#### Animation Optimization

```elm
-- Optimized update function that only processes active animations
updateAnimations : Time.Posix -> Model -> Model
updateAnimations time model =
    { model
        | robotTimeline = 
            if Animator.isRunning model.robotTimeline then
                Animator.update time model.robotTimeline
            else
                model.robotTimeline
        , buttonHighlightTimeline =
            if Animator.isRunning model.buttonHighlightTimeline then
                Animator.update time model.buttonHighlightTimeline
            else
                model.buttonHighlightTimeline
        , blockedMovementTimeline =
            if Animator.isRunning model.blockedMovementTimeline then
                Animator.update time model.blockedMovementTimeline
            else
                model.blockedMovementTimeline
    }
```

### Testing Strategy for elm-animator

#### Animation State Testing

```elm
-- Test animation state transitions
testAnimationStates : Test
testAnimationStates =
    describe "Animation state management"
        [ test "robot movement animation starts correctly" <|
            \_ ->
                let
                    initialModel = initModel
                    fromPos = { row = 0, col = 0 }
                    toPos = { row = 0, col = 1 }
                    updatedModel = animateMovement fromPos toPos initialModel
                in
                Expect.true "Animation should be running"
                    (Animator.isRunning updatedModel.robotTimeline)
        ]
```

#### Timeline Completion Testing

```elm
-- Test that animations complete with correct final states
testAnimationCompletion : Test
testAnimationCompletion =
    describe "Animation completion"
        [ test "robot reaches target position after movement animation" <|
            \_ ->
                let
                    targetPos = { row = 1, col = 1 }
                    -- Simulate animation completion
                    finalModel = completeAllAnimations initialModel
                in
                Expect.equal targetPos finalModel.robot.position
        ]
```

### Migration Strategy

#### Gradual Replacement

1. **Phase 1**: Add elm-animator dependency and basic timeline setup
2. **Phase 2**: Replace robot movement animations with elm-animator
3. **Phase 3**: Replace robot rotation animations with elm-animator
4. **Phase 4**: Replace button highlight animations with elm-animator
5. **Phase 5**: Remove CSS transition dependencies

#### Fallback Mechanism

```elm
-- Graceful fallback for animation failures
updateWithAnimationFallback : Msg -> Model -> (Model, Cmd Msg)
updateWithAnimationFallback msg model =
    case msg of
        MoveForward ->
            if canUseAnimations model then
                -- Use elm-animator
                ( animateMovement model.robot.position newPosition model
                , Cmd.none
                )
            else
                -- Fallback to immediate state change
                ( { model | robot = { robot | position = newPosition } }
                , Cmd.none
                )
```

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

### Phase 5: elm-animator Integration
- Add elm-animator dependency to project
- Implement timeline-based animation system
- Replace CSS transitions with elm-animator animations
- Add comprehensive animation testing
- Optimize performance and ensure graceful fallbacks
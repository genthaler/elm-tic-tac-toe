---
inclusion: fileMatch
fileMatchPattern: '*.elm'
---

# Robot Game Animation Utilities

The `RobotGame.Animation` module provides reusable animation functions and utilities for managing elm-animator timelines, preventing conflicting animations, and coordinating animation state across the robot game.

## Overview

This module was created as part of task 21 to provide:

- **Animation state checking functions** - Check if animations are running
- **Animation control functions** - Start different types of animations
- **Timeline management utilities** - Efficiently update elm-animator timelines
- **Interpolation utilities** - Get current interpolated values during animations
- **Helper functions** - Convert between directions and angles
- **Animation coordination logic** - Prevent conflicting animations

## Key Functions

### Animation State Checking

```elm
-- Check if any animations are currently running
isAnimating : Model -> Bool

-- Get current interpolated robot state from timelines
getCurrentAnimatedState : Model -> Robot
```

### Animation Control

```elm
-- Start movement animation between positions
startMovementAnimation : Position -> Position -> Model -> Model

-- Start rotation animation between directions  
startRotationAnimation : Direction -> Direction -> Model -> Model

-- Start button highlight animation for specific buttons
startButtonHighlightAnimation : List Button -> Model -> Model

-- Start blocked movement animation with bounce/shake effect
startBlockedMovementAnimation : Model -> Model
```

### Timeline Management

```elm
-- Update all elm-animator timelines efficiently
updateAnimations : Time.Posix -> Model -> Model
```

### Interpolation Utilities

```elm
-- Get interpolated position during movement animations
getInterpolatedPosition : Model -> Position

-- Get interpolated rotation angle during rotation animations
getInterpolatedRotationAngle : Model -> Float

-- Get button highlight opacity for specific button
getButtonHighlightOpacity : String -> Model -> Float

-- Check if blocked movement animation is active
isBlockedMovementAnimating : Model -> Bool
```

## Animation Configuration

The module includes a configurable animation system:

```elm
type alias AnimationConfig =
    { movementDuration : Float -- 300ms with ease-out easing
    , rotationDuration : Float -- 200ms with ease-in-out easing  
    , buttonHighlightDuration : Float -- 150ms with ease-out easing
    , blockedMovementDuration : Float -- 200ms bounce/shake effect
    }

-- Default configuration matching design requirements
defaultAnimationConfig : AnimationConfig
```

## Usage Examples

### Checking Animation State

```elm
-- Prevent input during animations
if Animation.isAnimating model then
    -- Animation in progress - ignore input
    ( model, NoEffect )
else
    -- Process user input
    handleUserInput model
```

### Starting Animations

```elm
-- Start movement animation
updatedModel = 
    Animation.startMovementAnimation fromPos toPos model

-- Start rotation animation  
updatedModel =
    Animation.startRotationAnimation fromDir toDir model

-- Start button highlights
updatedModel =
    Animation.startButtonHighlightAnimation [ForwardButton] model
```

### Timeline Updates

```elm
-- In AnimationFrame message handler
AnimationFrame time ->
    ( Animation.updateAnimations time model, NoEffect )
```

### Getting Interpolated Values

```elm
-- Get current robot position during movement
currentPos = Animation.getInterpolatedPosition model

-- Get current rotation angle during rotation
currentAngle = Animation.getInterpolatedRotationAngle model

-- Get button highlight opacity
opacity = Animation.getButtonHighlightOpacity "forward" model
```

## Integration with Existing Code

The Animation module is designed to work alongside the existing robot game implementation:

- **Compatible with existing Model types** - Uses the same Model, Position, Direction, etc.
- **Works with elm-animator timelines** - Leverages existing timeline infrastructure
- **Maintains animation state consistency** - Uses the same AnimationState approach
- **Provides reusable utilities** - Can be used by Main.elm and View.elm

## Testing

The module includes comprehensive unit tests and integration tests:

- **Unit tests** (`tests/RobotGame/AnimationUnitTest.elm`) - Test individual functions
- **Integration tests** (`tests/RobotGame/AnimationIntegrationTest.elm`) - Test with Main module

## Requirements Satisfied

This implementation satisfies the following requirements from the design document:

- **12.1** - Clear separation between animation logic and game logic
- **12.2** - Consistent patterns for timeline management and state updates  
- **12.3** - Reusable animation utilities for other game modules
- **12.4** - Clear state information about active timelines and animation progress
- **14.4** - Efficient timeline update functions that only process active animations

## Future Enhancements

The Animation module provides a foundation for future animation features:

- **Animation queuing** - Queue multiple animations to run in sequence
- **Custom easing functions** - Add more sophisticated easing curves
- **Animation events** - Trigger events at specific animation milestones
- **Performance monitoring** - Track animation performance and optimization
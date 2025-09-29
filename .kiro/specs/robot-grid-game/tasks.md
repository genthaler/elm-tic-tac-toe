# Implementation Plan

- [x] 1. Set up core data models and types
  - Create `src/RobotGame/Model.elm` with Position, Direction, Robot, and Model types
  - Implement JSON encoding/decoding functions for state persistence
  - Write unit tests for data model validation and transformations
  - _Requirements: 1.1, 1.3_

- [x] 2. Implement core game logic and movement validation
  - Create `src/RobotGame/RobotGame.elm` with movement and rotation functions
  - Implement boundary checking to prevent robot from moving outside 5x5 grid
  - Create direction calculation functions for left/right/opposite rotations
  - Write comprehensive unit tests for all movement and rotation scenarios
  - _Requirements: 2.1, 2.2, 3.1, 3.3_

- [x] 3. Create basic grid visualization and robot rendering
  - Create `src/RobotGame/View.elm` with 5x5 grid rendering using elm-ui
  - Implement robot visualization with clear directional indicator (arrow or similar)
  - Create theme-aware styling that integrates with existing ColorScheme system
  - Write visual tests to verify grid and robot display correctly
  - _Requirements: 1.1, 1.2, 1.3, 6.1, 6.2_

- [x] 4. Implement game initialization and update logic
  - Create `src/RobotGame/Main.elm` with init, update, and subscriptions functions
  - Implement message handling for MoveForward, RotateLeft, RotateRight, and RotateToDirection
  - Add proper state management for robot position and facing direction updates
  - Write integration tests for game state transitions
  - _Requirements: 2.1, 2.3, 3.1, 3.2_

- [x] 5. Add visual control buttons for movement and rotation
  - Implement forward movement button in View.elm with proper styling and accessibility
  - Create rotation control buttons (left, right, and directional buttons)
  - Add button state management (enabled/disabled based on movement validity)
  - Implement touch-friendly button sizing and hover/press visual feedback
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 6. Implement keyboard input handling
  - Add keyboard event subscriptions in Main.elm for arrow key detection
  - Map arrow keys to appropriate game actions (up=forward, left/right=rotate, down=opposite)
  - Implement key event filtering to handle only relevant keyboard input
  - Write tests for keyboard input translation to game messages
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 7. Add movement validation and visual feedback for blocked actions
  - Implement boundary checking in update function to prevent invalid moves
  - Add visual feedback when robot cannot move forward (button disabled state, subtle animation)
  - Ensure robot position and facing direction remain unchanged for blocked movements
  - Create visual indicators for blocked movement attempts
  - _Requirements: 2.2, 6.4_

- [x] 8. Implement smooth animations for movement and rotation
  - Add AnimationState type and animation management to Model.elm
  - Create smooth transition animations for robot movement between grid cells
  - Implement rotation animations with visual direction indicator changes
  - Add animation completion handling to prevent input during transitions
  - _Requirements: 6.3, 6.5_

- [x] 9. Integrate robot game with main application routing
  - Update `src/App.elm` to include RobotGamePage in Page type
  - Add navigation messages and routing logic for robot game
  - Implement robot game model management in main app state
  - Add robot game message handling in main app update function
  - _Requirements: 1.1_

- [x] 10. Update landing page to include robot game option
  - Modify `src/Landing/Landing.elm` to add PlayRobotGameClicked message
  - Update `src/Landing/LandingView.elm` to display robot game navigation button
  - Implement navigation from landing page to robot game
  - Style robot game button consistently with existing landing page design
  - _Requirements: 1.1_

- [x] 11. Add responsive design and theme integration
  - Implement responsive grid sizing based on window dimensions in View.elm
  - Integrate robot game with existing ColorScheme theme system
  - Add proper theme-aware colors for grid, robot, and controls
  - Test robot game appearance in both light and dark themes
  - _Requirements: 6.1, 6.2, 6.5_

- [x] 12. Create comprehensive test suite
  - Write unit tests for all core game logic functions in RobotGame.elm
  - Create integration tests for complete user interaction flows
  - Add visual regression tests for grid and robot rendering
  - Implement keyboard input testing for all control scenarios
  - _Requirements: 2.1, 2.2, 3.1, 3.2, 4.1, 4.2, 4.3, 4.4, 5.2, 5.3_

- [x] 13. Polish user experience and accessibility
  - Add proper ARIA labels and keyboard navigation support for visual controls
  - Implement smooth visual transitions and hover states for all interactive elements
  - Add visual feedback for successful moves and blocked attempts
  - Ensure consistent visual design with existing application components
  - _Requirements: 5.4, 5.5, 6.3, 6.4, 6.5_

- [x] 14. Implement comprehensive elm-program-test integration tests for user input workflows
  - Replace placeholder test in `tests/RobotGame/UserInputIntegrationTest.elm` with comprehensive integration tests
  - Create elm-program-test scenarios for button click workflows (forward, rotate left/right, directional buttons)
  - Implement elm-program-test scenarios for keyboard input workflows (arrow keys, rapid input, invalid keys)
  - Add elm-program-test scenarios for mixed input method workflows (keyboard + buttons, input method switching)
  - Create elm-program-test scenarios for user interface feedback workflows (visual feedback, error messages, accessibility)
  - Implement elm-program-test scenarios for complete user journey workflows (corner-to-corner navigation, boundary exploration)
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 15. Implement selective button highlighting system
  - Add `highlightedButtons` field to Model type to track which buttons should be highlighted
  - Implement `ButtonHighlightComplete` message handling for managing highlight duration
  - Create helper functions to determine which buttons should be highlighted for each action type
  - Update View.elm to apply highlight styling only to buttons in the highlightedButtons set
  - Add animation timing for button highlights with automatic clearing after brief duration
  - Update all action handlers (MoveForward, RotateLeft, RotateRight, RotateToDirection) to set appropriate button highlights
  - Ensure keyboard actions trigger the same selective highlighting as their button equivalents
  - Write unit tests for highlight logic and integration tests for visual feedback behavior
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 16. Add elm-animator dependency and basic timeline setup
  - Add mdgriffith/elm-animator package to elm.json dependencies
  - Update Model.elm to include elm-animator Timeline types for robot position, rotation, and button highlights
  - Add Tick and AnimationFrame message types to handle elm-animator updates
  - Implement basic timeline initialization in init function
  - Add AnimationFrame subscription to Main.elm for smooth animation updates
  - Write unit tests for timeline initialization and basic animation state management
  - _Requirements: 9.1, 9.5, 12.1, 13.1_

- [ ] 17. Implement robot movement animation with elm-animator
  - Replace CSS-based movement transitions with elm-animator timeline animations
  - Create animateMovement function that uses elm-animator to smoothly transition robot position
  - Implement 300ms movement duration with ease-out easing for natural deceleration
  - Update View.elm to render robot at interpolated positions during movement animations
  - Add animation state checking to prevent input during active movement animations
  - Write unit tests for movement animation state transitions and integration tests for smooth visual movement
  - _Requirements: 9.1, 10.1, 11.1, 13.4_

- [ ] 18. Implement robot rotation animation with elm-animator
  - Replace CSS-based rotation transitions with elm-animator timeline animations for robot direction changes
  - Create animateRotation function that uses elm-animator to smoothly transition robot facing direction
  - Implement 200ms rotation duration with ease-in-out easing for smooth direction changes
  - Update robot SVG rendering to use interpolated rotation angles during rotation animations
  - Ensure rotation animations maintain robot position while smoothly changing directional indicator
  - Write unit tests for rotation animation logic and integration tests for visual rotation smoothness
  - _Requirements: 9.2, 10.2, 11.2, 13.4_

- [ ] 19. Implement button highlight animation with elm-animator
  - Replace CSS-based button highlight transitions with elm-animator timeline animations
  - Create animateButtonHighlight function that manages selective button highlighting using timelines
  - Implement 150ms highlight duration with ease-out easing for responsive visual feedback
  - Update View.elm button rendering to use elm-animator interpolated highlight opacity values
  - Maintain existing selective highlighting logic (forward button, rotation buttons, direction buttons)
  - Write unit tests for button highlight animation state and integration tests for visual feedback consistency
  - _Requirements: 9.3, 10.3, 11.3, 13.4_

- [ ] 20. Implement blocked movement animation with elm-animator
  - Create blocked movement animation using elm-animator for subtle bounce/shake effect
  - Implement 200ms blocked movement feedback with custom easing curve for clear visual indication
  - Replace existing blocked movement visual feedback with elm-animator controlled animations
  - Add timeline management for blocked movement state to prevent animation conflicts
  - Ensure blocked movement animations provide clear feedback without disrupting game flow
  - Write unit tests for blocked movement animation logic and integration tests for user feedback clarity
  - _Requirements: 10.4, 11.1, 13.2, 13.4_

- [ ] 21. Create reusable animation utilities and state management
  - Create RobotGame.Animation module with reusable animation functions and utilities
  - Implement isAnimating function to check if any animations are currently running
  - Create getCurrentAnimatedState function to get current interpolated robot state
  - Add animation coordination logic to prevent conflicting animations and manage animation queues
  - Implement efficient timeline update functions that only process active animations
  - Write comprehensive unit tests for animation utilities and state management functions
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 14.4_

- [ ] 22. Remove CSS transition dependencies and optimize performance
  - Remove minimalTransitionCSS and all CSS-based animation classes from View.elm
  - Optimize animation frame updates to only process active timelines for better performance
  - Implement memory management for completed timelines to prevent memory leaks
  - Add graceful fallback mechanism for animation failures that preserves game functionality
  - Ensure animation system doesn't introduce performance regressions compared to CSS transitions
  - Write performance tests and regression tests to verify animation system efficiency
  - _Requirements: 13.1, 13.3, 14.4, 14.5_

- [ ] 23. Implement comprehensive elm-animator testing suite
  - Write unit tests for all animation state transitions and timeline management functions
  - Create integration tests for complete user workflows with elm-animator animations
  - Implement deterministic animation testing that doesn't depend on real-time behavior
  - Add animation completion tests that verify correct final states after animations finish
  - Create performance tests to ensure animations don't negatively impact game responsiveness
  - Write regression tests to verify all existing functionality works with new animation system
  - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5_

- [-] 24. Set up elm-program-test infrastructure and basic button click tests
  - [ ] 24.1 Set up elm-program-test infrastructure and basic button click tests
    - Create `tests/RobotGame/UserInputIntegrationTest.elm` with elm-program-test setup
    - Implement basic button click workflow tests (forward button functionality)
    - Add rotation button tests (rotate left and rotate right buttons)
    - Create directional button tests (North, South, East, West buttons)
    - Write helper functions for common test operations (robot positioning, button clicking)
    - _Requirements: 8.1, 8.2_

  - [ ] 24.2. Implement keyboard input integration tests
    - Create keyboard input workflow tests (arrow key handling)
    - Add rapid input sequence tests (multiple quick key presses)
    - Implement invalid key handling tests (non-arrow keys)
    - Test keyboard input state management and event filtering
    - _Requirements: 8.2, 8.3_

  - [ ] 24.3. Create mixed input method workflow tests
    - Add tests for switching between keyboard and button inputs seamlessly
    - Implement tests for simultaneous input method usage
    - Create tests for input method priority and conflict resolution
    - Test input method state consistency across different interaction types
    - _Requirements: 8.3, 8.4_

  - [ ] 24.4. Implement user interface feedback and visual verification tests
    - Create tests for visual feedback verification (button highlights, robot position updates)
    - Add tests for error message display and blocked movement feedback
    - Implement tests for animation state verification during user interactions
    - Test accessibility features (ARIA labels, keyboard navigation support)
    - _Requirements: 8.4, 8.5_

  - [ ] 24.5. Create complete user journey and boundary exploration tests
    - Implement corner-to-corner navigation workflow tests
    - Add boundary exploration scenario tests (edge movement, corner positioning)
    - Create comprehensive user journey tests (complex movement sequences)
    - Test animation integration with user input (input during animations, completion verification)
    - _Requirements: 8.1, 8.5_

- [ ] 25. Refactor animation logic distribution for better separation of concerns
  - Move animation helper functions from Main.elm to RobotGame.Animation module
  - Refactor `animateButtonHighlight`, `directionToAngleFloat`, `calculateShortestRotationPath` functions to Animation module
  - Update Main.elm to use Animation module functions instead of local implementations
  - Create animation workflow functions in Animation module (startMovementWorkflow, startRotationWorkflow)
  - Implement animation state management functions that encapsulate timeline coordination
  - Update Main.elm update handlers to use Animation module workflow functions
  - Write unit tests for refactored animation functions to ensure no regression
  - Verify that animation behavior remains identical after refactoring
  - _Requirements: 12.1, 12.2, 12.3_

- [ ] 26. Implement deterministic animation testing framework
  - Create test utilities for deterministic animation testing without time dependencies
  - Implement mock timeline functions that simulate animation completion instantly
  - Create animation state verification helpers for testing animation transitions
  - Add performance benchmarking utilities for animation system efficiency testing
  - Implement regression testing framework for animation behavior consistency
  - Create test scenarios for animation failure handling and graceful fallbacks
  - Write comprehensive test coverage for all animation utilities and state management
  - Add integration tests that verify animation system doesn't negatively impact game responsiveness
  - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5_

- [ ] 27. Enhance selective button highlighting verification and testing
  - Create comprehensive unit tests for selective button highlighting logic
  - Implement integration tests that verify correct buttons are highlighted for each action type
  - Add visual regression tests for button highlight animations using elm-program-test
  - Create test scenarios for keyboard input triggering correct button highlights
  - Implement tests for highlight timing and automatic clearing behavior
  - Add accessibility tests for button highlight visibility and screen reader compatibility
  - Create performance tests to ensure highlighting doesn't impact animation smoothness
  - Write edge case tests for rapid input and highlight state management
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_
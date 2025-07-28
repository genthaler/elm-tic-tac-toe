# Implementation Plan

- [x] 1. Set up core game data structures and types
  - Create foundational data types for Player, Position, Board, and GameState
  - Implement JSON encoding/decoding functions for all core types
  - Write unit tests for data type serialization and deserialization
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 2. Implement basic game board logic
  - [x] 2.1 Create board initialization and cell management functions
    - Write functions to create empty 3x3 board
    - Implement cell state checking (empty, occupied by X, occupied by O)
    - Create position validation functions for row/column bounds
    - Write unit tests for board creation and cell access
    - _Requirements: 1.1, 1.4_

  - [x] 2.2 Implement move validation and application
    - Write function to validate moves (cell must be empty, game not ended)
    - Create function to apply valid moves to board state
    - Implement player turn switching logic
    - Write comprehensive unit tests for move validation edge cases
    - _Requirements: 1.4, 1.5, 1.6_

- [x] 3. Implement win detection and game ending logic
  - [x] 3.1 Create win condition checking functions
    - Write functions to check horizontal, vertical, and diagonal lines
    - Implement winner detection for both X and O players
    - Create draw detection when board is full with no winner
    - Write unit tests covering all possible win scenarios
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

  - [x] 3.2 Implement game state management
    - Create functions to transition between game states (Waiting, Winner, Draw)
    - Implement game ending prevention (no moves after game ends)
    - Write functions to generate appropriate status messages
    - Write unit tests for state transitions and game ending
    - _Requirements: 3.5, 3.6_

- [x] 4. Implement AI opponent using negamax algorithm
  - [x] 4.1 Create board evaluation and scoring functions
    - Write heuristic function to score board positions for each player
    - Implement line scoring logic (favor lines with player pieces)
    - Create terminal position detection (game over states)
    - Write unit tests for scoring accuracy and consistency
    - _Requirements: 2.1, 2.5_

  - [x] 4.2 Implement AI move selection algorithm
    - Integrate negamax algorithm for optimal move calculation
    - Create function to find best available move for AI player
    - Implement move generation for available positions
    - Write unit tests to verify AI makes valid and reasonable moves
    - _Requirements: 2.1, 2.2, 2.4_

- [x] 5. Create web worker for AI computations

  - [x] 5.1 Implement GameWorker module for background processing
    - Create worker initialization and message handling
    - Implement model decoding and move encoding for worker communication
    - Create AI move calculation workflow in worker context
    - Write integration tests for worker communication
    - _Requirements: 2.2, 2.3, 8.3, 8.4_

  - [x] 5.2 Integrate worker communication with main application
    - Set up ports for sending models to worker and receiving moves
    - Implement worker message subscriptions in main application
    - Create error handling for worker communication failures
    - Write tests for complete main-to-worker-to-main flow
    - _Requirements: 2.2, 2.3, 8.3_

- [x] 6. Implement user interface and visual components
  - [x] 6.1 Create game board rendering with elm-ui
    - Write functions to render 3x3 grid layout with proper spacing
    - Implement cell rendering with click handlers for empty cells
    - Create SVG-based X and O symbols for visual appeal
    - Write UI tests for board layout and cell interactions
    - _Requirements: 1.1, 1.4, 8.5_

  - [x] 6.2 Implement game status display and controls
    - Create status message display for current player turn and game results
    - Implement reset button with game state clearing functionality
    - Add color scheme toggle button for light/dark theme switching
    - Write UI tests for status updates and control interactions
    - _Requirements: 4.1, 4.2, 4.3, 5.1, 5.2, 5.3, 6.1, 6.2_

- [x] 7. Implement timeout and auto-play functionality
  - [x] 7.1 Create timer system for idle timeout detection
    - Implement time tracking for last move and current time
    - Create countdown timer visual component
    - Write timeout detection logic (5 second threshold)
    - Write unit tests for time calculations and timeout detection
    - _Requirements: 7.1, 7.2_

  - [x] 7.2 Implement auto-play when timeout occurs
    - Create automatic move triggering when timer expires
    - Implement best move selection for timed-out human player
    - Ensure normal game flow continues after auto-move
    - Write integration tests for complete timeout and auto-play flow
    - _Requirements: 7.2, 7.3, 7.4, 7.5_

 v - [x] 8. Implement responsive design and theme system
  - [x] 8.1 Create color scheme and theming system
    - Define light and dark theme color palettes
    - Implement theme application to all UI components
    - Create theme persistence and initialization
    - Write tests for theme switching and color consistency
    - _Requirements: 6.3, 6.4, 6.5_

  - [x] 8.2 Implement responsive layout and viewport handling
    - Create viewport size detection and tracking
    - Implement responsive cell sizing and layout adjustments
    - Add window resize event handling
    - Write tests for layout adaptation to different screen sizes
    - _Requirements: 8.1, 8.2, 8.5_

- [x] 9. Implement comprehensive error handling
  - [x] 9.1 Create error state management and display
    - Implement error message capture and display system
    - Create error recovery through reset functionality
    - Add graceful handling of invalid moves and game states
    - Write unit tests for error scenarios and recovery
    - _Requirements: 5.5, 4.4_

  - [x] 9.2 Add robust JSON communication error handling
    - Implement error handling for encoding/decoding failures
    - Create fallback behavior for worker communication errors
    - Add validation for all incoming messages and data
    - Write integration tests for error scenarios and recovery
    - _Requirements: 2.5, 8.4_

- [x] 10. Create comprehensive test suite
  - [x] 10.1 Write unit tests for all game logic functions
    - Create tests for move validation, win detection, and state management
    - Write tests for AI algorithm correctness and move quality
    - Implement tests for JSON serialization and data integrity
    - Add property-based tests for game invariants
    - _Requirements: All requirements validation_

  - [x] 10.2 Write integration tests for complete game flows
    - Create end-to-end tests for human vs AI game scenarios
    - Write tests for timeout and auto-play functionality
    - Implement tests for theme switching and responsive behavior
    - Add tests for error handling and recovery scenarios
    - _Requirements: All requirements validation_

- [x] 11. Create component style guide with elm-book
  - [x] 11.1 Set up elm-book infrastructure and basic chapters
    - Install elm-book dependency and configure build system
    - Create Book.elm module with basic elm-book setup
    - Implement stateful component integration with game model
    - Add npm script for running the style guide server
    - _Requirements: 9.1, 9.6_

  - [x] 11.2 Implement component showcase chapters
    - Create chapter for player symbols (X and O) as SVG and string representations
    - Implement individual cell component showcase with different states
    - Add complete game interface chapter with interactive functionality
    - Create theme elements chapter demonstrating color schemes
    - _Requirements: 9.2, 9.3, 9.4, 9.5_

  - [x] 11.3 Add interactive features and state management
    - Implement stateful component updates with game logic integration
    - Add timer subscriptions for live component updates
    - Create dark/light mode synchronization with elm-book
    - Write component interaction handlers and state mappers
    - _Requirements: 9.6, 9.7_

- [x] 12. Optimize performance and finalize implementation
  - [x] 12.1 Optimize AI algorithm performance
    - Fine-tune search depth and algorithm parameters
    - Implement move ordering for better alpha-beta pruning
    - Add performance monitoring and optimization
    - Write performance tests and benchmarks
    - _Requirements: 2.1, 8.3, 8.4_

  - [x] 12.2 Final integration and polish
    - Integrate all components into cohesive application
    - Perform final testing of all features and edge cases
    - Optimize bundle size and loading performance
    - Add final documentation and code comments
    - _Requirements: All requirements final validation_
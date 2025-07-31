# Implementation Plan

- [x] 1. Create core landing page data structures and types
  - Define Page type with LandingPage, GamePage, and StyleGuidePage variants
  - Create AppModel type that includes currentPage, colorScheme, gameModel, and landingModel
  - Define AppMsg type for navigation and component messages
  - Create Landing.Model type for landing page specific state
  - _Requirements: 1.1, 1.4, 4.3_

- [x] 2. Implement landing page view components
  - Create LandingView.elm module with landing page UI components
  - Implement responsive landing page layout using existing theme system
  - Create navigation buttons for "Play Game" and "View Style Guide" options
  - Add theme toggle button using existing icon components
  - Ensure responsive design works on mobile, tablet, and desktop
  - _Requirements: 1.2, 1.3, 1.5, 4.1_

- [x] 3. Create landing page logic module
  - Implement Landing.elm module with update function and message handling
  - Handle PlayGameClicked, ViewStyleGuideClicked, and ColorSchemeToggled messages
  - Implement window resize handling for responsive design
  - Create init function for landing page initial state
  - _Requirements: 2.1, 3.1, 4.2_

- [x] 4. Implement main application routing and navigation
  - Create LandingMain.elm as the new application entry point
  - Implement page navigation logic with NavigateToGame, NavigateToStyleGuide, and NavigateToLanding messages
  - Handle message routing between landing page, game, and style guide components
  - Implement state preservation for game model when navigating away
  - _Requirements: 2.1, 2.3, 3.1, 3.3_

- [x] 5. Integrate theme system across all views
  - Import and reuse theme definitions from existing TicTacToe/View.elm module
  - Implement theme persistence across page navigation
  - Ensure ColorSchemeChanged message updates all relevant components
  - Maintain theme consistency between landing page, game, and style guide
  - _Requirements: 1.4, 2.4, 3.4, 4.2, 4.3_

- [x] 6. Update build configuration and entry points
  - Modify src/index.html to import Landing/LandingMain.elm instead of TicTacToe/Main.elm
  - Update index.js to initialize the new main application
  - Ensure existing build scripts (build, serve, parcel) work with new entry point
  - Verify elm-book integration continues to work for style guide access
  - _Requirements: 5.1, 5.2, 5.3_

- [x] 7. Implement navigation back to landing page from other views
  - Add "Back to Home" or similar navigation option in game interface
  - Add "Back to Home" or similar navigation option in style guide interface
  - Ensure navigation preserves current theme and game state
  - Test navigation flow between all three views
  - _Requirements: 2.3, 3.3_

- [x] 8. Add responsive design and window management
  - Implement window resize handling in main application
  - Pass window size information to all child components
  - Ensure landing page adapts to different screen sizes
  - Test responsive behavior on mobile, tablet, and desktop viewports
  - _Requirements: 1.5_

- [x] 9. Create comprehensive tests for landing page functionality
  - Write unit tests for Landing.elm update function and message handling
  - Write unit tests for LandingView.elm component rendering
  - Write integration tests for navigation between all views
  - Write tests for theme persistence across navigation
  - Test responsive design calculations and window resize handling
  - _Requirements: 5.4_

- [x] 10. Integrate and test complete application flow
  - Test complete user journey from landing page to game and back
  - Test complete user journey from landing page to style guide and back
  - Verify theme switching works across all views
  - Test build and deployment process with new entry point
  - Verify hot reloading works in development mode
  - _Requirements: 2.1, 2.2, 2.4, 3.1, 3.2, 3.4, 5.2, 5.3_
# Implementation Plan

- [x] 1. Create Route module with URL parsing and generation
  - Create `src/Route.elm` with Route type definition and URL parsing functions
  - Implement `fromUrl`, `toString`, `toUrl`, and `parser` functions
  - Add comprehensive URL pattern matching for all application routes
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

- [x] 2. Update App module to use Browser.application
  - Modify `src/App.elm` to use `Browser.application` instead of `Browser.element`
  - Add `url` and `navKey` fields to `AppModel` type
  - Update `init` function to handle URL and navigation key parameters
  - _Requirements: 2.1, 4.2_

- [x] 3. Implement URL change handling in App module
  - Add `UrlRequested` and `UrlChanged` message types to `AppMsg`
  - Implement URL change handling in the `update` function
  - Add route-based navigation with `NavigateToRoute` message
  - _Requirements: 2.1, 2.2, 2.3, 5.1, 5.2_

- [x] 4. Add URL synchronization for page navigation
  - Update existing navigation messages to sync URL with page changes
  - Implement `routeToPage` and `pageToRoute` conversion functions
  - Ensure URL updates when navigating between pages programmatically
  - _Requirements: 2.1, 5.3, 5.4_

- [x] 5. Update Landing page navigation to use routes
  - Modify `Landing.elm` and `LandingView.elm` to use route-based navigation
  - Replace direct page navigation with `NavigateToRoute` messages
  - Maintain existing UI design and functionality
  - _Requirements: 5.1, 5.2, 5.3_

- [x] 6. Add navigation back to landing from style guide
  - Update `Theme.elm` style guide to include navigation back to landing
  - Implement route-based navigation in style guide view
  - Ensure consistent navigation experience across all pages
  - _Requirements: 2.2, 2.3, 5.1_

- [x] 7. Implement state preservation during navigation
  - Ensure game state is maintained when navigating away and back
  - Preserve theme preferences across route changes
  - Maintain window size information during navigation
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 8. Add error handling for invalid URLs
  - Implement fallback routing for unrecognized URLs
  - Add redirect logic for root URL to landing page
  - Handle malformed URLs gracefully with landing page fallback
  - _Requirements: 1.1, 1.6_

- [x] 9. Create comprehensive tests for routing functionality
  - Write unit tests for Route module URL parsing and generation
  - Add integration tests for navigation between all pages
  - Test browser back/forward button functionality
  - _Requirements: 2.2, 2.3, 4.1_

- [x] 10. Update application entry point and build configuration
  - Verify that `src/index.html` and `src/index.js` work with Browser.application
  - Ensure build process handles URL routing correctly
  - Test that production build supports direct URL access to all routes
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 3.4_
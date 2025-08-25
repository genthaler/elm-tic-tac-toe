# Implementation Plan

- [x] 1. Add elm-hash-routing dependency and setup
  - Add `mthadley/elm-hash-routing` package to `elm.json` dependencies
  - Verify package installation and compatibility with existing dependencies
  - Review elm-hash-routing documentation and API patterns
  - _Requirements: 4.1, 4.3, 4.5, 6.1_

- [x] 2. Create Route module with hash-based parsing
  - Create `src/Route.elm` with Route type definition for all application pages
  - Implement hash URL parser using elm-hash-routing's Parser combinators
  - Add `fromLocation`, `toPath`, `toString`, and `navigateTo` functions
  - _Requirements: 1.2, 1.3, 1.4, 1.5, 4.2, 4.4_

- [x] 3. Integrate elm-hash-routing with App module
  - Update `src/App.elm` to use `HashRouting.program` for main function
  - Add `currentRoute` field to `AppModel` type for tracking current route
  - Implement `HashChanged` message handling in update function
  - _Requirements: 2.1, 2.5, 6.3_

- [x] 4. Implement hash URL synchronization
  - Add route-to-page and page-to-route conversion functions
  - Ensure hash URL updates when navigating between pages
  - Handle initial hash URL parsing on application startup
  - _Requirements: 2.1, 5.3, 6.5_

- [x] 5. Add route-based navigation commands
  - Implement `NavigateToRoute` message type and handler
  - Create navigation commands using elm-hash-routing's navigate function
  - Ensure programmatic navigation updates hash URL correctly
  - _Requirements: 5.1, 5.4, 6.4_

- [x] 6. Update Landing page for hash routing
  - Modify `Landing.elm` and `LandingView.elm` to use hash-based navigation
  - Replace direct page navigation with `NavigateToRoute` messages
  - Maintain existing UI design and functionality with hash URLs
  - _Requirements: 5.1, 5.2_

- [x] 7. Add style guide navigation with hash routing
  - Update style guide pages to include navigation back to landing
  - Implement hash-based navigation in style guide views
  - Ensure consistent navigation experience across all pages
  - _Requirements: 2.2, 2.3, 5.1_

- [x] 8. Implement error handling for invalid hash URLs
  - Handle parsing failures gracefully with default route fallback
  - Implement fallback routing for unrecognized hash URLs
  - Ensure malformed hash URLs default to landing page
  - _Requirements: 1.6, 6.2, 6.6_

- [x] 9. Ensure state preservation during hash navigation
  - Verify game state is maintained when navigating via hash URLs
  - Preserve theme preferences across hash route changes
  - Maintain window size information during hash navigation
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 10. Create comprehensive tests for hash routing
  - Write unit tests for Route module hash URL parsing and generation
  - Add integration tests for hash navigation between all pages
  - Test browser back/forward button functionality with hash URLs
  - _Requirements: 2.2, 2.3, 4.1_

- [x] 11. Test hash routing in production build
  - Verify hash routing works correctly in production build
  - Test direct hash URL access to all routes
  - Ensure bookmark and refresh functionality works with hash URLs
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 3.4_
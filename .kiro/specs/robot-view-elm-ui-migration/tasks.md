# Implementation Plan

- [x] 1. Remove CSS dependencies and implement main layout structure
  - Remove the large CSS string and Html.node usage from the view function
  - Implement Element.layout with theme-aware background and font colors
  - Create the main viewModel function following TicTacToe.View's pattern with centerX, centerY positioning
  - Replace the complex HTML structure with a simple Element.column layout
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 2. Implement header component using TicTacToe.View patterns
  - Create viewHeader function with Element.row layout for title and navigation
  - Implement viewBackToHomeButton following TicTacToe's backToHomeButton pattern
  - Add game title with consistent typography and centerX positioning
  - Create placeholder for theme toggle button (if needed) following TicTacToe's colorSchemeToggleIcon pattern
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [x] 3. Migrate grid rendering to pure elm-ui layout
  - Replace viewGrid function to use Element.column for rows instead of HTML attributes
  - Implement viewRow function using Element.row for cell layout
  - Refactor viewCell function to use Element.el with Background.color and Element.Border properties
  - Remove all HTML attributes and CSS classes from grid cells
  - _Requirements: 2.1, 2.2, 2.4_

- [x] 4. Refactor robot visualization using elm-ui and SVG patterns
  - Simplify viewRobot function to use Element.el with Element.html for SVG content
  - Remove CSS animation classes and use SVG transforms for rotation
  - Implement robot body and directional arrow using SVG paths with theme colors
  - Use BaseTheme colors (robotBodyColorHex, robotDirectionColorHex) for consistent theming
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 5. Implement control buttons using elm-ui button patterns
  - Refactor viewControlButtons to use Element.column and Element.row for layout
  - Replace viewForwardButton with Element.el using Element.Events.onClick and elm-ui styling
  - Implement rotation buttons using Element.el with Background.color, Element.Border, and Element.padding
  - Add Element.mouseOver for hover states instead of CSS hover selectors
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 6. Implement animation states through elm-ui conditional styling
  - Create helper functions to determine cell colors based on AnimationState
  - Replace CSS animation classes with elm-ui conditional Background.color changes
  - Implement blocked movement feedback using theme colors instead of CSS classes
  - Simplify robot animation by using SVG rotation and elm-ui color changes
  - _Requirements: 5.1, 5.2, 5.3_

- [x] 7. Add status feedback components using elm-ui text elements
  - Create viewGameStatus function using Element.text with theme-aware colors
  - Implement viewSuccessMovementFeedback using Element.el with conditional visibility
  - Create viewBlockedMovementFeedback using elm-ui styling instead of CSS animations
  - Remove HTML-based feedback elements and replace with elm-ui components
  - _Requirements: 7.3, 5.3_

- [x] 8. Apply responsive design using Theme.Responsive utilities
  - Replace manual responsive calculations with getResponsiveFontSize, getResponsivePadding, getResponsiveSpacing
  - Use calculateResponsiveCellSize for grid cell dimensions
  - Apply responsive values consistently across all components (header, grid, buttons)
  - Remove CSS media queries and use elm-ui responsive patterns
  - _Requirements: 2.4, 7.4_

- [x] 9. Preserve accessibility features in elm-ui implementation
  - Maintain all ARIA labels using Element.htmlAttribute for accessibility attributes
  - Preserve keyboard navigation support through proper focus management
  - Keep screen reader support by maintaining semantic HTML structure where needed
  - Ensure all interactive elements have proper accessibility attributes
  - _Requirements: 7.5_

- [x] 10. Implement minimal CSS transitions for essential animations
  - Create a minimal CSS string for only essential transitions that cannot be achieved with elm-ui
  - Focus on smooth robot rotation and movement transitions using CSS transform
  - Remove all complex keyframe animations and CSS classes
  - Keep only basic transition properties for smooth visual feedback
  - _Requirements: 5.4, 7.3_

- [x] 11. Test visual consistency and functionality preservation
  - Verify that the migrated view maintains the same visual appearance as the original
  - Test all game functionality including movement, rotation, and keyboard controls
  - Ensure responsive behavior works correctly across different screen sizes
  - Validate that both light and dark themes display properly
  - _Requirements: 7.1, 7.2, 7.4_

- [x] 12. Clean up code and optimize imports
  - Remove unused imports related to HTML and CSS functionality
  - Simplify the module structure by removing unnecessary helper functions
  - Ensure all functions follow elm-ui patterns and naming conventions
  - Add proper documentation for the new elm-ui implementation
  - _Requirements: 1.2, 1.3_
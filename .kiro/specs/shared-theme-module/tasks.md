# Implementation Plan

- [x] 1. Create shared theme module foundation
  - Create `src/Theme/Theme.elm` with core types and module structure
  - Implement ColorScheme type with Light and Dark variants
  - Add JSON encoding and decoding functions for ColorScheme
  - _Requirements: 1.1, 1.2, 5.1, 5.2_

- [x] 2. Implement responsive design utilities
  - Add ScreenSize type with Mobile, Tablet, Desktop variants
  - Implement getScreenSize function for screen size detection
  - Create responsive calculation functions (cell size, font size, spacing, padding)
  - Add responsive configuration type and default values
  - _Requirements: 1.4, 3.2_

- [x] 3. Create base theme infrastructure
  - Define BaseTheme type alias with common theme properties
  - Implement theme selection functions for light and dark modes
  - Create color palette utilities and constants
  - Add theme configuration validation and error handling
  - _Requirements: 1.3, 3.1, 4.3_

- [x] 4. Add comprehensive tests for shared theme module
  - Create `tests/Theme/ThemeTest.elm` with ColorScheme tests
  - Add responsive design utility tests with boundary conditions
  - Implement theme selection and configuration tests
  - Add JSON encoding/decoding round-trip tests
  - _Requirements: 4.1, 4.2, 4.3, 5.3, 5.4_

- [x] 5. Update TicTacToe to use shared theme module
  - Modify `src/TicTacToe/Model.elm` to import ColorScheme from Theme module
  - Update JSON encoding/decoding in TicTacToe.Model to use shared functions
  - Refactor `src/TicTacToe/View.elm` to use shared responsive utilities
  - Maintain TicTacToe-specific theme properties while using shared base
  - _Requirements: 2.1, 2.3, 3.2, 3.4_

- [x] 6. Update RobotGame to use shared theme module
  - Modify `src/RobotGame/Model.elm` to import ColorScheme from Theme module
  - Update JSON encoding/decoding in RobotGame.Model to use shared functions
  - Refactor `src/RobotGame/View.elm` to use shared responsive utilities
  - Maintain RobotGame-specific theme properties while using shared base
  - _Requirements: 2.2, 2.4, 3.2, 3.4_

- [x] 7. Update existing tests to work with shared module
  - Update `tests/TicTacToe/` tests to import ColorScheme from shared module
  - Update `tests/RobotGame/ResponsiveThemeTest.elm` to use shared utilities
  - Modify any other tests that reference theme-related functionality
  - Ensure all existing tests continue to pass
  - _Requirements: 4.4, 5.5_

- [x] 8. Add integration tests for shared theme usage
  - Create integration tests verifying both games work with shared theme module
  - Add cross-game theme consistency tests
  - Implement backward compatibility tests for existing game states
  - Add visual regression tests to ensure appearance is preserved
  - _Requirements: 4.5, 5.4, 5.5_

- [x] 9. Clean up duplicated code and finalize migration
  - Remove duplicated theme-related code from individual game modules
  - Update module documentation and exports
  - Verify no unused imports or dead code remains
  - Run full test suite to ensure everything works correctly
  - _Requirements: 2.5, 3.5_

- [x] 10. Update theme documentation and validation
  - Update module documentation to reflect current theme structure and available colors
  - Add validation functions to ensure theme color combinations meet accessibility standards
  - Create comprehensive examples showing both light and dark theme variations
  - Update any inline documentation and type annotations
  - _Requirements: 1.3, 4.3, 6.4_
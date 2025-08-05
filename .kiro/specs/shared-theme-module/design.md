# Design Document

## Overview

The shared theme module has been implemented as `src/Theme/Theme.elm` and provides a centralized theming system for all games in the project. The design follows a modular approach where common theme infrastructure is shared while allowing game-specific customizations. The module exports types, utilities, and functions that both TicTacToe and RobotGame import and use, eliminating code duplication.

### Current State

The shared theme module is fully functional with:
- ✅ ColorScheme type with JSON encoding/decoding
- ✅ Responsive design utilities
- ✅ Integration with both TicTacToe and RobotGame

## Architecture

### Module Structure

```
src/
├── Theme/
│   └── Theme.elm          # Main shared theme module
├── TicTacToe/
│   ├── Model.elm          # Updated to import ColorScheme from Theme
│   └── View.elm           # Updated to use shared theme utilities
└── RobotGame/
    ├── Model.elm          # Updated to import ColorScheme from Theme
    └── View.elm           # Updated to use shared theme utilities
```

### Design Principles

1. **Separation of Concerns**: Common theme infrastructure is separated from game-specific visual customizations
2. **Backward Compatibility**: Existing game functionality and appearance is preserved
3. **Extensibility**: Games can define their own theme properties while using shared utilities
4. **Type Safety**: Strong typing ensures theme consistency and prevents runtime errors

## Components and Interfaces

### Core Types

```elm
-- ColorScheme type (shared by both games)
type ColorScheme
    = Light
    | Dark

-- Base theme properties that all games share
type alias BaseTheme =
    { backgroundColor : Color
    , fontColor : Color
    , secondaryFontColor : Color
    , borderColor : Color
    , accentColor : Color
    }

-- Screen size detection for responsive design
type ScreenSize
    = Mobile
    | Tablet
    | Desktop
```

### Theme Configuration

Each game will define its own theme configuration that extends the base theme:

```elm
-- Game-specific theme type (defined in each game's View module)
type alias GameTheme =
    { base : BaseTheme
    , gameSpecific : GameSpecificProperties
    }
```

### Responsive Design Utilities

The shared module will provide responsive design functions:

```elm
-- Screen size detection
getScreenSize : Maybe ( Int, Int ) -> ScreenSize

-- Responsive sizing utilities
calculateResponsiveCellSize : Maybe ( Int, Int ) -> Int -> Int -> Int
getResponsiveFontSize : Maybe ( Int, Int ) -> Int -> Int
getResponsiveSpacing : Maybe ( Int, Int ) -> Int -> Int
getResponsivePadding : Maybe ( Int, Int ) -> Int -> Int
```

### Theme Selection

Theme selection functions will be provided for each color scheme:

```elm
-- Base theme selection
getBaseTheme : ColorScheme -> BaseTheme

-- Color palette utilities
lightColorPalette : ColorPalette
darkColorPalette : ColorPalette
```

## Data Models

### ColorScheme

The `ColorScheme` type will be moved to the shared module with JSON encoding/decoding support:

```elm
type ColorScheme
    = Light
    | Dark

-- JSON encoding/decoding
encodeColorScheme : ColorScheme -> Encode.Value
decodeColorScheme : Decoder ColorScheme
```

### Theme Configuration

Base theme properties that are common across games:

```elm
type alias BaseTheme =
    { -- Background colors
      backgroundColor : Color
    , fontColor : Color
    , secondaryFontColor : Color
    
    -- Border and accent colors  
    , borderColor : Color
    , accentColor : Color
    
    -- Interactive element colors
    , buttonColor : Color
    , buttonHoverColor : Color
    }
```

### Responsive Configuration

Screen size and responsive calculation configuration:

```elm
type alias ResponsiveConfig =
    { mobileBreakpoint : Int
    , tabletBreakpoint : Int
    , minCellSize : Int
    , maxCellSize : Int
    , baseFontSize : Int
    }
```

## Error Handling

### JSON Decoding Errors

- Invalid ColorScheme values will default to `Light`
- Malformed JSON will be handled gracefully with fallback values
- Error logging will be provided for debugging purposes

### Responsive Calculation Errors

- Missing window dimensions will use sensible defaults
- Invalid screen sizes will default to Desktop configuration
- Minimum and maximum bounds will be enforced for all calculations

### Theme Configuration Errors

- Missing theme properties will use fallback values
- Invalid color values will be replaced with safe defaults
- Theme switching errors will preserve the current theme

## Testing Strategy

### Unit Tests

1. **ColorScheme Tests**
   - JSON encoding/decoding round-trip tests
   - Invalid input handling tests
   - Default value tests

2. **Responsive Design Tests**
   - Screen size detection accuracy tests
   - Responsive calculation boundary tests
   - Default value handling tests

3. **Theme Configuration Tests**
   - Base theme property tests
   - Theme selection function tests
   - Color palette consistency tests

### Integration Tests

1. **Game Integration Tests**
   - TicTacToe theme integration tests
   - RobotGame theme integration tests
   - Cross-game theme consistency tests

2. **Backward Compatibility Tests**
   - Existing game state loading tests
   - Visual regression tests
   - Functionality preservation tests

### Migration Tests

1. **Data Migration Tests**
   - Existing ColorScheme data compatibility
   - Game state preservation tests
   - JSON format compatibility tests

## Implementation Phases

### Phase 1: Create Shared Module ✅ COMPLETED
- Create `src/Theme/Theme.elm` with core types and utilities
- Implement ColorScheme with JSON support
- Add responsive design utilities
- Create base theme configurations

### Phase 2: Update TicTacToe ✅ COMPLETED
- Update TicTacToe.Model to import ColorScheme from shared module
- Refactor TicTacToe.View to use shared responsive utilities
- Maintain game-specific theme properties
- Update tests to use shared module

### Phase 3: Update RobotGame ✅ COMPLETED
- Update RobotGame.Model to import ColorScheme from shared module
- Refactor RobotGame.View to use shared responsive utilities
- Maintain game-specific theme properties
- Update tests to use shared module

### Phase 4: Testing and Validation ✅ COMPLETED
- Run comprehensive test suite
- Verify visual consistency
- Test theme switching functionality
- Validate backward compatibility

### Phase 5: Dark Theme Enhancement 🔄 IN PROGRESS
- Improve dark theme color palette using diverse AussiePalette colors
- Ensure proper contrast ratios and accessibility compliance
- Create cohesive visual hierarchy for dark mode
- Update documentation and validation functions

## Migration Strategy

### Backward Compatibility

- Existing JSON-encoded ColorScheme values will continue to work
- Game state files will load correctly with the new shared module
- Visual appearance will be preserved during migration

### Gradual Migration

- Games can be migrated one at a time
- Shared module can coexist with existing implementations during transition
- Rollback capability maintained until migration is complete

### Validation

- Automated tests will verify migration success
- Visual regression testing will ensure appearance consistency
- Performance benchmarks will confirm no degradation
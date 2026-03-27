# Design Document

## Overview

The shared theme module is implemented in `src/Theme/Theme.elm` and provides the common theme primitives used by the tic-tac-toe application. The module centralizes color scheme state, persistence, responsive sizing, and theme selection so the rest of the app can stay focused on gameplay and the optional search inspection panel.

## Architecture

### Module Structure

```
src/
├── Theme/
│   └── Theme.elm       # Shared theme module
└── TicTacToe/
    ├── Model.elm       # Stores ColorScheme and viewport state
    ├── View.elm        # Uses shared theme helpers for layout
    └── Main.elm        # Coordinates theme persistence and subscriptions
```

### Design Principles

1. **Single Source of Truth**: Theme state and helpers live in one module
2. **Persistence**: Color scheme values round-trip through JSON
3. **Responsiveness**: Layout helpers adapt to viewport size without duplicating logic
4. **Integration**: The tic-tac-toe app consumes the module directly, with no separate theme-demo surface, and the inspection panel uses the same primitives

## Components and Interfaces

### Core Types

```elm
type ColorScheme
    = Light
    | Dark

type ScreenSize
    = Mobile
    | Tablet
    | Desktop

type alias Theme =
    { backgroundColor : Color
    , textColor : Color
    , accentColor : Color
    , borderColor : Color
    }
```

### Theme Selection

The module exposes selection helpers that return a theme record for the active color scheme:

```elm
getTheme : ColorScheme -> Theme
```

The returned theme is used by the tic-tac-toe view to style the board, controls, inspection tree, status text, and background consistently.

### Responsive Design Utilities

The module also provides viewport-aware helpers:

```elm
getScreenSize : Maybe ( Int, Int ) -> ScreenSize
calculateResponsiveCellSize : Maybe ( Int, Int ) -> Int -> Int -> Int
getResponsiveFontSize : Maybe ( Int, Int ) -> Int -> Int
getResponsiveSpacing : Maybe ( Int, Int ) -> Int -> Int
getResponsivePadding : Maybe ( Int, Int ) -> Int -> Int
```

These helpers keep the single-screen game and inspection controls legible and touch-friendly without requiring local sizing logic in the view layer.

### JSON Support

Color scheme persistence uses straightforward JSON encoding and decoding:

```elm
encodeColorScheme : ColorScheme -> Encode.Value
decodeColorScheme : Decoder ColorScheme
```

Invalid values decode to a safe default so preference storage cannot break the app.

## Error Handling

- Missing viewport data falls back to sensible responsive defaults
- Invalid persisted color scheme values fall back to Light
- Theme selection always returns a usable theme record

## Testing Strategy

### Unit Tests

1. `ColorScheme` encoding and decoding round trips
2. Responsive sizing helper boundaries and defaults
3. Theme selection results for light and dark modes
4. Inspection panel layout remains readable alongside the board and controls

### Integration Tests

1. Tic-tac-toe model and view using the shared theme module
2. Theme persistence across app startup and reset flows
3. Responsive rendering behavior on different viewport sizes
4. Shared theming keeps the inspection panel aligned with the rest of the app

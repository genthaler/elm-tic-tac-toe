# Design Document

## Overview

The landing page will be implemented as a new Elm application that serves as the main entry point for the Tic-Tac-Toe project. It will provide navigation to both the game and style guide while maintaining visual consistency with the existing design system. The implementation will use a simple routing mechanism to switch between the landing page, game, and style guide views.

## Architecture

### Application Structure
The landing page will be implemented using a new main application module that manages three distinct views:
- **Landing View**: The main navigation page
- **Game View**: The existing tic-tac-toe game
- **Style Guide View**: The existing elm-book interface

### Routing Strategy
Instead of implementing a complex routing library, we'll use a simple page-based state management approach:
- A `Page` type will define the three possible views
- The main model will track the current page
- Navigation will be handled through message passing
- URL changes will be managed through browser history API

### State Management
- The landing page will have its own minimal state (theme preference)
- Game state will be preserved when navigating away and back
- Theme preferences will be shared across all views
- Each view will maintain its own specific state when active

## Components and Interfaces

### Main Application Module (`src/LandingMain.elm`)
```elm
type Page
    = LandingPage
    | GamePage
    | StyleGuidePage

type alias Model =
    { currentPage : Page
    , colorScheme : ColorScheme
    , gameModel : Maybe GameModel
    , landingModel : LandingModel
    }

type Msg
    = NavigateToGame
    | NavigateToStyleGuide
    | NavigateToLanding
    | GameMsg GameMsg
    | LandingMsg LandingMsg
    | ColorSchemeChanged ColorScheme
```

### Landing Page Module (`src/Landing.elm`)
```elm
type alias Model =
    { colorScheme : ColorScheme
    , maybeWindow : Maybe (Int, Int)
    }

type Msg
    = PlayGameClicked
    | ViewStyleGuideClicked
    | ColorSchemeToggled
    | WindowResized Int Int
```

### Landing View Component (`src/LandingView.elm`)
The landing view will reuse the existing theme system and UI components:
- Same color schemes (Light/Dark) as the game
- Same responsive design patterns
- Same typography and spacing system
- Same button and icon components

### Integration Points
- **Theme System**: Reuse `View.elm` theme definitions and color schemes
- **Responsive Design**: Reuse responsive utilities from `View.elm`
- **Icons**: Reuse existing SVG icons for theme toggle and navigation
- **Build System**: Integrate with existing Parcel configuration

## Data Models

### Page State Model
```elm
type Page
    = LandingPage
    | GamePage
    | StyleGuidePage

type alias AppModel =
    { currentPage : Page
    , colorScheme : ColorScheme
    , gameModel : Maybe Model.Model  -- Game state preserved
    , landingModel : Landing.Model
    , maybeWindow : Maybe (Int, Int)
    }
```

### Landing Page Model
```elm
type alias LandingModel =
    { colorScheme : ColorScheme
    , maybeWindow : Maybe (Int, Int)
    }
```

### Navigation Messages
```elm
type AppMsg
    = NavigateToGame
    | NavigateToStyleGuide  
    | NavigateToLanding
    | GameMsg Model.Msg
    | LandingMsg Landing.Msg
    | ColorSchemeChanged ColorScheme
    | WindowResized Int Int
```

## Error Handling

### Navigation Errors
- Invalid page states will default to landing page
- Failed navigation attempts will show error messages
- Malformed URLs will redirect to landing page

### State Preservation
- Game state will be preserved when navigating away
- Theme preferences will persist across page changes
- Window size information will be maintained globally

### Fallback Behavior
- If game state becomes corrupted, reset to initial state
- If theme preference is invalid, default to light mode
- If window size is unavailable, use desktop defaults

## Testing Strategy

### Unit Tests
- Landing page component rendering
- Navigation message handling
- Theme switching functionality
- Responsive design calculations

### Integration Tests
- Navigation between all three views
- State preservation during navigation
- Theme persistence across views
- Build system integration

### Visual Tests
- Landing page appearance in both themes
- Responsive behavior on different screen sizes
- Button and icon rendering
- Typography and spacing consistency

### End-to-End Tests
- Complete user journey from landing to game
- Complete user journey from landing to style guide
- Theme switching across all views
- Browser back/forward navigation

## Implementation Notes

### File Structure
```
src/
├── LandingMain.elm          # New main application entry point
├── Landing.elm              # Landing page logic
├── LandingView.elm          # Landing page UI components
├── Main.elm                 # Existing game logic (unchanged)
├── View.elm                 # Existing game UI (reused for theming)
├── Book.elm                 # Existing style guide (unchanged)
└── index.html               # Updated to use LandingMain
```

### Build Configuration
- Update `src/index.html` to import `LandingMain.elm` instead of `Main.elm`
- Maintain existing Parcel configuration
- Preserve existing npm scripts and build process
- Ensure elm-book integration continues to work

### Theme Integration
- Import and reuse theme definitions from `View.elm`
- Maintain consistency with existing color schemes
- Use same responsive design utilities
- Preserve existing icon and button styles

### Performance Considerations
- Lazy load game and style guide modules when needed
- Minimize bundle size by sharing common components
- Optimize for fast initial landing page load
- Maintain existing web worker functionality for game AI
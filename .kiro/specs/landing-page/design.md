# Design Document

## Overview

The landing page will be implemented as a new Elm application that serves as the main entry point for the multi-game project (Tic-Tac-Toe and Robot Grid Game). It will provide navigation to both games and the Theme module's style guide while maintaining visual consistency with the existing design system. The implementation will use a simple routing mechanism to switch between the landing page, games, and theme style guide views.

**Key Design Decision**: We're implementing a simple page-based routing system rather than a complex URL-based router to minimize dependencies and maintain simplicity while still providing clear navigation paths between all application sections.

## Architecture

### Application Structure
The landing page will be implemented using a new main application module that manages three distinct views:
- **Landing View**: The main navigation page with clear navigation options
- **Game View**: The existing tic-tac-toe game with preserved functionality
- **Theme Style Guide View**: The Theme module's style guide interface showcasing theme components and variations

**Design Rationale**: This structure allows for clean separation of concerns while maintaining state preservation and theme consistency across all views.

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

### Main Application Module (`src/Landing/LandingMain.elm`)
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

### App Module (`src/App.elm`)
```elm
type alias Model =
    { colorScheme : ColorScheme
    , maybeWindow : Maybe (Int, Int)
    }

type Msg
    = PlayGameClicked
    | ViewThemeStyleGuideClicked
    | ColorSchemeToggled
    | WindowResized Int Int
```

### Landing View Component (`src/Landing/LandingView.elm`)
The landing view will reuse the existing theme system and UI components:
- Same color schemes (Light/Dark) as the game
- Same responsive design patterns
- Same typography and spacing system
- Same button and icon components

### Integration Points
- **Theme System**: Reuse `Theme/Theme.elm` and `TicTacToe/View.elm` theme definitions and color schemes
- **Responsive Design**: Reuse responsive utilities from `TicTacToe/View.elm`
- **Icons**: Reuse existing SVG icons for theme toggle and navigation
- **Build System**: Integrate with existing Parcel configuration
- **Style Guide Integration**: Connect to `Theme/StyleGuide.elm` for theme showcase functionality

## Data Models

### Page State Model
```elm
type Page
    = LandingPage
    | GamePage
    | ThemeStyleGuidePage

type alias AppModel =
    { currentPage : Page
    , colorScheme : ColorScheme
    , gameModel : Maybe TicTacToeModel.Model  -- Game state preserved
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
    | NavigateToThemeStyleGuide  
    | NavigateToLanding
    | GameMsg TicTacToeModel.Msg
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
- Complete user journey from landing to theme style guide
- Theme switching across all views
- Browser back/forward navigation

## Implementation Notes

### File Structure
```
src/
├── Landing/
│   ├── LandingMain.elm      # New main application entry point
│   ├── Landing.elm          # Landing page logic
│   └── LandingView.elm      # Landing page UI components
├── TicTacToe/
│   ├── Main.elm             # Existing game logic (unchanged)
│   ├── View.elm             # Existing game UI (reused for theming)
│   ├── Model.elm            # Game data types and state
│   ├── TicTacToe.elm        # Core game logic
│   └── GameWorker.elm       # Web worker for AI
├── Theme/
│   ├── Theme.elm            # Shared theme module
│   └── StyleGuide.elm       # Theme style guide module
├── Book.elm                 # Legacy elm-book integration (if needed)
└── index.html               # Updated to use Landing/LandingMain
```

### Build Configuration
- Update `src/index.html` to import `Landing/LandingMain.elm` instead of `TicTacToe/Main.elm`
- Maintain existing Parcel configuration
- Preserve existing npm scripts and build process
- Ensure elm-book integration continues to work

### Theme Integration
- Import and reuse theme definitions from `TicTacToe/View.elm`
- Maintain consistency with existing color schemes
- Use same responsive design utilities
- Preserve existing icon and button styles

### Performance Considerations
- Lazy load game and theme style guide modules when needed
- Minimize bundle size by sharing common components
- Optimize for fast initial landing page load
- Maintain existing web worker functionality for game AI
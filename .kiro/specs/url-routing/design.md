# Design Document

## Overview

This design implements URL-based routing for the Elm application using `Browser.application` instead of `Browser.element`. The routing system will provide deep linking, browser navigation support, and maintain the existing page-based architecture while adding URL synchronization.

## Architecture

### Current State Analysis

The application currently uses:
- `Browser.element` with manual page switching via `Page` type
- Internal navigation through message passing
- No URL synchronization
- State preservation between page switches

### Proposed Changes

1. **Upgrade to Browser.application**: Switch from `Browser.element` to `Browser.application` to gain access to URL handling
2. **Route Module**: Create a dedicated `Route` module for URL parsing and generation
3. **URL Synchronization**: Keep URL in sync with current page state
4. **Preserve Existing Architecture**: Maintain current `Page` type and state management

## Components and Interfaces

### Route Module (`src/Route.elm`)

```elm
module Route exposing 
    ( Route(..)
    , fromUrl
    , toUrl
    , toString
    , parser
    )

import Url exposing (Url)
import Url.Parser as Parser exposing (Parser)

type Route
    = Landing
    | TicTacToe  
    | RobotGame
    | StyleGuide

-- Parse URL to Route
fromUrl : Url -> Maybe Route

-- Convert Route to URL string
toString : Route -> String

-- Generate full URL from Route
toUrl : Route -> Url

-- URL parser
parser : Parser (Route -> a) a
```

### Updated App Module

**Key Changes:**
- Switch from `Browser.element` to `Browser.application`
- Add `Url` and `Browser.Navigation.Key` to model
- Handle `UrlRequested` and `UrlChanged` messages
- Synchronize URL with page changes

**New Model Structure:**
```elm
type alias AppModel =
    { currentPage : Page
    , url : Url
    , navKey : Browser.Navigation.Key
    , colorScheme : ColorScheme
    , gameModel : Maybe TicTacToeModel.Model
    , robotGameModel : Maybe RobotGameModel.Model
    , landingModel : Landing.Model
    , maybeWindow : Maybe ( Int, Int )
    }
```

**New Messages:**
```elm
type AppMsg
    = -- Existing messages...
    | UrlRequested Browser.UrlRequest
    | UrlChanged Url
    | NavigateToRoute Route
```

### Navigation Integration

**Landing Page Updates:**
- Update navigation buttons to use `NavigateToRoute` messages
- Maintain existing UI and functionality

**Style Guide Navigation:**
- Add navigation back to landing page
- Integrate with URL routing system

## Data Models

### Route to Page Mapping

```elm
routeToPage : Route -> Page
routeToPage route =
    case route of
        Route.Landing -> LandingPage
        Route.TicTacToe -> GamePage
        Route.RobotGame -> RobotGamePage
        Route.StyleGuide -> StyleGuidePage

pageToRoute : Page -> Route
pageToRoute page =
    case page of
        LandingPage -> Route.Landing
        GamePage -> Route.TicTacToe
        RobotGamePage -> Route.RobotGame
        StyleGuidePage -> Route.StyleGuide
```

### URL Structure

- `/` → Redirect to `/landing`
- `/landing` → Landing page
- `/tic-tac-toe` → Tic-tac-toe game
- `/robot-game` → Robot grid game  
- `/style-guide` → Style guide
- Invalid URLs → Redirect to `/landing`

## Error Handling

### URL Parsing Errors
- Invalid URLs default to `Landing` route
- Malformed URLs redirect to `/landing`
- Missing routes fall back to landing page

### Navigation Errors
- Failed navigation attempts log errors but don't crash
- External link requests open in new tabs
- Internal navigation failures redirect to landing

### State Preservation
- Game state maintained during navigation
- Theme preferences preserved across routes
- Window size information maintained

## Testing Strategy

### Unit Tests
- Route parsing and generation functions
- URL to Route conversion accuracy
- Route to Page mapping correctness

### Integration Tests  
- Navigation between all pages
- Browser back/forward button functionality
- URL synchronization with page state
- State preservation during navigation

### Manual Testing
- Direct URL access to all routes
- Bookmark and refresh functionality
- Browser navigation button behavior
- Invalid URL handling

## Implementation Phases

### Phase 1: Route Module
- Create `Route.elm` with URL parsing
- Implement route to string conversion
- Add URL parser with all routes

### Phase 2: App Module Updates
- Switch to `Browser.application`
- Add URL and navigation key to model
- Implement URL change handling

### Phase 3: Navigation Integration
- Update landing page navigation
- Add style guide back navigation
- Implement route-based navigation messages

### Phase 4: Testing and Refinement
- Add comprehensive tests
- Handle edge cases and errors
- Optimize navigation performance

## Backward Compatibility

- Existing `Page` type remains unchanged
- Current state management preserved
- All existing functionality maintained
- No breaking changes to game logic
- Theme system integration unchanged
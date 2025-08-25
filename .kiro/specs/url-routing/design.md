# Design Document

## Overview

This design implements hash-based URL routing for the Elm application using mthadley/elm-hash-routing. The routing system will provide deep linking, browser navigation support, and integrate seamlessly with the application's page-based architecture through hash URL synchronization. Hash-based routing is chosen for its simplicity in deployment (no server configuration needed) and compatibility with static hosting.

## Architecture

### Architecture Overview

The hash-based URL routing system will provide:
- Deep linking to specific application pages via hash URLs
- Browser back/forward navigation support
- URL synchronization with application state
- Seamless integration with the page-based architecture

### Core Components

1. **elm-hash-routing Integration**: Use mthadley/elm-hash-routing for robust hash routing
2. **Route Module**: Dedicated `Route` module using elm-hash-routing's URL parsing
3. **Hash URL Synchronization**: Keep hash URL in sync with current page state
4. **Page Integration**: Connect routing with the application's `Page` type system
5. **Hash Change Handling**: Subscribe to hash changes using elm-hash-routing

## Components and Interfaces

### elm-hash-routing Integration

**Package:** `mthadley/elm-hash-routing`

**Key Benefits:**
- Mature, well-tested hash routing library
- Type-safe URL parsing with combinators
- Built-in hash change subscriptions
- No server configuration required
- Works with Browser.element (no need to upgrade to Browser.application)

**Core Functions Used:**
- `HashRouting.program` - Sets up hash routing subscriptions
- `HashRouting.Parser` - URL parser combinators
- `HashRouting.navigate` - Programmatic navigation
- `HashRouting.HashLocation` - Hash location type

### Route Module (`src/Route.elm`)

```elm
module Route exposing 
    ( Route(..)
    , fromLocation
    , toPath
    , toString
    , parser
    , navigateTo
    )

import HashRouting exposing (HashLocation)
import HashRouting.Parser as Parser exposing (Parser)

type Route
    = Landing
    | TicTacToe  
    | RobotGame
    | StyleGuide

-- Parse hash location to Route
fromLocation : HashLocation -> Maybe Route

-- Convert Route to hash path string
toPath : Route -> String

-- Convert Route to display string
toString : Route -> String

-- Hash URL parser using elm-hash-routing
parser : Parser Route

-- Navigation command
navigateTo : Route -> Cmd msg
```

### App Module Integration

**Routing Features:**
- Hash location tracking in application model
- Hash change message handling from elm-hash-routing
- Route-based navigation commands
- Integration with existing page system

**Model Structure:**
```elm
type alias AppModel =
    { currentPage : Page
    , currentRoute : Maybe Route
    , colorScheme : ColorScheme
    , gameModel : Maybe TicTacToeModel.Model
    , robotGameModel : Maybe RobotGameModel.Model
    , landingModel : Landing.Model
    , maybeWindow : Maybe ( Int, Int )
    }
```

**Routing Messages:**
```elm
type AppMsg
    = -- Existing messages...
    | HashChanged HashLocation
    | NavigateToRoute Route
```

### Navigation Integration

**Landing Page Integration:**
- Navigation buttons will use `NavigateToRoute` messages
- Existing UI and functionality preserved

**Style Guide Integration:**
- Navigation back to landing page via hash routing
- Seamless integration with URL routing system

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

### Hash URL Structure

- `#/` or empty hash → Landing page (default)
- `#/landing` → Landing page
- `#/tic-tac-toe` → Tic-tac-toe game
- `#/robot-game` → Robot grid game  
- `#/style-guide` → Style guide
- Invalid hash URLs → Default to landing page

## Error Handling

### Hash URL Parsing Errors
- Invalid hash URLs default to `Landing` route
- Malformed hash URLs fall back to landing page
- Missing routes default to landing page

### Navigation Errors
- Failed hash navigation attempts log errors but don't crash
- Hash navigation failures fall back to landing page
- elm-hash-routing handles malformed hash URLs gracefully

### State Preservation
- Game state maintained during hash navigation
- Theme preferences preserved across routes
- Window size information maintained
- Hash changes don't trigger page reloads

## Testing Strategy

### Unit Tests
- Route parsing and generation functions
- URL to Route conversion accuracy
- Route to Page mapping correctness

### Integration Tests  
- Navigation between all pages
- Browser back/forward button functionality with hash URLs
- Hash URL synchronization with page state
- State preservation during hash navigation

### Manual Testing
- Direct hash URL access to all routes
- Bookmark and refresh functionality with hash URLs
- Browser navigation button behavior with hash routing
- Invalid hash URL handling

## Implementation Phases

### Phase 1: Dependencies and Route Module
- Add mthadley/elm-hash-routing to elm.json
- Create `Route.elm` with hash URL parsing using elm-hash-routing
- Implement route to hash path conversion
- Add hash URL parser with all routes

### Phase 2: App Module Updates
- Add hash location tracking to model
- Implement hash change subscriptions using elm-hash-routing
- Handle HashChanged messages
- Add route navigation commands

### Phase 3: Navigation Integration
- Update landing page navigation to use hash routing
- Add style guide back navigation with hash URLs
- Implement route-based navigation messages
- Update all internal links to use hash navigation

### Phase 4: Testing and Refinement
- Add comprehensive tests for hash routing
- Handle edge cases and hash URL errors
- Test browser back/forward functionality
- Optimize hash navigation performance

## Implementation Details

### elm-hash-routing Setup

**Main Application Setup:**
```elm
main : Program () AppModel AppMsg
main =
    HashRouting.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , parser = Route.parser
        , onUrlChange = HashChanged
        }
```

**Route Parser Implementation:**
```elm
parser : Parser Route
parser =
    Parser.oneOf
        [ Parser.map Landing (Parser.s "landing")
        , Parser.map TicTacToe (Parser.s "tic-tac-toe")
        , Parser.map RobotGame (Parser.s "robot-game")
        , Parser.map StyleGuide (Parser.s "style-guide")
        , Parser.map Landing Parser.top  -- Default route
        ]
```

**Navigation Commands:**
```elm
navigateTo : Route -> Cmd msg
navigateTo route =
    HashRouting.navigate (toPath route)

toPath : Route -> String
toPath route =
    case route of
        Landing -> "landing"
        TicTacToe -> "tic-tac-toe"
        RobotGame -> "robot-game"
        StyleGuide -> "style-guide"
```

### Update Function Changes

```elm
update : AppMsg -> AppModel -> ( AppModel, Cmd AppMsg )
update msg model =
    case msg of
        HashChanged location ->
            let
                maybeRoute = Route.fromLocation location
                newRoute = Maybe.withDefault Route.Landing maybeRoute
                newPage = routeToPage newRoute
            in
            ( { model 
                | currentPage = newPage
                , currentRoute = Just newRoute
              }
            , Cmd.none
            )
        
        NavigateToRoute route ->
            ( model, Route.navigateTo route )
        
        -- ... existing message handlers
```

## Integration Approach

- Seamless integration with existing `Page` type system
- Preservation of current state management patterns
- Full compatibility with existing functionality
- No impact on game logic or theme system
- Works with Browser.element architecture
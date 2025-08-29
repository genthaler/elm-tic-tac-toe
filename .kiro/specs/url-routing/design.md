# Design Document

## Overview

This design implements hash-based URL routing for the Elm application using `Browser.Hash.application` from the `mthadley/elm-hash-routing` package. The routing system provides deep linking, browser navigation support, and direct route-based navigation. Hash-based routing is chosen for its simplicity in deployment (no server configuration needed) and compatibility with static hosting.

## Architecture

### Architecture Overview

The hash-based URL routing system provides:
- Deep linking to specific application routes via hash URLs
- Browser back/forward navigation support
- URL synchronization with application state
- Direct route-based navigation without intermediate abstractions

### Core Components

1. **Browser.Hash Integration**: Use `Browser.Hash.application` from `mthadley/elm-hash-routing` package
2. **Route Module**: Dedicated `Route` module with URL parsing and generation
3. **Hash URL Synchronization**: Keep hash URL in sync with current route
4. **Direct Route Usage**: Use Route type directly throughout the application
5. **Hash Change Handling**: Subscribe to URL changes using Browser.Hash

## Components and Interfaces

### Browser.Hash Integration

**External Package:** `mthadley/elm-hash-routing`

**Key Benefits:**
- Specialized hash routing functionality
- Type-safe URL parsing with Url.Parser
- Built-in hash change subscriptions
- No server configuration required
- Simplified hash-based navigation

**Core Functions Used:**
- `Browser.Hash.application` - Sets up hash routing application
- `Url.Parser` - URL parser combinators
- `Browser.Navigation.pushUrl` - Programmatic navigation
- `Url.Url` - URL type for parsing

### Route Module (`src/Route.elm`)

```elm
module Route exposing 
    ( Route(..)
    , fromUrl
    , fromUrlWithFallback
    , toHashUrl
    , toString
    , toUrl
    , navigateTo
    )

import Browser.Navigation as Nav
import Url exposing (Url)
import Url.Parser as Parser exposing (Parser)

type Route
    = Landing
    | TicTacToe  
    | RobotGame
    | StyleGuide

-- Parse URL to Route with error handling
fromUrl : Url -> Maybe Route

-- Parse URL to Route with fallback to Landing
fromUrlWithFallback : Url -> Route

-- Convert Route to hash URL string
toHashUrl : Route -> String

-- Convert Route to display string
toString : Route -> String

-- Convert Route to URL for testing
toUrl : Route -> Url

-- Navigation command
navigateTo : Nav.Key -> Route -> Cmd msg
```

### App Module Integration

**Routing Features:**
- Direct route tracking in application model
- URL change message handling from Browser.Hash
- Route-based navigation commands
- Direct route usage throughout application

**Model Structure:**
```elm
type alias AppModel =
    { currentRoute : Route
    , url : Url
    , navKey : Nav.Key
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
    | UrlRequested Browser.UrlRequest
    | UrlChanged Url
    | NavigateToRoute Route
```

### Navigation Integration

**Landing Route Integration:**
- Navigation buttons use `NavigateToRoute` messages
- Existing UI and functionality preserved

**Style Guide Integration:**
- Navigation back to landing route via hash routing
- Seamless integration with URL routing system

## Data Models

### Direct Route Usage

The application uses Route directly without intermediate Page types:

```elm
-- Route type represents all application routes
type Route
    = Landing
    | TicTacToe
    | RobotGame
    | StyleGuide

-- View rendering based on current route
view : AppModel -> Html AppMsg
view model =
    case model.currentRoute of
        Landing -> LandingView.view model.landingModel LandingMsg
        TicTacToe -> TicTacToeView.view gameModel |> Html.map TicTacToeMsg
        RobotGame -> RobotGameView.view robotGameModel |> Html.map RobotGameMsg
        StyleGuide -> viewStyleGuideWithNavigation model.colorScheme model.maybeWindow
```

### Hash URL Structure

- `#/` or empty hash → Landing route (default)
- `#/landing` → Landing route
- `#/tic-tac-toe` → Tic-tac-toe game route
- `#/robot-game` → Robot grid game route
- `#/style-guide` → Style guide route
- Invalid hash URLs → Default to landing route

## Error Handling

### Hash URL Parsing Errors
- Invalid hash URLs default to `Landing` route
- Malformed hash URLs fall back to landing route
- Missing routes default to landing route

### Navigation Errors
- Failed hash navigation attempts log errors but don't crash
- Hash navigation failures fall back to landing route
- Browser.Hash handles malformed hash URLs gracefully

### State Preservation
- Game state maintained during hash navigation
- Theme preferences preserved across routes
- Window size information maintained
- Hash changes don't trigger full reloads

## Testing Strategy

### Unit Tests
- Route parsing and generation functions
- URL to Route conversion accuracy
- Hash URL generation consistency

### Integration Tests  
- Navigation between all routes
- Browser back/forward button functionality with hash URLs
- Hash URL synchronization with route state
- State preservation during hash navigation

### Manual Testing
- Direct hash URL access to all routes
- Bookmark and refresh functionality with hash URLs
- Browser navigation button behavior with hash routing
- Invalid hash URL handling

## Implementation Phases

### Phase 1: Route Module and Browser.Hash
- Create `Route.elm` with hash URL parsing using Url.Parser
- Implement route to hash URL conversion
- Add hash URL parser with all routes
- Set up Browser.Hash.application

### Phase 2: App Module Updates
- Add direct route tracking to model
- Implement URL change subscriptions using Browser.Hash
- Handle UrlChanged messages
- Add route navigation commands

### Phase 3: Navigation Integration
- Update landing route navigation to use hash routing
- Add style guide back navigation with hash URLs
- Implement route-based navigation messages
- Update all internal links to use hash navigation

### Phase 4: Testing and Refinement
- Add comprehensive tests for hash routing
- Handle edge cases and hash URL errors
- Test browser back/forward functionality
- Optimize hash navigation performance

## Implementation Details

### Browser.Hash Setup

**Main Application Setup:**
```elm
main : Program Flags AppModel AppMsg
main =
    Hash.application
        { init = init
        , view = \model -> { title = "Elm Games", body = [ view model ] }
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }
```

**Route Parser Implementation:**
```elm
parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Landing top -- Default route for root path
        , Parser.map Landing (s "landing")
        , Parser.map TicTacToe (s "tic-tac-toe")
        , Parser.map RobotGame (s "robot-game")
        , Parser.map StyleGuide (s "style-guide")
        ]
```

**Navigation Commands:**
```elm
navigateTo : Nav.Key -> Route -> Cmd msg
navigateTo navKey route =
    Nav.pushUrl navKey (toHashUrl route)

toHashUrl : Route -> String
toHashUrl route =
    "#/" ++ toPath route

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
        UrlChanged url ->
            let
                parsedRoute = Route.fromUrlWithFallback url
            in
            ( { model 
                | currentRoute = parsedRoute
                , url = url
              }
            , Cmd.none
            )
        
        NavigateToRoute route ->
            ( { model | currentRoute = route }
            , Route.navigateTo model.navKey route
            )
        
        -- ... existing message handlers
```

## Integration Approach

- Direct route usage eliminates unnecessary abstractions
- Simplified state management with single route field
- Full compatibility with existing functionality
- No impact on game logic or theme system
- Uses Browser.Hash.application architecture from mthadley/elm-hash-routing
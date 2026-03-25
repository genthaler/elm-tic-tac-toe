---
inclusion: fileMatch
fileMatchPattern: '*.elm'
---

# Hash Routing Implementation Guide

## Overview

This project implements hash-based routing using `Browser.Hash.application` from the `mthadley/elm-hash-routing` package for single-page application navigation. Hash routing enables direct URL access to all application pages while maintaining browser navigation functionality.

## Architecture

### Core Components

- **`src/Route.elm`**: Central routing module with URL parsing and generation
- **`src/App.elm`**: Main application with hash routing integration
- **`Browser.Hash`**: Hash routing application type from `mthadley/elm-hash-routing`

### Route Definition

All routes are defined in the `Route` type:

```elm
type Route
    = Landing
    | TicTacToe
    | RobotGame
    | StyleGuide
```

### Hash URL Format

All routes use consistent hash URL format:
- Landing: `#/landing` or `#/` (root)
- Tic-Tac-Toe: `#/tic-tac-toe`
- Robot Game: `#/robot-game`
- Style Guide: `#/style-guide`

## Key Functions

### URL Parsing
- `fromUrl : Url -> Maybe Route` - Parse URL to route (may fail)
- `fromUrlWithFallback : Url -> Route` - Parse with fallback to Landing

### URL Generation
- `toHashUrl : Route -> String` - Generate hash URL for navigation
- `navigateTo : Nav.Key -> Route -> Cmd msg` - Navigate to route

### Route Conversion
- `toString : Route -> String` - Convert route to path string
- `toUrl : Route -> Url` - Convert route to URL (for testing)

## Error Handling

### Invalid URLs
- Malformed URLs default to Landing page
- Case-sensitive routing (e.g., `TIC-TAC-TOE` is invalid)
- Extra path segments are rejected
- Special characters cause fallback to Landing

### Graceful Fallbacks
- `fromUrlWithFallback` ensures valid route is always returned
- App redirects invalid hash URLs to `#/landing`
- Browser navigation maintains proper URL state

## Testing Strategy

### Unit Tests (`tests/RouteUnitTest.elm`)
- Hash URL parsing for all valid routes
- Hash URL generation consistency
- Error handling for invalid URLs
- Round-trip parsing/generation consistency

### Integration Tests (`tests/NavigationFlowIntegrationTest.elm`)
- Route-Page integration with App module
- Browser navigation simulation
- Hash URL parsing integration
- Error handling for invalid hash URLs
- Hash URL consistency across components

### Production Tests (`tests/ProductionHashRoutingTest.elm`)
- Direct hash URL access verification
- Bookmark and refresh functionality
- Production build specific behavior
- Error handling in production environment

## Production Build Requirements

### Web Worker Compatibility
Hash routing works correctly with web workers in production builds:
- AI functionality requires production build
- Development servers don't support worker compilation
- Use `npm run serve`

### Testing Procedure
1. Build production: `npm run build`
2. Start test server: `npm run serve`
3. Test all hash URLs manually
4. Verify bookmark and refresh functionality
5. Follow `PRODUCTION_HASH_ROUTING_TEST_GUIDE.md`

## State Preservation

### Page Models
- Game models initialized on first navigation
- State preserved across route changes
- Theme and window size maintained globally

### Navigation Flow
```
User clicks link → NavigateToRoute msg → Route.navigateTo → Browser updates hash → UrlChanged msg → App updates page
```

## Best Practices

### Route Definition
- Use kebab-case for route paths
- Keep routes simple and descriptive
- Avoid nested routes for simplicity
- Maintain consistency across all routes

### Error Handling
- Always provide fallback routes
- Log invalid URLs for debugging
- Redirect gracefully without breaking user experience
- Test edge cases thoroughly

### Testing
- Test both unit and integration scenarios
- Verify production build behavior
- Test browser navigation (back/forward)
- Validate bookmark and refresh functionality

## Common Issues

### Development vs Production
- Hash routing works differently in development
- Web workers require production build
- Use production test server for accurate testing

### Browser Compatibility
- Hash routing works in all modern browsers
- Graceful degradation for older browsers
- Mobile browser support included

### URL Handling
- Hash fragments are automatically parsed by Browser.Hash
- Query parameters are ignored in routing
- Fragment-based routing prevents server-side routing conflicts

## Migration Guide

When adding new routes:

1. Add route to `Route` type
2. Update `parser` function
3. Add route to `toPath` function
4. Update App.elm page handling
5. Add comprehensive tests
6. Update documentation

## Performance Considerations

- Hash parsing is fast and efficient
- Route changes don't require server requests
- State preservation reduces re-initialization overhead
- Production builds are optimized for routing performance

## Security Considerations

- Hash URLs are client-side only
- No server-side route exposure
- Input validation prevents malicious URLs
- Fallback routes prevent broken states

This hash routing implementation provides a robust, tested, and production-ready navigation system for the Elm application.
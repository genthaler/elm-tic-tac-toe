# URL Routing Implementation Guide

## Overview

The Elm Games application now supports full URL-based routing using `Browser.application`. This enables:

- Direct URL access to all pages
- Browser back/forward navigation
- Bookmarking and sharing of specific pages
- State preservation during navigation

## Architecture

### Browser.application Setup

The application uses `Browser.application` instead of `Browser.element` to gain access to URL handling:

```elm
main : Program Flags AppModel AppMsg
main =
    Browser.application
        { init = init
        , view = \model -> { title = "Elm Games", body = [ view model ] }
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }
```

### Route Module

The `Route.elm` module handles URL parsing and generation:

- `fromUrl : Url -> Maybe Route` - Parse URLs into routes
- `toString : Route -> String` - Convert routes to URL strings
- `toUrl : Route -> Url` - Generate full URL structures

### Supported Routes

| URL | Page | Description |
|-----|------|-------------|
| `/` | Landing | Root URL redirects to `/landing` |
| `/landing` | Landing | Main landing page with navigation |
| `/tic-tac-toe` | Game | Tic-tac-toe game with AI |
| `/robot-game` | Robot Game | Robot grid navigation game |
| `/style-guide` | Style Guide | Component style guide |
| Invalid URLs | Landing | Fallback to landing page |

## Build Configuration

### Server Configuration

The `serve.json` file ensures proper SPA routing:

```json
{
  "public": "dist",
  "rewrites": [
    { "source": "**", "destination": "/index.html" }
  ]
}
```

This configuration ensures that all routes serve the main `index.html` file, allowing the Elm application to handle routing client-side.

### Build Process

The build process uses Parcel with Elm transformer:

1. **Development**: `npm run start:parcel` - For UI development
2. **Production Build**: `npm run build` - Creates optimized build in `dist/`
3. **Production Server**: `npm run serve` - Serves built files with SPA routing

## Testing URL Routing

### Automated Tests

The application includes comprehensive routing tests:

- `RouteTest.elm` - Unit tests for URL parsing and generation
- `RoutingIntegrationTest.elm` - Integration tests for navigation
- `UrlHandlingTest.elm` - Tests for URL handling edge cases

Run tests with: `npm run test`

### Manual Testing

1. **Build the application**:
   ```bash
   npm run build
   ```

2. **Start the production server**:
   ```bash
   npm run serve
   ```

3. **Test direct URL access**:
   - Visit `http://localhost:3000/` (should redirect to `/landing`)
   - Visit `http://localhost:3000/landing`
   - Visit `http://localhost:3000/tic-tac-toe`
   - Visit `http://localhost:3000/robot-game`
   - Visit `http://localhost:3000/style-guide`
   - Visit `http://localhost:3000/invalid-url` (should redirect to `/landing`)

4. **Test browser navigation**:
   - Navigate between pages using the UI
   - Use browser back/forward buttons
   - Refresh pages and verify correct loading
   - Bookmark pages and verify they load correctly

### Web Worker Testing

For testing web worker functionality (tic-tac-toe AI):

1. **Important**: Web workers only work in production builds
2. Use `npm run build && npm run serve` for testing
3. Development mode (`npm run start:parcel`) will not work for worker features

## State Preservation

The routing system preserves:

- **Game State**: Tic-tac-toe and robot game progress maintained during navigation
- **Theme Preferences**: Color scheme preserved across all pages
- **Window Size**: Responsive layout information maintained

## Error Handling

- **Invalid URLs**: Redirect to landing page
- **Malformed URLs**: Graceful fallback to landing
- **Navigation Errors**: Log errors without crashing
- **External Links**: Open in new tabs

## Implementation Details

### URL Synchronization

The application keeps URLs synchronized with page state:

1. **URL Changes**: `UrlChanged` message updates current page
2. **Navigation**: `NavigateToRoute` message updates URL and page
3. **Initialization**: URL determines initial page on app load

### Route-Page Mapping

```elm
routeToPage : Route -> Page
pageToRoute : Page -> Route
```

These functions provide bidirectional conversion between routes and pages, ensuring consistency.

## Deployment Considerations

### Production Deployment

When deploying to production:

1. Ensure server supports SPA routing (serves `index.html` for all routes)
2. Configure proper MIME types for `.js` and `.css` files
3. Set appropriate cache headers for static assets
4. Test all routes work with direct URL access

### Common Server Configurations

**Apache (.htaccess)**:
```apache
RewriteEngine On
RewriteBase /
RewriteRule ^index\.html$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.html [L]
```

**Nginx**:
```nginx
location / {
  try_files $uri $uri/ /index.html;
}
```

**Express.js**:
```javascript
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'dist/index.html'));
});
```

## Troubleshooting

### Common Issues

1. **404 on Direct URL Access**: Server not configured for SPA routing
2. **Worker Errors**: Using development server instead of production build
3. **State Loss**: Check that models are properly preserved in update function
4. **Theme Not Persisting**: Verify localStorage integration in `index.js`

### Debug Steps

1. Check browser developer tools for JavaScript errors
2. Verify network requests are successful
3. Test with production build (`npm run build && npm run serve`)
4. Run automated tests (`npm run test`)
5. Check elm-review for code issues (`npm run review`)
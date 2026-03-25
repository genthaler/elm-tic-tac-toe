# Web Worker Testing Guidelines

## Important: Production Build Required

Web worker functionality **cannot be tested** using development servers like `npm run start:parcel`. Development mode compilation removes the DOM nodes and worker compilation needed for proper web worker functionality.

## Correct Testing Procedure

To test web worker functionality:

1. **Build for production**: `npm run build`
2. **Serve the built files**: `npm run serve`
3. **Test in browser**: Navigate to `http://localhost:3000`

## Why Development Mode Fails

- Parcel's development server doesn't properly compile web workers
- Hot module replacement interferes with worker initialization
- Development builds may not include proper worker bundling
- DOM nodes required for worker communication may be missing

## Testing Web Worker Features

When testing the tic-tac-toe game's AI functionality:

1. Make a move as the human player (X)
2. Observe that the game state changes to "Player O's thinking"
3. Verify that the AI makes a move automatically
4. Check browser developer tools for any worker-related errors
5. Ensure the game continues normally after AI moves

## Development Workflow

- Use `npm run start:parcel` for UI development and non-worker features
- Use `npm run build && npm run serve` when testing worker integration
- Run `npm run test` for unit tests (these don't require workers)
- Always test worker functionality in production build before deployment

## Browser Developer Tools

To debug worker issues:
- Open browser DevTools
- Check the Console tab for worker errors
- Look at the Network tab to verify worker.js is loaded
- Use the Application tab to inspect worker registration
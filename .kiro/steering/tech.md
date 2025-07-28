# Technology Stack

## Core Technologies
- **Elm 0.19.1**: Functional programming language for the frontend
- **Parcel 2.12.0**: Build tool and bundler
- **Node.js >= 20**: Runtime environment

## Key Libraries
- **elm-ui**: UI framework for responsive design
- **elm-book**: Component style guide and documentation
- **elm-test**: Testing framework
- **elm-verify-examples**: Documentation testing

## Architecture
- **Web Workers**: AI computations run in background workers to avoid blocking UI
- **Ports**: Communication between Elm and JavaScript for worker messaging
- **Functional Architecture**: Immutable state with Model-View-Update pattern

## Common Commands

### Development
```bash
npm run parcel         # Start development server with hot reload. This doesn't work with web workers.
npm run book           # Start elm-book style guide server.
```

### Building
```bash
npm run build          # Production build into dist/ (no source maps, no optimization)
npm run serve          # Build and serve files from dist/
```

### Testing
```bash
npm run test           # Run elm-test suite including documentation examples
```

### Deployment
```bash
npm run deploy         # Build and deploy to GitHub Pages
```

## Build Configuration
- Entry points: `src/index.html`, `src/Book.elm`
- Output directory: `dist/`
- Browser support: `> 0.5%, last 2 versions, not dead`
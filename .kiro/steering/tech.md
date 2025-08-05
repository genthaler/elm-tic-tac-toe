# Technology Stack

## Core Technologies
- **Elm 0.19.1-3**: Functional programming language for the frontend
- **Parcel 2.12.0**: Build tool and bundler with @parcel/transformer-elm
- **Node.js >= 20**: Runtime environment

## Key Libraries
- **elm-ui 1.1.8**: Elm UI style framework
- **elm-flat-colors 1.0.1**: Flat UI Colors library
- **elm-book 1.0.1**: Component style guide and documentation
- **elm-test 0.19.1-revision12**: Testing framework
- **elm-verify-examples 5.0.0**: Documentation testing
- **elm-review 2.13.3**: Code analysis and linting

## Architecture
- **Web Workers**: AI computations run in background workers to avoid blocking UI
- **Ports**: Communication between Elm and JavaScript for worker messaging
- **Functional Architecture**: Immutable state with Model-View-Update pattern

## Common Commands

### Testing
```bash
npm run test           # Run elm-test suite including documentation examples
npm run review         # Run elm-review for code analysis
npm run review:fix     # Auto-fix elm-review issues
npm run review:perf    # Benchmark elm-review performance
npm run review:ci      # Run elm-review for CI (JSON output, no color)
```

### Building
```bash
npm run clean          # Remove build artifacts and cache
npm run build          # Production build into dist/ (no source maps, public-url: ./)
```

## Build Configuration
- Entry points: `src/index.html`, `src/Book.elm`
- Output directory: `dist/`
- Browser support: `> 0.5%, last 2 versions, not dead`
- Build tools: Parcel with Elm transformer, serve for local serving
- Utilities: shx for cross-platform shell commands, gh-pages for deployment

## AI hints
- Do not run `npx` to run tools directly, stick to the npm run scripts listed above.
- Do not run `elm` directly.
- Do not run `elm-review` directly.
- Do not run `serve` or `npm run serve`.
- For the scripts that it's OK to run, it's also OK to run `timeout` to invoke the those scripts.
- Before any task is marked complete, the test, review and build scripts must succeed.
- Do not chain commands.
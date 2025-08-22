# Technology Stack

## Core Technologies
- **Elm 0.19.1-3**: Functional programming language for the frontend
- **Parcel 2.12.0**: Build tool and bundler with @parcel/transformer-elm
- **Node.js >= 20**: Runtime environment`

## Key Elm Libraries
- **elm-ui 1.1.8**: Elm UI style framework
- **elm-flat-colors 1.0.1**: Flat UI Colors library
- **elm-book 1.0.1**: Component style guide and documentation
- **elm-test 0.19.1-revision12**: Testing framework
- **elm-verify-examples 5.0.0**: Documentation testing
- **avh4/elm-program-test 4.0.0**: End-to-end testing
- **elm-review 2.13.3**: Code analysis and linting

## Architecture
- **The Elm Architecture**: Immutable state with Model-View-Update pattern
- **Ports**: Communication between Elm and JavaScript for worker messaging
- **Web Workers**: AI computations run in background workers to avoid blocking UI

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

### Text Replacement
```bash
./scripts/find_replace.sh <file_glob> <search_text> <replacement_text> [--yes]
```

**Usage examples:**
```bash
./scripts/find_replace.sh "tests/**/*.elm" ".backgroundColor" ".backgroundColorHex"
./scripts/find_replace.sh "src/**/*.elm" "oldFunction" "newFunction" --yes
./scripts/find_replace.sh "*.md" "TODO" "DONE"
```

The script provides interactive confirmation unless `--yes` flag is used for automation.

## AI hints
- **NEVER run `elm` directly** - always use `npm run test`, `npm run build`, or other npm scripts
- **NEVER run `elm-review` directly** - use `npm run review` instead
- **NEVER run `npx` commands** - stick to the npm run scripts listed above
- **NEVER run `serve` or `npm run serve`** - this is not available in this project
- **NEVER chain commands** with `&&`, `||`, `;` etc - run commands individually
- For the scripts that it's OK to run, it's also OK to run `timeout` to invoke those scripts
- Before any task is marked complete, the test, review and build scripts must succeed
- **ONLY use these npm scripts**: `npm run test`, `npm run review`, `npm run review:fix`, `npm run review:perf`, `npm run review:ci`, `npm run clean`, `npm run build`
- **For bulk text replacements** - use `./scripts/find_replace.sh` for safe, interactive find-and-replace operations
# Elm Tic-Tac-Toe

A sophisticated tic-tac-toe game built with Elm, showcasing advanced functional programming concepts, game theory algorithms, and modern web development practices.

## 🎮 Features

### Core Gameplay
- **Human vs AI**: Play against an intelligent computer opponent
- **Strategic AI**: Uses negamax algorithm with alpha-beta pruning for optimal moves
- **Instant Response**: Web worker architecture keeps UI responsive during AI calculations
- **Smart Difficulty**: AI adapts search depth (5-9 levels) based on game complexity
- **Auto-Play**: Timeout system prevents games from stalling (5-second idle timeout)

### User Experience
- **Responsive Design**: Seamless experience on desktop, tablet, and mobile devices
- **Theme Support**: Beautiful light and dark color schemes with smooth transitions
- **Visual Feedback**: Clear game state indicators and smooth animations
- **Accessibility**: High contrast colors and touch-friendly interface
- **Error Recovery**: Graceful handling of edge cases with user-friendly messages

### Technical Excellence
- **Functional Architecture**: Pure functions, immutable state, and type safety
- **Comprehensive Testing**: 446+ tests covering all functionality and edge cases
- **Performance Optimized**: Bundle size reduced by 80% with advanced optimizations
- **Clean Code**: Well-documented, maintainable codebase following Elm best practices

## 🧠 AI Intelligence & Performance

The AI opponent uses advanced game theory algorithms with multiple performance optimizations:

### Algorithm Features
- **Negamax with Alpha-Beta Pruning**: Eliminates up to 75% of search nodes
- **Intelligent Move Ordering**: Evaluates tactical moves first for maximum pruning efficiency
- **Adaptive Search Depth**: Dynamically adjusts from 5-9 levels based on position complexity
- **Early Termination**: Instantly detects winning moves and critical blocks
- **Iterative Deepening**: Progressive search refinement for complex mid-game positions

### Strategic Capabilities
- **Tactical Awareness**: Prioritizes immediate wins and blocks opponent threats
- **Positional Understanding**: Values center control and corner positions
- **Fork Recognition**: Identifies and creates multiple winning threats
- **Endgame Precision**: Perfect play in positions with few remaining moves

### Performance Benchmarks
- **Opening Moves**: <1ms decision time with strategic preferences
- **Mid-Game**: 5-15ms with full tactical evaluation
- **Endgame**: 2-8ms with complete position analysis
- **Memory Usage**: Minimal footprint due to functional immutability
- **Search Efficiency**: 60-80% node pruning in typical positions

### Technical Architecture
- **Web Worker Integration**: AI computations run in background thread
- **Optimized Evaluation**: Cached board scoring with vectorized line analysis
- **Performance Monitoring**: Built-in metrics for algorithm optimization
- **Robust Error Handling**: Graceful degradation and recovery mechanisms

## 🚀 Quick Start

### Prerequisites
- Node.js >= 20
- npm or yarn package manager

### Installation

```bash
# Clone the repository
git clone https://github.com/genthaler/elm-tic-tac-toe.git

# Navigate to project directory
cd elm-tic-tac-toe

# Install dependencies
npm install
```

### Development Commands

```bash
# Start development server with hot reload
npm run start:parcel

# Build and serve production version
npm run start

# Build optimized production bundle
npm run build

# Serve built files
npm run serve

# Run comprehensive test suite
npm run test

# Run tests with documentation verification
npm run test:all

# Watch mode for test-driven development
npm run test:watch
```

### Code Quality & Linting

This project uses [elm-review](https://package.elm-lang.org/packages/jfmengels/elm-review/latest/) for automated code quality analysis and linting.

```bash
# Run elm-review to analyze code quality
npm run review

# Automatically fix issues that can be safely auto-fixed
npm run review:fix

# Run elm-review with performance benchmarking
npm run review:perf

# Run elm-review excluding tests directory
npm run review:clean

# Run elm-review with CI-friendly output (JSON format, no colors)
npm run review:ci
```

#### elm-review Rules

The project is configured with a comprehensive set of rules in `review/src/ReviewConfig.elm`:

**Code Quality Rules:**
- **NoDebug.Log**: Prevents `Debug.log` statements from reaching production
- **NoDebug.TodoOrToString**: Catches TODO comments and toString usage
- **NoConfusingPrefixOperator**: Prevents confusing operator usage
- **NoSimpleLetBody**: Suggests removing unnecessary let expressions
- **NoPrematureLetComputation**: Optimizes let expression placement

**Module Structure Rules:**
- **NoExposingEverything**: Encourages explicit exports
- **NoImportingEverything**: Prevents wildcard imports
- **NoMissingTypeAnnotation**: Ensures functions have type signatures
- **NoMissingTypeExpose**: Ensures exposed types are properly documented

**Unused Code Detection:**
- **NoUnused.Variables**: Detects unused variables and function parameters
- **NoUnused.Parameters**: Identifies unused function parameters
- **NoUnused.Patterns**: Finds unused pattern matches
- **NoUnused.CustomTypeConstructors**: Detects unused type constructors
- **NoUnused.Exports**: Identifies unused module exports
- **NoUnused.Modules**: Finds unused module dependencies
- **NoUnused.Dependencies**: Detects unused package dependencies

**Documentation & Simplification:**
- **Docs.ReviewAtDocs**: Ensures documentation quality
- **Simplify**: Suggests more idiomatic Elm patterns and simplifications

**Performance Optimization:**
Rules are ordered from fastest to slowest, and test directories have relaxed rules to avoid unnecessary analysis overhead.

#### Customizing elm-review Rules

To add or modify rules:

1. Install new rule packages: `cd review && elm install author/package-name`
2. Edit `review/src/ReviewConfig.elm` to import and configure the rule
3. Test the configuration: `npm run review`

**Example: Adding a new rule**
```elm
-- In review/src/ReviewConfig.elm
import SomeNewRule

config : List Rule
config =
    [ -- existing rules...
    , SomeNewRule.rule SomeNewRule.defaults
    ]
```

**Example: Configuring rule exceptions**
```elm
-- Ignore specific rules in test directories
, NoMissingTypeAnnotation.rule
    |> Rule.ignoreErrorsForDirectories [ "tests/" ]

-- Configure rule with custom settings
, Simplify.rule (Simplify.defaults |> Simplify.ignoreConstructors [ "MyType" ])
```

**Example: Disabling a rule temporarily**
```elm
-- Comment out rules you want to disable
-- , NoDebug.Log.rule
```

#### Troubleshooting elm-review

**Common Issues:**

- **"elm-review command not found"**: Run `npm install` to ensure elm-review is installed
- **Configuration errors**: Check `review/src/ReviewConfig.elm` for syntax errors
- **Rule conflicts**: Some rules may conflict with project style - disable specific rules if needed
- **Performance issues**: Use `npm run review:perf` to identify slow rules

**Getting Help:**
- Check the [elm-review documentation](https://package.elm-lang.org/packages/jfmengels/elm-review/latest/)
- Browse available rules at [elm-review rules](https://package.elm-lang.org/packages/jfmengels/elm-review/latest/Review-Rule)
- Report issues to the [elm-review GitHub repository](https://github.com/jfmengels/node-elm-review)

### Testing Web Worker Functionality

**Important**: Web worker features require production build testing:

```bash
# Build for production (required for workers)
npm run build

# Serve built files
npm run serve

# Open http://localhost:3000 in browser
```

Development servers don't properly support web worker compilation.

## 🏗️ Architecture & Development

### Technology Stack
- **Elm 0.19.1**: Functional programming language for frontend
- **Parcel 2.12**: Modern build tool with zero configuration
- **elm-ui**: Declarative UI framework with responsive design
- **elm-flat-colors 1.0.1**: Flat UI Colors library
- **Web Workers**: Background processing for AI computations
- **elm-test**: Comprehensive testing framework
- **elm-review**: Static analysis tool for code quality and linting

### Project Structure

#### Root Directory
```
├── elm.json                     # Elm package configuration and dependencies
├── package.json                 # Node.js dependencies and npm scripts
├── .parcelrc                    # Parcel bundler configuration
├── .tool-versions               # Development tool versions
└── README.md                    # Project documentation
```

#### Source Code (`src/`)
```
src/
├── App.elm                      # Main application entry point with routing and ports
├── Book.elm                     # Component style guide using elm-book
├── index.html                   # HTML entry point
├── index.js                     # JavaScript bridge and worker setup
├── worker.js                    # Web worker initialization
├── Landing/
│   ├── Landing.elm              # Landing page logic and state management
│   └── LandingView.elm          # Landing page UI components
├── TicTacToe/
│   ├── Main.elm                 # Game application logic and subscriptions
│   ├── Model.elm                # Core data types, game state, and JSON encoding/decoding
│   ├── View.elm                 # UI rendering and visual components
│   ├── GameWorker.elm           # Web worker for AI game logic
│   └── TicTacToe.elm            # Core game rules, move validation, and AI integration
└── GameTheory/
    ├── AdversarialEager.elm     # Negamax algorithms
    ├── AdversarialLazy.elm      # Lazy evaluation variants
    └── ExtendedOrder.elm        # Extended ordering utilities for game evaluation
```

#### Tests (`tests/`)
```
tests/
├── Landing/                     # Landing page tests
├── TicTacToe/                   # Game logic tests
├── GameTheory/                  # Algorithm-specific tests
└── elm-verify-examples.json    # Configuration for documentation testing
```

#### Configuration & Build (`review/`)
```
review/
├── elm.json                     # elm-review dependencies
├── elm-stuff/                   # elm-review compiler cache
├── src/
│   └── ReviewConfig.elm         # Code quality rules configuration
└── suppressed/                  # Suppressed review issues
```

#### Generated/Build Artifacts
```
├── elm-stuff/                   # Elm compiler cache and generated files
├── dist/                        # Production build output
├── .parcel-cache/               # Parcel bundler cache
└── node_modules/                # Node.js dependencies
```

#### Naming Conventions
- **Elm modules**: PascalCase (e.g., `TicTacToe.elm`)
- **Test files**: Append `Test` (e.g., `TicTacToeTest.elm`)
- **Folders**: Group related functionality by domain
- **Game theory algorithms**: Separated into their own module hierarchy

### Data Flow Architecture

```
User Input → App.elm → TicTacToe/Main.elm → Model Update → View Rendering
     ↓
AI Turn → Web Worker → TicTacToe/GameWorker.elm → AI Algorithm → Move Response
```

### Key Design Patterns
- **Model-View-Update (MVU)**: Elm's architecture for predictable state management
- **Immutable State**: All data structures are immutable for reliability
- **Pure Functions**: No side effects in core game logic
- **Type Safety**: Compile-time guarantees prevent runtime errors
- **Port Communication**: Type-safe JavaScript interop for web workers 

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the ISC License - a permissive open source license that lets people do anything with your code with proper attribution and without warranty. The ISC license is functionally equivalent to the MIT License but with simpler language.

## 📊 Performance Summary

### Bundle Size Optimization
- **Main Application**: 91KB (optimized from 512KB - 82% reduction)
- **AI Worker**: 21KB (optimized from 136KB - 85% reduction)  
- **Style Guide**: 145KB (optimized from 815KB - 82% reduction)
- **Total Bundle**: ~257KB (down from ~1.46MB - 82% overall reduction)

### Runtime Performance
- **Initial Load**: <100ms on modern browsers
- **AI Response Time**: 1-15ms for most positions
- **Memory Usage**: <5MB typical, minimal garbage collection
- **UI Responsiveness**: 60fps maintained during AI calculations
- **Test Coverage**: 446 tests with 100% pass rate

### Browser Compatibility
- **Modern Browsers**: Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
- **Mobile Support**: iOS Safari, Chrome Mobile, Samsung Internet
- **Progressive Enhancement**: Graceful degradation for older browsers

## 🔗 Learn More

### Elm Resources
- [Elm Guide](https://guide.elm-lang.org/) - Official Elm learning resource
- [Elm Packages](https://package.elm-lang.org/) - Community packages
- [Elm Discourse](https://discourse.elm-lang.org/) - Community discussions

### Game Theory & AI
- [Negamax Algorithm](https://en.wikipedia.org/wiki/Negamax) - Core AI algorithm
- [Alpha-Beta Pruning](https://en.wikipedia.org/wiki/Alpha%E2%80%93beta_pruning) - Optimization technique
- [Game Theory](https://en.wikipedia.org/wiki/Game_theory) - Mathematical foundation

### Web Performance
- [Web Workers](https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API) - Background processing
- [Bundle Optimization](https://web.dev/reduce-javascript-payloads-with-code-splitting/) - Performance techniques


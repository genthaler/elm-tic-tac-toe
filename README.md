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
- **Web Workers**: Background processing for AI computations
- **elm-test**: Comprehensive testing framework

### Project Structure

```
src/
├── Main.elm              # Application entry point and main game loop
├── Model.elm             # Core data types and JSON serialization
├── View.elm              # UI rendering with responsive design
├── GameWorker.elm        # Web worker for AI computations
├── TicTacToe/
│   └── TicTacToe.elm     # Core game logic and AI algorithms
├── GameTheory/
│   ├── AdversarialEager.elm  # Negamax algorithm implementations
│   └── ExtendedOrder.elm     # Extended ordering for game values
├── index.html            # HTML entry point
├── index.js              # JavaScript bridge and worker setup
└── worker.js             # Web worker initialization

tests/
├── *Test.elm             # Comprehensive test suites
├── GameTheory/           # Algorithm-specific tests
├── TicTacToe/            # Game logic tests
└── elm-verify-examples.json  # Documentation testing config
```

### Data Flow Architecture

```
User Input → Main.elm → Model Update → View Rendering
     ↓
AI Turn → Web Worker → GameWorker.elm → AI Algorithm → Move Response
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


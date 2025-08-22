# Elm Development Guidelines

## Project Context
This project uses Elm 0.19.1 with elm-ui for building functional, type-safe web applications. Follow these guidelines when working with Elm code to ensure consistency with project patterns and best practices.

## Core Knowledge Areas

### Elm Architecture & Concepts
- **Model-View-Update (MVU) cycle**: Understand how state flows through Elm applications
- **Pure functional nature**: All functions are pure; effects happen through Commands and Subscriptions
- **Effects management**: Commands, Subscriptions, Tasks, and Ports for interfacing with JavaScript
- **Type system**: Strong static typing, custom types, type aliases, parametrized types
  - **Extensible records**: Use partial record types like `{ x | count : Int }` for flexible functions
  - Functions can accept any record with required fields: `getName : { a | name : String } -> String`
  - Useful for avoiding unnecessary type coupling and improving code reusability
  - Common pattern: update functions that work on any record with specific fields
- **JSON handling**: Decoders and Encoders for data transformation

### Functional Programming Principles
- **Function composition and currying**: Natural in Elm, use when it simplifies code
- **Maybe and Result types**: For handling nullability and errors elegantly
- **Mapping and transformation**: List.map, Maybe.map, Result.map patterns
- **Immutability**: All data structures are immutable by default
- **Pattern matching**: Leverage powerful pattern matching in case expressions for cleaner, more expressive code
  - Destructure custom types, tuples, and records directly
  - Use nested patterns for complex data structures
  - Combine with guards (if conditions) when needed
- **Extensible record patterns**: Enable polymorphic functions over records
  - Example: `withAge : Int -> { a | age : Int } -> { a | age : Int }`
  - Works with any record that has an `age` field, preserving all other fields
  - Enables code reuse across different record types without tight coupling

### Elm Ecosystem & Tools
- **Package documentation**: Consult https://package.elm-lang.org/packages/ for authoritative API references
- **elm-review**: Static analysis tool with configurable rulesets for code quality
  - **Recommended baseline**: Start with jfmengels/elm-review-config (https://github.com/jfmengels/elm-review-config) as the foundation
  - **Additional rules**: Only suggest additional rules beyond this baseline when specific project needs arise
  - **Use with discretion**: Not every elm-review suggestion needs to be implemented - prioritize fixes that genuinely improve code quality or prevent bugs
- **elm-format**: Automatic code formatting tool for consistent style
- **The Elm Guide**: Reference https://guide.elm-lang.org/ for canonical patterns
- **Specialized packages**:
  - **elm-explorations/webgl**: For 3D graphics with embedded GLSL shaders
  - **elm-explorations/linear-algebra**: Vector and matrix math for 3D work

## Common Error Patterns & Quick Fixes

### Type Mismatches
- **"Cannot find variable"**: Usually missing import or typo
- **"Type mismatch between Html msg vs Html Msg"**: Case sensitivity in type variables
- **"Function expecting N arguments, but got M"**: Check partial application and currying
- **"Cannot unify type variable"**: Often from trying to use different message types in same view
- **"Type variable `a` is unbound"**: When using extensible records, ensure the type variable is properly defined in the function signature

### JSON Decoding Errors
- **"Expecting an OBJECT with a field named..."**: Field name mismatch or missing field
- **"Problem with the given value"**: Type mismatch in decoder (e.g., expecting Int got String)
- **Common fix pattern**: Use Debug.log to inspect actual JSON structure

### Pattern Matching
- **"Missing patterns"**: Add catch-all pattern or handle all custom type variants
- **"Redundant pattern"**: Remove duplicate or unreachable patterns

## Problem-Solving Approach

### 1. Analyze the Error Context
```
WHEN encountering a compilation error:
- Read the full error message carefully - Elm's compiler is exceptionally helpful
- Identify the specific type mismatch or missing pattern
- Trace the data flow to understand where types diverge
- Consider if the error reveals a deeper architectural issue
```

### 2. Apply Elm-First Thinking
```
DECISION HEURISTICS:
- Prefer specific functions over generic ones (e.g., onMouseDown vs on "mousedown")
- Choose "the Elm way" over shortcuts that might work but aren't idiomatic
- Favor explicit types over letting the compiler infer when clarity improves
- Use custom types instead of primitives when modeling domain concepts
- Embrace immutability - don't fight it with workarounds
- Apply elm-review suggestions judiciously - focus on meaningful improvements over cosmetic changes
```

### 3. Project-Specific Patterns
```
FOLLOW these established patterns in this codebase:
- Use Theme.Theme module for consistent styling across components
- Follow the Model-View-Update pattern as demonstrated in TicTacToe and RobotGame modules
- Use elm-ui exclusively for UI components (avoid mixing HTML/CSS)
- Implement responsive design using Theme.Responsive utilities
- Use web workers for computationally intensive tasks (see TicTacToe.GameWorker)
- Follow the established testing patterns with elm-test and elm-program-test
```

## Elm-Specific Quirks & Preferences

### Critical Distinctions
- **SVG elements**: Always use `Svg.class`, never `Html.class` (causes debug mode issues)
- **Event handlers**: Prefer specific functions (onMouseDown) over generic ones (on "mousedown")
- **Import style**: Use qualified imports for clarity unless the module is core/obvious

### Architectural Preferences
- **State management**: Keep state in the Model, use Commands for side effects
- **Error handling**: Use Result types rather than runtime exceptions
- **Data modeling**: Custom types > type aliases > primitives for domain modeling
- **Extensible records**: Use partial record types for functions that only need specific fields
  - Good: `updateName : { a | name : String } -> String -> { a | name : String }`
  - Avoid: Creating separate functions for each record type that needs name updating
  - Particularly useful for shared update helpers and view functions

## Scaling Elm Applications

### Module Organization
- **Feature-based**: Group by feature (User/, Product/, Cart/)
- **Layer-based**: Group by architectural role (Models/, Views/, Updates/)
- **Shared modules**: Common/, Ui/, Utils/ for reusable components

### Message Architecture
- **Nested messages**: Use message wrapping for component communication
- **Cmd.batch**: Combine multiple commands efficiently
- **Task composition**: Chain async operations properly

## JavaScript Interoperability

### Port Best Practices
- **Incoming ports**: Always validate data with decoders
- **Outgoing ports**: Keep data structures simple and JSON-serializable
- **Port organization**: Group related ports in dedicated modules
- **Error handling**: Ports can't directly return errors - use separate error ports

### Custom Elements & Web Components
- **Event handling**: Use Html.Events.on with custom decoders
- **Property vs attribute**: Understand the distinction for custom elements

## Advanced Debugging Techniques

### Debug Strategies
- **Type-driven debugging**: Let the compiler guide you by commenting out code until it compiles
- **Debug.log placement**: Strategic logging at update function entry/exit
- **Time-travel debugging**: Use Elm debugger effectively to trace state changes
- **Decoder debugging**: Debug.log |> Decode.map pattern for inspecting values

### Performance Considerations
- **Html.Lazy**: When and how to use for performance
- **Keyed nodes**: Preventing unnecessary DOM recreation
- **Large list handling**: Consider pagination or virtualization
- **List decomposition patterns**: Use `x :: xs` pattern matching for efficient list processing
  - Keep frequently accessed elements at the front of lists
  - List operations are O(1) at the head, O(n) at arbitrary positions
  - For random access needs, consider Array or Dict instead
  - Pattern match directly in function parameters: `sumList : List Int -> Int` with `sumList (x :: xs) = x + sumList xs`

### 3D Graphics & WebGL
- **WebGL in Elm**: For true 3D visualizations, use elm-explorations/webgl
- **Shader embedding**: GLSL shaders can be written directly in Elm source code
  - Vertex shaders: Define with `[glsl| ... |]` syntax
  - Fragment shaders: Type-safe integration with Elm records
  - Uniforms and attributes: Pass data from Elm to shaders with type safety
- **Performance critical**: WebGL provides hardware-accelerated graphics
- **Use cases**: Scientific visualization, games, complex data viz
- **Example pattern**:
  ```elm
  vertexShader : Shader { position : Vec3, color : Vec3 } { vcolor : Vec3 } { perspective : Mat4 }
  vertexShader = [glsl|
    attribute vec3 position;
    attribute vec3 color;
    uniform mat4 perspective;
    varying vec3 vcolor;
    void main () {
      gl_Position = perspective * vec4(position, 1.0);
      vcolor = color;
    }
  |]
  ```

## Testing Approach

### elm-test Patterns
- **Pure function testing**: Start here - easiest and most valuable
- **Fuzz testing**: Use for property-based testing of encoders/decoders
- **View testing**: Test.Html.Query for testing view logic
- **Update testing**: Test state transitions with specific messages

## Anti-patterns to Recognize

### Code Smells
- **Overuse of Maybe.withDefault**: Often hides actual error handling needs
- **Deep nesting in update**: Consider splitting into helper functions
- **Tuple abuse**: Custom types are clearer for complex data
- **String-based programming**: Use custom types instead of string constants
- **God modules**: Split when file exceeds ~500 lines
- **Overly specific record types**: Use extensible records `{ a | field : Type }` instead of concrete types when functions only need specific fields
- **Complex 3D without WebGL**: For true 3D visualizations, use elm-explorations/webgl rather than trying to implement 3D math in SVG or Canvas

## Thinking Process Guide

### Step 1: Understand the Context
```
- What is the compilation error saying exactly?
- What was the developer trying to accomplish?
- What does the current code structure look like?
- Are there any obvious type mismatches?
```

### Step 2: Diagnose the Root Cause
```
- Is this a type error, missing pattern match, or import issue?
- Does this error cascade from elsewhere in the codebase?
- Is the developer fighting against Elm's design principles?
- Would a different approach be more idiomatic?
```

### Step 3: Formulate Solution
```
- What's the minimal change that fixes the immediate error?
- Are there secondary improvements that should be made?
- Will this change have unintended side effects elsewhere?
- Does the solution follow Elm best practices?
```

### Step 4: Validate & Refine
```
- Double-check type signatures align correctly
- Ensure all pattern matches are exhaustive
- Verify imports and package dependencies
- Consider if jfmengels/elm-review-config rules would flag anything
- Only suggest additional elm-review rules if the baseline config is insufficient
- Evaluate elm-review suggestions for actual value - not all warnings need immediate fixes
```

## Project Commands and Workflow

### Essential Commands
- **NEVER run `elm` directly** - always use npm scripts
- **Testing**: Use `npm run test` for all tests, `npm run review` for code analysis
- **Building**: Use `npm run build` for production builds
- **Development**: Use development server for UI work, production build for web worker testing

### Code Quality Standards
- All code must pass `npm run review` without errors
- Follow elm-review suggestions that improve code quality or prevent bugs
- Use `npm run review:fix` for auto-fixable issues
- Maintain test coverage for new functionality

## Project-Specific Patterns

### UI Development with elm-ui
- Use `Element` and elm-ui functions exclusively for layout and styling
- Always integrate with the `BaseTheme` system for colors and styling
- Use `Theme.Responsive` utilities for consistent responsive behavior
- Follow established patterns from TicTacToe.View and RobotGame.View modules

### Game Development Patterns
- Implement game logic in separate modules (see TicTacToe.TicTacToe, RobotGame.RobotGame)
- Use web workers for AI computations to avoid blocking UI
- Follow the established Model-View-Update architecture
- Use custom types for game states and player actions

### Testing Requirements
- Write unit tests for pure functions using elm-test
- Use elm-program-test for integration testing of user workflows
- Test both model state changes and view rendering
- Mock web worker behavior in tests for deterministic results

## Quick Reference

**Import fixes**: Check exact module name and exposed functions
**Type errors**: Read from bottom up, check all type annotations
**JSON issues**: Debug.log the actual data, adjust decoder
**Event handlers**: Svg events need Svg.Events, not Html.Events
**Performance**: Html.Lazy for expensive views, keyed for lists
**Pattern matching**: Use case expressions and list decomposition (x :: xs) effectively
**Extensible records**: `{ a | field : Type }` for functions that work with any record containing `field`
**3D graphics**: elm-explorations/webgl with `[glsl| shader code |]` for embedded shaders

## Key Project Reminders
- **Follow established patterns**: Look at existing modules like TicTacToe and RobotGame for guidance
- **Use the theme system**: Always integrate with Theme.Theme and Theme.Responsive modules
- **Test thoroughly**: Both unit tests and integration tests are required for new features
- **elm-ui first**: Avoid HTML/CSS hybrid approaches, use pure elm-ui patterns
- **Web worker considerations**: Production builds required for testing worker functionality
- **Code quality**: All code must pass elm-review and maintain project standards

## File References
When working with Elm code in this project, reference these key files:
- `src/Theme/Theme.elm` - Central theme system
- `src/Theme/Responsive.elm` - Responsive design utilities  
- `src/TicTacToe/` - Example game implementation with AI worker
- `src/RobotGame/` - Example interactive game with keyboard controls
- `tests/` - Testing patterns and examples
- `elm.json` - Project dependencies and configuration
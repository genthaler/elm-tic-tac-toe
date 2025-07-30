# Design Document

## Overview

This design outlines the integration of elm-review into the Elm Tic-Tac-Toe project. elm-review will be added as a development dependency with a carefully selected ruleset that provides valuable code quality feedback while being appropriate for the project's current architecture and coding style.

## Architecture

### Tool Integration
- **elm-review**: Main static analysis tool for Elm code
- **npm scripts**: Integration point for running elm-review commands
- **Configuration file**: `review/src/ReviewConfig.elm` for rule configuration
- **CI Integration**: elm-review will be part of the test suite

### File Structure
```
project-root/
├── review/
│   ├── elm.json              # elm-review dependencies
│   └── src/
│       └── ReviewConfig.elm  # Rule configuration
├── package.json              # Updated with elm-review scripts
└── existing files...
```

## Components and Interfaces

### Package Dependencies
- **jfmengels/elm-review**: Core review tool (2.15.1)
- **jfmengels/elm-review-unused**: Comprehensive unused code detection (1.2.4)
- **jfmengels/elm-review-simplify**: Code simplification suggestions (2.1.9)
- **jfmengels/elm-review-debug**: Debug statement detection (1.0.8)
- **jfmengels/elm-review-common**: Common best practices (1.3.3)
- **jfmengels/elm-review-documentation**: Documentation quality rules (2.0.4)
- **jfmengels/elm-review-code-style**: Code style enforcement (1.2.0)

### NPM Scripts
```json
{
  "review": "elm-review",
  "review:fix": "elm-review --fix-all-without-prompt",
  "review:perf": "time elm-review --benchmark-info",
  "review:clean": "elm-review --ignore-dirs tests/",
  "review:ci": "elm-review --no-color --report=json",
  "pretest": "elm-verify-examples && npm run review"
}
```

**Script Purposes:**
- **review**: Basic elm-review execution for development
- **review:fix**: Automatically fix all issues that can be safely auto-fixed
- **review:perf**: Performance benchmarking with timing information
- **review:clean**: Run review excluding test directories for faster analysis
- **review:ci**: CI-friendly output with JSON format and no colors
- **pretest**: Integration with test workflow - runs elm-review before tests

### Configuration Strategy
The ReviewConfig.elm includes a comprehensive ruleset organized by performance impact:

**Fast Syntax-Based Rules:**
1. **NoConfusingPrefixOperator**: Prevent confusing operator usage
2. **NoDebug.Log**: Prevent Debug.log in production code
3. **NoDebug.TodoOrToString**: Catch TODO comments and toString usage
4. **NoSimpleLetBody**: Remove unnecessary let expressions
5. **NoPrematureLetComputation**: Optimize let expression placement

**Module Structure Rules:**
6. **NoExposingEverything**: Encourage explicit exports
7. **NoImportingEverything**: Prevent wildcard imports
8. **NoMissingTypeAnnotation**: Ensure functions have type signatures
9. **NoMissingTypeExpose**: Ensure exposed types are documented

**Unused Code Detection Rules:**
10. **NoUnused.Variables**: Detect unused variables
11. **NoUnused.Parameters**: Identify unused function parameters
12. **NoUnused.Patterns**: Find unused pattern matches
13. **NoUnused.CustomTypeConstructorArgs**: Detect unused constructor arguments
14. **NoUnused.CustomTypeConstructors**: Find unused type constructors
15. **NoUnused.Exports**: Identify unused module exports
16. **NoUnused.Modules**: Find unused module dependencies
17. **NoUnused.Dependencies**: Detect unused package dependencies

**Documentation and Simplification Rules:**
18. **Docs.ReviewAtDocs**: Ensure documentation quality
19. **Simplify**: Suggest more idiomatic Elm patterns

**Performance Optimization:**
- Rules are ordered from fastest to slowest execution
- Test directories have relaxed rules via `Rule.ignoreErrorsForDirectories`
- Expensive analysis rules run last to maximize early termination benefits

## Data Models

### Review Configuration
```elm
module ReviewConfig exposing (config)

import Docs.ReviewAtDocs
import NoConfusingPrefixOperator
import NoDebug.Log
import NoDebug.TodoOrToString
import NoExposingEverything
import NoImportingEverything
import NoMissingTypeAnnotation
import NoMissingTypeExpose
import NoPrematureLetComputation
import NoSimpleLetBody
import NoUnused.CustomTypeConstructorArgs
import NoUnused.CustomTypeConstructors
import NoUnused.Dependencies
import NoUnused.Exports
import NoUnused.Modules
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
import Review.Rule as Rule exposing (Rule)
import Simplify

config : List Rule
config =
    -- Fast syntax-based rules first
    [ NoConfusingPrefixOperator.rule
    , NoDebug.Log.rule
    , NoDebug.TodoOrToString.rule
        |> Rule.ignoreErrorsForDirectories [ "tests/" ]
    , NoSimpleLetBody.rule
    , NoPrematureLetComputation.rule
    
    -- Module structure rules
    , NoExposingEverything.rule
        |> Rule.ignoreErrorsForDirectories [ "tests/" ]
    , NoImportingEverything.rule []
        |> Rule.ignoreErrorsForDirectories [ "tests/" ]
    , NoMissingTypeAnnotation.rule
        |> Rule.ignoreErrorsForDirectories [ "tests/" ]
    , NoMissingTypeExpose.rule
    
    -- Unused detection rules
    , NoUnused.Variables.rule
    , NoUnused.Parameters.rule
    , NoUnused.Patterns.rule
    , NoUnused.CustomTypeConstructorArgs.rule
    , NoUnused.CustomTypeConstructors.rule []
    , NoUnused.Exports.rule
        |> Rule.ignoreErrorsForDirectories [ "tests/" ]
    , NoUnused.Modules.rule
    , NoUnused.Dependencies.rule
    
    -- Documentation and simplification rules
    , Docs.ReviewAtDocs.rule
        |> Rule.ignoreErrorsForDirectories [ "tests/" ]
    , Simplify.rule Simplify.defaults
        |> Rule.ignoreErrorsForDirectories [ "tests/" ]
    ]
```

### Integration Points
- **Pre-test hook**: Run elm-review before elm-test
- **Build validation**: Ensure code quality before builds
- **Developer workflow**: Easy access via npm scripts

## Error Handling

### Review Failures
- **Exit codes**: elm-review uses standard exit codes (0 = success, 1 = issues found)
- **Error reporting**: Clear console output with file locations and issue descriptions
- **Graceful degradation**: If elm-review fails to run, other tools should continue

### Configuration Errors
- **Invalid rules**: elm-review will report configuration errors clearly
- **Missing dependencies**: Package installation will be validated
- **Version conflicts**: Use compatible versions of all review packages

### Integration Failures
- **Script failures**: npm scripts will propagate exit codes appropriately
- **CI integration**: Failed reviews will fail the build process
- **Developer experience**: Clear error messages for common issues

## Testing Strategy

### Validation Approach
1. **Installation testing**: Verify elm-review installs correctly
2. **Configuration testing**: Ensure ReviewConfig.elm compiles and runs
3. **Rule testing**: Test that rules detect expected issues
4. **Integration testing**: Verify npm scripts work as expected
5. **CI testing**: Confirm elm-review runs in automated environments

### Test Cases
- **Clean codebase**: elm-review should pass on current code
- **Intentional issues**: Create test files with known issues to verify detection
- **Auto-fix testing**: Verify --fix-all works for fixable issues
- **Performance testing**: Ensure reasonable execution time

### Quality Assurance
- **Rule selection**: Choose rules that add value without being overly restrictive
- **False positive management**: Configure rules to minimize false positives
- **Documentation**: Provide clear guidance on using elm-review
- **Maintenance**: Plan for updating rules and dependencies

## Implementation Considerations

### Rule Selection Rationale

**Code Quality Rules:**
- **NoConfusingPrefixOperator**: Prevents hard-to-read operator usage
- **NoSimpleLetBody**: Eliminates unnecessary let expressions for cleaner code
- **NoPrematureLetComputation**: Optimizes performance by proper let placement

**Debug Prevention Rules:**
- **NoDebug.Log**: Prevents debug statements from reaching production
- **NoDebug.TodoOrToString**: Catches TODO comments and toString usage that should be addressed

**Module Structure Rules:**
- **NoExposingEverything**: Encourages explicit exports for better API design
- **NoImportingEverything**: Prevents namespace pollution and improves compile times
- **NoMissingTypeAnnotation**: Ensures functions have type signatures for better documentation
- **NoMissingTypeExpose**: Ensures exposed types are properly documented

**Comprehensive Unused Code Detection:**
- **NoUnused.Variables**: Identifies dead code and unused variables
- **NoUnused.Parameters**: Finds unused function parameters
- **NoUnused.Patterns**: Detects unused pattern matches
- **NoUnused.CustomTypeConstructorArgs**: Finds unused constructor arguments
- **NoUnused.CustomTypeConstructors**: Identifies unused type constructors
- **NoUnused.Exports**: Reduces API surface by finding unused exports
- **NoUnused.Modules**: Identifies unused module dependencies
- **NoUnused.Dependencies**: Detects unused package dependencies for smaller bundles

**Documentation and Simplification:**
- **Docs.ReviewAtDocs**: Ensures documentation quality and completeness
- **Simplify**: Suggests more idiomatic Elm patterns and optimizations

**Test Directory Exceptions:**
Many rules are relaxed for test directories using `Rule.ignoreErrorsForDirectories [ "tests/" ]` to avoid overly restrictive analysis where different patterns are acceptable.

### Performance Optimization
- **Incremental analysis**: elm-review only analyzes changed files when possible
- **Parallel execution**: Tool runs efficiently on multi-core systems
- **Caching**: elm-review caches analysis results for faster subsequent runs

### Developer Experience
- **Clear output**: Well-formatted error messages with context
- **IDE integration**: Works with popular Elm IDE extensions
- **Customization**: Easy to add or remove rules as project evolves
- **Documentation**: Include usage examples in project README
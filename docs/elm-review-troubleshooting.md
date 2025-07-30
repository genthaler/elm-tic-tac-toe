# elm-review Troubleshooting Guide

This guide helps resolve common issues when working with elm-review in the Elm Tic-Tac-Toe project.

## Installation Issues

### "elm-review command not found"

**Problem**: The `elm-review` command is not available in your terminal.

**Solutions**:
1. Ensure elm-review is installed: `npm install`
2. Check if it's in your local node_modules: `./node_modules/.bin/elm-review --version`
3. Use npm scripts instead: `npm run review`

### "Cannot find module 'elm-review'"

**Problem**: elm-review package is missing from node_modules.

**Solutions**:
1. Delete node_modules and reinstall: `rm -rf node_modules && npm install`
2. Check package.json has elm-review in devDependencies
3. Try installing explicitly: `npm install --save-dev elm-review`

## Configuration Issues

### "ReviewConfig.elm has compilation errors"

**Problem**: The review configuration file has syntax errors.

**Solutions**:
1. Check `review/src/ReviewConfig.elm` for syntax errors
2. Ensure all imported rules are available in `review/elm.json`
3. Run `elm make review/src/ReviewConfig.elm` to see specific errors
4. Compare with the working configuration in the repository

### "Rule not found" errors

**Problem**: A rule is imported but the package isn't installed.

**Solutions**:
1. Check `review/elm.json` for missing dependencies
2. Install missing rule packages: `cd review && elm install author/package-name`
3. Remove unused rule imports from ReviewConfig.elm

### "Conflicting rule configurations"

**Problem**: Multiple rules conflict with each other or project style.

**Solutions**:
1. Review rule documentation for configuration options
2. Disable conflicting rules temporarily
3. Configure rules with custom settings:
   ```elm
   SomeRule.rule (SomeRule.defaults |> SomeRule.ignoreInLambdas)
   ```

## Performance Issues

### "elm-review is very slow"

**Problem**: Review takes too long to complete.

**Solutions**:
1. Use `npm run review:perf` to identify slow rules
2. Consider excluding large directories: `npm run review:clean`
3. Update to latest elm-review version
4. Check for rules that analyze the entire project vs. individual files

### "Out of memory" errors

**Problem**: elm-review crashes with memory errors.

**Solutions**:
1. Increase Node.js memory limit: `NODE_OPTIONS="--max-old-space-size=4096" npm run review`
2. Exclude unnecessary directories from analysis
3. Run review on smaller subsets of files
4. Check for infinite loops in custom rules

## Rule-Specific Issues

### NoUnused.Variables false positives

**Problem**: Rule reports variables as unused when they are actually needed.

**Solutions**:
1. Use underscore prefix for intentionally unused variables: `_unusedParam`
2. Add rule exceptions in ReviewConfig.elm
3. Check if the variable is used in a way the rule doesn't recognize

### Simplify rule too aggressive

**Problem**: Simplify rule suggests changes that reduce code readability.

**Solutions**:
1. Configure Simplify with custom settings:
   ```elm
   Simplify.rule (Simplify.defaults |> Simplify.ignoreConstructors [ "MyType" ])
   ```
2. Disable specific simplifications that don't fit your style
3. Use `-- elm-review:disable-next-line Simplify` for specific cases

### NoDebug.Log in development

**Problem**: Rule prevents using Debug.log during development.

**Solutions**:
1. Use a separate review configuration for development
2. Temporarily disable the rule: comment out `NoDebug.Log.rule`
3. Use conditional compilation with flags
4. Remember to remove Debug.log before committing

## Integration Issues

### elm-review not running in CI

**Problem**: Continuous integration doesn't run elm-review.

**Solutions**:
1. Ensure CI runs `npm run review` or includes it in test script
2. Use `npm run review:ci` for CI-friendly output
3. Check that review/ directory is committed to repository
4. Verify elm-review is in package.json devDependencies

### Pre-commit hooks failing

**Problem**: Git pre-commit hooks fail due to elm-review errors.

**Solutions**:
1. Fix the reported issues: `npm run review:fix`
2. Run review manually before committing: `npm run review`
3. Configure git hooks to run review automatically
4. Use `--no-verify` flag to skip hooks temporarily (not recommended)

## Getting Help

### Debug Information

When reporting issues, include:
1. elm-review version: `npm list elm-review`
2. Node.js version: `node --version`
3. Operating system
4. Full error message
5. ReviewConfig.elm contents
6. Steps to reproduce

### Resources

- [elm-review documentation](https://package.elm-lang.org/packages/jfmengels/elm-review/latest/)
- [Available rules catalog](https://package.elm-lang.org/packages/jfmengels/elm-review/latest/Review-Rule)
- [elm-review GitHub repository](https://github.com/jfmengels/node-elm-review)
- [Elm Discourse community](https://discourse.elm-lang.org/)

### Creating Custom Rules

If you need custom rules for your project:

1. Follow the [custom rule guide](https://package.elm-lang.org/packages/jfmengels/elm-review/latest/Review-Rule)
2. Test rules thoroughly with edge cases
3. Consider contributing useful rules back to the community
4. Document custom rules in your project README

## Common Workflow

### Daily Development
```bash
# Before starting work
npm run review

# After making changes
npm run review:fix

# Before committing
npm run test  # includes review in pretest hook
```

### Adding New Rules
```bash
# 1. Add rule package
cd review && elm install author/new-rule-package

# 2. Update ReviewConfig.elm
# Add import and rule to config list

# 3. Test configuration
npm run review

# 4. Fix any issues found
npm run review:fix
```

### Debugging Rule Issues
```bash
# Get detailed performance info
npm run review:perf

# Test without tests directory
npm run review:clean

# Get machine-readable output
npm run review:ci
```
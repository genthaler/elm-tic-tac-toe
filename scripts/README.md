# Scripts

This directory contains utility scripts for the project.

## Available Scripts

### `analyze-code-ratio.js`
Analyzes the ratio of test code to production code in the project.

**Usage:**
```bash
npm run analyze:code-ratio
```

**Output:**
- Line counts for production code (Elm, JS/HTML, config files)
- Line counts for test code
- Test-to-production ratios
- Analysis of test coverage quality

### `test-coverage.js`
Processes elm-test JSON output to generate test coverage reports.

**Usage:**
```bash
npm run test:coverage
```

### `benchmark-tests.sh`
Benchmarks test execution performance.

**Usage:**
```bash
./scripts/benchmark-tests.sh
```
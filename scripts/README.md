# Scripts

This directory contains utility scripts for the project.

## Available Scripts

### `analyze-code-ratio.js`
Analyzes the ratio of test code to production code in the project.

**Usage:**
```bash
npm run analyze:code-ratio              # Analysis only
npm run analyze:code-ratio:enforce      # Analysis with enforcement
```

**Output:**
- Line counts for production code (Elm, JS/HTML, config files)
- Line counts for test code
- Test-to-production ratios
- Analysis of test coverage quality

**Enforcement Mode:**
- Enforces test-to-production ratio between 1.1:1 and 2.1:1
- Exit code 0: Ratio within acceptable range
- Exit code 1: Ratio below minimum (insufficient tests)
- Exit code 2: Ratio above maximum (possibly over-tested)
- Used in predeploy script to prevent deployment of poorly tested code

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
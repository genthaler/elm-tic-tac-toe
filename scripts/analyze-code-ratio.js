#!/usr/bin/env node

const { execSync } = require('child_process');

function getLineCount(command) {
    try {
        const output = execSync(command, { encoding: 'utf8' });
        const lines = output.trim().split('\n');
        const lastLine = lines[lines.length - 1];
        const match = lastLine.match(/^\s*(\d+)/);
        return match ? parseInt(match[1]) : 0;
    } catch (error) {
        return 0;
    }
}

function main() {
    console.log('=== Code Analysis ===\n');

    // Production code
    console.log('Production Code:');
    const srcElm = getLineCount('find src -name "*.elm" -exec wc -l {} +');
    const srcOther = getLineCount('find src -type f \\( -name "*.js" -o -name "*.html" -o -name "*.css" \\) -exec wc -l {} +');
    const config = getLineCount('wc -l elm.json package.json');

    console.log(`  Elm files: ${srcElm.toLocaleString()} lines`);
    console.log(`  JS/HTML files: ${srcOther.toLocaleString()} lines`);
    console.log(`  Config files: ${config.toLocaleString()} lines`);

    const totalProd = srcElm + srcOther + config;
    console.log(`  Total Production: ${totalProd.toLocaleString()} lines\n`);

    // Test code
    console.log('Test Code:');
    const tests = getLineCount('find tests -name "*.elm" -exec wc -l {} +');
    console.log(`  Test files: ${tests.toLocaleString()} lines\n`);

    // Ratios
    console.log('Ratios:');
    const totalRatio = tests / totalProd;
    const elmRatio = tests / srcElm;

    console.log(`  Test-to-Production Ratio: ${totalRatio.toFixed(2)}:1`);
    console.log(`  Test-to-Elm Ratio: ${elmRatio.toFixed(2)}:1\n`);

    // Analysis
    console.log('Analysis:');
    if (totalRatio < 1.0) {
        console.log('  📊 Coverage: Below average (consider adding more tests)');
    } else if (totalRatio < 1.5) {
        console.log('  📊 Coverage: Good (healthy test coverage)');
    } else if (totalRatio < 2.1) {
        console.log('  📊 Coverage: Excellent (comprehensive test coverage)');
    } else {
        console.log('  📊 Coverage: Very high (possibly over-tested)');
    }

    console.log(`  📈 Test lines per production line: ${totalRatio.toFixed(1)}`);
    console.log('  🎯  Industry standards typically suggest: ');
    console.log('    Good projects: 1:1 to 1.5:1 ratio');
    console.log('    Excellent projects: 1.5:1 to 2:1 ratio');
    console.log('    Over-tested projects: >2:1 ratio}');
}

main();
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
    const args = process.argv.slice(2);
    const enforceRatio = args.includes('--enforce-ratio');
    const minRatio = 1.1;
    const maxRatio = 2.1;

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
    let status = 'unknown';
    let statusIcon = '❓';

    if (totalRatio < 1.1) {
        status = 'Below average (consider adding more tests)';
        statusIcon = '⚠️';
    } else if (totalRatio < 1.5) {
        status = 'Good (healthy test coverage)';
        statusIcon = '📊';
    } else if (totalRatio < 2.1) {
        status = 'Excellent (comprehensive test coverage)';
        statusIcon = '✅';
    } else {
        status = 'Very high (possibly over-tested)';
        statusIcon = '📈';
    }

    console.log(`  ${statusIcon} Coverage: ${status}`);
    console.log(`  📈 Test lines per production line: ${totalRatio.toFixed(1)}`);
    console.log('  🎯  Industry standards typically suggest: ');
    console.log('    Good projects: 1:1 to 1.5:1 ratio');
    console.log('    Excellent projects: 1.5:1 to 2:1 ratio');
    console.log('    Over-tested projects: >2:1 ratio}');

    // Enforcement check
    if (enforceRatio) {
        console.log('\n=== Ratio Enforcement ===');
        console.log(`Required range: ${minRatio.toFixed(1)}-${maxRatio.toFixed(1)}:1`);
        console.log(`Current ratio: ${totalRatio.toFixed(2)}:1`);

        if (totalRatio < minRatio) {
            console.error(`❌ FAIL: Test coverage ratio ${totalRatio.toFixed(2)}:1 is below minimum ${minRatio}:1`);
            console.error('   Please add more tests to improve coverage.');
            process.exit(1);
        } else if (totalRatio > maxRatio) {
            console.error(`❌ FAIL: Test coverage ratio ${totalRatio.toFixed(2)}:1 exceeds maximum ${maxRatio}:1`);
            console.error('   Consider removing redundant tests or refactoring.');
            process.exit(2);
        } else {
            console.log(`✅ PASS: Test coverage ratio ${totalRatio.toFixed(2)}:1 is within acceptable range`);
        }
    }
}

main();
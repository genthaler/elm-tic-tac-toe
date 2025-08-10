#!/usr/bin/env node

/**
 * Simple test coverage reporter for elm-test JSON output
 * Processes JSON output from elm-test --report json to provide coverage summary
 */

const fs = require('fs');
const path = require('path');

function processTestResults(jsonOutput) {
    const lines = jsonOutput.trim().split('\n');
    const events = lines.map(line => {
        try {
            return JSON.parse(line);
        } catch (e) {
            return null;
        }
    }).filter(event => event !== null);

    const testCompleted = events.filter(event => event.event === 'testCompleted');
    const runComplete = events.find(event => event.event === 'runComplete');

    if (!runComplete) {
        console.error('No run completion event found');
        process.exit(1);
    }

    const totalTests = parseInt(runComplete.passed) + parseInt(runComplete.failed);
    const passedTests = parseInt(runComplete.passed);
    const failedTests = parseInt(runComplete.failed);
    const duration = parseInt(runComplete.duration);

    // Categorize tests by type
    const integrationTests = testCompleted.filter(test =>
        test.labels.some(label =>
            label.includes('Integration') ||
            label.includes('ProgramTest') ||
            label.includes('Program Test')
        )
    );

    const unitTests = testCompleted.filter(test =>
        !test.labels.some(label =>
            label.includes('Integration') ||
            label.includes('ProgramTest') ||
            label.includes('Program Test')
        )
    );

    console.log('\n=== Test Coverage Summary ===');
    console.log(`Total Tests: ${totalTests}`);
    console.log(`Passed: ${passedTests}`);
    console.log(`Failed: ${failedTests}`);
    console.log(`Success Rate: ${((passedTests / totalTests) * 100).toFixed(1)}%`);
    console.log(`Duration: ${duration}ms`);

    console.log('\n=== Test Categorization ===');
    console.log(`Unit Tests: ${unitTests.length}`);
    console.log(`Integration Tests: ${integrationTests.length}`);
    console.log(`Integration Coverage: ${((integrationTests.length / totalTests) * 100).toFixed(1)}%`);

    // Module coverage
    const moduleStats = {};
    testCompleted.forEach(test => {
        const moduleName = test.labels[0] || 'Unknown';
        if (!moduleStats[moduleName]) {
            moduleStats[moduleName] = { total: 0, passed: 0, failed: 0 };
        }
        moduleStats[moduleName].total++;
        if (test.status === 'pass') {
            moduleStats[moduleName].passed++;
        } else {
            moduleStats[moduleName].failed++;
        }
    });

    console.log('\n=== Module Coverage ===');
    Object.keys(moduleStats).sort().forEach(module => {
        const stats = moduleStats[module];
        const successRate = ((stats.passed / stats.total) * 100).toFixed(1);
        console.log(`${module}: ${stats.total} tests (${successRate}% pass rate)`);
    });

    if (failedTests > 0) {
        console.log('\n=== Failed Tests ===');
        testCompleted.filter(test => test.status !== 'pass').forEach(test => {
            console.log(`❌ ${test.labels.join(' > ')}`);
            if (test.failures && test.failures.length > 0) {
                test.failures.forEach(failure => {
                    console.log(`   ${failure.message || failure}`);
                });
            }
        });
    }

    console.log('\n=== Summary ===');
    if (failedTests === 0) {
        console.log('✅ All tests passed!');
    } else {
        console.log(`❌ ${failedTests} test(s) failed`);
        process.exit(1);
    }
}

// Read from stdin if no file provided
if (process.argv.length > 2) {
    const filePath = process.argv[2];
    const jsonOutput = fs.readFileSync(filePath, 'utf8');
    processTestResults(jsonOutput);
} else {
    let input = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('readable', () => {
        const chunk = process.stdin.read();
        if (chunk !== null) {
            input += chunk;
        }
    });
    process.stdin.on('end', () => {
        processTestResults(input);
    });
}
#!/usr/bin/env node

/**
 * Simple HTTP server for testing the production build
 * 
 * This server serves the built files from the dist/ directory
 * and provides proper handling for hash routing.
 * 
 * Usage: node test-production-server.js
 * Then open: http://localhost:3000
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3000;
const DIST_DIR = path.join(__dirname, 'dist');

// MIME types for different file extensions
const mimeTypes = {
    '.html': 'text/html',
    '.js': 'application/javascript',
    '.css': 'text/css',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon'
};

function getMimeType(filePath) {
    const ext = path.extname(filePath).toLowerCase();
    return mimeTypes[ext] || 'application/octet-stream';
}

function serveFile(res, filePath) {
    fs.readFile(filePath, (err, data) => {
        if (err) {
            res.writeHead(404, { 'Content-Type': 'text/plain' });
            res.end('File not found');
            return;
        }

        const mimeType = getMimeType(filePath);
        res.writeHead(200, { 'Content-Type': mimeType });
        res.end(data);
    });
}

const server = http.createServer((req, res) => {
    let urlPath = req.url;

    // Remove query parameters and hash fragments
    const queryIndex = urlPath.indexOf('?');
    if (queryIndex !== -1) {
        urlPath = urlPath.substring(0, queryIndex);
    }

    // For hash routing, all routes should serve index.html
    // The client-side router will handle the hash fragments
    if (urlPath === '/' || urlPath === '/index.html') {
        serveFile(res, path.join(DIST_DIR, 'index.html'));
        return;
    }

    // Serve static assets
    const filePath = path.join(DIST_DIR, urlPath);

    // Check if file exists
    fs.access(filePath, fs.constants.F_OK, (err) => {
        if (err) {
            // File doesn't exist, serve index.html for client-side routing
            serveFile(res, path.join(DIST_DIR, 'index.html'));
        } else {
            // File exists, serve it
            serveFile(res, filePath);
        }
    });
});

// Check if dist directory exists
if (!fs.existsSync(DIST_DIR)) {
    console.error('❌ Error: dist/ directory not found!');
    console.error('Please run "npm run build" first to create the production build.');
    process.exit(1);
}

server.listen(PORT, () => {
    console.log('🚀 Production test server started!');
    console.log(`📁 Serving files from: ${DIST_DIR}`);
    console.log(`🌐 Server running at: http://localhost:${PORT}`);
    console.log('');
    console.log('🧪 Test these hash URLs:');
    console.log(`   Landing Page:    http://localhost:${PORT}/#/landing`);
    console.log(`   Tic-Tac-Toe:     http://localhost:${PORT}/#/tic-tac-toe`);
    console.log(`   Robot Game:      http://localhost:${PORT}/#/robot-game`);
    console.log(`   Style Guide:     http://localhost:${PORT}/#/style-guide`);
    console.log('');
    console.log('📖 See PRODUCTION_HASH_ROUTING_TEST_GUIDE.md for detailed testing instructions');
    console.log('');
    console.log('Press Ctrl+C to stop the server');
});

server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
        console.error(`❌ Error: Port ${PORT} is already in use!`);
        console.error('Please stop any other servers running on this port and try again.');
    } else {
        console.error('❌ Server error:', err);
    }
    process.exit(1);
});
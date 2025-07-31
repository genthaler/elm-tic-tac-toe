import { Elm } from './TicTacToe/GameWorker.elm';

console.log('Elm object:', Elm);
console.log('Available Elm modules:', Object.keys(Elm || {}));

// Initialize the Elm app with error handling
let app;
try {
    if (!Elm || !Elm.TicTacToe.GameWorker) {
        throw new Error('GameWorker module not available. Available modules: ' + Object.keys(Elm || {}));
    }
    app = Elm.TicTacToe.GameWorker.init();
    console.log('GameWorker initialized successfully');
} catch (error) {
    console.error('Failed to initialize GameWorker:', error);
    self.postMessage({
        type: 'GameError',
        errorInfo: {
            message: 'Worker initialization failed: ' + error.message,
            errorType: 'WorkerCommunicationError',
            recoverable: true
        }
    });
    throw error;
}

// Add error handling
self.onerror = (error) => {
    console.error('Worker self error:', error);
};

self.onunhandledrejection = (event) => {
    console.error('Worker unhandled rejection:', event);
};

// Listen for data from the outside and send it to GameWorker
self.onmessage = function ({ data }) {
    console.log('data in worker', data);
    if (app && app.ports && app.ports.getModel) {
        app.ports.getModel.send(data);
    } else {
        console.error('App or ports not available');
        self.postMessage({
            type: 'GameError',
            errorInfo: {
                message: 'Worker app not properly initialized',
                errorType: 'WorkerCommunicationError',
                recoverable: true
            }
        });
    }
};

// Listen for data from GameWorker and send it outside
if (app && app.ports && app.ports.sendMove) {
    app.ports.sendMove.subscribe(function (data) {
        console.log('data from GameWorker', data);
        self.postMessage(data);
    });
} else {
    console.error('Cannot subscribe to sendMove port - app not initialized');
}
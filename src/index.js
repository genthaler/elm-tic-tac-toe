import { Elm } from './Main.elm';

// Initialize the worker
const worker = new Worker(new URL('./worker.js', import.meta.url), { type: 'module' });

// System theme detection
const darkModeMediaQuery = window.matchMedia('(prefers-color-scheme: dark)');

const getModeFromMediaQuery = (matches) => matches ? 'Dark' : 'Light';

// Initialize the Elm app
const app = Elm.Main.init({
    node: document.getElementById('elm'),
    flags: {
        mode: getModeFromMediaQuery(darkModeMediaQuery.matches)
    }
});

// Listen for data from Elm and send it to the worker
app.ports.sendToWorker.subscribe((data) => {
    console.log('data in index', data);
    worker.postMessage(data);
});

// Listen for data from the worker and send it to Elm
worker.onmessage = (event) => {
    console.log('event from worker', event);
    app.ports.receiveFromWorker.send(event.data);
};

// Listen for theme changes
darkModeMediaQuery.addEventListener('change', (e) => {
    app.ports.modeChanged.send(getModeFromMediaQuery(e.matches));
});
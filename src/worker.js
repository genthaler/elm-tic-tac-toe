import { Elm } from './GameWorker.elm';

// Initialize the Elm app
const app = Elm.GameWorker.init();

// Listen for data from the outside and send it to GameWorker
self.onmessage = function ({ data }) {
    // console.log('data in worker', data);
    app.ports.getModel.send(data);
};

// Listen for data from GameWorker and send it outside
app.ports.sendMove.subscribe(function (data) {
    // console.log('data from GameWorker', data);
    self.postMessage(data);
});
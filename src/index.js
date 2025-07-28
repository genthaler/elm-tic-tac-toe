import { Elm } from './Main.elm';

// Initialize the worker
const worker = new Worker(new URL('./worker.js', import.meta.url), { type: 'module' });

// System color scheme detection
const colorSchemeMediaQuery = window.matchMedia('(prefers-color-scheme: dark)');

// Helper function to get the color scheme from the media query
const getColorSchemeFromMediaQuery = (matches) => matches ? 'Dark' : 'Light';

// Theme persistence functions
const THEME_STORAGE_KEY = 'tic-tac-toe-theme';

const getStoredTheme = () => {
    try {
        return localStorage.getItem(THEME_STORAGE_KEY);
    } catch (e) {
        return null;
    }
};

const storeTheme = (theme) => {
    try {
        localStorage.setItem(THEME_STORAGE_KEY, theme);
    } catch (e) {
        // Silently fail if localStorage is not available
    }
};

// Get initial theme preference (stored theme takes precedence over system preference)
const getInitialTheme = () => {
    const storedTheme = getStoredTheme();
    if (storedTheme === 'Light' || storedTheme === 'Dark') {
        return storedTheme;
    }
    return getColorSchemeFromMediaQuery(colorSchemeMediaQuery.matches);
};

// Initialize the Elm app
const app = Elm.Main.init({
    node: document.getElementById('elm'),
    flags: {
        colorScheme: getInitialTheme()
    }
});

// Listen for system color scheme changes (only if no stored preference)
colorSchemeMediaQuery.addEventListener('change', (e) => {
    if (!getStoredTheme()) {
        app.ports.modeChanged.send(getColorSchemeFromMediaQuery(e.matches));
    }
});


// Listen for data from Elm and send it to the worker
app.ports.sendToWorker.subscribe((data) => {
    // console.log('data in index', data);
    worker.postMessage(data);
});

// Listen for data from the worker and send it to Elm
worker.onmessage = (event) => {
    // console.log('event from worker', event);
    app.ports.receiveFromWorker.send(event.data);
};

// Listen for theme changes from Elm and persist them
if (app.ports.themeChanged) {
    app.ports.themeChanged.subscribe((theme) => {
        storeTheme(theme);
    });
}

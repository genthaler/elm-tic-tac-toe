# Elm TTT

A Tic Tac Toe game built with Elm, demonstrating functional programming concepts and immutable state management.

## Features

- Interactive Tic Tac Toe game board
- Turn-based gameplay (X and O players)
- Win detection
- Draw detection
- Clean, functional code architecture
- Responsive design
- Uses a web worker to handle AI logic and unblock the main thread
- UI component style guide with elm-book

## Installation

### Clone the repository

git clone https://github.com/genthaler/elm-ttt.git

### Navigate to the project directory

cd elm-ttt

### Install dependencies

npm i 

### npm scripts

- `npm run start`: starts the game with the elm reactor (open your browser at http://localhost:8000)
- `npm run build`: builds the project with Parcel.js into the `dist` directory
- `npm run serve`: serves the static files in the `dist` directory with serve

## Development

This project is built with Elm 0.19.1. The game logic is organized into:

- `index.html`: Entry point
- `index.js`: Starts up the Elm application and the worker
- `worker.js`: Worker for the game logic when it's the AI's turn
- `Main.elm`: Main game loop
- `Model.elm`: Game state and message types
- `View.elm`: UI rendering
- `GameWorker.elm`: Worker for the game logic
- `Game.elm`: Game logic
- `Book.elm`: Style guide

The Model is passed from the application to the worker and the worker returns a new Msg. 

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the ISC License - a permissive open source license that lets people do anything with your code with proper attribution and without warranty. The ISC license is functionally equivalent to the MIT License but with simpler language.

## Learn More

To learn more about Elm, check out the [Elm Guide](https://guide.elm-lang.org/).


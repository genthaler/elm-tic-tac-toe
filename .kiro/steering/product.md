# Product Overview


## Tic-tac-toe

A Tic-Tac-Toe game built with Elm that demonstrates functional programming concepts and immutable state management. The game features:

- Interactive turn-based gameplay between human and AI players
- AI opponent using negamax algorithm with game theory implementations
- Web worker architecture to handle AI computations without blocking the UI
- Hash-based routing for direct URL access to all game pages
- Clean functional architecture with immutable state
- Responsive design with elm-ui

The project serves as both a playable game and an educational example of functional programming patterns, game theory algorithms, hash routing, and Elm architecture best practices.

## Robot game

- The Robot Grid Game is an interactive control game where users can navigate a robot on a 5x5 grid using directional movement and rotation controls. 
- The robot maintains a facing direction and can move forward in that direction or rotate to face any of the four cardinal directions (North, South, East, West).
- The game provides both keyboard controls for efficient gameplay and visual button controls for accessibility and mobile compatibility.

## Navigation & Routing

- Hash-based routing system enabling direct URL access to all application pages
- Browser back/forward navigation support with URL preservation
- Bookmark and refresh functionality for all routes
- Graceful error handling for invalid URLs with fallback to landing page

## Themes

- A module for holding shared themes across the project, and a style guide for displaying those themes
- Component style guide using elm-book accessible via hash routing

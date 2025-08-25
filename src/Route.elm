module Route exposing
    ( Route(..)
    , fromUrl
    , fromUrlWithFallback
    , navigateTo
    , toHashUrl
    , toString
    , toUrl
    )

{-| Route module for hash-based navigation in the application.

This module provides hash URL parsing and generation for all application routes,
enabling deep linking and browser navigation support using hash-based routing.

Implements hash-based routing using Browser.Hash for reliable hash URL handling.

-}

import Browser.Navigation as Nav
import Url exposing (Url)
import Url.Parser as Parser exposing (Parser, oneOf, s, top)


{-| Represents all possible routes in the application
-}
type Route
    = Landing
    | TicTacToe
    | RobotGame
    | StyleGuide


{-| Parse a URL and extract the route

Browser.Hash automatically converts hash URLs to regular URLs, so we can use standard URL parsing.
This supports both hash URLs like "/#/landing" and path URLs like "/landing".

For error handling:

  - Invalid or malformed URLs return Nothing
  - The calling code should handle Nothing by defaulting to Landing route
  - This ensures graceful fallback for unrecognized hash URLs

-}
fromUrl : Url -> Maybe Route
fromUrl url =
    Parser.parse parser url


{-| Parse a URL and extract the route with fallback to Landing

This function provides graceful error handling by always returning a valid route.
Invalid or malformed URLs default to the Landing route.

-}
fromUrlWithFallback : Url -> Route
fromUrlWithFallback url =
    fromUrl url |> Maybe.withDefault Landing


{-| Get a safe hash URL for a route

This ensures that navigation commands always produce valid hash URLs.

-}
toHashUrl : Route -> String
toHashUrl route =
    "#/" ++ toPath route


{-| Convert a Route to a hash path string for navigation

This generates the hash path portion of the URL

-}
toPath : Route -> String
toPath route =
    case route of
        Landing ->
            "landing"

        TicTacToe ->
            "tic-tac-toe"

        RobotGame ->
            "robot-game"

        StyleGuide ->
            "style-guide"


{-| Convert a Route to a URL path string

This provides the URL path representation of the route for compatibility with existing tests.
For hash-based routing, this represents the path that would be in the hash fragment.

-}
toString : Route -> String
toString route =
    "/" ++ toPath route


{-| Navigate to a specific route using hash routing

This creates a navigation command that updates the hash URL.
Uses toHashUrl to ensure consistent hash URL format.

-}
navigateTo : Nav.Key -> Route -> Cmd msg
navigateTo key route =
    Nav.pushUrl key (toHashUrl route)


{-| Convert a Route to a URL

For compatibility with existing tests, this puts the route in the path.
In actual hash-based routing, the route would be in the fragment.

-}
toUrl : Route -> Url
toUrl route =
    { protocol = Url.Https
    , host = ""
    , port_ = Nothing
    , path = toString route
    , query = Nothing
    , fragment = Nothing
    }


{-| Hash URL parser for all application routes

This parser handles:

  - #/ or empty hash -> Landing (default route)
  - #/landing -> Landing
  - #/tic-tac-toe -> TicTacToe
  - #/robot-game -> RobotGame
  - #/style-guide -> StyleGuide

Invalid hash URLs will return Nothing from fromUrl and should be handled by redirecting to Landing.
The parser is designed to be strict - only exact matches are accepted to ensure predictable routing.

-}
parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Landing top -- Default route for root path
        , Parser.map Landing (s "landing")
        , Parser.map TicTacToe (s "tic-tac-toe")
        , Parser.map RobotGame (s "robot-game")
        , Parser.map StyleGuide (s "style-guide")
        ]

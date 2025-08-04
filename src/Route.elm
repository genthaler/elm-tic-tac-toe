module Route exposing
    ( Route(..)
    , fromUrl
    , toString
    , toUrl
    )

{-| Route module for URL-based navigation in the application.

This module provides URL parsing and generation for all application routes,
enabling deep linking and browser navigation support.

-}

import Url exposing (Url)
import Url.Parser as Parser exposing (Parser, oneOf, s, top)


{-| Represents all possible routes in the application
-}
type Route
    = Landing
    | TicTacToe
    | RobotGame
    | StyleGuide


{-| Parse a URL into a Route

Returns Nothing for invalid URLs, which should be handled by redirecting to Landing

-}
fromUrl : Url -> Maybe Route
fromUrl url =
    Parser.parse parser url


{-| Convert a Route to a URL string for navigation

This generates the path portion of the URL without the domain

-}
toString : Route -> String
toString route =
    case route of
        Landing ->
            "/landing"

        TicTacToe ->
            "/tic-tac-toe"

        RobotGame ->
            "/robot-game"

        StyleGuide ->
            "/style-guide"


{-| Generate a full URL from a Route

This creates a complete URL structure that can be used with Browser.Navigation

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


{-| URL parser for all application routes

This parser handles:

  - / -> Landing (root URL redirects to landing)
  - /landing -> Landing
  - /tic-tac-toe -> TicTacToe
  - /robot-game -> RobotGame
  - /style-guide -> StyleGuide

Invalid URLs will return Nothing from fromUrl and should be handled by redirecting to Landing

-}
parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Landing top -- Handle root URL "/"
        , Parser.map Landing (s "landing")
        , Parser.map TicTacToe (s "tic-tac-toe")
        , Parser.map RobotGame (s "robot-game")
        , Parser.map StyleGuide (s "style-guide")
        ]

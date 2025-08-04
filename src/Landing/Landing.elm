module Landing.Landing exposing (Model, Msg(..), init, update)

{-| Landing page module for the Tic-Tac-Toe application.

This module handles the landing page state and logic, providing navigation
to the game and style guide while maintaining theme preferences.

-}

import Route
import Theme.Theme exposing (ColorScheme)



-- MODEL


{-| Landing page model containing theme and window information
-}
type alias Model =
    { colorScheme : ColorScheme
    , maybeWindow : Maybe ( Int, Int )
    }


{-| Initialize the landing page model
-}
init : ColorScheme -> Maybe ( Int, Int ) -> Model
init colorScheme maybeWindow =
    { colorScheme = colorScheme
    , maybeWindow = maybeWindow
    }



-- MSG


{-| Messages that can be sent from the landing page
-}
type Msg
    = NavigateToRoute Route.Route
    | ColorSchemeToggled



-- UPDATE


{-| Update function for landing page messages
-}
update : Msg -> Model -> Model
update msg model =
    case msg of
        NavigateToRoute _ ->
            -- Navigation is handled by parent, no state change needed
            model

        ColorSchemeToggled ->
            -- Theme change is handled by parent, no state change needed
            model

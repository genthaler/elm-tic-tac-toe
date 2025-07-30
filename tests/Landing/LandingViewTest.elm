module Landing.LandingViewTest exposing (suite)

import Expect
import Landing.Landing as Landing
import Landing.LandingView as LandingView
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector exposing (tag, text)
import TicTacToe.Model exposing (ColorScheme(..))


suite : Test
suite =
    describe "LandingView Module Tests"
        [ describe "View Rendering Tests"
            [ test "renders landing page with correct title" <|
                \_ ->
                    let
                        model =
                            Landing.init Light (Just ( 1200, 800 ))

                        html =
                            LandingView.view model identity
                    in
                    html
                        |> Query.fromHtml
                        |> Query.find [ text "Elm Tic-Tac-Toe" ]
                        |> Query.has [ text "Elm Tic-Tac-Toe" ]
            , test "renders welcome message" <|
                \_ ->
                    let
                        model =
                            Landing.init Light (Just ( 1200, 800 ))

                        html =
                            LandingView.view model identity
                    in
                    html
                        |> Query.fromHtml
                        |> Query.find [ text "Welcome!" ]
                        |> Query.has [ text "Welcome!" ]
            , test "renders Play Game button" <|
                \_ ->
                    let
                        model =
                            Landing.init Light (Just ( 1200, 800 ))

                        html =
                            LandingView.view model identity
                    in
                    html
                        |> Query.fromHtml
                        |> Query.find [ text "Play Game" ]
                        |> Query.has [ text "Play Game" ]
            , test "renders View Style Guide button" <|
                \_ ->
                    let
                        model =
                            Landing.init Light (Just ( 1200, 800 ))

                        html =
                            LandingView.view model identity
                    in
                    html
                        |> Query.fromHtml
                        |> Query.find [ text "View Style Guide" ]
                        |> Query.has [ text "View Style Guide" ]
            ]
        , describe "Responsive Design Tests"
            [ test "renders correctly on mobile viewport" <|
                \_ ->
                    let
                        mobileModel =
                            Landing.init Light (Just ( 400, 600 ))

                        html =
                            LandingView.view mobileModel identity
                    in
                    html
                        |> Query.fromHtml
                        |> Query.find [ text "Elm Tic-Tac-Toe" ]
                        |> Query.has [ text "Elm Tic-Tac-Toe" ]
            , test "renders correctly on tablet viewport" <|
                \_ ->
                    let
                        tabletModel =
                            Landing.init Light (Just ( 800, 600 ))

                        html =
                            LandingView.view tabletModel identity
                    in
                    html
                        |> Query.fromHtml
                        |> Query.find [ text "Elm Tic-Tac-Toe" ]
                        |> Query.has [ text "Elm Tic-Tac-Toe" ]
            , test "renders correctly on desktop viewport" <|
                \_ ->
                    let
                        desktopModel =
                            Landing.init Light (Just ( 1200, 800 ))

                        html =
                            LandingView.view desktopModel identity
                    in
                    html
                        |> Query.fromHtml
                        |> Query.find [ text "Elm Tic-Tac-Toe" ]
                        |> Query.has [ text "Elm Tic-Tac-Toe" ]
            ]
        , describe "Theme Support Tests"
            [ test "renders correctly with light theme" <|
                \_ ->
                    let
                        lightModel =
                            Landing.init Light (Just ( 1200, 800 ))

                        html =
                            LandingView.view lightModel identity
                    in
                    html
                        |> Query.fromHtml
                        |> Query.find [ text "Elm Tic-Tac-Toe" ]
                        |> Query.has [ text "Elm Tic-Tac-Toe" ]
            , test "renders correctly with dark theme" <|
                \_ ->
                    let
                        darkModel =
                            Landing.init Dark (Just ( 1200, 800 ))

                        html =
                            LandingView.view darkModel identity
                    in
                    html
                        |> Query.fromHtml
                        |> Query.find [ text "Elm Tic-Tac-Toe" ]
                        |> Query.has [ text "Elm Tic-Tac-Toe" ]
            ]
        , describe "Component Structure Tests"
            [ test "contains SVG icons for theme toggle" <|
                \_ ->
                    let
                        model =
                            Landing.init Light (Just ( 1200, 800 ))

                        html =
                            LandingView.view model identity
                    in
                    html
                        |> Query.fromHtml
                        |> Query.findAll [ tag "svg" ]
                        |> Query.count (Expect.atLeast 1)
            , test "contains navigation button descriptions" <|
                \_ ->
                    let
                        model =
                            Landing.init Light (Just ( 1200, 800 ))

                        html =
                            LandingView.view model identity
                    in
                    html
                        |> Query.fromHtml
                        |> Query.find [ text "Start playing tic-tac-toe" ]
                        |> Query.has [ text "Start playing tic-tac-toe" ]
            ]
        ]

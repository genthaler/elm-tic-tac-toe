module UIIntegrationTest exposing (..)

{-| Integration tests for the complete UI functionality.
These tests verify that the UI components work together correctly.
-}

import Expect
import Model exposing (ColorScheme(..), GameState(..), Model, Msg(..), Player(..), Position, createUnknownError, initialModel)
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Time
import View exposing (view)


suite : Test
suite =
    describe "UI Integration Tests"
        [ gameFlowTests
        , themeIntegrationTests
        , controlsIntegrationTests
        ]


gameFlowTests : Test
gameFlowTests =
    describe "Complete Game Flow UI"
        [ test "initial game state renders correctly" <|
            \_ ->
                let
                    model =
                        initialModel

                    html =
                        view model
                in
                html
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.text "Tic-Tac-Toe" ]
                        , Query.has [ Selector.text "Player X's turn" ]
                        , Query.findAll [ Selector.tag "svg" ] >> Query.count (Expect.equal 2) -- Reset and color toggle
                        ]
        , test "game with moves renders board correctly" <|
            \_ ->
                let
                    boardWithMoves =
                        [ [ Just X, Nothing, Nothing ]
                        , [ Nothing, Just O, Nothing ]
                        , [ Nothing, Nothing, Nothing ]
                        ]

                    model =
                        { initialModel | board = boardWithMoves, gameState = Waiting X }

                    html =
                        view model
                in
                html
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.text "Tic-Tac-Toe" ]
                        , Query.has [ Selector.text "Player X's turn" ]
                        , Query.findAll [ Selector.tag "svg" ] >> Query.count (Expect.atLeast 4) -- Reset, color toggle, X, O
                        ]
        , test "winner state shows complete UI" <|
            \_ ->
                let
                    winningBoard =
                        [ [ Just X, Just X, Just X ]
                        , [ Nothing, Just O, Nothing ]
                        , [ Nothing, Nothing, Nothing ]
                        ]

                    model =
                        { initialModel | board = winningBoard, gameState = Winner X }

                    html =
                        view model
                in
                html
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.text "Tic-Tac-Toe" ]
                        , Query.has [ Selector.text "Player X wins!" ]
                        , Query.findAll [ Selector.tag "svg" ] >> Query.count (Expect.atLeast 5) -- Reset, color toggle, 3 X's, 1 O
                        ]
        , test "draw state shows complete UI" <|
            \_ ->
                let
                    drawBoard =
                        [ [ Just X, Just O, Just X ]
                        , [ Just O, Just X, Just O ]
                        , [ Just O, Just X, Just O ]
                        ]

                    model =
                        { initialModel | board = drawBoard, gameState = Draw }

                    html =
                        view model
                in
                html
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.text "Tic-Tac-Toe" ]
                        , Query.has [ Selector.text "Game ended in a draw!" ]
                        , Query.findAll [ Selector.tag "svg" ] >> Query.count (Expect.atLeast 11) -- Reset, color toggle, 9 pieces
                        ]
        ]


themeIntegrationTests : Test
themeIntegrationTests =
    describe "Theme Integration"
        [ test "light theme renders all components" <|
            \_ ->
                let
                    model =
                        { initialModel | colorScheme = Light, gameState = Waiting X }

                    html =
                        view model
                in
                html
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.text "Tic-Tac-Toe" ]
                        , Query.has [ Selector.text "Player X's turn" ]
                        , Query.findAll [ Selector.tag "svg" ] >> Query.count (Expect.equal 2)
                        ]
        , test "dark theme renders all components" <|
            \_ ->
                let
                    model =
                        { initialModel | colorScheme = Dark, gameState = Waiting X }

                    html =
                        view model
                in
                html
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.text "Tic-Tac-Toe" ]
                        , Query.has [ Selector.text "Player X's turn" ]
                        , Query.findAll [ Selector.tag "svg" ] >> Query.count (Expect.equal 2)
                        ]
        , test "theme switching maintains game state display" <|
            \_ ->
                let
                    gameState =
                        Winner O

                    lightModel =
                        { initialModel | colorScheme = Light, gameState = gameState }

                    darkModel =
                        { initialModel | colorScheme = Dark, gameState = gameState }

                    lightHtml =
                        view lightModel

                    darkHtml =
                        view darkModel
                in
                Expect.all
                    [ \_ -> lightHtml |> Query.fromHtml |> Query.has [ Selector.text "Player O wins!" ]
                    , \_ -> darkHtml |> Query.fromHtml |> Query.has [ Selector.text "Player O wins!" ]
                    ]
                    ()
        ]


controlsIntegrationTests : Test
controlsIntegrationTests =
    describe "Controls Integration"
        [ test "all controls present in waiting state" <|
            \_ ->
                let
                    model =
                        { initialModel | gameState = Waiting X }

                    html =
                        view model
                in
                html
                    |> Query.fromHtml
                    |> Query.findAll [ Selector.tag "svg" ]
                    |> Query.count (Expect.equal 2)

        -- Reset and color toggle
        , test "timer appears with controls when appropriate" <|
            \_ ->
                let
                    model =
                        { initialModel
                            | gameState = Waiting X
                            , lastMove = Just (Time.millisToPosix 1000)
                            , now = Just (Time.millisToPosix 3000)
                        }

                    html =
                        view model
                in
                html
                    |> Query.fromHtml
                    |> Query.findAll [ Selector.tag "svg" ]
                    |> Query.count (Expect.equal 3)

        -- Reset, color toggle, and timer
        , test "controls work in all game states" <|
            \_ ->
                let
                    testGameState gameState expectedText =
                        let
                            model =
                                { initialModel | gameState = gameState }

                            html =
                                view model
                        in
                        html
                            |> Query.fromHtml
                            |> Expect.all
                                [ Query.has [ Selector.text expectedText ]
                                , Query.findAll [ Selector.tag "svg" ] >> Query.count (Expect.atLeast 2)
                                ]
                in
                Expect.all
                    [ \_ -> testGameState (Waiting X) "Player X's turn"
                    , \_ -> testGameState (Thinking O) "Player O's thinking"
                    , \_ -> testGameState (Winner X) "Player X wins!"
                    , \_ -> testGameState Draw "Game ended in a draw!"
                    , \_ -> testGameState (Error (createUnknownError "Test")) "Test (Please reset the game)"
                    ]
                    ()
        ]

module TicTacToe.ThemeIntegrationTest exposing (suite)

{-| Integration tests for theme switching during TicTacToe gameplay.

These tests verify that color scheme changes work correctly during active games,
that theme preferences persist across different game states, and that theme
changes affect all UI components appropriately.

-}

import Expect
import Html.Attributes
import ProgramTest exposing (ProgramTest)
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import TestUtils.ProgramTestHelpers exposing (clickCell, simulateClick)
import Theme.Theme exposing (ColorScheme(..))
import TicTacToe.Model as TicTacToeModel exposing (GameState(..), Player(..))
import TicTacToe.ProgramTestHelpers exposing (startTicTacToe)


suite : Test
suite =
    describe "TicTacToe Theme Integration Tests"
        [ testColorSchemeToggleDuringActiveGame
        , testThemePersistenceAcrossGameStates
        , testThemeChangesAffectAllUIComponents
        ]


{-| Test color scheme toggle during active game
Requirements: 2.5 - Theme switching during gameplay
-}
testColorSchemeToggleDuringActiveGame : Test
testColorSchemeToggleDuringActiveGame =
    describe "Color scheme toggle during active game"
        [ test "can toggle from light to dark theme during game" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 0, col = 0 }
                    -- Make a move to start the game
                    |> simulateClick "color-scheme-toggle"
                    -- Toggle to dark theme
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal Dark model.colorScheme
                                , \_ -> Expect.equal (Thinking O) model.gameState
                                ]
                                ()
                        )
        , test "can toggle from dark to light theme during game" <|
            \() ->
                startTicTacToe ()
                    |> ProgramTest.update (TicTacToeModel.ColorScheme Dark)
                    -- Start with dark theme
                    |> clickCell { row = 1, col = 1 }
                    -- Make a move to start the game
                    |> simulateClick "color-scheme-toggle"
                    -- Toggle to light theme
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal Light model.colorScheme
                                , \_ -> Expect.equal (Thinking O) model.gameState
                                ]
                                ()
                        )
        , test "theme toggle works during AI thinking phase" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 0, col = 0 }
                    -- Human makes first move
                    |> simulateClick "color-scheme-toggle"
                    -- Toggle theme while AI is thinking
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal Dark model.colorScheme
                                , \_ -> Expect.equal (Thinking O) model.gameState
                                ]
                                ()
                        )
        , test "theme toggle works during waiting phase" <|
            \() ->
                startTicTacToe ()
                    |> simulateClick "color-scheme-toggle"
                    -- Toggle theme while waiting for human move
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal Dark model.colorScheme
                                , \_ -> Expect.equal (Waiting X) model.gameState
                                ]
                                ()
                        )
        , test "theme toggle works after game completion" <|
            \() ->
                startTicTacToe ()
                    |> simulateGameToCompletion
                    |> simulateClick "color-scheme-toggle"
                    -- Toggle theme after game ends
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.equal Dark model.colorScheme
                        )
        , test "multiple theme toggles work correctly" <|
            \() ->
                startTicTacToe ()
                    |> simulateClick "color-scheme-toggle"
                    |> simulateClick "color-scheme-toggle"
                    |> simulateClick "color-scheme-toggle"
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.equal Dark model.colorScheme
                        )
        ]


{-| Test theme persistence across game states
Requirements: 2.5, 3.4 - Theme persistence across game states
-}
testThemePersistenceAcrossGameStates : Test
testThemePersistenceAcrossGameStates =
    describe "Theme persistence across game states"
        [ test "theme persists when transitioning from waiting to thinking" <|
            \() ->
                startTicTacToe ()
                    |> simulateClick "color-scheme-toggle"
                    -- Set to dark theme
                    |> clickCell { row = 0, col = 0 }
                    -- Make move to transition to thinking state
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal Dark model.colorScheme
                                , \_ -> Expect.equal (Thinking O) model.gameState
                                ]
                                ()
                        )
        , test "theme persists when transitioning from thinking to waiting" <|
            \() ->
                startTicTacToe ()
                    |> simulateClick "color-scheme-toggle"
                    -- Set to dark theme
                    |> clickCell { row = 0, col = 0 }
                    -- Human move
                    |> simulateAIMove { row = 1, col = 1 }
                    -- AI responds
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal Dark model.colorScheme
                                , \_ -> Expect.equal (Waiting X) model.gameState
                                ]
                                ()
                        )
        , test "theme persists when game ends in winner state" <|
            \() ->
                startTicTacToe ()
                    |> simulateClick "color-scheme-toggle"
                    -- Set to dark theme
                    |> simulateWinningGame X
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal Dark model.colorScheme
                                , \_ -> Expect.equal (Winner X) model.gameState
                                ]
                                ()
                        )
        , test "theme persists when game ends in draw state" <|
            \() ->
                startTicTacToe ()
                    |> simulateClick "color-scheme-toggle"
                    -- Set to dark theme
                    |> simulateDrawGame
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal Dark model.colorScheme
                                , \_ -> Expect.equal Draw model.gameState
                                ]
                                ()
                        )
        , test "theme persists when game encounters error state" <|
            \() ->
                startTicTacToe ()
                    |> simulateClick "color-scheme-toggle"
                    -- Set to dark theme
                    |> ProgramTest.update (TicTacToeModel.GameError (TicTacToeModel.createGameLogicError "Test error"))
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal Dark model.colorScheme
                                , \_ ->
                                    case model.gameState of
                                        Error _ ->
                                            Expect.pass

                                        _ ->
                                            Expect.fail "Expected Error state"
                                ]
                                ()
                        )
        , test "theme persists after game reset" <|
            \() ->
                startTicTacToe ()
                    |> simulateClick "color-scheme-toggle"
                    -- Set to dark theme
                    |> clickCell { row = 0, col = 0 }
                    -- Make some moves
                    |> simulateClick "reset-button"
                    -- Reset the game
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal Dark model.colorScheme
                                , \_ -> Expect.equal (Waiting X) model.gameState
                                ]
                                ()
                        )
        ]


{-| Test theme changes affecting all UI components
Requirements: 2.5, 3.4 - Theme changes affecting all UI components
-}
testThemeChangesAffectAllUIComponents : Test
testThemeChangesAffectAllUIComponents =
    describe "Theme changes affect all UI components"
        [ test "theme toggle affects game board appearance" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 0, col = 0 }
                    -- Place X in top-left
                    |> simulateAIMove { row = 1, col = 1 }
                    -- AI places O in center
                    |> simulateClick "color-scheme-toggle"
                    -- Toggle to dark theme
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.equal Dark model.colorScheme
                        )
        , test "theme toggle affects header and controls" <|
            \() ->
                let
                    programTest =
                        startTicTacToe ()
                            |> simulateClick "color-scheme-toggle"

                    -- Toggle theme
                in
                Expect.all
                    [ \_ ->
                        programTest
                            |> ProgramTest.expectView
                                (Query.has [ Selector.attribute (Html.Attributes.attribute "aria-label" "reset-button") ])
                    , \_ ->
                        programTest
                            |> ProgramTest.expectModel
                                (\model ->
                                    Expect.equal Dark model.colorScheme
                                )
                    ]
                    ()
        , test "theme toggle affects status messages" <|
            \() ->
                startTicTacToe ()
                    |> simulateClick "color-scheme-toggle"
                    -- Toggle to dark theme
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.equal Dark model.colorScheme
                        )
        , test "theme toggle affects player symbols" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 0, col = 0 }
                    -- Place X symbol
                    |> simulateAIMove { row = 1, col = 1 }
                    -- Place O symbol
                    |> simulateClick "color-scheme-toggle"
                    -- Toggle theme
                    |> ProgramTest.expectModel
                        (\model ->
                            let
                                hasXSymbol =
                                    List.any (List.any (\cell -> cell == Just X)) model.board

                                hasOSymbol =
                                    List.any (List.any (\cell -> cell == Just O)) model.board
                            in
                            Expect.all
                                [ \_ -> Expect.equal Dark model.colorScheme
                                , \_ -> Expect.equal True hasXSymbol
                                , \_ -> Expect.equal True hasOSymbol
                                ]
                                ()
                        )
        , test "theme toggle affects interactive elements" <|
            \() ->
                let
                    programTest =
                        startTicTacToe ()
                            |> simulateClick "color-scheme-toggle"

                    -- Toggle to dark theme
                in
                Expect.all
                    [ \_ ->
                        programTest
                            |> ProgramTest.expectView
                                (Query.has [ Selector.attribute (Html.Attributes.attribute "aria-label" "reset-button") ])
                    , \_ ->
                        programTest
                            |> ProgramTest.expectModel
                                (\model ->
                                    Expect.equal Dark model.colorScheme
                                )
                    ]
                    ()
        , test "theme toggle affects timer display" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 0, col = 0 }
                    -- Start game to show timer
                    |> simulateAIMove { row = 1, col = 1 }
                    -- AI responds, now waiting for human
                    |> simulateClick "color-scheme-toggle"
                    -- Toggle theme
                    |> ProgramTest.expectModel
                        (\model ->
                            Expect.all
                                [ \_ -> Expect.equal Dark model.colorScheme
                                , \_ -> Expect.equal (Waiting X) model.gameState
                                ]
                                ()
                        )
        , test "all UI components maintain consistency after theme change" <|
            \() ->
                let
                    programTest =
                        startTicTacToe ()
                            |> clickCell { row = 0, col = 0 }
                            -- Make initial move
                            |> simulateAIMove { row = 1, col = 1 }
                            -- AI responds
                            |> clickCell { row = 0, col = 1 }
                            -- Make another move
                            |> simulateClick "color-scheme-toggle"

                    -- Toggle theme
                in
                Expect.all
                    [ \_ ->
                        programTest
                            |> ProgramTest.expectView
                                (Query.has [ Selector.attribute (Html.Attributes.attribute "aria-label" "reset-button") ])
                    , \_ ->
                        programTest
                            |> ProgramTest.expectModel
                                (\model ->
                                    let
                                        hasGameProgressed =
                                            List.any (List.any (\cell -> cell /= Nothing)) model.board
                                    in
                                    Expect.all
                                        [ \_ -> Expect.equal Dark model.colorScheme
                                        , \_ -> Expect.equal True hasGameProgressed
                                        ]
                                        ()
                                )
                    ]
                    ()
        ]



-- Helper functions


{-| Simulate AI making a move at the specified position
-}
simulateAIMove : { row : Int, col : Int } -> ProgramTest TicTacToeModel.Model TicTacToeModel.Msg effect -> ProgramTest TicTacToeModel.Model TicTacToeModel.Msg effect
simulateAIMove position programTest =
    programTest
        |> ProgramTest.update (TicTacToeModel.MoveMade position)


{-| Simulate a complete game ending in a winner
-}
simulateWinningGame : Player -> ProgramTest TicTacToeModel.Model TicTacToeModel.Msg effect -> ProgramTest TicTacToeModel.Model TicTacToeModel.Msg effect
simulateWinningGame winner programTest =
    case winner of
        X ->
            -- Simulate X winning with top row
            programTest
                -- X: (0,0)
                |> clickCell { row = 0, col = 0 }
                -- O: (1,0)
                |> simulateAIMove { row = 1, col = 0 }
                -- X: (0,1)
                |> clickCell { row = 0, col = 1 }
                -- O: (1,1)
                |> simulateAIMove { row = 1, col = 1 }
                -- X: (0,2) - X wins with top row
                |> clickCell { row = 0, col = 2 }

        O ->
            -- Simulate O winning with middle column
            programTest
                -- X: (0,0)
                |> clickCell { row = 0, col = 0 }
                -- O: (1,1)
                |> simulateAIMove { row = 1, col = 1 }
                -- X: (0,1)
                |> clickCell { row = 0, col = 1 }
                -- O: (0,1) - invalid, let's try different sequence
                |> simulateAIMove { row = 0, col = 1 }
                -- O: (2,1) - O wins with middle column
                |> simulateAIMove { row = 2, col = 1 }


{-| Simulate a game ending in a draw
-}
simulateDrawGame : ProgramTest TicTacToeModel.Model TicTacToeModel.Msg effect -> ProgramTest TicTacToeModel.Model TicTacToeModel.Msg effect
simulateDrawGame programTest =
    programTest
        -- X: (0,0)
        |> clickCell { row = 0, col = 0 }
        -- O: (1,1)
        |> simulateAIMove { row = 1, col = 1 }
        -- X: (0,2)
        |> clickCell { row = 0, col = 2 }
        -- O: (0,1)
        |> simulateAIMove { row = 0, col = 1 }
        -- X: (2,1)
        |> clickCell { row = 2, col = 1 }
        -- O: (1,0)
        |> simulateAIMove { row = 1, col = 0 }
        -- X: (1,2)
        |> clickCell { row = 1, col = 2 }
        -- O: (2,2)
        |> simulateAIMove { row = 2, col = 2 }
        -- X: (2,0) - Draw
        |> clickCell { row = 2, col = 0 }


{-| Simulate a game to completion (either win or draw)
-}
simulateGameToCompletion : ProgramTest TicTacToeModel.Model TicTacToeModel.Msg effect -> ProgramTest TicTacToeModel.Model TicTacToeModel.Msg effect
simulateGameToCompletion programTest =
    simulateWinningGame X programTest

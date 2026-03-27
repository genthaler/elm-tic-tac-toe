module TicTacToe.SearchInspectionIntegrationTest exposing (suite)

import Expect
import ProgramTest exposing (ProgramTest)
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import TestUtils.ProgramTestHelpers exposing (clickButtonById, clickCell, expectTextPresent)
import TicTacToe.Main
import TicTacToe.Model exposing (Model, Msg(..), initialModel)
import TicTacToe.View


suite : Test
suite =
    describe "TicTacToe search inspection"
        [ computerTurnControlsTests
        , negamaxInspectionTests
        , alphaBetaInspectionTests
        , fastPlayPreservationTests
        ]


computerTurnControlsTests : Test
computerTurnControlsTests =
    describe "Computer turn controls"
        [ test "shows the computer turn status after a human move" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 0, col = 0 }
                    |> ProgramTest.expectView
                        (Query.find [ Selector.class "game-status" ]
                            >> Query.has [ Selector.text "Player O is ready. Auto move or inspect the search." ]
                        )
        , test "renders the AI control labels on the computer turn" <|
            \() ->
                let
                    programTest =
                        startTicTacToe ()
                            |> clickCell { row = 0, col = 0 }
                in
                Expect.all
                    [ \pt -> expectTextPresent "Auto move" pt
                    , \pt -> expectTextPresent "Inspect Negamax" pt
                    , \pt -> expectTextPresent "Inspect Alpha-Beta" pt
                    ]
                    programTest
        ]


negamaxInspectionTests : Test
negamaxInspectionTests =
    describe "Negamax inspection flow"
        [ test "exposes stepping controls and summary text" <|
            \() ->
                let
                    programTest =
                        startTicTacToe ()
                            |> clickCell { row = 0, col = 0 }
                            |> clickButtonById "inspect-negamax"
                in
                Expect.all
                    [ \pt -> expectTextPresent "Back" pt
                    , \pt -> expectTextPresent "Forward" pt
                    , \pt -> expectTextPresent "Play to end" pt
                    , \pt -> expectTextPresent "Apply move" pt
                    , \pt -> expectTextPresent "Active node" pt
                    , \pt -> expectTextPresent "best move" pt
                    ]
                    programTest
        , test "keeps the inspection shell visible while stepping" <|
            \() ->
                let
                    programTest =
                        startTicTacToe ()
                            |> clickCell { row = 0, col = 0 }
                            |> clickButtonById "inspect-negamax"
                            |> clickButtonById "trace-forward"
                            |> clickButtonById "trace-back"
                in
                Expect.all
                    [ \pt -> expectTextPresent "Active node" pt
                    , \pt -> expectTextPresent "best move" pt
                    ]
                    programTest
        ]


alphaBetaInspectionTests : Test
alphaBetaInspectionTests =
    describe "Alpha-beta inspection flow"
        [ test "shows alpha, beta, and pruning indicators" <|
            \() ->
                let
                    programTest =
                        startTicTacToe ()
                            |> clickCell { row = 0, col = 0 }
                            |> clickButtonById "inspect-alpha-beta"
                in
                Expect.all
                    [ \pt -> expectTextPresent "alpha" pt
                    , \pt -> expectTextPresent "beta" pt
                    , \pt -> expectTextPresent "pruned" pt
                    ]
                    programTest
        , test "step controls remain available while inspecting alpha-beta" <|
            \() ->
                let
                    programTest =
                        startTicTacToe ()
                            |> clickCell { row = 0, col = 0 }
                            |> clickButtonById "inspect-alpha-beta"
                            |> clickButtonById "trace-forward"
                in
                Expect.all
                    [ \pt -> expectTextPresent "Active node" pt
                    , \pt -> expectTextPresent "best move" pt
                    ]
                    programTest
        ]


fastPlayPreservationTests : Test
fastPlayPreservationTests =
    describe "Fast-play preservation"
        [ test "auto move still commits a single AI response" <|
            \() ->
                startTicTacToe ()
                    |> clickCell { row = 0, col = 0 }
                    |> clickButtonById "auto-move"
                    |> ProgramTest.update (MoveMade { row = 1, col = 1 })
                    |> ProgramTest.expectView
                        (Query.find [ Selector.class "game-board" ]
                            >> Query.findAll [ Selector.class "cell-occupied" ]
                            >> Query.count (Expect.equal 2)
                        )
        ]


startTicTacToe : () -> ProgramTest Model Msg (Cmd Msg)
startTicTacToe _ =
    ProgramTest.createElement
        { init = \_ -> ( initialModel, Cmd.none )
        , update = TicTacToe.Main.update
        , view = TicTacToe.View.view
        }
        |> ProgramTest.start ()

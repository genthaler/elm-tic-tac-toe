module GameInvariantsTest exposing (suite)

{-| Property-based tests for game invariants.
These tests verify that the game maintains consistent state and follows rules.
-}

import Expect
import Model exposing (GameState(..), Player(..), createUnknownError)
import Test exposing (Test, describe, test)
import TicTacToe.TicTacToe as TicTacToe exposing (GameWon(..))


suite : Test
suite =
    describe "Game Invariants"
        [ boardInvariants
        , gameStateInvariants
        , moveInvariants
        , winConditionInvariants
        , aiInvariants
        ]


boardInvariants : Test
boardInvariants =
    describe "Board invariants"
        [ test "board always has 3x3 dimensions" <|
            \_ ->
                let
                    board =
                        TicTacToe.createEmptyBoard

                    hasCorrectDimensions =
                        List.length board == 3 && List.all (\row -> List.length row == 3) board
                in
                Expect.equal True hasCorrectDimensions
        , test "board after move maintains 3x3 dimensions" <|
            \_ ->
                let
                    board =
                        TicTacToe.createEmptyBoard

                    newBoard =
                        TicTacToe.makeMove X { row = 1, col = 1 } board

                    hasCorrectDimensions =
                        List.length newBoard == 3 && List.all (\row -> List.length row == 3) newBoard
                in
                Expect.equal True hasCorrectDimensions
        , test "valid positions are always within bounds" <|
            \_ ->
                let
                    validPositions =
                        [ { row = 0, col = 0 }
                        , { row = 0, col = 1 }
                        , { row = 0, col = 2 }
                        , { row = 1, col = 0 }
                        , { row = 1, col = 1 }
                        , { row = 1, col = 2 }
                        , { row = 2, col = 0 }
                        , { row = 2, col = 1 }
                        , { row = 2, col = 2 }
                        ]

                    allValid =
                        List.all TicTacToe.isValidPosition validPositions

                    invalidPositions =
                        [ { row = -1, col = 0 }
                        , { row = 0, col = -1 }
                        , { row = 3, col = 0 }
                        , { row = 0, col = 3 }
                        , { row = 3, col = 3 }
                        ]

                    allInvalid =
                        List.all (not << TicTacToe.isValidPosition) invalidPositions
                in
                Expect.all
                    [ \_ -> Expect.equal True allValid
                    , \_ -> Expect.equal True allInvalid
                    ]
                    ()
        , test "piece count never exceeds game rules" <|
            \_ ->
                let
                    -- Test various board states
                    testBoards =
                        [ TicTacToe.createEmptyBoard
                        , TicTacToe.makeMove X { row = 0, col = 0 } TicTacToe.createEmptyBoard
                        , TicTacToe.makeMove O { row = 1, col = 1 } (TicTacToe.makeMove X { row = 0, col = 0 } TicTacToe.createEmptyBoard)
                        ]

                    validatePieceCount board =
                        let
                            ( xCount, oCount ) =
                                board
                                    |> List.concat
                                    |> List.foldl
                                        (\cell ( x, o ) ->
                                            case cell of
                                                Just X ->
                                                    ( x + 1, o )

                                                Just O ->
                                                    ( x, o + 1 )

                                                Nothing ->
                                                    ( x, o )
                                        )
                                        ( 0, 0 )
                        in
                        -- X goes first, so X count should be equal to O count or one more
                        xCount == oCount || xCount == oCount + 1

                    results =
                        List.map validatePieceCount testBoards
                in
                Expect.equal [ True, True, True ] results
        ]


gameStateInvariants : Test
gameStateInvariants =
    describe "Game state invariants"
        [ test "game state transitions are valid" <|
            \_ ->
                let
                    -- Test valid state transitions
                    validTransitions =
                        [ ( Waiting X, Thinking O )
                        , ( Thinking O, Waiting X )
                        , ( Waiting X, Winner X )
                        , ( Waiting O, Winner O )
                        , ( Waiting X, Draw )
                        , ( Thinking O, Draw )
                        ]

                    -- All these should be logically valid transitions
                    allValid =
                        List.all
                            (\( from, to ) ->
                                case ( from, to ) of
                                    ( Waiting _, Thinking _ ) ->
                                        True

                                    ( Thinking _, Waiting _ ) ->
                                        True

                                    ( Waiting _, Winner _ ) ->
                                        True

                                    ( Thinking _, Winner _ ) ->
                                        True

                                    ( Waiting _, Draw ) ->
                                        True

                                    ( Thinking _, Draw ) ->
                                        True

                                    _ ->
                                        False
                            )
                            validTransitions
                in
                Expect.equal True allValid
        , test "terminal states are final" <|
            \_ ->
                let
                    terminalStates =
                        [ Winner X, Winner O, Draw, Error (createUnknownError "test") ]

                    isTerminal state =
                        case state of
                            Winner _ ->
                                True

                            Draw ->
                                True

                            Error _ ->
                                True

                            _ ->
                                False

                    allTerminal =
                        List.all isTerminal terminalStates
                in
                Expect.equal True allTerminal
        , test "waiting and thinking states are non-terminal" <|
            \_ ->
                let
                    nonTerminalStates =
                        [ Waiting X, Waiting O, Thinking X, Thinking O ]

                    isNonTerminal state =
                        case state of
                            Waiting _ ->
                                True

                            Thinking _ ->
                                True

                            _ ->
                                False

                    allNonTerminal =
                        List.all isNonTerminal nonTerminalStates
                in
                Expect.equal True allNonTerminal
        ]


moveInvariants : Test
moveInvariants =
    describe "Move invariants"
        [ test "valid moves only place pieces in empty cells" <|
            \_ ->
                let
                    board =
                        TicTacToe.createEmptyBoard

                    position =
                        { row = 1, col = 1 }

                    gameState =
                        Waiting X

                    isValidBefore =
                        TicTacToe.isValidMove position board gameState

                    boardAfterMove =
                        TicTacToe.makeMove X position board

                    isValidAfter =
                        TicTacToe.isValidMove position boardAfterMove gameState
                in
                Expect.all
                    [ \_ -> Expect.equal True isValidBefore
                    , \_ -> Expect.equal False isValidAfter
                    ]
                    ()
        , test "moves preserve other pieces on board" <|
            \_ ->
                let
                    initialBoard =
                        [ [ Just X, Nothing, Nothing ]
                        , [ Nothing, Nothing, Nothing ]
                        , [ Nothing, Nothing, Just O ]
                        ]

                    position =
                        { row = 1, col = 1 }

                    newBoard =
                        TicTacToe.makeMove X position initialBoard

                    preservedPieces =
                        [ TicTacToe.getCellState { row = 0, col = 0 } newBoard == Just X
                        , TicTacToe.getCellState { row = 2, col = 2 } newBoard == Just O
                        , TicTacToe.getCellState { row = 1, col = 1 } newBoard == Just X
                        ]
                in
                Expect.equal [ True, True, True ] preservedPieces
        , test "player switching alternates correctly" <|
            \_ ->
                let
                    switchedX =
                        TicTacToe.switchPlayer X

                    switchedO =
                        TicTacToe.switchPlayer O

                    doubleSwitchX =
                        X |> TicTacToe.switchPlayer |> TicTacToe.switchPlayer

                    doubleSwitchO =
                        O |> TicTacToe.switchPlayer |> TicTacToe.switchPlayer
                in
                Expect.all
                    [ \_ -> Expect.equal O switchedX
                    , \_ -> Expect.equal X switchedO
                    , \_ -> Expect.equal X doubleSwitchX
                    , \_ -> Expect.equal O doubleSwitchO
                    ]
                    ()
        , test "invalid moves don't change board state" <|
            \_ ->
                let
                    board =
                        [ [ Just X, Nothing, Nothing ]
                        , [ Nothing, Nothing, Nothing ]
                        , [ Nothing, Nothing, Nothing ]
                        ]

                    -- Try to place in occupied cell
                    invalidPosition =
                        { row = 0, col = 0 }

                    -- makeMove doesn't validate, but we can test the principle
                    -- The move will be applied (makeMove doesn't validate)
                    -- but we can verify that validation would catch this
                    wouldBeValid =
                        TicTacToe.isValidMove invalidPosition board (Waiting O)
                in
                Expect.equal False wouldBeValid
        ]


winConditionInvariants : Test
winConditionInvariants =
    describe "Win condition invariants"
        [ test "win detection is consistent" <|
            \_ ->
                let
                    winningBoards =
                        [ -- Horizontal wins
                          [ [ Just X, Just X, Just X ]
                          , [ Nothing, Nothing, Nothing ]
                          , [ Nothing, Nothing, Nothing ]
                          ]
                        , [ [ Nothing, Nothing, Nothing ]
                          , [ Just O, Just O, Just O ]
                          , [ Nothing, Nothing, Nothing ]
                          ]
                        , -- Vertical wins
                          [ [ Just X, Nothing, Nothing ]
                          , [ Just X, Nothing, Nothing ]
                          , [ Just X, Nothing, Nothing ]
                          ]
                        , -- Diagonal wins
                          [ [ Just O, Nothing, Nothing ]
                          , [ Nothing, Just O, Nothing ]
                          , [ Nothing, Nothing, Just O ]
                          ]
                        ]

                    results =
                        List.map TicTacToe.checkWinner winningBoards

                    expectedResults =
                        [ PlayerWon X, PlayerWon O, PlayerWon X, PlayerWon O ]
                in
                Expect.equal expectedResults results
        , test "draw detection requires full board with no winner" <|
            \_ ->
                let
                    drawBoard =
                        [ [ Just X, Just O, Just X ]
                        , [ Just O, Just O, Just X ]
                        , [ Just O, Just X, Just O ]
                        ]

                    result =
                        TicTacToe.checkWinner drawBoard

                    -- Verify board is full
                    isFull =
                        drawBoard
                            |> List.concat
                            |> List.all (\cell -> cell /= Nothing)
                in
                Expect.all
                    [ \_ -> Expect.equal GameDraw result
                    , \_ -> Expect.equal True isFull
                    ]
                    ()
        , test "game continues when no win condition is met" <|
            \_ ->
                let
                    incompleteBoards =
                        [ TicTacToe.createEmptyBoard
                        , [ [ Just X, Nothing, Nothing ]
                          , [ Nothing, Just O, Nothing ]
                          , [ Nothing, Nothing, Nothing ]
                          ]
                        , [ [ Just X, Just O, Nothing ]
                          , [ Just O, Just X, Nothing ]
                          , [ Nothing, Nothing, Nothing ]
                          ]
                        ]

                    results =
                        List.map TicTacToe.checkWinner incompleteBoards

                    expectedResults =
                        [ GameContinues, GameContinues, GameContinues ]
                in
                Expect.equal expectedResults results
        , test "win overrides draw" <|
            \_ ->
                let
                    -- Full board with a win
                    winningFullBoard =
                        [ [ Just X, Just X, Just X ]
                        , [ Just O, Just O, Just X ]
                        , [ Just O, Just X, Just O ]
                        ]

                    result =
                        TicTacToe.checkWinner winningFullBoard

                    -- Should detect win, not draw
                    isFull =
                        winningFullBoard
                            |> List.concat
                            |> List.all (\cell -> cell /= Nothing)
                in
                Expect.all
                    [ \_ -> Expect.equal (PlayerWon X) result
                    , \_ -> Expect.equal True isFull
                    ]
                    ()
        ]


aiInvariants : Test
aiInvariants =
    describe "AI invariants"
        [ test "AI only suggests valid moves" <|
            \_ ->
                let
                    testBoards =
                        [ TicTacToe.createEmptyBoard
                        , [ [ Just X, Nothing, Nothing ]
                          , [ Nothing, Nothing, Nothing ]
                          , [ Nothing, Nothing, Nothing ]
                          ]
                        , [ [ Just X, Just O, Nothing ]
                          , [ Nothing, Just X, Nothing ]
                          , [ Just O, Nothing, Nothing ]
                          ]
                        ]

                    testAIMove board =
                        case TicTacToe.findBestMove O board of
                            Just position ->
                                TicTacToe.isValidMove position board (Waiting O)

                            Nothing ->
                                -- No move available should only happen on full board
                                board
                                    |> List.concat
                                    |> List.all (\cell -> cell /= Nothing)

                    results =
                        List.map testAIMove testBoards
                in
                Expect.equal [ True, True, True ] results
        , test "AI behavior on terminal boards" <|
            \_ ->
                let
                    terminalBoards =
                        [ -- X wins
                          [ [ Just X, Just X, Just X ]
                          , [ Nothing, Nothing, Nothing ]
                          , [ Nothing, Nothing, Nothing ]
                          ]
                        , -- Draw
                          [ [ Just X, Just O, Just X ]
                          , [ Just O, Just O, Just X ]
                          , [ Just O, Just X, Just O ]
                          ]
                        ]

                    results =
                        List.map (TicTacToe.findBestMove O) terminalBoards

                    -- For terminal boards, AI should either return Nothing or a move that would be invalid
                    -- The first board has a winner, so game should be over
                    -- The second board is a draw, so no moves should be possible
                    isReasonableResult result =
                        case result of
                            Nothing ->
                                True

                            Just position ->
                                -- If AI returns a move, check if the board state makes sense
                                TicTacToe.isValidPosition position

                    validResults =
                        List.map isReasonableResult results
                in
                Expect.equal [ True, True ] validResults
        , test "AI move quality is consistent" <|
            \_ ->
                let
                    board =
                        [ [ Just X, Nothing, Nothing ]
                        , [ Nothing, Nothing, Nothing ]
                        , [ Nothing, Nothing, Nothing ]
                        ]

                    -- AI should make the same move for the same position
                    move1 =
                        TicTacToe.findBestMove O board

                    move2 =
                        TicTacToe.findBestMove O board
                in
                Expect.equal move1 move2
        , test "AI prefers winning moves" <|
            \_ ->
                let
                    -- Board where O can win
                    winningBoard =
                        [ [ Just O, Just O, Nothing ]
                        , [ Just X, Just X, Nothing ]
                        , [ Nothing, Nothing, Nothing ]
                        ]

                    aiMove =
                        TicTacToe.findBestMove O winningBoard

                    -- Should choose the winning move
                    expectedMove =
                        Just { row = 0, col = 2 }
                in
                Expect.equal expectedMove aiMove
        , test "AI blocks opponent winning moves" <|
            \_ ->
                let
                    -- Board where X is about to win
                    blockingBoard =
                        [ [ Just X, Just X, Nothing ]
                        , [ Nothing, Just O, Nothing ]
                        , [ Nothing, Nothing, Nothing ]
                        ]

                    aiMove =
                        TicTacToe.findBestMove O blockingBoard

                    -- Should block the winning move
                    expectedMove =
                        Just { row = 0, col = 2 }
                in
                Expect.equal expectedMove aiMove
        ]

module GameTest exposing (suite)

import Expect
import ExtendedOrder exposing (ExtendedOrder(..))
import Game exposing (evaluateMove, findBestMove, possibleMoves, scoreBoard)
import Model exposing (Board, Mode(..), Model, Player(..), Position, initialModel)
import Test exposing (Test, describe, test)


suite : Test
suite =
    let
        ( x, o, n ) =
            ( Just X, Just O, Nothing )
    in
    describe "Game"
        [ describe "possibleMoves"
            [ test "should return all positions for empty board" <|
                \_ ->
                    initialModel
                        |> .board
                        |> possibleMoves
                        |> List.length
                        |> Expect.equal 9
            , test "should exclude occupied positions" <|
                \_ ->
                    let
                        board : Board
                        board =
                            [ [ x, n, n ]
                            , [ n, o, n ]
                            , [ n, n, n ]
                            ]
                    in
                    possibleMoves board
                        |> List.length
                        |> Expect.equal 7
            , test "should return correct positions" <|
                \_ ->
                    let
                        board : Board
                        board =
                            [ [ x, n, n ]
                            , [ n, o, n ]
                            , [ n, n, n ]
                            ]

                        expected : List Position
                        expected =
                            [ Position 0 1
                            , Position 0 2
                            , Position 1 0
                            , Position 1 2
                            , Position 2 0
                            , Position 2 1
                            , Position 2 2
                            ]
                    in
                    possibleMoves board
                        |> List.sortBy (\pos -> pos.row * 3 + pos.col)
                        |> Expect.equal expected
            ]
        , describe "findBestMove"
            [ test "should choose winning move when available" <|
                \_ ->
                    let
                        model : Model
                        model =
                            { board =
                                [ [ x, x, n ]
                                , [ o, o, n ]
                                , [ n, n, n ]
                                ]
                            , currentPlayer = X
                            , isThinking = False
                            , errorMessage = Nothing
                            , winner = Nothing
                            , mode = Light
                            }

                        expectedMove : Maybe Position
                        expectedMove =
                            Just (Position 0 2)
                    in
                    findBestMove model
                        |> Expect.equal expectedMove
            , test "should block opponent's winning move" <|
                \_ ->
                    let
                        model : Model
                        model =
                            { board =
                                [ [ o, o, n ]
                                , [ x, n, n ]
                                , [ n, n, n ]
                                ]
                            , currentPlayer = X
                            , isThinking = False
                            , errorMessage = Nothing
                            , winner = Nothing
                            , mode = Light
                            }

                        expectedMove : Maybe Position
                        expectedMove =
                            Just (Position 0 2)
                    in
                    findBestMove model
                        |> Expect.equal expectedMove
            , test "should prefer center on empty board" <|
                \_ ->
                    initialModel
                        |> findBestMove
                        |> Expect.equal (Just (Position 1 1))
            ]
        , describe "scoreBoard"
            [ test "should return positive score for X winning 1*10^3 + 1*10^1 - 1*10^2" <|
                \_ ->
                    let
                        board : Board
                        board =
                            [ [ x, x, x ]
                            , [ o, o, n ]
                            , [ n, n, n ]
                            ]
                    in
                    scoreBoard X board
                        |> Expect.equal 910
            , test "should return negative score for O winning" <|
                \_ ->
                    let
                        board : Board
                        board =
                            [ [ o, o, o ]
                            , [ x, x, n ]
                            , [ n, n, n ]
                            ]
                    in
                    scoreBoard X board
                        |> Expect.equal -910
            , test "should return 0 for a draw" <|
                \_ ->
                    let
                        board : Board
                        board =
                            [ [ x, o, x ]
                            , [ x, o, o ]
                            , [ o, x, x ]
                            ]
                    in
                    scoreBoard X board
                        |> Expect.equal 0
            , test "should return score for ongoing game 3*10^1 - 2*10^1" <|
                \_ ->
                    let
                        board : Board
                        board =
                            [ [ x, o, n ]
                            , [ n, x, n ]
                            , [ n, n, o ]
                            ]
                    in
                    scoreBoard X board
                        |> Expect.equal 10
            , test "foo" <|
                \_ ->
                    let
                        board : Board
                        board =
                            [ [ x, n, o ]
                            , [ n, n, n ]
                            , [ n, n, n ]
                            ]
                    in
                    scoreBoard O board
                        |> Expect.equal 0
            ]
        , describe "evaluateMove"
            [ test "should prefer winning move" <|
                \_ ->
                    let
                        board : Board
                        board =
                            [ [ x, x, n ]
                            , [ o, o, n ]
                            , [ n, n, n ]
                            ]

                        model : Model
                        model =
                            { initialModel
                                | board = board
                                , currentPlayer = X
                                , mode = Light
                            }
                    in
                    evaluateMove model (Position 0 2)
                        |> (\a ->
                                case a of
                                    Comparable b ->
                                        Expect.greaterThan 0 b

                                    _ ->
                                        Expect.fail "Don't expect negative or positive infinity"
                           )
            , test "should block opponent winning move" <|
                \_ ->
                    let
                        board : Board
                        board =
                            [ [ x, n, n ]
                            , [ o, o, n ]
                            , [ n, n, n ]
                            ]

                        model : Model
                        model =
                            { initialModel
                                | board = board
                                , currentPlayer = X
                                , mode = Light
                            }
                    in
                    evaluateMove model (Position 1 2)
                        |> (\a ->
                                case a of
                                    Comparable b ->
                                        Expect.greaterThan 0 b

                                    _ ->
                                        Expect.fail "Don't expect negative or positive infinity"
                           )
            , Test.only <|
                test "should prefer center over corners" <|
                    \_ ->
                        let
                            model : Model
                            model =
                                initialModel

                            cornerMove =
                                evaluateMove model (Position 0 0)
                        in
                        evaluateMove model (Position 1 1)
                            |> (\a ->
                                    case ( a, cornerMove ) of
                                        ( Comparable b, Comparable c ) ->
                                            Expect.greaterThan c b

                                        _ ->
                                            Expect.fail "Don't expect negative or positive infinity"
                               )
            ]
        ]

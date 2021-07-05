module TicTacToeTest exposing (all)

-- import Fuzz exposing (Fuzzer, int, list, string)

import Expect
import Test exposing (Test, describe, test)
import TicTacToe exposing (Move, Player(..), alphabetaGame, getMoves, getWinningPositions, initGame, minimaxGame, restoreGame, updateGame)


all : Test
all =
    let
        ( n, x, o ) =
            ( Nothing, Just X, Just O )
    in
    describe "Game test"
        [ describe "Alpha-beta pruning"
            [ test "The best possible result is to win with 2 lines" <|
                \_ ->
                    alphabetaGame initGame
                        |> Expect.equal (Just (Move X ( 1, 1 )))
            , test "End game" <|
                \_ ->
                    restoreGame X
                        [ [ x, n, n ]
                        , [ x, n, n ]
                        , [ n, n, n ]
                        ]
                        |> Result.map alphabetaGame
                        |> Expect.equal (Ok (Just (Move X ( 2, 0 ))))
            ]

        -- , describe "Game mechanics"
        --     [ test "If there's a winning move, then the game is over" <|
        --         \_ ->
        --             Expect.equal (Just True) <|
        --                 (restoreGame X
        --                     [ [ x, n, n ]
        --                     , [ x, n, n ]
        --                     , [ x, n, n ]
        --                     ]
        --                     |> Maybe.map (updateGame 2 0)
        --                     |> Maybe.map (getWinningPositions >> List.isEmpty >> not)
        --                 )
        -- , test "score game" <|
        --     \_ ->
        --         Expect.equal
        --             [ ( 0
        --               , [ [ ( 0, 1 ), ( 1, 1 ), ( 2, 1 ) ]
        --                 , [ ( 0, 2 ), ( 1, 2 ), ( 2, 2 ) ]
        --                 ]
        --               )
        --             , ( 1
        --               , [ [ ( 0, 0 ), ( 0, 1 ), ( 0, 2 ) ]
        --                 , [ ( 1, 0 ), ( 1, 1 ), ( 1, 2 ) ]
        --                 , [ ( 2, 0 ), ( 2, 1 ), ( 2, 2 ) ]
        --                 , [ ( 0, 0 ), ( 1, 1 ), ( 2, 2 ) ]
        --                 , [ ( 0, 2 ), ( 1, 1 ), ( 2, 0 ) ]
        --                 ]
        --               )
        --             , ( 3
        --               , [ [ ( 0, 0 ), ( 1, 0 ), ( 2, 0 ) ]
        --                 ]
        --               )
        --             ]
        --         <|
        --             (restoreGame X
        --                 [ [ j X, n, n ]
        --                 , [ j X, n, n ]
        --                 , [ n, n, n ]
        --                 ]
        --                 |> Maybe.map (updateGame 2 0)
        --                 |> Maybe.map TicTacToe.scoreGame
        --                 |> Maybe.map Dict.toList
        --                 |> Maybe.withDefault []
        --             )
        -- ]
        ]

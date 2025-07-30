module TicTacToe.IntentionalIssuesTest exposing (..)

-- Intentional unused import to test NoUnused.Imports rule

import Expect
import Test exposing (..)



-- Intentional unused variables to test NoUnused.Variables rule


unusedFunction : Int -> Int
unusedFunction x =
    x + 1



-- Function with unused parameter


functionWithUnusedParam : String -> Int -> String
functionWithUnusedParam text _ =
    text



-- Intentional Debug.log to test NoDebug.Log rule


testWithDebugLog : Test
testWithDebugLog =
    test "function with debug log" <|
        \_ ->
            let
                result =
                    42
            in
            Expect.equal result 42



-- More unused variables in different contexts


testUnusedInLet : Test
testUnusedInLet =
    test "unused variables in let expression" <|
        \_ ->
            let
                used =
                    1

                result =
                    used + 10
            in
            Expect.equal result 11



-- Unused top-level function


unusedTopLevelFunction : String
unusedTopLevelFunction =
    "This function is never called"



-- Function that could be simplified (for Simplify rule)


inefficientFunction : List Int -> List Int
inefficientFunction list =
    List.map (\x -> x) list



-- Identity function, should be simplified
-- Another simplification opportunity


redundantCase : Maybe Int -> Int
redundantCase maybe =
    case maybe of
        Just value ->
            value

        Nothing ->
            0



-- Could use Maybe.withDefault


suite : Test
suite =
    describe "Intentional Issues Test Suite"
        [ testWithDebugLog
        , testUnusedInLet
        , test "basic test" <|
            \_ ->
                Expect.equal (2 + 2) 4
        ]

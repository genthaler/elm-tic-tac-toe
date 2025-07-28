module GameTheory.ExtendedOrderTest exposing (suite)

{-| Test suite for GameTheory.ExtendedOrder module.
Tests extended ordering with infinity values.
-}

import Expect
import GameTheory.ExtendedOrder as ExtendedOrder exposing (ExtendedOrder(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "GameTheory.ExtendedOrder"
        [ equalityTests
        , comparisonTests
        , orderingTests
        , arithmeticTests
        , propertyTests
        ]


equalityTests : Test
equalityTests =
    describe "Equality operations"
        [ test "eq with same Comparable values" <|
            \_ ->
                Expect.equal True (ExtendedOrder.eq (Comparable 5) (Comparable 5))
        , test "eq with different Comparable values" <|
            \_ ->
                Expect.equal False (ExtendedOrder.eq (Comparable 5) (Comparable 3))
        , test "eq with PositiveInfinity" <|
            \_ ->
                Expect.equal True (ExtendedOrder.eq PositiveInfinity PositiveInfinity)
        , test "eq with NegativeInfinity" <|
            \_ ->
                Expect.equal True (ExtendedOrder.eq NegativeInfinity NegativeInfinity)
        , test "eq with different infinities" <|
            \_ ->
                Expect.equal False (ExtendedOrder.eq PositiveInfinity NegativeInfinity)
        , test "eq with PositiveInfinity and Comparable" <|
            \_ ->
                Expect.equal False (ExtendedOrder.eq PositiveInfinity (Comparable 100))
        , test "eq with NegativeInfinity and Comparable" <|
            \_ ->
                Expect.equal False (ExtendedOrder.eq NegativeInfinity (Comparable -100))
        ]


comparisonTests : Test
comparisonTests =
    describe "Comparison operations"
        [ describe "Greater than (gt)"
            [ test "gt with Comparable values" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal True (ExtendedOrder.gt (Comparable 5) (Comparable 3))
                        , \_ -> Expect.equal False (ExtendedOrder.gt (Comparable 3) (Comparable 5))
                        , \_ -> Expect.equal False (ExtendedOrder.gt (Comparable 5) (Comparable 5))
                        ]
                        ()
            , test "gt with PositiveInfinity" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal False (ExtendedOrder.gt PositiveInfinity PositiveInfinity)
                        , \_ -> Expect.equal True (ExtendedOrder.gt PositiveInfinity NegativeInfinity)
                        , \_ -> Expect.equal True (ExtendedOrder.gt PositiveInfinity (Comparable 1000))
                        , \_ -> Expect.equal False (ExtendedOrder.gt (Comparable 1000) PositiveInfinity)
                        ]
                        ()
            , test "gt with NegativeInfinity" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal False (ExtendedOrder.gt NegativeInfinity NegativeInfinity)
                        , \_ -> Expect.equal False (ExtendedOrder.gt NegativeInfinity PositiveInfinity)
                        , \_ -> Expect.equal False (ExtendedOrder.gt NegativeInfinity (Comparable -1000))
                        , \_ -> Expect.equal True (ExtendedOrder.gt (Comparable -1000) NegativeInfinity)
                        ]
                        ()
            ]
        , describe "Greater than or equal (ge)"
            [ test "ge with equal values" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal True (ExtendedOrder.ge (Comparable 5) (Comparable 5))
                        , \_ -> Expect.equal True (ExtendedOrder.ge PositiveInfinity PositiveInfinity)
                        , \_ -> Expect.equal True (ExtendedOrder.ge NegativeInfinity NegativeInfinity)
                        ]
                        ()
            , test "ge with greater values" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal True (ExtendedOrder.ge (Comparable 5) (Comparable 3))
                        , \_ -> Expect.equal True (ExtendedOrder.ge PositiveInfinity (Comparable 1000))
                        , \_ -> Expect.equal True (ExtendedOrder.ge (Comparable -100) NegativeInfinity)
                        ]
                        ()
            , test "ge with lesser values" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal False (ExtendedOrder.ge (Comparable 3) (Comparable 5))
                        , \_ -> Expect.equal False (ExtendedOrder.ge (Comparable 1000) PositiveInfinity)
                        , \_ -> Expect.equal False (ExtendedOrder.ge NegativeInfinity (Comparable -100))
                        ]
                        ()
            ]
        , describe "Less than (lt)"
            [ test "lt with Comparable values" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal True (ExtendedOrder.lt (Comparable 3) (Comparable 5))
                        , \_ -> Expect.equal False (ExtendedOrder.lt (Comparable 5) (Comparable 3))
                        , \_ -> Expect.equal False (ExtendedOrder.lt (Comparable 5) (Comparable 5))
                        ]
                        ()
            , test "lt with infinities" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal True (ExtendedOrder.lt NegativeInfinity PositiveInfinity)
                        , \_ -> Expect.equal True (ExtendedOrder.lt (Comparable 100) PositiveInfinity)
                        , \_ -> Expect.equal True (ExtendedOrder.lt NegativeInfinity (Comparable -100))
                        , \_ -> Expect.equal False (ExtendedOrder.lt PositiveInfinity (Comparable 100))
                        ]
                        ()
            ]
        , describe "Less than or equal (le)"
            [ test "le with equal values" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal True (ExtendedOrder.le (Comparable 5) (Comparable 5))
                        , \_ -> Expect.equal True (ExtendedOrder.le PositiveInfinity PositiveInfinity)
                        , \_ -> Expect.equal True (ExtendedOrder.le NegativeInfinity NegativeInfinity)
                        ]
                        ()
            , test "le with lesser values" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal True (ExtendedOrder.le (Comparable 3) (Comparable 5))
                        , \_ -> Expect.equal True (ExtendedOrder.le NegativeInfinity (Comparable -100))
                        , \_ -> Expect.equal True (ExtendedOrder.le (Comparable 100) PositiveInfinity)
                        ]
                        ()
            ]
        ]


orderingTests : Test
orderingTests =
    describe "Ordering operations"
        [ describe "compare function"
            [ test "compare returns correct Order" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal EQ (ExtendedOrder.compare (Comparable 5) (Comparable 5))
                        , \_ -> Expect.equal LT (ExtendedOrder.compare (Comparable 3) (Comparable 5))
                        , \_ -> Expect.equal GT (ExtendedOrder.compare (Comparable 5) (Comparable 3))
                        , \_ -> Expect.equal EQ (ExtendedOrder.compare PositiveInfinity PositiveInfinity)
                        , \_ -> Expect.equal GT (ExtendedOrder.compare PositiveInfinity (Comparable 1000))
                        , \_ -> Expect.equal LT (ExtendedOrder.compare NegativeInfinity (Comparable -1000))
                        ]
                        ()
            ]
        , describe "max function"
            [ test "max returns greater value" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal (Comparable 5) (ExtendedOrder.max (Comparable 3) (Comparable 5))
                        , \_ -> Expect.equal (Comparable 5) (ExtendedOrder.max (Comparable 5) (Comparable 3))
                        , \_ -> Expect.equal PositiveInfinity (ExtendedOrder.max PositiveInfinity (Comparable 1000))
                        , \_ -> Expect.equal (Comparable -100) (ExtendedOrder.max NegativeInfinity (Comparable -100))
                        ]
                        ()
            , test "max with equal values" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal (Comparable 5) (ExtendedOrder.max (Comparable 5) (Comparable 5))
                        , \_ -> Expect.equal PositiveInfinity (ExtendedOrder.max PositiveInfinity PositiveInfinity)
                        , \_ -> Expect.equal NegativeInfinity (ExtendedOrder.max NegativeInfinity NegativeInfinity)
                        ]
                        ()
            ]
        , describe "min function"
            [ test "min returns lesser value" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal (Comparable 3) (ExtendedOrder.min (Comparable 3) (Comparable 5))
                        , \_ -> Expect.equal (Comparable 3) (ExtendedOrder.min (Comparable 5) (Comparable 3))
                        , \_ -> Expect.equal (Comparable 1000) (ExtendedOrder.min PositiveInfinity (Comparable 1000))
                        , \_ -> Expect.equal NegativeInfinity (ExtendedOrder.min NegativeInfinity (Comparable -100))
                        ]
                        ()
            ]
        ]


arithmeticTests : Test
arithmeticTests =
    describe "Arithmetic operations"
        [ describe "negate function"
            [ test "negate Comparable values" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal (Comparable -5) (ExtendedOrder.negate (Comparable 5))
                        , \_ -> Expect.equal (Comparable 5) (ExtendedOrder.negate (Comparable -5))
                        , \_ -> Expect.equal (Comparable 0) (ExtendedOrder.negate (Comparable 0))
                        ]
                        ()
            , test "negate infinity values" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal NegativeInfinity (ExtendedOrder.negate PositiveInfinity)
                        , \_ -> Expect.equal PositiveInfinity (ExtendedOrder.negate NegativeInfinity)
                        ]
                        ()
            , test "double negate returns original" <|
                \_ ->
                    let
                        values =
                            [ Comparable 5, Comparable -3, Comparable 0, PositiveInfinity, NegativeInfinity ]

                        doubleNegate value =
                            value |> ExtendedOrder.negate |> ExtendedOrder.negate

                        results =
                            List.map (\v -> doubleNegate v == v) values
                    in
                    Expect.equal [ True, True, True, True, True ] results
            ]
        , describe "map function"
            [ test "map transforms Comparable values" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal (Comparable 10) (ExtendedOrder.map ((*) 2) (Comparable 5))
                        , \_ -> Expect.equal (Comparable 8) (ExtendedOrder.map ((+) 3) (Comparable 5))
                        ]
                        ()
            , test "map preserves infinity values" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal PositiveInfinity (ExtendedOrder.map ((*) 2) PositiveInfinity)
                        , \_ -> Expect.equal NegativeInfinity (ExtendedOrder.map ((*) 2) NegativeInfinity)
                        ]
                        ()
            ]
        ]


propertyTests : Test
propertyTests =
    describe "Property-based tests and invariants"
        [ describe "Sign checking functions"
            [ test "isPositive correctly identifies positive values" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal True (ExtendedOrder.isPositive (Comparable 5))
                        , \_ -> Expect.equal False (ExtendedOrder.isPositive (Comparable -5))
                        , \_ -> Expect.equal False (ExtendedOrder.isPositive (Comparable 0))
                        , \_ -> Expect.equal True (ExtendedOrder.isPositive PositiveInfinity)
                        , \_ -> Expect.equal False (ExtendedOrder.isPositive NegativeInfinity)
                        ]
                        ()
            , test "isNegative correctly identifies negative values" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal False (ExtendedOrder.isNegative (Comparable 5))
                        , \_ -> Expect.equal True (ExtendedOrder.isNegative (Comparable -5))
                        , \_ -> Expect.equal False (ExtendedOrder.isNegative (Comparable 0))
                        , \_ -> Expect.equal False (ExtendedOrder.isNegative PositiveInfinity)
                        , \_ -> Expect.equal True (ExtendedOrder.isNegative NegativeInfinity)
                        ]
                        ()
            , test "isZero correctly identifies zero values" <|
                \_ ->
                    Expect.all
                        [ \_ -> Expect.equal False (ExtendedOrder.isZero (Comparable 5))
                        , \_ -> Expect.equal False (ExtendedOrder.isZero (Comparable -5))
                        , \_ -> Expect.equal True (ExtendedOrder.isZero (Comparable 0))
                        , \_ -> Expect.equal False (ExtendedOrder.isZero PositiveInfinity)
                        , \_ -> Expect.equal False (ExtendedOrder.isZero NegativeInfinity)
                        ]
                        ()
            ]
        , describe "Ordering invariants"
            [ test "transitivity of gt" <|
                \_ ->
                    let
                        a =
                            Comparable 1

                        b =
                            Comparable 2

                        c =
                            Comparable 3

                        aGtB =
                            ExtendedOrder.gt b a

                        bGtC =
                            ExtendedOrder.gt c b

                        aGtC =
                            ExtendedOrder.gt c a
                    in
                    -- If a > b and b > c, then a > c
                    if aGtB && bGtC then
                        Expect.equal True aGtC

                    else
                        Expect.pass
            , test "antisymmetry of gt" <|
                \_ ->
                    let
                        a =
                            Comparable 5

                        b =
                            Comparable 3

                        aGtB =
                            ExtendedOrder.gt a b

                        bGtA =
                            ExtendedOrder.gt b a
                    in
                    -- If a > b, then not (b > a)
                    if aGtB then
                        Expect.equal False bGtA

                    else
                        Expect.pass
            , test "reflexivity of eq" <|
                \_ ->
                    let
                        values =
                            [ Comparable 5, Comparable -3, PositiveInfinity, NegativeInfinity ]

                        results =
                            List.map (\v -> ExtendedOrder.eq v v) values
                    in
                    Expect.equal [ True, True, True, True ] results
            ]
        , describe "Max/Min properties"
            [ test "max is commutative" <|
                \_ ->
                    let
                        a =
                            Comparable 5

                        b =
                            Comparable 3

                        maxAB =
                            ExtendedOrder.max a b

                        maxBA =
                            ExtendedOrder.max b a
                    in
                    Expect.equal maxAB maxBA
            , test "min is commutative" <|
                \_ ->
                    let
                        a =
                            Comparable 5

                        b =
                            Comparable 3

                        minAB =
                            ExtendedOrder.min a b

                        minBA =
                            ExtendedOrder.min b a
                    in
                    Expect.equal minAB minBA
            , test "max is associative" <|
                \_ ->
                    let
                        a =
                            Comparable 1

                        b =
                            Comparable 2

                        c =
                            Comparable 3

                        maxABC1 =
                            ExtendedOrder.max (ExtendedOrder.max a b) c

                        maxABC2 =
                            ExtendedOrder.max a (ExtendedOrder.max b c)
                    in
                    Expect.equal maxABC1 maxABC2
            , test "min is associative" <|
                \_ ->
                    let
                        a =
                            Comparable 1

                        b =
                            Comparable 2

                        c =
                            Comparable 3

                        minABC1 =
                            ExtendedOrder.min (ExtendedOrder.min a b) c

                        minABC2 =
                            ExtendedOrder.min a (ExtendedOrder.min b c)
                    in
                    Expect.equal minABC1 minABC2
            ]
        ]

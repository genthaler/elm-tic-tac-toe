module NumberExtended exposing (..)

{-| This module implements numbers extended with positive and negative infinity

It (ab)uses the fact that `number` is an implicit Elm typeclass

@docs NumberExtended

-}


type NumberExtended comparable
    = PositiveInfinity
    | NegativeInfinity
    | Number comparable


{-| equality

    eq (Number 1) (Number 1) --> True

    eq (Number 1) (Number 2) --> False

    eq (Number 2) (Number 1) --> False

    eq PositiveInfinity PositiveInfinity --> True

    eq NegativeInfinity NegativeInfinity --> True

    eq PositiveInfinity NegativeInfinity --> False

    eq NegativeInfinity PositiveInfinity --> False

    eq PositiveInfinity (Number 1) --> False

    eq (Number 1) PositiveInfinity --> False

    eq NegativeInfinity (Number 1) --> False

    eq (Number 1) NegativeInfinity --> False

-}
eq : NumberExtended comparable -> NumberExtended comparable -> Bool
eq a b =
    a == b


{-| greater than

    gt (Number 1) (Number 1) --> False

    gt (Number 1) (Number 2) --> False

    gt (Number 2) (Number 1) --> True

    gt PositiveInfinity PositiveInfinity --> False

    gt NegativeInfinity NegativeInfinity --> False

    gt PositiveInfinity NegativeInfinity --> True

    gt NegativeInfinity PositiveInfinity --> False

    gt PositiveInfinity (Number 1) --> True

    gt (Number 1) PositiveInfinity --> False

    gt NegativeInfinity (Number 1) --> False

    gt (Number 1) NegativeInfinity --> True

-}
gt : NumberExtended comparable -> NumberExtended comparable -> Bool
gt a b =
    case a of
        PositiveInfinity ->
            b /= PositiveInfinity

        NegativeInfinity ->
            False

        Number x ->
            case b of
                NegativeInfinity ->
                    True

                Number y ->
                    x > y

                PositiveInfinity ->
                    False


{-| greater than or equal to

    ge (Number 1) (Number 1) --> True

    ge (Number 1) (Number 2) --> False

    ge (Number 2) (Number 1) --> True

    ge PositiveInfinity PositiveInfinity --> True

    ge NegativeInfinity NegativeInfinity --> True

    ge PositiveInfinity NegativeInfinity --> True

    ge NegativeInfinity PositiveInfinity --> False

    ge PositiveInfinity (Number 1) --> True

    ge (Number 1) PositiveInfinity --> False

    ge NegativeInfinity (Number 1) --> False

    ge (Number 1) NegativeInfinity --> True

-}
ge : NumberExtended comparable -> NumberExtended comparable -> Bool
ge a b =
    eq a b || gt a b


{-| less than

    lt (Number 1) (Number 1) --> False

    lt (Number 1) (Number 2) --> True

    lt (Number 2) (Number 1) --> False

    lt PositiveInfinity PositiveInfinity --> False

    lt NegativeInfinity NegativeInfinity --> False

    lt PositiveInfinity NegativeInfinity --> False

    lt NegativeInfinity PositiveInfinity --> True

    lt PositiveInfinity (Number 1) --> False

    lt (Number 1) PositiveInfinity --> True

    lt NegativeInfinity (Number 1) --> True

    lt (Number 1) NegativeInfinity --> False

-}
lt : NumberExtended comparable -> NumberExtended comparable -> Bool
lt a b =
    not (ge a b)


{-| less than or equal to

    le (Number 1) (Number 1) --> True

    le (Number 1) (Number 2) --> True

    le (Number 2) (Number 1) --> False

    le PositiveInfinity PositiveInfinity --> True

    le NegativeInfinity NegativeInfinity --> True

    le PositiveInfinity NegativeInfinity --> False

    le NegativeInfinity PositiveInfinity --> True

    le PositiveInfinity (Number 1) --> False

    le (Number 1) PositiveInfinity --> True

    le NegativeInfinity (Number 1) --> True

    le (Number 1) NegativeInfinity --> False

-}
le : NumberExtended comparable -> NumberExtended comparable -> Bool
le a b =
    not (gt a b)


compare : NumberExtended comparable -> NumberExtended comparable -> Order
compare a b =
    if eq a b then
        EQ

    else if lt a b then
        LT

    else
        GT


max : NumberExtended comparable -> NumberExtended comparable -> NumberExtended comparable
max a b =
    if gt a b then
        a

    else
        b


min : NumberExtended comparable -> NumberExtended comparable -> NumberExtended comparable
min a b =
    if lt a b then
        a

    else
        b

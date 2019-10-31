module Matrix exposing
    ( Matrix
    , empty, repeat, initialize, identity, fromList, fromLists
    , height, width, size
    , get, set
    , map, map2, transpose, dot, indexedMap
    , toList, toLists, pretty
    )

{-| A simple linear algebra library using flat-arrays
Follows Array semantics as far as possible


# The Matrix type

@docs Matrix


# Creating matrices

@docs empty, repeat, initialize, identity, fromList, fromLists


# Get matrix dimensions

@docs height, width, size


# Working with individual elements

@docs get, set


# Matrix manipulation

@docs map, map2, transpose, dot, indexedMap


# Matrix representation

@docs toList, toLists, pretty

-}

import Array exposing (Array)
import Debug


{-| Representation of a matrix. You can create matrices of any type
but arithmetic operations in Matrix.Operations requires the matrices
to have numeric types.
-}
type Matrix a
    = Matrix
        { nrows : Int
        , ncols : Int
        , mvect : Array (Array a)
        }


{-| Create an empty matrix.

    size empty == ( 0, 0 )

-}
empty : Matrix a
empty =
    Matrix
        { nrows = 0
        , ncols = 0
        , mvect = Array.empty
        }


{-| Create a matrix with a given size, filled with a default value.

    repeat 2 3 0 ~= [ [ 0, 0, 0 ], [ 0, 0, 0 ] ]

-}
repeat : Int -> Int -> a -> Matrix a
repeat nrows ncols value =
    Matrix
        { nrows = nrows
        , ncols = ncols
        , mvect = Array.repeat nrows <| Array.repeat ncols value
        }


{-| Creates a matrix with a given size, with the elements at index `(i, j)` initialized to the result of `f (i, j)`.

    initialize 3
        3
        (\( i, j ) ->
            if i == j then
                1

            else
                0
        )
        == identity 3

-}
initialize : Int -> Int -> (Int -> Int -> a) -> Matrix a
initialize nrows ncols f =
    let
        f_ i =
            Array.initialize ncols <| f i

        data =
            Array.initialize nrows f_
    in
    Matrix
        { nrows = nrows
        , ncols = ncols
        , mvect = data
        }


{-| Create the identity matrix of dimension `n`.
-}
identity : Int -> Matrix number
identity n =
    let
        f i j =
            if i == j then
                1

            else
                0
    in
    initialize n n f


{-| Return the number of rows in a given matrix.
-}
height : Matrix a -> Int
height (Matrix { nrows }) =
    nrows


{-| Return the number of columns in a given matrix.
-}
width : Matrix a -> Int
width (Matrix { ncols }) =
    ncols


{-| Return the dimensions of a given matrix in the form `(rows, columns)`.
-}
size : Matrix a -> ( Int, Int )
size m =
    ( height m, width m )


{-| Return `Just` the element at the index or `Nothing` if the index is out of bounds.
-}
get : Int -> Int -> Matrix a -> Maybe a
get i j (Matrix ({ mvect } as m)) =
    mvect |> Array.get i |> Maybe.andThen (Array.get j)


{-| Set the element at a particular index. Returns an updated Matrix.
If the index is out of bounds, then return Nothing

    let
        matrix1 =
            repeat 2 2 1

        matrix2 =
            Matrix.fromList [ 1, 1, 2, 1 ]
    in
    Maybe.andThen (set 1 0 2) matrix1 == matrix2

-}
set : Int -> Int -> a -> Matrix a -> Matrix a
set i j a (Matrix ({ mvect } as m)) =
    let
        mvect2 =
            mvect
                |> Array.get i
                |> Maybe.map (Array.set j a)
                |> Maybe.map (flip (Array.set i) mvect)
                |> Maybe.withDefault mvect
    in
    Matrix { m | mvect = mvect2 }


{-| Create a matrix from a list given the desired size.
If the list has a length inferior to `n * m`, returns `Nothing`.

    fromList 2 2 [ 1, 1, 1, 1, 1 ] == Just <| repeat 2 2 1

    fromList 3 3 [ 0, 1, 2 ] == Nothing

-}
fromList : Int -> Int -> List a -> Maybe (Matrix a)
fromList n m list =
    if List.length list < n * m then
        Nothing

    else
        Just <| initialize n m <| Array.get (n * m) <| Array.fromList <| list


{-| Create a matrix from a list of lists.
If any inner list is shorter than the first, returns `Nothing`.
Otherwise, the length of the first list determines the width of the matrix.

    fromLists [] == Just empty

    fromLists [ [] ] == Just empty

    fromLists [ [ 1, 2, 3 ], [ 1, 2 ] ] == Nothing

    fromLists [ [ 1, 0 ], [ 0, 1 ] ] == Just <| identity 2

-}
fromLists : List (List a) -> Maybe (Matrix a)
fromLists list =
    let
        sizes =
            List.map List.length list
    in
    if Maybe.map2 (==) (List.minimum sizes) (List.maximum sizes) |> Maybe.withDefault True then
        Just Array.fromList <| List.map <| Array.fromList <| list

    else
        Nothing


{-| Apply a function on every element of a matrix
-}
map : (a -> b) -> Matrix a -> Matrix b
map f (Matrix m) =
    Matrix
        { m | mvect = Array.map <| Array.map <| m.mvect }


{-| Applies a function on every element with its index as first and second arguments.

    indexedMap (\x y e -> 10 * x + y) (repeat 2 2 1)
        == [ [ ( 0, 0, 1 )
             , ( 1, 0, 1 )
             ]
           , [ ( 0, 1, 1 )
             , ( 1, 1, 1 )
             ]
           ]

-}
indexedMap : (Int -> Int -> a -> b) -> Matrix a -> Matrix b
indexedMap f (Matrix m) =
    Matrix
        { nrows = m.nrows
        , ncols = m.ncols
        , mvect = Array.indexedMap <| Array.indexedMap f <| m.mvect
        }


{-| Apply a function between pairwise elements of two matrices.
If the matrices are of differents sizes, returns `Nothing`.
-}
map2 : (a -> b -> c) -> Matrix a -> Matrix b -> Maybe (Matrix c)
map2 f m1 m2 =
    let
        f_ =
            Debug.todo ""
    in
    Just <| indexedMap f_ m1


{-| Return the transpose of a matrix.
-}
transpose : Matrix a -> Matrix a
transpose m =
    Debug.todo ""



-- initialize (width m) (height m) <| \( i, j ) -> unsafeGet j i m


{-| Perform the standard matrix multiplication.
If the dimensions of the matrices are incompatible, returns `Nothing`.
-}
dot : Matrix number -> Matrix number -> Maybe (Matrix number)
dot m1 m2 =
    Debug.todo "don't like the original"


{-| Convert the matrix to a flat list.

    toList (identity 3) == [ 1, 0, 0, 0, 1, 0, 0, 0, 1 ]

-}
toList : Matrix a -> List a
toList (Matrix { mvect }) =
    Array.toList mvect


{-| Convert the matrix to a list of lists.

    toLists (identity 3) = [ [1,0,0], [0,1,0], [0,0,1] ]

-}
toLists : Matrix a -> List (List a)
toLists m =
    Debug.todo ""



-- let
--     topLevelArray =
--         Array
-- in
-- List.range 1 (height m)
--     |> List.concatMap
--         (\i ->
--             [ List.range 1 (width m)
--                 |> List.concatMap (\j -> [ unsafeGet i j m ])
--             ]
--         )


{-| Convert a matrix to a formatted string.

    pretty (identity 3) = """
        [ [ 1, 0, 0 ]
        , [ 0, 1, 0 ]
        , [ 0, 0, 1 ] ]
    """

-}
pretty : (a -> String) -> Matrix a -> String
pretty toString m =
    let
        list =
            toLists m
    in
    "[ " ++ prettyPrint toString list ++ " ]"



{- Utilities -}


prettyPrint : (a -> String) -> List (List a) -> String
prettyPrint toString list =
    case list of
        [] ->
            ""

        x :: [] ->
            "[ " ++ prettyList toString x ++ " ]"

        x :: xs ->
            "[ " ++ prettyList toString x ++ " ]\n, " ++ prettyPrint toString xs


prettyList : (a -> String) -> List a -> String
prettyList toString list =
    case list of
        [] ->
            ""

        x :: [] ->
            toString x

        x :: xs ->
            toString x ++ ", " ++ prettyList toString xs


flip f b a =
    f a b

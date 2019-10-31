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
        , arrays : Array (Array a)
        }


{-| Create an empty matrix.

    size empty == ( 0, 0 )

-}
empty : Matrix a
empty =
    Matrix
        { nrows = 0
        , ncols = 0
        , arrays = Array.empty
        }


{-| Create a matrix with a given size, filled with a default value.

    repeat 2 3 0 ~= [ [ 0, 0, 0 ], [ 0, 0, 0 ] ]

-}
repeat : Int -> Int -> a -> Matrix a
repeat nrows ncols value =
    Matrix
        { nrows = nrows
        , ncols = ncols
        , arrays = Array.repeat nrows <| Array.repeat ncols value
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
    in
    Matrix
        { nrows = nrows
        , ncols = ncols
        , arrays = Array.initialize nrows f_
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
get i j (Matrix ({ arrays } as m)) =
    arrays |> Array.get i |> Maybe.andThen (Array.get j)


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
set i j a m =
    let
        set_ arrays =
            arrays
                |> Array.get i
                |> Maybe.map (Array.set j a)
                |> Maybe.map (flip (Array.set i) arrays)
                |> Maybe.withDefault arrays
    in
    mapArrays set_ m


{-| Create a matrix from a list given the desired size.
If the list has a length inferior to `n * m`, returns `Nothing`.

    fromList 2 2 [ 1, 1, 1, 1, 1 ] == Just <| repeat 2 2 1

    fromList 3 3 [ 0, 1, 2 ] == Nothing

-}
fromList : Int -> Int -> List a -> Maybe (Matrix a)
fromList n m list =
    if List.length list /= n * m then
        Nothing

    else
        let
            -- convert it to a list, slicing is a bit nicer than the equivalent List functionality.
            array =
                Array.fromList list

            getSlice i =
                Array.slice i (i + m) array
        in
        Just <| Matrix { nrows = n, ncols = m, arrays = Array.initialize n getSlice }


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
    if List.isEmpty list then
        Just <| Matrix { nrows = 0, ncols = 0, arrays = Array.empty }

    else
        let
            sizes =
                List.map List.length list

            min =
                List.minimum sizes

            max =
                List.maximum sizes

            sizesMatch =
                Maybe.map2 (==) min max

            notEmptyWidth =
                Maybe.map ((/=) 0) min

            valid =
                Maybe.map2 (&&) sizesMatch notEmptyWidth
        in
        if valid |> Maybe.withDefault True then
            let
                arrays =
                    Array.map Array.fromList <| Array.fromList list
            in
            Just <| Matrix { nrows = Array.length arrays, ncols = 0, arrays = arrays }

        else
            Nothing


{-| Apply a function on every element of a matrix
-}
map : (a -> b) -> Matrix a -> Matrix b
map f =
    mapArrays <| Array.map <| Array.map f


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
indexedMap f =
    mapArrays <| Array.indexedMap (Array.indexedMap << f)


{-| Apply a function between pairwise elements of two matrices.
If the matrices are of differents sizes, returns `Nothing`.
-}
map2 : (a -> b -> c) -> Matrix a -> Matrix b -> Maybe (Matrix c)
map2 f ((Matrix m1) as m0) (Matrix m2) =
    -- for the time being, cheat by going to List.map2
    let
        g =
            Debug.todo ""

        a3 =
            List.map2 g (Array.toList m1.arrays) (Array.toList m2.arrays)
    in
    Just <| mapArrays g m0


{-| Return the transpose of a matrix.
-}
transpose : Matrix a -> Matrix a
transpose m =
    -- initialize (width m) (height m) <| \( i, j ) -> unsafeGet j i m
    Debug.todo ""


{-| Perform the standard matrix multiplication.
If the dimensions of the matrices are incompatible, returns `Nothing`.
-}
dot : Matrix number -> Matrix number -> Maybe (Matrix number)
dot m1 m2 =
    Debug.todo "don't like the original"


{-| Convert the matrix to a list of lists.

    toLists (identity 3) = [ [1,0,0], [0,1,0], [0,0,1] ]

-}
toLists : Matrix a -> List (List a)
toLists (Matrix { arrays }) =
    arrays |> Array.map Array.toList |> Array.toList


{-| Convert the matrix to a flat list.

    toList (identity 3) == [ 1, 0, 0, 0, 1, 0, 0, 0, 1 ]

-}
toList : Matrix a -> List a
toList =
    toLists >> List.concat


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


putArrays : Array (Array a) -> Matrix a -> Matrix a
putArrays arrays (Matrix matrix) =
    Matrix { matrix | arrays = arrays }


type alias ArraysMapper a b =
    Array (Array a) -> Array (Array b)


mapArrays : ArraysMapper a b -> Matrix a -> Matrix b
mapArrays f (Matrix { nrows, ncols, arrays }) =
    Matrix { nrows = nrows, ncols = ncols, arrays = f arrays }

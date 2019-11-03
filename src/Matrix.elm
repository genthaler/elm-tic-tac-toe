module Matrix exposing
    ( Matrix
    , empty, repeat, initialize, identity, fromList, fromLists
    , height, width, size
    , get, set
    , map, map2, transpose, dot, indexedMap
    , toList, toLists, pretty
    )

{-| A simple linear algebra library using flat-array
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
import Array.Extra
import Basics.Extra


{-| Representation of a matrix. You can create matrices of any type
but arithmetic operations in Matrix.Operations requires the matrices
to have numeric types.
-}
type Matrix a
    = Matrix
        { nrows : Int
        , ncols : Int
        , array : Array a
        }


{-| Create an empty matrix.

    size empty == ( 0, 0 )

-}
empty : Matrix a
empty =
    makeMatrix 0 0 Array.empty


{-| Create a matrix with a given size, filled with a default value.

    repeat 2 3 0 ~= [ [ 0, 0, 0 ], [ 0, 0, 0 ] ]

-}
repeat : Int -> Int -> a -> Matrix a
repeat nrows ncols value =
    makeMatrix nrows ncols (Array.repeat (nrows * ncols) value)


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
    makeMatrix nrows ncols (Array.initialize (nrows * ncols) (from2d f ncols))


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
get i j (Matrix { nrows, ncols, array }) =
    if i < 0 || j < 0 || i >= nrows || j >= ncols then
        Nothing

    else
        Array.get ((ncols * i) + j) array


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
set i j a ((Matrix { nrows, ncols }) as m) =
    if i < 0 || j < 0 || i >= nrows || j >= ncols then
        m

    else
        mapArray (to2d Array.set ncols i j a) m


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
        Just <| Matrix { nrows = n, ncols = m, array = Array.fromList list }


{-| Create a matrix from a list of lists.
If the lengths of the inner lists is not consistent, returns `Nothing`.
A list of empty lists would be a matrix of height n and width 0,
which is unrepresentable in matrix math, so return `Nothing`.

    fromLists [] == Just empty

    fromLists [ [ 1, 2, 3 ], [ 1, 2 ] ] == Nothing

    fromLists [ [ 1, 0 ], [ 0, 1 ] ] == Just <| identity 2

    fromLists [ [] ] == Nothing

-}
fromLists : List (List a) -> Maybe (Matrix a)
fromLists lists =
    let
        rows =
            List.length lists
    in
    if rows == 0 then
        Just <| makeMatrix 0 0 Array.empty

    else
        let
            mincols =
                List.foldl (min << List.length) Basics.Extra.maxSafeInteger lists

            maxcols =
                List.foldl (max << List.length) 0 lists
        in
        if mincols /= maxcols || mincols == 0 then
            Nothing

        else
            Just <| makeMatrix rows mincols <| Array.fromList <| List.concat <| lists


{-| Apply a function on every element of a matrix
-}
map : (a -> b) -> Matrix a -> Matrix b
map =
    mapArray << Array.map


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
indexedMap f m =
    mapArray (Array.indexedMap (from2d f (width m))) m


{-| Apply a function between pairwise elements of two matrices.
If the matrices are of differents sizes, returns `Nothing`.
-}
map2 : (a -> b -> c) -> Matrix a -> Matrix b -> Maybe (Matrix c)
map2 f ((Matrix m1_) as m1) ((Matrix m2_) as m2) =
    if size m1 /= size m2 then
        Nothing

    else
        Just <| makeMatrix m1_.nrows m1_.ncols (Array.Extra.map2 f m1_.array m2_.array)


{-| Return the transpose of a matrix.
-}
transpose : Matrix a -> Matrix a
transpose m =
    initialize (width m) (height m) (\i j -> get j i m)
        |> mapArray (Array.Extra.filterMap Basics.identity)


{-| Perform the standard matrix multiplication.
If the dimensions of the matrices are incompatible, returns `Nothing`.
-}
dot : Matrix number -> Matrix number -> Maybe (Matrix number)
dot m1 m2 =
    let
        arrays1 =
            m1 |> toArrays

        arrays2 =
            m2 |> transpose |> toArrays

        element : Int -> Int -> Maybe number
        element row col =
            Maybe.map2 (Array.Extra.map2 (*)) (Array.get row arrays1) (Array.get col arrays2)
                |> Maybe.map (Array.toList >> List.sum)
    in
    if width m1 /= height m2 then
        Nothing

    else
        initialize (height m1) (width m2) element
            |> mapArray (Array.Extra.filterMap Basics.identity)
            |> Just


{-| Convert the matrix to a list of lists.

    toLists (identity 3) = [ [1,0,0], [0,1,0], [0,0,1] ]

-}
toArrays : Matrix a -> Array (Array a)
toArrays m =
    let
        slice i =
            Array.slice (i * width m) ((i + 1) * width m) (toArray m)
    in
    Array.initialize (height m) slice


{-| Convert the matrix to a flat list.

    toList (identity 3) == [ 1, 0, 0, 0, 1, 0, 0, 0, 1 ]

-}
toArray : Matrix a -> Array a
toArray (Matrix { array }) =
    array


{-| Convert the matrix to a list of lists.

    toLists (identity 3) = [ [1,0,0], [0,1,0], [0,0,1] ]

-}
toLists : Matrix a -> List (List a)
toLists =
    toArrays >> Array.toList >> List.map Array.toList


{-| Convert the matrix to a flat list.

    toList (identity 3) == [ 1, 0, 0, 0, 1, 0, 0, 0, 1 ]

-}
toList : Matrix a -> List a
toList =
    toArray >> Array.toList


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


mapArray : (Array a -> Array b) -> Matrix a -> Matrix b
mapArray f (Matrix { nrows, ncols, array }) =
    makeMatrix nrows ncols (f array)


from2d : (Int -> Int -> a) -> Int -> Int -> a
from2d f ncols i =
    f (i // ncols) (remainderBy ncols i)


to2d : (Int -> a) -> Int -> Int -> Int -> a
to2d f ncols i j =
    f ((i * ncols) + j)


makeMatrix : Int -> Int -> Array a -> Matrix a
makeMatrix nrows ncols array =
    Matrix { nrows = nrows, ncols = ncols, array = array }

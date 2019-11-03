module Minimax exposing (alphabeta)

{-| -}

import StateMachine exposing (Allowed, State(..), map, untag)


type alias CallFrame board ply value =
    { alpha : value
    , beta : value
    , minimax : Bool
    , board : board
    , plies :
        List
            { ply : ply
            , value : Maybe value
            }
    }


type alias AlphaBetaState board ply value =
    { depth : Int
    , positiveInfinity : value
    , zero : value
    , negativeInfinity : value
    , comparator : value -> value -> Order
    , heuristic : board -> ply -> value
    , generator : board -> List ply
    , doPly : ply -> board -> board
    , callStack : List (CallFrame board ply value)
    }


type AlphaBetaStateMachine board ply value
    = Generating (State { computing : Allowed } (AlphaBetaState board ply value))
    | Computing (State { sorting : Allowed } (AlphaBetaState board ply value))
    | Sorting (State { generating : Allowed, deciding : Allowed } (AlphaBetaState board ply value))
    | Deciding (State { ending : Allowed } (AlphaBetaState board ply value))
    | Ending (State { done : Allowed } (Result ( AlphaBetaState board ply value, String ) ply))


toGenerating : AlphaBetaState board ply value -> AlphaBetaStateMachine board ply value
toGenerating =
    Generating << State


toComputing : State { a | generating : Allowed } (AlphaBetaState board ply value) -> AlphaBetaStateMachine board ply value
toComputing =
    Computing << State << untag


toSorting : State { a | generating : Allowed } (AlphaBetaState board ply value) -> AlphaBetaStateMachine board ply value
toSorting =
    Sorting << State << untag


toDeciding : State { a | generating : Allowed } (AlphaBetaState board ply value) -> AlphaBetaStateMachine board ply value
toDeciding =
    Deciding << State << untag


toEnding : State a b -> Result ( AlphaBetaState board ply value, String ) ply -> AlphaBetaStateMachine board ply value
toEnding _ =
    Ending << State


{-| This function implements the [minimax algorithm with alpha-beta pruning](https://en.wikipedia.org/wiki/Alpha%E2%80%93beta_pruning).

    alphabeta depth positiveInfinity negativeInfinity maximizingPlayer heuristic getChildren node =

    ```
    function alphabeta(node, depth, α, β, maximizingPlayer) is
        if depth = 0 or node is a terminal node then
            return the heuristic value of node
        if maximizingPlayer then
            value := −∞
            for each child of node do
                value := max(value, alphabeta(child, depth − 1, α, β, FALSE))
                α := max(α, value)
                if α ≥ β then
                    break (* β cut-off *)
            return value
        else
            value := +∞
            for each child of node do
                value := min(value, alphabeta(child, depth − 1, α, β, TRUE))
                β := min(β, value)
                if α ≥ β then
                    break (* α cut-off *)
            return value
    ```
    `alphabeta(origin, depth, −∞, +∞)`

    Also want to implement
    > The optimization reduces the effective depth to slightly more than half that of simple minimax
    > if the nodes are evaluated in an optimal or near optimal order (best choice for side on move ordered first at each node).

    It might be cheaper to only store the initial map and apply moves.
    Applying the moves also gives a way to apply a delta to the score as moves are applied.
    Actually, should be able to store the current map, and be able to store the move that got me here in an undoable way,
    so I only have to undo the move before trying the next possible move.
    How to store this in an impossible states fashion...

    So I just need it to be a list, adding to the front as I descend, and popping off as I complete branches.
    So hopefully at any given point the head is the best known solution.

    States are:

    - I'm at the required depth
    - generating children (i.e. plies)
    - computing heuristics for each child
    - sorting children
    - Exploring children
        - update alpha/beta, cutoff
    - Done, here's the best ply. The best ply is the current one at the top/bottom level, the rest are speculative.

    Need an doPly and undoPly function, which means a Ply has to contain enough information to be able to be undone.
    Or maybe we delta the board, and apply the inverse of the delta to undo. e.g. Dict has some diffing functions.
    Could create 2 variants of the algorithm.
    Need an heuristicPly to calculate a delta on the heuristic score
    How do we deal with probabilistic moves?
    It might be a bit much to ask for both a doPly+undoPly as well as an evaluatePly?
    I have a space/time tradeoff to make - I want to be able to sort the list of moves before depth-first search,
    since this is an optimisation that can cut the time down to about half.
    But that means I either have to store all the boards or calculate the heuristic of a given board.
    Hang on, these are just heuristics! Just calculate the heuristic of the move. Sort those. Done!
        In fact, never need to calculate heuristic of board, just start from "zero".
        Only need the board in order to generate new moves.
        This only works if it makes sense to calculate heuristics based on the move without the context of the whole board
        Could maybe assign value to each piece that can be affected, so one can calculate the delta that way.
        It's all very game specific. So might still be better to calculate heuristic of the whole board

    The costly things to do are generating moves and calculating heuristics. Sorting and calculating cutoff shouldn't be too expensive.
    But sorting and calculating cutoff happen between the others, so maybe deserve their own states.

-}
alphabeta :
    Int
    -> value
    -> value
    -> value
    -> (value -> value -> Order)
    -> (board -> ply -> value)
    -> (board -> List ply)
    -> (ply -> board -> board)
    -> board
    -> AlphaBetaStateMachine board ply value
alphabeta depth positiveInfinity zero negativeInfinity comparator heuristic generator doPly board =
    toGenerating <|
        { depth = depth
        , positiveInfinity = positiveInfinity
        , zero = zero
        , negativeInfinity = negativeInfinity
        , comparator = comparator
        , heuristic = heuristic
        , generator = generator
        , doPly = doPly
        , callStack =
            [ { alpha = positiveInfinity
              , beta = negativeInfinity
              , minimax = True
              , board = board
              , plies = []
              }
            ]
        }


step : AlphaBetaStateMachine board ply value -> AlphaBetaStateMachine board ply value
step sm =
    case sm of
        Generating ((State alphaBetaState) as state) ->
            case alphaBetaState.callStack of
                [] ->
                    toEnding state (Err ( alphaBetaState, "Unexpectedly empty callstack" ))

                callFrame :: callStack ->
                    toComputing <|
                        State <|
                            { alphaBetaState
                                | callStack =
                                    { callFrame
                                        | plies = callFrame.board |> alphaBetaState.generator |> List.map (\ply -> { ply = ply, value = Nothing })
                                    }
                                        :: callStack
                            }

        Computing ((State alphaBetaState) as state) ->
            case alphaBetaState.callStack of
                [] ->
                    toEnding state (Err ( alphaBetaState, "Unexpectedly empty callstack" ))

                callFrame :: callStack ->
                    toSorting <| State <| { alphaBetaState | callStack = { callFrame | plies = List.map (\plyValue -> { plyValue | value = Just (alphaBetaState.heuristic callFrame.board plyValue.ply) }) callFrame.plies } :: callStack }

        Sorting ((State alphaBetaState) as state) ->
            case alphaBetaState.callStack of
                [] ->
                    toEnding state (Err ( alphaBetaState, "Unexpectedly empty callstack" ))

                callFrame :: callStack ->
                    toDeciding <|
                        State <|
                            { alphaBetaState
                                | callStack =
                                    { callFrame
                                        | plies =
                                            callFrame.plies
                                                |> List.sortWith
                                                    (\a b ->
                                                        alphaBetaState.comparator
                                                            (Maybe.withDefault alphaBetaState.zero a.value)
                                                            (Maybe.withDefault alphaBetaState.zero b.value)
                                                    )
                                    }
                                        :: callStack
                            }

        Deciding ((State alphaBetaState) as state) ->
            case alphaBetaState.callStack of
                [] ->
                    toEnding state (Err ( alphaBetaState, "Unexpectedly empty callstack" ))

                callFrame :: callStack ->
                    case callFrame.plies of
                        [] ->
                            toDeciding <|
                                State <|
                                    { alphaBetaState
                                        | depth = alphaBetaState.depth + 1
                                        , callStack =
                                            { callFrame
                                                | minimax = not callFrame.minimax
                                            }
                                                :: callStack
                                    }

                        plyValue :: [] ->
                            toEnding state (Ok plyValue.ply)

                        _ ->
                            toDeciding <|
                                State <|
                                    { alphaBetaState | callStack = callStack }

        --     toGenerating
        -- <|
        --     State <|
        --         { alphaBetaState | callStack = callStack, depth = alphaBetaState.depth - 1, minimax = not alphaBetaState.minimax }
        Ending _ ->
            sm



-- alphabeta0 : AlphaBetaState board ply value -> AlphaBetaState board ply value
-- alphabeta0 state =
--     if state.depth == 0 then
--         state.heuristic state.board
--     else
--         case state.generator state.board of
--             [] ->
--                 state.heuristic state.board
--             children0 ->
--                 case state.minimax of
--                     True ->
--                         let
--                             cutoff value alpha1 beta1 children1 =
--                                 case children1 of
--                                     [] ->
--                                         value
--                                     child :: children2 ->
--                                         let
--                                             value2 =
--                                                 Basics.max value (alphabeta0 (state.depth - 1) alpha1 beta1 (not state.minimax) child)
--                                             alpha2 =
--                                                 Basics.max value2 alpha1
--                                         in
--                                         if alpha2 >= beta1 then
--                                             value2
--                                         else
--                                             cutoff value2 alpha2 beta1 children2
--                         in
--                         cutoff state.negativeInfinity state.alpha state.beta children0
--                     False ->
--                         let
--                             cutoff value alpha1 beta1 children1 =
--                                 case children1 of
--                                     [] ->
--                                         value
--                                     child :: children2 ->
--                                         let
--                                             value2 =
--                                                 Basics.max value (alphabeta0 (state.depth - 1) alpha1 beta1 (not state.minimax) child)
--                                             beta2 =
--                                                 Basics.max value2 beta1
--                                         in
--                                         if alpha1 >= beta2 then
--                                             value2
--                                         else
--                                             cutoff value2 alpha1 beta2 children2
--                         in
--                         cutoff state.positiveInfinity state.alpha state.beta children0

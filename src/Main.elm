module Main exposing (main)

import Bool.Extra
import Browser
import Browser.Dom
import Browser.Events
import Debug
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Html exposing (Html)
import Matrix exposing (Matrix)
import Maybe exposing (Maybe)
import Task


type Player
    = O
    | X


type alias Model =
    { board : Matrix (Maybe ( Player, Bool ))
    , currentPlayer : Player
    , maybeWindow : Maybe ( Int, Int )
    }


type Msg
    = Click Int Int
    | GetViewPort Browser.Dom.Viewport
    | GetResize Int Int


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model (Matrix.repeat 3 3 Nothing) X Nothing
    , Task.perform GetViewPort Browser.Dom.getViewport
    )


viewPlayer : Player -> Element msg
viewPlayer player =
    case player of
        X ->
            Element.text "X"

        O ->
            Element.text "O"


viewCell : Bool -> Int -> Int -> Maybe ( Player, Bool ) -> Element Msg
viewCell gameOver x y cell =
    let
        handler =
            if gameOver then
                Nothing

            else
                case cell of
                    Nothing ->
                        Just <| Click x y

                    _ ->
                        Nothing

        fontColor =
            case cell of
                Just ( _, True ) ->
                    Element.rgb255 255 255 255

                _ ->
                    Element.rgb255 0 0 0

        cellContent =
            case cell of
                Just ( player, _ ) ->
                    viewPlayer player

                Nothing ->
                    Element.text " "
    in
    Input.button
        [ Element.width Element.fill
        , Element.height Element.fill
        , Background.color (Element.rgb255 100 100 100)
        , Border.color (Element.rgb 0 0.7 0)
        , Border.solid
        , Border.rounded 4
        , Border.shadow { offset = ( 4.0, 4.0 ), size = 3, blur = 1.0, color = Element.rgb255 150 150 150 }
        ]
        { onPress = handler
        , label = Element.el [ Element.centerX, Element.centerY, Font.size 128, Font.color fontColor ] <| cellContent
        }


isGameOver : Matrix (Maybe ( Player, Bool )) -> Bool
isGameOver =
    Debug.todo "isGameOver"


view : Model -> Html Msg
view { board, currentPlayer, maybeWindow } =
    let
        viewBoard =
            Element.column
                [ Region.mainContent
                , Element.width Element.fill
                , Element.height Element.fill
                ]
                << List.map
                    (Element.row
                        [ Element.width Element.fill
                        , Element.height Element.fill
                        , Element.padding 10
                        , Element.spacing 10
                        ]
                    )
                << Matrix.toLists
                << Matrix.indexedMap (viewCell (isGameOver board))

        viewHeader ( height, width ) player =
            Element.el
                [ Region.announce
                , Region.heading 1
                , Element.width Element.fill
                , Element.height <| Element.px 64
                ]
            <|
                Element.row
                    [ Element.centerX
                    , Element.width Element.shrink
                    , Font.size (Debug.log "font size" <| min height width * 64 // 1000)
                    ]
                    [ Element.text "Ready, Player ", viewPlayer <| player ]

        viewWindow window =
            Element.column
                [ Element.width Element.fill
                , Element.height Element.fill

                -- , Element.spacing 5
                ]
                [ viewHeader window currentPlayer, viewBoard board ]
    in
    maybeWindow
        |> Maybe.map viewWindow
        |> Maybe.withDefault Element.none
        |> Element.layout
            [ Background.color (Element.rgb255 200 200 200)
            , Element.width Element.fill
            , Element.height Element.fill
            , Element.padding 10
            , Element.spacing 10
            ]


checkHasWon : Model -> Model
checkHasWon m =
    -- player has won if it satisfies exists for p in Range 0 2 for all q in Range 0 2, one of the following formulae succeeds:
    -- \p q -> get p q m == player
    -- \p q-> get q p == player
    -- or one of these is satisfied:
    -- \q -> get q q ==  player
    -- \q -- get (2-q) q == player
    -- for first run through, returning boolean, it's any of p, but the second time through it's all of p, returning modified model
    let
        r =
            List.range 0 2

        gameover =
            List.any

        equalPlayer : Maybe ( Player, Bool ) -> Bool
        equalPlayer =
            Maybe.map (Tuple.first >> (==) m.currentPlayer)
                >> Maybe.withDefault False

        anyRow board =
            r |> Bool.Extra.anyPass [ List.map ] board

        -- topRow  =
        checkCell p q =
            Matrix.get p q m.board |> Maybe.map equalPlayer |> Maybe.withDefault False

        functions : List (Int -> Int -> Bool)
        functions =
            [ \p q -> Matrix.get p q m.board |> Maybe.map equalPlayer |> Maybe.withDefault False

            -- \p q-> get q p == player
            -- or one of these is satisfied:
            -- \q -> get q q ==  player
            -- \q -- get (2-q) q == player
            ]

        checkHasWon_ =
            Bool.Extra.any functions
    in
    m


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        otherPlayer =
            case model.currentPlayer of
                X ->
                    O

                O ->
                    X
    in
    case msg of
        Click x y ->
            let
                model1 =
                    { model | board = Matrix.set x y (Just ( model.currentPlayer, False )) model.board }

                model2 =
                    checkHasWon model1
            in
            ( model2, Cmd.none )

        GetViewPort viewport ->
            ( { model | maybeWindow = Just ( round viewport.scene.width, round viewport.scene.height ) }, Cmd.none )

        GetResize x y ->
            ( { model | maybeWindow = Just ( x, y ) }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Browser.Events.onResize GetResize


main : Program () Model Msg
main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }

module Main exposing (main)

import Browser
import Browser.Dom
import Browser.Events
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Game exposing (Game, Player(..), getWinningPositions, initGame, updateGame)
import Html exposing (Html)
import Matrix
import Maybe
import Task


type alias Model =
    { game : Game
    , maybeWindow : Maybe ( Int, Int )
    }


type Msg
    = Click Int Int
    | GetViewPort Browser.Dom.Viewport
    | GetResize Int Int


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model initGame Nothing
    , Task.perform GetViewPort Browser.Dom.getViewport
    )


viewPlayer : Player -> Element msg
viewPlayer player =
    case player of
        X ->
            Element.text "X"

        O ->
            Element.text "O"


viewCell : List ( Int, Int ) -> Int -> Int -> Maybe Player -> Element Msg
viewCell winningPositions x y cell =
    let
        handler =
            if List.isEmpty winningPositions then
                case cell of
                    Nothing ->
                        Just <| Click x y

                    _ ->
                        Nothing

            else
                Nothing

        fontColor =
            if List.member ( x, y ) winningPositions then
                Element.rgb255 255 255 255

            else
                Element.rgb255 0 0 0

        cellContent =
            case cell of
                Just player ->
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


view : Model -> Html Msg
view { game, maybeWindow } =
    let
        winningPositions =
            getWinningPositions game

        gameOver =
            winningPositions |> List.isEmpty |> not

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
                << Matrix.indexedMap (viewCell winningPositions)

        headline =
            if gameOver then
                "Winner, Player "

            else
                "Ready, Player "

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
                    , Font.size (min height width * 64 // 1000)
                    ]
                    [ Element.text headline, viewPlayer <| player ]

        viewWindow window =
            Element.column
                [ Element.width Element.fill
                , Element.height Element.fill

                -- , Element.spacing 5
                ]
                [ viewHeader window game.player, viewBoard game.board ]
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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Click x y ->
            ( { model | game = updateGame x y model.game }
            , Cmd.none
            )

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

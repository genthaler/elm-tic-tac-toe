module Main exposing (main)

import Array
import Browser
import Browser.Dom
import Browser.Events
import Dict exposing (Dict)
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Html exposing (Html)
import List.Extra
import Maybe
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Task
import TicTacToe exposing (Game, GameState(..), Player(..), alphabetaGame, gameStateToString, getWinningPositions, heuristic, initGame, moves, play, playerToString)
import Time



-- Model


type alias Model =
    { game : Game
    , scores : Dict Int Int
    , lastMove : Maybe Time.Posix
    , now : Maybe Time.Posix
    , maybeWindow : Maybe ( Int, Int )
    }



-- Msg


type Msg
    = GetViewPort Browser.Dom.Viewport
    | GetResize Int Int
    | NewGame
    | Click Int
    | Tick Time.Posix
    | LastMove Time.Posix


idleTimeout : Int
idleTimeout =
    12000


millisSinceLastMove : Maybe Time.Posix -> Maybe Time.Posix -> Int
millisSinceLastMove now lastMove =
    Maybe.map2 (\a b -> Time.posixToMillis a - Time.posixToMillis b) now lastMove
        |> Maybe.withDefault 0
        |> Basics.max 0



-- Init


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model initGame Dict.empty Nothing Nothing Nothing
    , Task.perform GetViewPort Browser.Dom.getViewport
    )



-- View


viewPlayer : Maybe Player -> Maybe Int -> Element msg
viewPlayer mp ms =
    [ playerToString mp |> Just
    , Maybe.map (\s -> "(" ++ String.fromInt s ++ ")") ms
    ]
        |> List.filterMap identity
        |> String.join " "
        |> Element.text


viewStatus : ( Int, Int ) -> Game -> Element msg
viewStatus ( height, width ) game =
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
            , Font.size (Basics.min height width * 64 // 1000)
            ]
            [ Element.text (gameStateToString game.gameState) ]


viewCell : GameState -> List Int -> Dict Int Int -> Int -> List ( Int, Maybe Player ) -> Element Msg
viewCell gameState winningPositions scores i list =
    let
        maybeCell : Maybe ( Int, Maybe Player )
        maybeCell =
            List.Extra.getAt i list

        maybePlayer : Maybe Player
        maybePlayer =
            maybeCell |> Maybe.map Tuple.second |> Maybe.andThen identity

        maybePosition : Maybe Int
        maybePosition =
            maybeCell |> Maybe.map Tuple.first

        handler =
            case gameState of
                InProgress _ ->
                    if maybePlayer == Nothing then
                        maybePosition |> Maybe.map Click

                    else
                        Nothing

                _ ->
                    Nothing

        fontColor =
            maybePosition
                |> Maybe.map
                    (\position ->
                        if List.member position winningPositions then
                            Element.rgb255 255 255 255

                        else
                            Element.rgb255 0 0 0
                    )
                |> Maybe.withDefault (Element.rgb255 0 0 0)

        cellContent =
            viewPlayer maybePlayer
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
        , label = Element.el [ Element.centerX, Element.centerY, Font.size 128, Font.color fontColor ] <| cellContent (Dict.get i scores)
        }


viewBoard : Game -> Dict Int Int -> Element Msg
viewBoard game scores =
    let
        winningPositions =
            case game.gameState of
                GameWon _ ->
                    getWinningPositions game

                _ ->
                    []
    in
    case Array.toIndexedList game.board of
        [ p0, p1, p2, p3, p4, p5, p6, p7, p8 ] ->
            { data =
                [ [ p0, p1, p2 ]
                , [ p3, p4, p5 ]
                , [ p6, p7, p8 ]
                ]
            , columns =
                List.range 0 2
                    |> List.map
                        (\i ->
                            { header = Element.none
                            , width = Element.fill
                            , view = viewCell game.gameState winningPositions scores i
                            }
                        )
            }
                |> Element.table []

        _ ->
            Element.none


viewHand : Int -> Float -> Float -> Svg msg
viewHand width length turns =
    let
        t =
            2 * pi * (turns - 0.25)

        x =
            200 + length * cos t

        y =
            200 + length * sin t
    in
    line
        [ x1 "200"
        , y1 "200"
        , x2 (String.fromFloat x)
        , y2 (String.fromFloat y)
        , stroke "black"
        , strokeWidth (String.fromInt width)
        , strokeLinecap "round"
        ]
        []


viewClock : Int -> Element Msg
viewClock milliseconds =
    Element.html <|
        svg
            [ viewBox "0 0 400 400"
            , width "400"
            , height "400"
            ]
            [ circle [ cx "200", cy "200", r "120", fill "gray" ] []
            , viewHand 3 90 (toFloat milliseconds / toFloat idleTimeout)
            ]



-- Element.column []
--     [ Element.text (String.fromInt milliseconds)
--     , Element.text (String.fromInt idleTimeout)
--     , Element.text (String.fromFloat (toFloat milliseconds / toFloat idleTimeout))
--     ]


viewNewGame : Element Msg
viewNewGame =
    Input.button
        [ Element.width Element.fill
        , Element.height Element.fill
        , Background.color (Element.rgb255 100 100 100)
        , Border.color (Element.rgb 0 0.7 0)
        , Border.solid
        , Border.rounded 4
        , Border.shadow { offset = ( 4.0, 4.0 ), size = 3, blur = 1.0, color = Element.rgb255 150 150 150 }
        ]
        { onPress = Just NewGame
        , label = Element.el [ Element.centerX, Element.centerY, Font.size 128, Font.color (Element.rgb255 0 0 0) ] <| Element.text "New Game"
        }


view : Model -> Html Msg
view { game, scores, lastMove, now, maybeWindow } =
    let
        viewWindow : ( Int, Int ) -> Element Msg
        viewWindow window =
            Element.column
                [ Element.width Element.fill
                , Element.height Element.fill
                , Element.spacing 5
                ]
                [ viewStatus window game
                , viewBoard game scores
                , Element.row
                    []
                    [ viewClock (millisSinceLastMove now lastMove)
                    , viewNewGame
                    ]
                ]
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



-- Update


resetTimer : Model -> Model
resetTimer model =
    case model.game.gameState of
        InProgress _ ->
            model

        _ ->
            { model | lastMove = Nothing, now = Nothing }


getScores : Game -> Dict Int Int
getScores game =
    game
        |> moves
        |> List.map (\position -> ( position, heuristic game position ))
        |> Dict.fromList


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetViewPort viewport ->
            ( { model | maybeWindow = Just ( round viewport.scene.width, round viewport.scene.height ) }, Cmd.none )

        GetResize x y ->
            ( { model | maybeWindow = Just ( x, y ) }, Cmd.none )

        NewGame ->
            ( { model | game = initGame } |> resetTimer, Cmd.none )

        Click position ->
            ( { model | game = play model.game position, scores = getScores model.game } |> resetTimer
            , Task.perform LastMove Time.now
            )

        Tick now ->
            case ( model.lastMove, model.game.gameState ) of
                ( Just lastMove, InProgress _ ) ->
                    -- if it's been idle long enough, do it for them
                    if Time.posixToMillis lastMove + idleTimeout < Time.posixToMillis now then
                        case alphabetaGame model.game of
                            Just position ->
                                ( { model | game = play model.game position, scores = getScores model.game, now = Just now } |> resetTimer
                                , Task.perform LastMove Time.now
                                )

                            Nothing ->
                                ( { model | now = Just now }, Cmd.none )

                    else
                        ( { model | now = Just now }, Cmd.none )

                _ ->
                    ( { model | now = Just now }, Cmd.none )

        LastMove lastMove ->
            ( { model | lastMove = Just lastMove }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions { game } =
    Sub.batch
        [ Browser.Events.onResize GetResize
        , case game.gameState of
            InProgress _ ->
                Time.every 1000 Tick

            _ ->
                Sub.none
        ]


main : Program () Model Msg
main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }

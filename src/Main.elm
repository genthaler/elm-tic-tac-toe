port module Main exposing (Flags, main)

{-| -}

import Browser
import Browser.Dom
import Browser.Events
import Json.Decode as Decode
import Json.Encode as Encode
import Model exposing (ColorScheme(..), Flags, GameState(..), Model, Msg(..), Player(..), decodeColorScheme, decodeMsg, encodeModel, initialModel)
import Result.Extra
import Task
import TicTacToe.TicTacToe exposing (moveMade)
import Time
import View exposing (view)



-- Init


type alias Flags =
    { colorScheme : String }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        colorScheme : ColorScheme
        colorScheme =
            case Decode.decodeString decodeColorScheme flags.colorScheme of
                Ok decodedColorScheme ->
                    decodedColorScheme

                Err _ ->
                    Light
    in
    ( { initialModel | colorScheme = colorScheme }, Task.perform GetViewPort Browser.Dom.getViewport )



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveMade position ->
            ( moveMade model position, Cmd.none )

        ResetGame ->
            ( { initialModel | colorScheme = model.colorScheme, lastMove = Nothing }
            , Cmd.none
            )

        GameError errorMessage ->
            ( { model | gameState = Error errorMessage }, Cmd.none )

        ColorScheme colorScheme ->
            ( { model | colorScheme = colorScheme }, Cmd.none )

        GetViewPort viewport ->
            ( { model | maybeWindow = Just ( round viewport.scene.width, round viewport.scene.height ) }, Cmd.none )

        GetResize x y ->
            ( { model | maybeWindow = Just ( x, y ) }, Cmd.none )

        Tick now ->
            case ( model.gameState, model.lastMove ) of
                ( Waiting player, Just lastMove ) ->
                    -- if it's been idle long enough, do it for them
                    if Time.posixToMillis now - Time.posixToMillis lastMove > Model.idleTimeoutMillis then
                        ( { model | gameState = Thinking player, now = Just now }
                        , sendToWorker (encodeModel model)
                        )

                    else
                        ( { model | now = Just now }, Cmd.none )

                _ ->
                    ( { model | now = Just now }, Cmd.none )



-- Main


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- Ports


port sendToWorker : Encode.Value -> Cmd msg


port receiveFromWorker : (Decode.Value -> msg) -> Sub msg


port modeChanged : (Decode.Value -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Browser.Events.onResize GetResize
        , Decode.decodeValue decodeColorScheme
            >> Result.map ColorScheme
            >> Result.mapError (Decode.errorToString >> GameError)
            >> Result.Extra.merge
            |> modeChanged
        , case model.gameState of
            Waiting _ ->
                Time.every 1000 Tick

            Thinking _ ->
                Decode.decodeValue decodeMsg
                    >> Result.mapError (Decode.errorToString >> GameError)
                    >> Result.Extra.merge
                    |> receiveFromWorker

            _ ->
                Sub.none
        ]

port module Main2 exposing (Flags, main)

{-| -}

import Browser
import Game
import Json.Decode as Decode
import Json.Encode as Encode
import Model exposing (Flags, Mode(..), Model, Msg(..), Player(..), decodeMode, decodeMsg, encodeModel, initialModel)
import Result.Extra
import View exposing (view)



-- Init


type alias Flags =
    { mode : String }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        mode : Mode
        mode =
            case Decode.decodeString decodeMode flags.mode of
                Ok decodedMode ->
                    decodedMode

                Err _ ->
                    Light
    in
    ( { initialModel | mode = mode }, Cmd.none )



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveMade position ->
            let
                newModel : Model
                newModel =
                    Game.moveMade model position
            in
            if newModel.winner == Nothing && newModel.currentPlayer == O then
                ( { newModel | isThinking = True }
                , sendToWorker (encodeModel newModel)
                )

            else
                ( newModel, Cmd.none )

        ResetGame ->
            ( { initialModel | mode = model.mode }
            , Cmd.none
            )

        GameError errorMessage ->
            ( { model | errorMessage = Just errorMessage }, Cmd.none )

        Mode mode ->
            ( { model | mode = mode }, Cmd.none )



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
        [ if model.isThinking then
            Decode.decodeValue decodeMsg
                >> Result.mapError (Decode.errorToString >> GameError)
                >> Result.Extra.merge
                |> receiveFromWorker

          else
            Sub.none
        , Decode.decodeValue decodeMode
            >> Result.map Mode
            >> Result.mapError (Decode.errorToString >> GameError)
            >> Result.Extra.merge
            |> modeChanged
        ]

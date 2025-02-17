port module GameWorker exposing (main)

import Game
import Json.Decode as Decode
import Json.Encode as Encode
import Model exposing (Msg(..), decodeModel)
import Result.Extra


init : () -> ( (), Cmd Msg )
init _ =
    ( (), Cmd.none )


update : Msg -> () -> ( (), Cmd Msg )
update msg _ =
    ( (), sendMove (Model.encodeMsg msg) )


subscriptions : () -> Sub Msg
subscriptions _ =
    Decode.decodeValue decodeModel
        >> Result.mapError (Decode.errorToString >> GameError)
        >> Result.map (Game.findBestMove >> Maybe.map MoveMade >> Maybe.withDefault (GameError "No move found"))
        >> Result.Extra.merge
        |> getModel


main : Program () () Msg
main =
    Platform.worker { init = init, update = update, subscriptions = subscriptions }


port getModel : (Decode.Value -> msg) -> Sub msg


port sendMove : Encode.Value -> Cmd msg

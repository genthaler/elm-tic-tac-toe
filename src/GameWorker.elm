port module GameWorker exposing (main)

import Json.Decode as Decode
import Json.Encode as Encode
import Model exposing (GameState(..), Msg(..), decodeModel)
import Result.Extra
import TicTacToe.TicTacToe exposing (findBestMove)


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
        >> Result.map
            (\model ->
                case model.gameState of
                    Thinking player ->
                        findBestMove player model.board
                            |> Maybe.map MoveMade
                            |> Maybe.withDefault (GameError "No move found")

                    Waiting player ->
                        findBestMove player model.board
                            |> Maybe.map MoveMade
                            |> Maybe.withDefault (GameError "No move found")

                    _ ->
                        GameError "Unexpected game state in worker"
            )
        >> Result.Extra.merge
        |> getModel


main : Program () () Msg
main =
    Platform.worker { init = init, update = update, subscriptions = subscriptions }


port getModel : (Decode.Value -> msg) -> Sub msg


port sendMove : Encode.Value -> Cmd msg

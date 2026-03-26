module RobotGame.TestUtils.DeterministicAnimator exposing
    ( finish
    , frame
    , frames
    , time
    )

import RobotGame.Animation as Animation
import RobotGame.Model exposing (Model)
import Time


time : Int -> Time.Posix
time =
    Time.millisToPosix


frame : Int -> Model -> Model
frame millis model =
    Animation.updateAnimationFrame (time millis) model


frames : List Int -> Model -> Model
frames millisValues model =
    List.foldl (\millis current -> frame millis current) model millisValues


finish : Model -> Model
finish model =
    model
        |> Animation.completeAnimation
        |> Animation.cleanupCompletedTimelines

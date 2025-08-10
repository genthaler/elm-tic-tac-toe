module Integration.ProgramTestSmokeTest exposing (..)

import Expect
import Html exposing (Html, div, text)
import Html.Attributes exposing (id)
import ProgramTest
import Test exposing (..)
import Test.Html.Query
import Test.Html.Selector



-- Simple test application for smoke testing


type alias Model =
    { message : String }


type Msg
    = UpdateMessage String


init : () -> ( Model, Cmd Msg )
init _ =
    ( { message = "Hello, elm-program-test!" }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateMessage newMessage ->
            ( { model | message = newMessage }, Cmd.none )


view : Model -> Html Msg
view model =
    div [ id "test-app" ]
        [ text model.message ]



-- Smoke test to verify elm-program-test integration


suite : Test
suite =
    describe "elm-program-test integration smoke test"
        [ test "can create and start a ProgramTest" <|
            \() ->
                ProgramTest.createElement
                    { init = init
                    , update = update
                    , view = view
                    }
                    |> ProgramTest.start ()
                    |> ProgramTest.expectViewHas [ Test.Html.Selector.text "Hello, elm-program-test!" ]
        , test "can verify element presence by id" <|
            \() ->
                ProgramTest.createElement
                    { init = init
                    , update = update
                    , view = view
                    }
                    |> ProgramTest.start ()
                    |> ProgramTest.expectView
                        (Test.Html.Query.has [ Test.Html.Selector.id "test-app" ])
        , test "can access model state" <|
            \() ->
                ProgramTest.createElement
                    { init = init
                    , update = update
                    , view = view
                    }
                    |> ProgramTest.start ()
                    |> ProgramTest.expectModel (\model -> Expect.equal "Hello, elm-program-test!" model.message)
        , test "can simulate message updates" <|
            \() ->
                ProgramTest.createElement
                    { init = init
                    , update = update
                    , view = view
                    }
                    |> ProgramTest.start ()
                    |> ProgramTest.update (UpdateMessage "Updated message!")
                    |> ProgramTest.expectModel (\model -> Expect.equal "Updated message!" model.message)
        ]

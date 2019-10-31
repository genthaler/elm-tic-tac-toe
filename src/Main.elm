module Main exposing (main)

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
    { board : Matrix ( Maybe Player, Bool )
    , currentPlayer : Player
    , gameOver : Bool
    , window : Maybe ( Int, Int )
    }


type Msg
    = Click Int Int



-- | GetViewPort Browser.Dom.Viewport
-- | GetResize Int Int


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model (Matrix.repeat 3 3 ( Nothing, False )) X False Nothing
      -- , Task.perform GetViewPort Browser.Dom.getViewport
    , Cmd.none
    )


viewPlayer : Maybe Player -> Element msg
viewPlayer player =
    case player of
        Just X ->
            Element.text "X"

        Just O ->
            Element.text "O"

        Nothing ->
            Element.none


viewCell : Bool -> Int -> Int -> ( Maybe Player, Bool ) -> Element Msg
viewCell gameOver x y ( maybePlayer, winningPosition ) =
    let
        handler =
            if gameOver then
                Nothing

            else
                case maybePlayer of
                    Nothing ->
                        Just <| Click x y

                    _ ->
                        Nothing

        fontColor =
            if winningPosition then
                Element.rgb255 255 255 255

            else
                Element.rgb255 0 0 0
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
        , label = Element.el [ Element.centerX, Element.centerY, Font.size 128, Font.color fontColor ] <| viewPlayer maybePlayer
        }


view : Model -> Html Msg
view { board, currentPlayer, gameOver } =
    let
        viewBoard =
            let
                zzz =
                    Debug.log "viewBoard" <| board
            in
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
                << Matrix.indexedMap (viewCell gameOver)

        viewHeader player =
            let
                zzz =
                    Debug.log "viewHeader" <| player
            in
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
                    , Font.size 64
                    ]
                    [ Element.text "Ready, Player ", viewPlayer <| Just player ]
    in
    Element.layout
        [ Background.color (Element.rgb255 200 200 200)
        , Element.width Element.fill
        , Element.height Element.fill
        , Element.padding 10
        , Element.spacing 10
        ]
    <|
        Element.column
            [ Element.width Element.fill
            , Element.height Element.fill

            -- , Element.spacing 5
            ]
            [ viewHeader currentPlayer, viewBoard board ]


checkHasWon : Player -> Matrix ( Maybe Player, Bool ) -> ( Matrix ( Maybe Player, Bool ), Bool )
checkHasWon player board =
    ( board, False )


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
                ( board1, gameOver_ ) =
                    checkHasWon model.currentPlayer model.board

                board2 =
                    Matrix.set x y ( Just model.currentPlayer, False ) board1
            in
            ( { model | board = board2, gameOver = gameOver_, currentPlayer = otherPlayer }, Cmd.none )



-- GetViewPort viewport ->
--     -- ( { model | window = Just ( round viewport.viewport.x, round viewport.viewport.y ) }, Cmd.none )
--     ( model, Cmd.none )
-- GetResize x y ->
--     -- ( { model | window = Just ( x, y ) }, Cmd.none )
--     ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- Browser.Events.onResize GetResize


main : Program () Model Msg
main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }

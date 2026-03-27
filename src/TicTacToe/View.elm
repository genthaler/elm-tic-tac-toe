module TicTacToe.View exposing (view)

{-| This module handles the UI rendering for the Tic-tac-toe game.
It renders the board, theme controls, and the AI search inspection surface.
-}

import Dict
import Element exposing (Color)
import Element.Background as Background
import Element.Border
import Element.Events
import Element.Font as Font
import Element.HexColor
import Element.Input as Input
import Html exposing (Html)
import Html.Attributes
import Set
import Svg
import Svg.Attributes as SvgAttr
import Theme.Responsive exposing (ScreenSize(..), calculateResponsiveCellSize, getResponsiveFontSize, getResponsivePadding, getResponsiveSpacing, getScreenSize)
import Theme.Theme exposing (BaseTheme, ColorScheme(..), getBaseTheme)
import TicTacToe.Model exposing (AITurnState(..), Board, ErrorInfo, ErrorType(..), GameState(..), Line, Model, Msg(..), Player(..), Position, SearchAlgorithm(..), SearchEvent(..), SearchInspection, SearchNode, SearchNodeId, SearchNodeStatus(..), SearchTrace)


view : Model -> Html Msg
view model =
    let
        theme : BaseTheme
        theme =
            getBaseTheme model.colorScheme
    in
    Element.layout
        [ Background.color (Element.HexColor.rgbCSSHex theme.backgroundColorHex)
        , Font.color (Element.HexColor.rgbCSSHex theme.fontColorHex)
        ]
    <|
        viewModel model


viewModel : Model -> Element.Element Msg
viewModel model =
    let
        theme : BaseTheme
        theme =
            getBaseTheme model.colorScheme
    in
    Element.el
        [ Element.centerX
        , Element.centerY
        , Background.color (Element.HexColor.rgbCSSHex theme.backgroundColorHex)
        , Font.color (Element.HexColor.rgbCSSHex theme.fontColorHex)
        , Font.bold
        , Font.size (getResponsiveFontSize model.maybeWindow 32)
        , Element.padding (getResponsivePadding model.maybeWindow 20)
        , Element.spacing (getResponsiveSpacing model.maybeWindow 15)
        ]
        (Element.column [ Element.spacing (getResponsiveSpacing model.maybeWindow 15), Element.width Element.fill ]
            [ viewHeader model theme
            , viewWorkspace model theme
            , viewStatusBar model theme
            ]
        )


viewHeader : Model -> BaseTheme -> Element.Element Msg
viewHeader model theme =
    Element.row
        [ Element.width Element.fill
        , Element.height (Element.px (getResponsiveFontSize model.maybeWindow 70))
        , Element.spacing (getResponsiveSpacing model.maybeWindow 15)
        , Element.padding (getResponsivePadding model.maybeWindow 15)
        , Background.color (Element.HexColor.rgbCSSHex theme.headerBackgroundColorHex)
        , Element.centerX
        ]
        [ Element.el [ Element.width Element.fill ] Element.none
        , Element.el
            [ Element.centerX
            , Font.color (Element.HexColor.rgbCSSHex theme.fontColorHex)
            , Font.size (getResponsiveFontSize model.maybeWindow 28)
            ]
            (Element.text "Tic-Tac-Toe")
        , Element.el [ Element.alignRight ] <|
            Element.row
                [ Element.spacing (getResponsiveSpacing model.maybeWindow 15)
                , Element.padding (getResponsivePadding model.maybeWindow 5)
                ]
                [ case ( model.gameState, model.lastMove ) of
                    ( Waiting X, Just _ ) ->
                        viewTimer model

                    _ ->
                        Element.none
                , resetIcon model
                , colorSchemeToggleIcon model
                ]
        ]


viewWorkspace : Model -> BaseTheme -> Element.Element Msg
viewWorkspace model theme =
    let
        maybeSearchPanel =
            viewSearchPanel model theme

        boardPanel =
            viewBoardPanel model theme
    in
    case maybeSearchPanel of
        Nothing ->
            boardPanel

        Just searchPanel ->
            case getScreenSize model.maybeWindow of
                Mobile ->
                    Element.column
                        [ Element.width Element.fill
                        , Element.spacing (getResponsiveSpacing model.maybeWindow 15)
                        ]
                        [ boardPanel
                        , searchPanel
                        ]

                _ ->
                    Element.row
                        [ Element.width Element.fill
                        , Element.spacing (getResponsiveSpacing model.maybeWindow 15)
                        , Element.alignTop
                        ]
                        [ Element.el [ Element.width (Element.fillPortion 2) ] boardPanel
                        , Element.el [ Element.width (Element.fillPortion 1) ] searchPanel
                        ]


viewBoardPanel : Model -> BaseTheme -> Element.Element Msg
viewBoardPanel model theme =
    Element.el
        [ Element.centerX
        , Background.color (Element.HexColor.rgbCSSHex theme.borderColorHex)
        , Element.padding (getResponsivePadding model.maybeWindow 10)
        , Element.Border.rounded 14
        , Element.Border.width 1
        , Element.Border.color (Element.HexColor.rgbCSSHex theme.borderColorHex)
        , Element.htmlAttribute (Html.Attributes.class "game-board")
        ]
        (Element.column [ Element.spacing (getResponsiveSpacing model.maybeWindow 10) ]
            (List.indexedMap (viewRow model True 5) model.board)
        )


viewSearchPanel : Model -> BaseTheme -> Maybe (Element.Element Msg)
viewSearchPanel model theme =
    case model.aiTurnState of
        Just AwaitingChoice ->
            Just (viewSearchLauncher model theme)

        Just FastThinking ->
            Just (viewFastThinkingPanel model theme)

        Just (Inspecting inspection) ->
            Just (viewSearchInspector model theme inspection)

        Nothing ->
            case model.gameState of
                Thinking _ ->
                    Just (viewSearchLauncher model theme)

                _ ->
                    Nothing


viewSearchLauncher : Model -> BaseTheme -> Element.Element Msg
viewSearchLauncher model theme =
    let
        sectionSpacing =
            getResponsiveSpacing model.maybeWindow 12
    in
    Element.column
        [ Element.width Element.fill
        , Element.spacing sectionSpacing
        , Element.padding (getResponsivePadding model.maybeWindow 15)
        , Background.color (Element.HexColor.rgbCSSHex theme.panelBackgroundColorHex)
        , Element.Border.rounded 14
        , Element.Border.width 1
        , Element.Border.color (Element.HexColor.rgbCSSHex theme.borderColorHex)
        , Element.htmlAttribute (Html.Attributes.class "ai-inspector")
        ]
        [ Element.el
            [ Font.size (getResponsiveFontSize model.maybeWindow 24)
            , Font.color (Element.HexColor.rgbCSSHex theme.fontColorHex)
            ]
            (Element.text "AI search")
        , Element.el
            [ Font.size (getResponsiveFontSize model.maybeWindow 16)
            , Font.color (Element.HexColor.rgbCSSHex theme.secondaryFontColorHex)
            ]
            (Element.text "Pick a search trace to inspect before applying the computer move.")
        , viewLauncherButtons model theme
        ]


viewLauncherButtons : Model -> BaseTheme -> Element.Element Msg
viewLauncherButtons model theme =
    case getScreenSize model.maybeWindow of
        Mobile ->
            Element.column
                [ Element.spacing (getResponsiveSpacing model.maybeWindow 10)
                , Element.width Element.fill
                ]
                [ actionButton model theme "auto-move" "Auto move" (Just RequestFastAIMove) True
                , actionButton model theme "inspect-negamax" "Inspect Negamax" (Just (StartInspection Negamax)) False
                , actionButton model theme "inspect-alpha-beta" "Inspect Alpha-Beta" (Just (StartInspection AlphaBeta)) False
                ]

        _ ->
            Element.column
                [ Element.spacing (getResponsiveSpacing model.maybeWindow 10)
                , Element.width Element.fill
                ]
                [ Element.row
                    [ Element.spacing (getResponsiveSpacing model.maybeWindow 10)
                    , Element.width Element.fill
                    ]
                    [ actionButton model theme "auto-move" "Auto move" (Just RequestFastAIMove) True
                    , actionButton model theme "inspect-negamax" "Inspect Negamax" (Just (StartInspection Negamax)) False
                    ]
                , actionButton model theme "inspect-alpha-beta" "Inspect Alpha-Beta" (Just (StartInspection AlphaBeta)) False
                ]


viewSearchInspector : Model -> BaseTheme -> SearchInspection -> Element.Element Msg
viewSearchInspector model theme inspection =
    let
        trace =
            inspection.trace

        currentIndex =
            clampEventIndex trace inspection.currentEventIndex

        maybeCurrentEvent =
            currentEvent trace currentIndex

        maybeActiveNode =
            case currentTraceNode trace currentIndex of
                Just node ->
                    Just node

                Nothing ->
                    Dict.get inspection.selectedNodeId trace.nodes

        traceFinished =
            isTraceFinished trace currentIndex

        focusedNode =
            case maybeActiveNode of
                Just node ->
                    node

                Nothing ->
                    traceToRootNode trace
    in
    Element.column
        [ Element.width Element.fill
        , Element.spacing (getResponsiveSpacing model.maybeWindow 12)
        , Element.padding (getResponsivePadding model.maybeWindow 15)
        , Background.color (Element.HexColor.rgbCSSHex theme.panelBackgroundColorHex)
        , Element.Border.rounded 14
        , Element.Border.width 1
        , Element.Border.color (Element.HexColor.rgbCSSHex theme.borderColorHex)
        , Element.htmlAttribute (Html.Attributes.class "ai-inspector")
        ]
        [ viewMetricGroup model
            [ searchModeChip model theme trace.algorithm
            , valueChip model theme "active event" (traceProgressLabel currentIndex (List.length trace.events))
            , valueChip model theme "best move" (Maybe.withDefault "pending" (Maybe.map viewPosition trace.bestMove))
            , valueChip model
                theme
                "committed"
                (if inspection.committed then
                    "yes"

                 else
                    "no"
                )
            ]
        , Element.el
            [ Font.size (getResponsiveFontSize model.maybeWindow 24)
            , Font.color (Element.HexColor.rgbCSSHex theme.fontColorHex)
            ]
            (Element.text "Search trace")
        , Element.el
            [ Font.size (getResponsiveFontSize model.maybeWindow 16)
            , Font.color (Element.HexColor.rgbCSSHex theme.secondaryFontColorHex)
            ]
            (Element.text (viewSearchEvent maybeCurrentEvent))
        , viewInspectorControls model theme trace currentIndex traceFinished inspection.committed
        , viewInspectorBody model theme trace focusedNode maybeCurrentEvent currentIndex
        ]


viewInspectorControls : Model -> BaseTheme -> SearchTrace -> Int -> Bool -> Bool -> Element.Element Msg
viewInspectorControls model theme trace currentIndex traceFinished finalMoveCommitted =
    case getScreenSize model.maybeWindow of
        Mobile ->
            Element.column
                [ Element.spacing (getResponsiveSpacing model.maybeWindow 10)
                , Element.width Element.fill
                ]
                [ actionButton model theme "trace-back" "Back" (Just StepInspectionBackward) (hasEvents trace && currentIndex > 0)
                , actionButton model theme "trace-forward" "Forward" (Just StepInspectionForward) (hasEvents trace && currentIndex < max 0 (List.length trace.events - 1))
                , actionButton model theme "trace-play" "Play to end" (Just PlayInspectionToEnd) (hasEvents trace && not traceFinished)
                , actionButton model theme "trace-apply" "Apply move" (Just ApplyInspectionMove) (hasEvents trace && traceFinished && not finalMoveCommitted)
                ]

        _ ->
            Element.row
                [ Element.spacing (getResponsiveSpacing model.maybeWindow 10)
                , Element.width Element.fill
                ]
                [ actionButton model theme "trace-back" "Back" (Just StepInspectionBackward) (hasEvents trace && currentIndex > 0)
                , actionButton model theme "trace-forward" "Forward" (Just StepInspectionForward) (hasEvents trace && currentIndex < max 0 (List.length trace.events - 1))
                , actionButton model theme "trace-play" "Play to end" (Just PlayInspectionToEnd) (hasEvents trace && not traceFinished)
                , actionButton model theme "trace-apply" "Apply move" (Just ApplyInspectionMove) (hasEvents trace && traceFinished && not finalMoveCommitted)
                ]


viewInspectorBody : Model -> BaseTheme -> SearchTrace -> SearchNode -> Maybe SearchEvent -> Int -> Element.Element Msg
viewInspectorBody model theme trace currentNode maybeCurrentEvent currentIndex =
    case getScreenSize model.maybeWindow of
        Mobile ->
            Element.column
                [ Element.spacing (getResponsiveSpacing model.maybeWindow 12)
                , Element.width Element.fill
                ]
                [ viewNodeDetails model theme trace currentNode maybeCurrentEvent currentIndex
                , viewTraceTree model theme trace currentNode.id currentIndex
                ]

        _ ->
            Element.row
                [ Element.spacing (getResponsiveSpacing model.maybeWindow 12)
                , Element.width Element.fill
                , Element.alignTop
                ]
                [ Element.el [ Element.width (Element.fillPortion 1) ] (viewNodeDetails model theme trace currentNode maybeCurrentEvent currentIndex)
                , Element.el [ Element.width (Element.fillPortion 1) ] (viewTraceTree model theme trace currentNode.id currentIndex)
                ]


viewNodeDetails : Model -> BaseTheme -> SearchTrace -> SearchNode -> Maybe SearchEvent -> Int -> Element.Element Msg
viewNodeDetails model theme trace node maybeCurrentEvent currentIndex =
    Element.column
        [ Element.width Element.fill
        , Element.spacing (getResponsiveSpacing model.maybeWindow 10)
        , Element.padding (getResponsivePadding model.maybeWindow 12)
        , Background.color (Element.HexColor.rgbCSSHex theme.backgroundColorHex)
        , Element.Border.rounded 12
        , Element.Border.width 1
        , Element.Border.color (Element.HexColor.rgbCSSHex theme.borderColorHex)
        , Element.htmlAttribute (Html.Attributes.class "trace-detail")
        ]
        [ Element.el
            [ Font.size (getResponsiveFontSize model.maybeWindow 20)
            , Font.color (Element.HexColor.rgbCSSHex theme.fontColorHex)
            ]
            (Element.text ("Active node " ++ String.fromInt node.id))
        , Element.el
            [ Font.size (getResponsiveFontSize model.maybeWindow 16)
            , Font.color (Element.HexColor.rgbCSSHex theme.secondaryFontColorHex)
            ]
            (Element.text (viewSearchEvent maybeCurrentEvent))
        , viewMetricGroup model
            [ valueChip model theme "depth" (String.fromInt node.depth)
            , valueChip model theme "score" (Maybe.withDefault "pending" (Maybe.map String.fromInt node.score))
            , valueChip model theme "status" (viewNodeStatus node.status)
            ]
        , viewMetricGroup model
            [ valueChip model theme "move" (Maybe.withDefault "root" (Maybe.map viewPosition node.moveFromParent))
            , valueChip model theme "children" (String.fromInt (List.length node.children))
            , valueChip model theme "event" (traceProgressLabel currentIndex (List.length trace.events))
            ]
        , if trace.algorithm == AlphaBeta then
            viewMetricGroup model
                [ valueChip model theme "alpha" (Maybe.withDefault "unbounded" (Maybe.map String.fromInt node.alpha))
                , valueChip model theme "beta" (Maybe.withDefault "unbounded" (Maybe.map String.fromInt node.beta))
                ]

          else
            Element.none
        , Element.el
            [ Font.size (getResponsiveFontSize model.maybeWindow 16)
            , Font.color (Element.HexColor.rgbCSSHex theme.secondaryFontColorHex)
            ]
            (Element.text "Board snapshot")
        , viewMiniBoard model theme node.board
        , Element.el
            [ Font.size (getResponsiveFontSize model.maybeWindow 16)
            , Font.color (Element.HexColor.rgbCSSHex theme.secondaryFontColorHex)
            ]
            (Element.text ("Children: " ++ String.join ", " (List.map String.fromInt node.children)))
        ]


viewTraceTree : Model -> BaseTheme -> SearchTrace -> SearchNodeId -> Int -> Element.Element Msg
viewTraceTree model theme trace activeNodeId currentIndex =
    let
        displayedNodes =
            traceNodesForDisplay trace activeNodeId currentIndex

        hiddenNodeCount =
            max 0 (Dict.size trace.nodes - List.length displayedNodes)
    in
    Element.column
        [ Element.width Element.fill
        , Element.spacing (getResponsiveSpacing model.maybeWindow 10)
        , Element.padding (getResponsivePadding model.maybeWindow 12)
        , Background.color (Element.HexColor.rgbCSSHex theme.backgroundColorHex)
        , Element.Border.rounded 12
        , Element.Border.width 1
        , Element.Border.color (Element.HexColor.rgbCSSHex theme.borderColorHex)
        , Element.htmlAttribute (Html.Attributes.class "trace-tree")
        ]
        ([ Element.el
            [ Font.size (getResponsiveFontSize model.maybeWindow 20)
            , Font.color (Element.HexColor.rgbCSSHex theme.fontColorHex)
            ]
            (Element.text "Trace order")
         , Element.el
            [ Font.size (getResponsiveFontSize model.maybeWindow 14)
            , Font.color (Element.HexColor.rgbCSSHex theme.secondaryFontColorHex)
            ]
            (Element.text
                (if hiddenNodeCount > 0 then
                    "Showing the focused search slice around the active node. "
                        ++ String.fromInt hiddenNodeCount
                        ++ " additional nodes stay collapsed."

                 else
                    "Showing the full traced search."
                )
            )
         ]
            ++ List.map (viewTraceNode model theme activeNodeId trace.algorithm) displayedNodes
        )


viewTraceNode : Model -> BaseTheme -> SearchNodeId -> SearchAlgorithm -> SearchNode -> Element.Element Msg
viewTraceNode model theme activeNodeId algorithm node =
    let
        isActive =
            node.id == activeNodeId

        baseBackground =
            case node.status of
                Pruned ->
                    theme.panelBackgroundColorHex

                Finalized ->
                    theme.panelBackgroundColorHex

                Active ->
                    theme.headerBackgroundColorHex

                Expanded ->
                    theme.gridBackgroundColorHex

                Unvisited ->
                    theme.backgroundColorHex

        borderColor =
            if isActive then
                theme.accentColorHex

            else
                case node.status of
                    Pruned ->
                        theme.errorColorHex

                    Finalized ->
                        theme.successColorHex

                    Active ->
                        theme.accentColorHex

                    Expanded ->
                        theme.borderColorHex

                    Unvisited ->
                        theme.borderColorHex
    in
    Element.column
        [ Element.width Element.fill
        , Element.paddingXY (getResponsivePadding model.maybeWindow 8) (getResponsivePadding model.maybeWindow 8)
        , Element.spacing (getResponsiveSpacing model.maybeWindow 8)
        , Background.color (Element.HexColor.rgbCSSHex baseBackground)
        , Element.Border.rounded 10
        , Element.Border.width 1
        , Element.Border.color (Element.HexColor.rgbCSSHex borderColor)
        , Element.htmlAttribute (Html.Attributes.class "trace-node")
        , if isActive then
            Element.htmlAttribute (Html.Attributes.class "trace-node-active")

          else
            Element.htmlAttribute (Html.Attributes.class "trace-node-idle")
        , if node.status == Pruned then
            Element.htmlAttribute (Html.Attributes.class "trace-node-pruned")

          else
            Element.htmlAttribute (Html.Attributes.class "trace-node-live")
        ]
        [ viewMetricGroup model
            [ Element.el
                [ Font.bold
                , Font.color (Element.HexColor.rgbCSSHex theme.fontColorHex)
                ]
                (Element.text ("Node " ++ String.fromInt node.id))
            , searchModeChip model theme algorithm
            , valueChip model theme "depth" (String.fromInt node.depth)
            , valueChip model theme "score" (Maybe.withDefault "pending" (Maybe.map String.fromInt node.score))
            ]
        , viewMetricGroup model
            [ valueChip model theme "move" (Maybe.withDefault "root" (Maybe.map viewPosition node.moveFromParent))
            , valueChip model theme "status" (viewNodeStatus node.status)
            , valueChip model theme "children" (String.fromInt (List.length node.children))
            ]
        , if algorithm == AlphaBeta then
            viewMetricGroup model
                [ valueChip model theme "alpha" (Maybe.withDefault "unbounded" (Maybe.map String.fromInt node.alpha))
                , valueChip model theme "beta" (Maybe.withDefault "unbounded" (Maybe.map String.fromInt node.beta))
                ]

          else
            Element.none
        ]


viewMiniBoard : Model -> BaseTheme -> Board -> Element.Element Msg
viewMiniBoard model theme board =
    Element.el
        [ Element.centerX
        , Background.color (Element.HexColor.rgbCSSHex theme.borderColorHex)
        , Element.padding (getResponsivePadding model.maybeWindow 8)
        , Element.Border.rounded 10
        , Element.Border.width 1
        , Element.Border.color (Element.HexColor.rgbCSSHex theme.borderColorHex)
        ]
        (Element.column [ Element.spacing (getResponsiveSpacing model.maybeWindow 6) ]
            (List.indexedMap (viewRow model False 8) board)
        )


viewStatusBar : Model -> BaseTheme -> Element.Element Msg
viewStatusBar model theme =
    Element.el
        [ Element.padding (getResponsivePadding model.maybeWindow 15)
        , Element.centerX
        , Background.color (Element.HexColor.rgbCSSHex theme.headerBackgroundColorHex)
        , Element.width Element.fill
        , Element.Border.rounded 12
        ]
        (Element.el
            [ Element.centerX
            , Font.color (getStatusColor model theme)
            , Font.size (getResponsiveFontSize model.maybeWindow 24)
            , Element.htmlAttribute (Html.Attributes.class "game-status")
            ]
            (Element.text (getStatusMessage model))
        )


getStatusColor : Model -> BaseTheme -> Color
getStatusColor model theme =
    case model.gameState of
        Winner _ ->
            Element.HexColor.rgbCSSHex theme.successColorHex

        Error errorInfo ->
            case errorInfo.errorType of
                TimeoutError ->
                    Element.HexColor.rgbCSSHex theme.secondaryFontColorHex

                _ ->
                    Element.HexColor.rgbCSSHex theme.errorColorHex

        _ ->
            Element.HexColor.rgbCSSHex theme.fontColorHex


getStatusMessage : Model -> String
getStatusMessage model =
    case model.gameState of
        Winner player ->
            "Player " ++ viewPlayerAsString player ++ " wins!"

        Waiting player ->
            case ( player, model.aiTurnState ) of
                ( O, Just AwaitingChoice ) ->
                    "Player O is ready. Auto move or inspect the search."

                ( O, Just (Inspecting inspection) ) ->
                    "Inspecting " ++ viewSearchAlgorithm inspection.trace.algorithm ++ " for Player O"

                _ ->
                    "Player " ++ viewPlayerAsString player ++ "'s turn"

        Thinking player ->
            case model.aiTurnState of
                Just FastThinking ->
                    "Player " ++ viewPlayerAsString player ++ "'s thinking"

                Nothing ->
                    "Player " ++ viewPlayerAsString player ++ "'s thinking"

                _ ->
                    "Player " ++ viewPlayerAsString player ++ "'s thinking"

        Draw ->
            "Game ended in a draw!"

        Error errorInfo ->
            formatErrorMessage errorInfo


formatErrorMessage : ErrorInfo -> String
formatErrorMessage errorInfo =
    let
        baseMessage =
            errorInfo.message

        contextualMessage =
            case errorInfo.errorType of
                InvalidMove ->
                    baseMessage ++ " (Try clicking an empty cell)"

                GameLogicError ->
                    baseMessage ++ " (Please reset the game)"

                WorkerCommunicationError ->
                    baseMessage ++ " (Please reset the game)"

                JsonError ->
                    baseMessage ++ " (Communication error - please reset)"

                TimeoutError ->
                    baseMessage ++ " (Click reset to continue)"

                UnknownError ->
                    baseMessage ++ " (Please reset the game)"
    in
    if errorInfo.recoverable then
        contextualMessage

    else
        contextualMessage ++ " (Game cannot continue)"


viewRow : Model -> Bool -> Int -> Int -> Line -> Element.Element Msg
viewRow model allowInteraction cellScale rowIndex row =
    Element.row [ Element.spacing (getResponsiveSpacing model.maybeWindow 10) ]
        (List.indexedMap (viewCell model allowInteraction cellScale rowIndex) row)


viewCell : Model -> Bool -> Int -> Int -> Int -> Maybe Player -> Element.Element Msg
viewCell model allowInteraction cellScale rowIndex colIndex maybePlayer =
    let
        theme : BaseTheme
        theme =
            getBaseTheme model.colorScheme

        cellSize : Int
        cellSize =
            calculateResponsiveCellSize model.maybeWindow
                cellScale
                (if allowInteraction then
                    200

                 else
                    88
                )

        cellTestId : String
        cellTestId =
            "cell-" ++ String.fromInt rowIndex ++ "-" ++ String.fromInt colIndex

        boardCellAttributes : List (Element.Attribute msg)
        boardCellAttributes =
            [ Background.color (Element.HexColor.rgbCSSHex theme.cellBackgroundColorHex)
            , Element.height (Element.px cellSize)
            , Element.width (Element.px cellSize)
            , Element.padding (getResponsivePadding model.maybeWindow 20)
            , Element.Border.width 2
            , Element.Border.color (Element.HexColor.rgbCSSHex theme.borderColorHex)
            , Element.htmlAttribute (Html.Attributes.attribute "role" "button")
            , Element.htmlAttribute (Html.Attributes.attribute "aria-label" cellTestId)
            ]
    in
    case maybePlayer of
        Just player ->
            player
                |> viewPlayerAsSvg model
                |> Element.el
                    (boardCellAttributes
                        ++ [ Element.htmlAttribute (Html.Attributes.class "cell-occupied") ]
                    )

        Nothing ->
            let
                hoverAttributes : List (Element.Attribute Msg)
                hoverAttributes =
                    if allowInteraction then
                        [ Element.mouseOver [ Background.color (Element.HexColor.rgbCSSHex theme.accentColorHex) ]
                        , Element.pointer
                        ]

                    else
                        []

                clickAttributes : List (Element.Attribute Msg)
                clickAttributes =
                    if allowInteraction then
                        [ Element.Events.onClick (MoveMade (Position rowIndex colIndex)) ]

                    else
                        []
            in
            Element.el
                (boardCellAttributes ++ clickAttributes ++ hoverAttributes)
                (Element.text " ")


searchModeChip : Model -> BaseTheme -> SearchAlgorithm -> Element.Element Msg
searchModeChip model theme algorithm =
    valueChip model theme "algorithm" (viewSearchAlgorithm algorithm)


valueChip : Model -> BaseTheme -> String -> String -> Element.Element Msg
valueChip model theme label value =
    Element.el
        [ Background.color (Element.HexColor.rgbCSSHex theme.panelBackgroundColorHex)
        , Font.color (Element.HexColor.rgbCSSHex theme.fontColorHex)
        , Element.Border.rounded 999
        , Element.Border.width 1
        , Element.Border.color (Element.HexColor.rgbCSSHex theme.borderColorHex)
        , Element.paddingXY (getResponsivePadding model.maybeWindow 10) (getResponsivePadding model.maybeWindow 6)
        ]
        (Element.row
            [ Element.spacing (getResponsiveSpacing model.maybeWindow 6) ]
            [ Element.el [ Font.bold ] (Element.text (label ++ ":"))
            , Element.text value
            ]
        )


viewMetricGroup : Model -> List (Element.Element Msg) -> Element.Element Msg
viewMetricGroup model children =
    case getScreenSize model.maybeWindow of
        Mobile ->
            Element.column
                [ Element.spacing (getResponsiveSpacing model.maybeWindow 8)
                , Element.width Element.fill
                ]
                children

        _ ->
            Element.row
                [ Element.width Element.fill
                , Element.spacing (getResponsiveSpacing model.maybeWindow 10)
                ]
                children


actionButton : Model -> BaseTheme -> String -> String -> Maybe Msg -> Bool -> Element.Element Msg
actionButton model theme elementId label onPress isPrimary =
    Input.button
        [ Element.htmlAttribute (Html.Attributes.id elementId)
        , Background.color
            (Element.HexColor.rgbCSSHex
                (if isPrimary then
                    theme.buttonColorHex

                 else
                    theme.buttonBackgroundColorHex
                )
            )
        , Font.color
            (Element.HexColor.rgbCSSHex theme.buttonTextColorHex)
        , Element.Border.rounded 10
        , Element.Border.width 1
        , Element.Border.color (Element.HexColor.rgbCSSHex theme.borderColorHex)
        , Element.padding (getResponsivePadding model.maybeWindow 12)
        ]
        { onPress = onPress
        , label =
            Element.el
                [ Font.bold
                , Font.size (getResponsiveFontSize model.maybeWindow 16)
                ]
                (Element.text label)
        }


viewSearchEvent : Maybe SearchEvent -> String
viewSearchEvent maybeEvent =
    case maybeEvent of
        Just event ->
            case event of
                EnteredNode nodeId ->
                    "Entered node " ++ String.fromInt nodeId

                ConsideredMove nodeId position childId ->
                    "Node " ++ String.fromInt nodeId ++ " considered " ++ viewPosition position ++ " -> " ++ String.fromInt childId

                LeafEvaluated nodeId score ->
                    "Node " ++ String.fromInt nodeId ++ " evaluated leaf score " ++ String.fromInt score

                ScorePropagated nodeId childId score ->
                    "Node " ++ String.fromInt nodeId ++ " received score " ++ String.fromInt score ++ " from node " ++ String.fromInt childId

                AlphaUpdated nodeId alpha ->
                    "Node " ++ String.fromInt nodeId ++ " alpha = " ++ String.fromInt alpha

                BetaUpdated nodeId beta ->
                    "Node " ++ String.fromInt nodeId ++ " beta = " ++ String.fromInt beta

                PrunedBranch nodeId childId position alpha beta ->
                    "Node " ++ String.fromInt nodeId ++ " pruned " ++ viewPosition position ++ " -> " ++ String.fromInt childId ++ " at " ++ String.fromInt alpha ++ "/" ++ String.fromInt beta

                NodeFinalized nodeId score ->
                    "Node " ++ String.fromInt nodeId ++ " finalized with " ++ String.fromInt score

        Nothing ->
            "No event selected"


viewSearchAlgorithm : SearchAlgorithm -> String
viewSearchAlgorithm algorithm =
    case algorithm of
        Negamax ->
            "Negamax"

        AlphaBeta ->
            "Alpha-Beta"


viewNodeStatus : SearchNodeStatus -> String
viewNodeStatus status =
    case status of
        Unvisited ->
            "unvisited"

        Active ->
            "active"

        Expanded ->
            "expanded"

        Finalized ->
            "finalized"

        Pruned ->
            "pruned"


viewFastThinkingPanel : Model -> BaseTheme -> Element.Element Msg
viewFastThinkingPanel model theme =
    Element.column
        [ Element.width Element.fill
        , Element.spacing (getResponsiveSpacing model.maybeWindow 12)
        , Element.padding (getResponsivePadding model.maybeWindow 15)
        , Background.color (Element.HexColor.rgbCSSHex theme.panelBackgroundColorHex)
        , Element.Border.rounded 14
        , Element.Border.width 1
        , Element.Border.color (Element.HexColor.rgbCSSHex theme.borderColorHex)
        ]
        [ Element.el [ Font.size (getResponsiveFontSize model.maybeWindow 24) ] (Element.text "AI search")
        , Element.el
            [ Font.size (getResponsiveFontSize model.maybeWindow 16)
            , Font.color (Element.HexColor.rgbCSSHex theme.secondaryFontColorHex)
            ]
            (Element.text "Fast worker-backed search is running for Player O.")
        , actionButton model theme "auto-move-running" "Waiting for worker" Nothing True
        ]


resetIcon : Model -> Element.Element Msg
resetIcon model =
    let
        theme =
            getBaseTheme model.colorScheme
    in
    Element.el
        [ Element.Events.onClick ResetGame
        , Element.pointer
        , Element.mouseOver [ Background.color (Element.HexColor.rgbCSSHex theme.buttonHoverColorHex) ]
        , Element.padding 8
        , Background.color (Element.HexColor.rgbCSSHex theme.buttonColorHex)
        , Element.Border.rounded 4
        , Element.htmlAttribute (Html.Attributes.attribute "role" "button")
        , Element.htmlAttribute (Html.Attributes.attribute "aria-label" "reset-button")
        ]
    <|
        Element.html <|
            Svg.svg
                [ SvgAttr.viewBox "0 0 24 24"
                , SvgAttr.version "1.1"
                , SvgAttr.width "24"
                , SvgAttr.height "24"
                ]
                [ Svg.path
                    [ SvgAttr.d "M17.65,6.35C16.2,4.9 14.21,4 12,4A8,8 0 0,0 4,12A8,8 0 0,0 12,20C15.73,20 18.84,17.45 19.73,14H17.65C16.83,16.33 14.61,18 12,18A6,6 0 0,1 6,12A6,6 0 0,1 12,6C13.66,6 15.14,6.69 16.22,7.78L13,11H20V4L17.65,6.35Z"
                    , SvgAttr.fill theme.iconColorHex
                    ]
                    []
                ]


colorSchemeToggleIcon : Model -> Element.Element Msg
colorSchemeToggleIcon model =
    let
        theme =
            getBaseTheme model.colorScheme

        iconPath =
            case model.colorScheme of
                Light ->
                    "M17.75,4.09L15.22,6.03L16.13,9.09L13.5,7.28L10.87,9.09L11.78,6.03L9.25,4.09L12.44,4L13.5,1L14.56,4L17.75,4.09M21.25,11L19.61,12.25L20.2,14.23L18.5,13.06L16.8,14.23L17.39,12.25L15.75,11L17.81,10.95L18.5,9L19.19,10.95L21.25,11M18.97,15.95C19.8,15.87 20.69,17.05 20.16,17.8C19.84,18.25 19.5,18.67 19.08,19.07C15.17,23 8.84,23 4.94,19.07C1.03,15.17 1.03,8.83 4.94,4.93C5.34,4.53 5.76,4.17 6.21,3.85C6.96,3.32 8.14,4.21 8.06,5.04C7.79,7.9 8.75,10.87 10.95,13.06C13.14,15.26 16.1,16.22 18.97,15.95M17.33,17.97C14.5,17.81 11.7,16.64 9.53,14.5C7.36,12.31 6.2,9.5 6.04,6.68C3.23,9.82 3.34,14.4 6.35,17.41C9.37,20.43 14,20.54 17.33,17.97Z"

                Dark ->
                    "M12,7A5,5 0 0,1 17,12A5,5 0 0,1 12,17A5,5 0 0,1 7,12A5,5 0 0,1 12,7M12,9A3,3 0 0,0 9,12A3,3 0 0,0 12,15A3,3 0 0,0 15,12A3,3 0 0,0 12,9M12,2L14.39,5.42C13.65,5.15 12.84,5 12,5C11.16,5 10.35,5.15 9.61,5.42L12,2M3.34,7L7.5,6.65C6.9,7.16 6.36,7.78 5.94,8.5C5.5,9.24 5.25,10 5.11,10.79L3.34,7M3.36,17L5.12,13.23C5.26,14 5.53,14.78 5.95,15.5C6.37,16.24 6.91,16.86 7.5,17.37L3.36,17M20.65,7L18.88,10.79C18.74,10 18.47,9.23 18.05,8.5C17.63,7.78 17.1,7.15 16.5,6.64L20.65,7M20.64,17L16.5,17.36C17.09,16.85 17.62,16.22 18.04,15.5C18.46,14.77 18.73,14 18.87,13.21L20.64,17M12,22L9.59,18.56C10.33,18.83 11.14,19 12,19C12.82,19 13.63,18.83 14.37,18.56L12,22Z"
    in
    Element.el
        [ Element.Events.onClick
            (ColorScheme
                (case model.colorScheme of
                    Light ->
                        Dark

                    Dark ->
                        Light
                )
            )
        , Element.pointer
        , Element.mouseOver [ Background.color (Element.HexColor.rgbCSSHex theme.buttonHoverColorHex) ]
        , Element.padding 8
        , Background.color (Element.HexColor.rgbCSSHex theme.buttonColorHex)
        , Element.Border.rounded 4
        , Element.htmlAttribute (Html.Attributes.attribute "role" "button")
        , Element.htmlAttribute (Html.Attributes.attribute "aria-label" "color-scheme-toggle")
        , Element.htmlAttribute (Html.Attributes.id "theme-toggle")
        ]
    <|
        Element.row [ Element.spacing 0 ]
            [ Element.html <|
                Svg.svg
                    [ SvgAttr.viewBox "0 0 24 24"
                    , SvgAttr.version "1.1"
                    , SvgAttr.width "24"
                    , SvgAttr.height "24"
                    ]
                    [ Svg.path
                        [ SvgAttr.d iconPath
                        , SvgAttr.fill theme.iconColorHex
                        ]
                        []
                    ]
            , Element.el
                [ Element.width (Element.px 1)
                , Element.height (Element.px 1)
                , Element.clip
                , Element.moveLeft 10000
                ]
                (Element.text
                    (case model.colorScheme of
                        Light ->
                            "Dark"

                        Dark ->
                            "Light"
                    )
                )
            ]


viewTimer : Model -> Element.Element msg
viewTimer model =
    let
        theme =
            getBaseTheme model.colorScheme

        config =
            { radius = 15
            , strokeWidth = 3
            }

        elapsedTime =
            TicTacToe.Model.timeSpent model

        progress =
            elapsedTime / toFloat TicTacToe.Model.idleTimeoutMillis

        circumference =
            2 * pi * config.radius

        dashOffset =
            circumference * (1 - progress)
    in
    Element.el
        [ Element.padding 4
        , Background.color (Element.HexColor.rgbCSSHex theme.headerBackgroundColorHex)
        , Element.Border.rounded 20
        ]
    <|
        Element.html <|
            Svg.svg
                [ SvgAttr.width "40"
                , SvgAttr.height "40"
                , SvgAttr.viewBox "0 0 40 40"
                ]
                [ Svg.circle
                    [ SvgAttr.cx "20"
                    , SvgAttr.cy "20"
                    , SvgAttr.r (String.fromFloat config.radius)
                    , SvgAttr.fill "none"
                    , SvgAttr.stroke theme.timerBackgroundColorHex
                    , SvgAttr.strokeWidth (String.fromFloat config.strokeWidth)
                    ]
                    []
                , Svg.circle
                    [ SvgAttr.cx "20"
                    , SvgAttr.cy "20"
                    , SvgAttr.r (String.fromFloat config.radius)
                    , SvgAttr.fill "none"
                    , SvgAttr.stroke theme.timerProgressColorHex
                    , SvgAttr.strokeWidth (String.fromFloat config.strokeWidth)
                    , SvgAttr.strokeDasharray (String.fromFloat circumference)
                    , SvgAttr.strokeDashoffset (String.fromFloat dashOffset)
                    , SvgAttr.transform "rotate(-90 20 20)"
                    , SvgAttr.strokeLinecap "round"
                    ]
                    []
                ]


viewPosition : Position -> String
viewPosition position =
    "row " ++ String.fromInt position.row ++ ", col " ++ String.fromInt position.col


viewPlayerAsString : Player -> String
viewPlayerAsString player =
    case player of
        X ->
            "X"

        O ->
            "O"


viewPlayerAsSvg : Model -> Player -> Element.Element msg
viewPlayerAsSvg model player =
    case player of
        X ->
            crossIcon model

        O ->
            circleIcon model


circleIcon : Model -> Element.Element msg
circleIcon model =
    let
        theme : BaseTheme
        theme =
            getBaseTheme model.colorScheme
    in
    Element.html <|
        Svg.svg
            [ SvgAttr.viewBox "0 0 24 24"
            , SvgAttr.fill "none"
            , SvgAttr.width "100%"
            , SvgAttr.height "100%"
            ]
            [ Svg.path
                [ SvgAttr.d "M21 12C21 16.9706 16.9706 21 12 21C7.02944 21 3 16.9706 3 12C3 7.02944 7.02944 3 12 3C16.9706 3 21 7.02944 21 12Z"
                , SvgAttr.stroke theme.pieceColorHex
                , SvgAttr.strokeWidth "3"
                , SvgAttr.strokeLinecap "round"
                , SvgAttr.strokeLinejoin "round"
                ]
                []
            ]


crossIcon : Model -> Element.Element msg
crossIcon model =
    let
        theme : BaseTheme
        theme =
            getBaseTheme model.colorScheme
    in
    Element.html <|
        Svg.svg
            [ SvgAttr.viewBox "0 0 24 24"
            , SvgAttr.fill "none"
            , SvgAttr.width "100%"
            , SvgAttr.height "100%"
            ]
            [ Svg.path
                [ SvgAttr.d "M18 6L6 18"
                , SvgAttr.stroke theme.pieceColorHex
                , SvgAttr.strokeWidth "3"
                , SvgAttr.strokeLinecap "round"
                , SvgAttr.strokeLinejoin "round"
                ]
                []
            , Svg.path
                [ SvgAttr.d "M6 6L18 18"
                , SvgAttr.stroke theme.pieceColorHex
                , SvgAttr.strokeWidth "3"
                , SvgAttr.strokeLinecap "round"
                , SvgAttr.strokeLinejoin "round"
                ]
                []
            ]


traceToRootNode : SearchTrace -> SearchNode
traceToRootNode trace =
    case Dict.get trace.rootNodeId trace.nodes of
        Just node ->
            node

        Nothing ->
            { id = trace.rootNodeId
            , board = [ [ Nothing, Nothing, Nothing ], [ Nothing, Nothing, Nothing ], [ Nothing, Nothing, Nothing ] ]
            , player = O
            , depth = 0
            , moveFromParent = Nothing
            , score = Nothing
            , alpha = Nothing
            , beta = Nothing
            , status = Unvisited
            , children = []
            }


isTraceFinished : SearchTrace -> Int -> Bool
isTraceFinished trace index =
    eventCount trace > 0 && index >= eventCount trace - 1


hasEvents : SearchTrace -> Bool
hasEvents trace =
    eventCount trace > 0


traceProgressLabel : Int -> Int -> String
traceProgressLabel index total =
    if total <= 0 then
        "0 / 0"

    else
        String.fromInt (index + 1) ++ " / " ++ String.fromInt total


eventCount : SearchTrace -> Int
eventCount trace =
    List.length trace.events


currentEvent : SearchTrace -> Int -> Maybe SearchEvent
currentEvent trace index =
    trace.events
        |> List.drop (clampEventIndex trace index)
        |> List.head


currentTraceNode : SearchTrace -> Int -> Maybe SearchNode
currentTraceNode trace index =
    currentEvent trace index
        |> Maybe.map eventNodeId
        |> Maybe.andThen (\nodeId -> Dict.get nodeId trace.nodes)


eventNodeId : SearchEvent -> SearchNodeId
eventNodeId event =
    case event of
        EnteredNode nodeId ->
            nodeId

        ConsideredMove nodeId _ _ ->
            nodeId

        LeafEvaluated nodeId _ ->
            nodeId

        ScorePropagated nodeId _ _ ->
            nodeId

        AlphaUpdated nodeId _ ->
            nodeId

        BetaUpdated nodeId _ ->
            nodeId

        PrunedBranch nodeId _ _ _ _ ->
            nodeId

        NodeFinalized nodeId _ ->
            nodeId


traceNodesForDisplay : SearchTrace -> SearchNodeId -> Int -> List SearchNode
traceNodesForDisplay trace activeNodeId currentIndex =
    let
        rootChildren =
            trace.nodes
                |> Dict.get trace.rootNodeId
                |> Maybe.map .children
                |> Maybe.withDefault []

        activeChildren =
            trace.nodes
                |> Dict.get activeNodeId
                |> Maybe.map .children
                |> Maybe.withDefault []

        recentNodeIds =
            trace.events
                |> List.take (clampEventIndex trace currentIndex + 1)
                |> List.reverse
                |> List.map eventNodeId
                |> uniqueNodeIds
                |> List.take 12

        bestMoveNodeIds =
            bestMoveNodeId trace
                |> Maybe.map List.singleton
                |> Maybe.withDefault []

        prunedNodeIds =
            trace.nodes
                |> Dict.values
                |> List.filter (\node -> node.status == Pruned)
                |> List.sortBy .id
                |> List.take 3
                |> List.map .id

        candidateNodeIds =
            uniqueNodeIds
                (trace.rootNodeId
                    :: rootChildren
                    ++ [ activeNodeId ]
                    ++ activeChildren
                    ++ bestMoveNodeIds
                    ++ prunedNodeIds
                    ++ recentNodeIds
                )
    in
    candidateNodeIds
        |> List.filterMap (\nodeId -> Dict.get nodeId trace.nodes)
        |> List.sortBy (\node -> ( node.depth, node.id ))


bestMoveNodeId : SearchTrace -> Maybe SearchNodeId
bestMoveNodeId trace =
    case ( Dict.get trace.rootNodeId trace.nodes, trace.bestMove ) of
        ( Just rootNode, Just bestMove ) ->
            rootNode.children
                |> List.filterMap
                    (\childId ->
                        case Dict.get childId trace.nodes of
                            Just childNode ->
                                if childNode.moveFromParent == Just bestMove then
                                    Just childNode.id

                                else
                                    Nothing

                            Nothing ->
                                Nothing
                    )
                |> List.head

        _ ->
            Nothing


uniqueNodeIds : List SearchNodeId -> List SearchNodeId
uniqueNodeIds nodeIds =
    nodeIds
        |> List.foldl
            (\nodeId ( seen, ordered ) ->
                if Set.member nodeId seen then
                    ( seen, ordered )

                else
                    ( Set.insert nodeId seen, nodeId :: ordered )
            )
            ( Set.empty, [] )
        |> Tuple.second
        |> List.reverse


clampEventIndex : SearchTrace -> Int -> Int
clampEventIndex trace index =
    if eventCount trace <= 0 then
        0

    else
        let
            maximumIndex =
                max 0 (eventCount trace - 1)
        in
        clamp 0 maximumIndex index

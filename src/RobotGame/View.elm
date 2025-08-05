module RobotGame.View exposing (Theme, currentTheme, view)

{-| This module handles the UI rendering for the Robot Grid Game.
It provides functions to render the 5x5 grid, robot with directional indicator, responsive design, and visual control buttons.
Includes comprehensive accessibility features with ARIA labels, keyboard navigation, and visual feedback.
-}

import Element exposing (Color, Element)
import Element.Background as Background
import Element.Border
import Element.Events
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import Html.Attributes
import RobotGame.Main as Main
import RobotGame.Model exposing (AnimationState(..), Direction(..), Model, Position)
import RobotGame.RobotGame as RobotGame
import Route
import String
import Svg
import Svg.Attributes as SvgAttr
import Theme.Responsive exposing (ScreenSize(..), calculateResponsiveCellSize, getResponsiveFontSize, getResponsivePadding, getResponsiveSpacing, getScreenSize)
import Theme.Theme exposing (BaseTheme, ColorScheme, getBaseTheme)


{-| RobotGame theme type alias for the shared theme
-}
type alias Theme =
    BaseTheme


{-| Get the current theme based on color scheme
-}
currentTheme : ColorScheme -> Theme
currentTheme =
    getBaseTheme


{-| Main view function that renders the entire robot game UI
-}
view : Model -> Html Main.Msg
view model =
    let
        theme : Theme
        theme =
            currentTheme model.colorScheme

        -- Global CSS styles for animations and accessibility
        globalAnimationStyles =
            """
            <style>
            /* Theme transition support for smooth color changes */
            body, .elm-ui-layout {
                transition: background-color 0.3s ease-in-out, color 0.3s ease-in-out;
            }
            
            /* Grid cell animations and hover effects */
            .grid-cell {
                transition: background-color 0.3s ease-in-out, border-color 0.3s ease-in-out, box-shadow 0.2s ease-in-out;
            }
            .grid-cell:hover {
                box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
            }
            
            /* Robot animations */
            .robot-rotating {
                transition: transform 0.2s ease-in-out;
            }
            .robot-moving {
                animation: robotPulse 0.3s ease-in-out;
            }
            .robot-blocked {
                animation: robotShake 0.5s ease-in-out;
            }
            .robot-success {
                animation: robotSuccess 0.4s ease-in-out;
            }
            
            /* Keyframe animations */
            @keyframes robotPulse {
                0% { transform: scale(1); }
                50% { transform: scale(1.1); }
                100% { transform: scale(1); }
            }
            @keyframes robotShake {
                0%, 100% { transform: translateX(0); }
                10%, 30%, 50%, 70%, 90% { transform: translateX(-2px); }
                20%, 40%, 60%, 80% { transform: translateX(2px); }
            }
            @keyframes robotSuccess {
                0% { transform: scale(1); }
                25% { transform: scale(1.05) rotate(2deg); }
                50% { transform: scale(1.1) rotate(-2deg); }
                75% { transform: scale(1.05) rotate(1deg); }
                100% { transform: scale(1) rotate(0deg); }
            }
            
            /* Enhanced button animations and accessibility */
            .control-button {
                transition: all 0.2s ease-in-out;
                position: relative;
                overflow: hidden;
            }
            .control-button:hover:not(:disabled) {
                transform: translateY(-2px);
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
            }
            .control-button:active:not(:disabled) {
                transform: translateY(-1px);
                box-shadow: 0 2px 6px rgba(0, 0, 0, 0.15);
            }
            .control-button:focus {
                outline: 3px solid rgba(52, 152, 219, 0.6);
                outline-offset: 2px;
                z-index: 10;
            }
            .control-button:focus-visible {
                outline: 3px solid rgba(52, 152, 219, 0.8);
                outline-offset: 2px;
            }
            .control-button:disabled {
                cursor: not-allowed;
                opacity: 0.6;
            }
            
            /* Enhanced keyboard navigation */
            .control-button[aria-pressed="true"] {
                background-color: rgba(52, 152, 219, 0.8) !important;
                box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.2);
            }
            
            /* Button press ripple effect */
            .control-button::after {
                content: '';
                position: absolute;
                top: 50%;
                left: 50%;
                width: 0;
                height: 0;
                border-radius: 50%;
                background: rgba(255, 255, 255, 0.3);
                transform: translate(-50%, -50%);
                transition: width 0.3s, height 0.3s;
            }
            .control-button:active::after {
                width: 100%;
                height: 100%;
            }
            
            /* Success feedback animation */
            .success-feedback {
                animation: successPulse 0.6s ease-in-out;
            }
            @keyframes successPulse {
                0% { opacity: 0; transform: scale(0.8); }
                50% { opacity: 1; transform: scale(1.1); }
                100% { opacity: 1; transform: scale(1); }
            }
            
            /* Blocked feedback animation */
            .blocked-feedback {
                animation: blockedPulse 0.5s ease-in-out;
            }
            @keyframes blockedPulse {
                0% { opacity: 0; transform: scale(0.9) translateY(10px); }
                100% { opacity: 1; transform: scale(1) translateY(0); }
            }
            
            /* Responsive design support for smooth size transitions */
            @media (max-width: 767px) {
                .robot-game-container {
                    padding: 10px;
                }
            }
            @media (min-width: 768px) and (max-width: 1023px) {
                .robot-game-container {
                    padding: 15px;
                }
            }
            @media (min-width: 1024px) {
                .robot-game-container {
                    padding: 20px;
                }
            }
            
            /* High contrast mode support */
            @media (prefers-contrast: high) {
                .control-button {
                    border-width: 3px !important;
                }
                .grid-cell {
                    border-width: 3px !important;
                }
                .control-button:focus {
                    outline-width: 4px !important;
                }
            }
            
            /* Reduced motion support */
            @media (prefers-reduced-motion: reduce) {
                .robot-rotating,
                .robot-moving,
                .robot-blocked,
                .robot-success,
                .control-button,
                .grid-cell,
                .success-feedback,
                .blocked-feedback {
                    animation: none !important;
                    transition: none !important;
                }
            }
            
            /* Enhanced focus management for keyboard users */
            .keyboard-user .control-button:focus {
                outline: 3px solid rgba(52, 152, 219, 0.8);
                outline-offset: 3px;
                box-shadow: 0 0 0 1px rgba(255, 255, 255, 0.8), 0 0 0 4px rgba(52, 152, 219, 0.3);
            }
            
            /* Skip link for screen readers */
            .skip-link {
                position: absolute;
                top: -40px;
                left: 6px;
                background: #000;
                color: #fff;
                padding: 8px;
                text-decoration: none;
                z-index: 1000;
                border-radius: 4px;
                font-weight: bold;
                transition: all 0.2s ease-in-out;
            }
            .skip-link:focus {
                top: 6px;
                outline: 2px solid #fff;
                outline-offset: 2px;
            }
            
            /* Consistent visual design for all interactive elements */
            .interactive-element {
                transition: all 0.2s ease-in-out;
                cursor: pointer;
            }
            .interactive-element:hover {
                transform: translateY(-1px);
                box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
            }
            .interactive-element:active {
                transform: translateY(0);
                box-shadow: 0 1px 4px rgba(0, 0, 0, 0.1);
            }
            
            /* Enhanced visual feedback for state changes */
            .state-change-feedback {
                animation: stateChangePulse 0.4s ease-in-out;
            }
            @keyframes stateChangePulse {
                0% { opacity: 0; transform: scale(0.95); }
                50% { opacity: 1; transform: scale(1.02); }
                100% { opacity: 1; transform: scale(1); }
            }
            </style>
            """
    in
    Html.div []
        [ Html.node "style" [] [ Html.text globalAnimationStyles ]
        , Html.a
            [ Html.Attributes.href "#main-content"
            , Html.Attributes.class "skip-link"
            , Html.Attributes.attribute "aria-label" "Skip to main content"
            ]
            [ Html.text "Skip to main content" ]
        , Element.layout
            [ Background.color theme.backgroundColor
            , Font.color theme.fontColor
            , Element.htmlAttribute (Html.Attributes.attribute "role" "application")
            , Element.htmlAttribute (Html.Attributes.attribute "aria-label" "Robot Grid Game")
            , Element.htmlAttribute (Html.Attributes.attribute "lang" "en")
            ]
          <|
            Element.el
                [ Element.centerX
                , Element.centerY
                , Background.color theme.gridBackgroundColor
                , Font.color theme.fontColor
                , Font.bold
                , Font.size (getResponsiveFontSize model.maybeWindow 32)
                , Element.padding (getResponsivePadding model.maybeWindow 20)
                , Element.spacing (getResponsiveSpacing model.maybeWindow 15)
                , Element.htmlAttribute (Html.Attributes.class "robot-game-container")
                , Element.htmlAttribute (Html.Attributes.attribute "role" "main")
                , Element.htmlAttribute (Html.Attributes.id "main-content")
                , Element.htmlAttribute (Html.Attributes.tabindex -1)
                ]
                (Element.column [ Element.spacing (getResponsiveSpacing model.maybeWindow 15) ]
                    [ -- Header section with title and navigation
                      Element.row
                        [ Element.width Element.fill
                        , Element.height (Element.px (getResponsiveFontSize model.maybeWindow 70))
                        , Element.padding (getResponsivePadding model.maybeWindow 15)
                        , Background.color theme.headerBackgroundColor
                        , Element.centerX
                        , Element.Border.rounded 8
                        , Element.Border.width 2
                        , Element.Border.color theme.borderColor
                        , Element.htmlAttribute (Html.Attributes.attribute "role" "banner")
                        , Element.htmlAttribute (Html.Attributes.class "state-change-feedback")
                        , Element.spacing (getResponsiveSpacing model.maybeWindow 15)
                        ]
                        [ -- Back to Home button
                          Element.el [ Element.alignLeft ] <|
                            viewBackToHomeButton model
                        , Element.el
                            [ Element.centerX
                            , Font.color theme.fontColor
                            , Font.size (getResponsiveFontSize model.maybeWindow 28)
                            , Element.htmlAttribute (Html.Attributes.attribute "role" "heading")
                            , Element.htmlAttribute (Html.Attributes.attribute "aria-level" "1")
                            ]
                            (Element.text "Robot Grid Game")
                        , Element.el [ Element.alignRight ] Element.none -- Spacer for balance
                        ]

                    -- Game status announcement for screen readers
                    , viewGameStatus model

                    -- Game grid section
                    , Element.el
                        [ Element.centerX
                        , Background.color theme.borderColor
                        , Element.padding (getResponsivePadding model.maybeWindow 10)
                        , Element.htmlAttribute (Html.Attributes.attribute "role" "region")
                        , Element.htmlAttribute (Html.Attributes.attribute "aria-label" "Game grid")
                        ]
                        (viewGrid model)

                    -- Success movement feedback
                    , viewSuccessMovementFeedback model

                    -- Blocked movement feedback
                    , viewBlockedMovementFeedback model

                    -- Control buttons section
                    , viewControlButtons model
                    ]
                )
        ]


{-| Render the 5x5 grid with the robot
-}
viewGrid : Model -> Element Main.Msg
viewGrid model =
    Element.column
        [ Element.spacing (getResponsiveSpacing model.maybeWindow 5)
        , Element.htmlAttribute (Html.Attributes.attribute "role" "grid")
        , Element.htmlAttribute (Html.Attributes.attribute "aria-label" "5x5 robot navigation grid")
        , Element.htmlAttribute (Html.Attributes.attribute "aria-rowcount" "5")
        , Element.htmlAttribute (Html.Attributes.attribute "aria-colcount" "5")
        ]
        (List.range 0 (model.gridSize - 1)
            |> List.map (viewRow model)
        )


{-| Render a single row of the grid
-}
viewRow : Model -> Int -> Element Main.Msg
viewRow model rowIndex =
    Element.row
        [ Element.spacing (getResponsiveSpacing model.maybeWindow 5)
        , Element.htmlAttribute (Html.Attributes.attribute "role" "row")
        , Element.htmlAttribute (Html.Attributes.attribute "aria-rowindex" (String.fromInt (rowIndex + 1)))
        ]
        (List.range 0 (model.gridSize - 1)
            |> List.map (viewCell model rowIndex)
        )


{-| Render a single cell of the grid, with robot if present
-}
viewCell : Model -> Int -> Int -> Element Main.Msg
viewCell model rowIndex colIndex =
    let
        theme : Theme
        theme =
            currentTheme model.colorScheme

        cellSize : Int
        cellSize =
            calculateResponsiveCellSize model.maybeWindow 7 120

        position : Position
        position =
            { row = rowIndex, col = colIndex }

        isRobotHere : Bool
        isRobotHere =
            model.robot.position == position

        isShowingBlockedFeedback : Bool
        isShowingBlockedFeedback =
            model.blockedMovementFeedback && model.animationState == BlockedMovement

        cellBackgroundColor : Color
        cellBackgroundColor =
            if isRobotHere && isShowingBlockedFeedback then
                theme.blockedMovementColor

            else if
                isRobotHere
                    || (case model.animationState of
                            Moving fromPos _ ->
                                fromPos == position

                            _ ->
                                False
                       )
            then
                theme.robotCellBackgroundColor

            else
                theme.cellBackgroundColor

        borderColor : Color
        borderColor =
            if isRobotHere && isShowingBlockedFeedback then
                theme.blockedMovementBorderColor

            else
                theme.borderColor

        cellAttributes : List (Element.Attr () msg)
        cellAttributes =
            [ Background.color cellBackgroundColor
            , Element.height (Element.px cellSize)
            , Element.width (Element.px cellSize)
            , Element.padding (getResponsivePadding model.maybeWindow 5)
            , Element.Border.width
                (if isRobotHere && isShowingBlockedFeedback then
                    3

                 else
                    2
                )
            , Element.Border.color borderColor
            , Element.htmlAttribute (Html.Attributes.class "grid-cell interactive-element")
            , Element.htmlAttribute
                (Html.Attributes.style "transition" "all 0.3s ease-in-out")
            , Element.htmlAttribute (Html.Attributes.attribute "role" "gridcell")
            , Element.htmlAttribute (Html.Attributes.attribute "aria-colindex" (String.fromInt (colIndex + 1)))
            , Element.htmlAttribute
                (Html.Attributes.attribute "aria-label"
                    (if isRobotHere then
                        "Robot at row " ++ String.fromInt (rowIndex + 1) ++ ", column " ++ String.fromInt (colIndex + 1) ++ ", facing " ++ directionToString model.robot.facing

                     else
                        "Empty cell at row " ++ String.fromInt (rowIndex + 1) ++ ", column " ++ String.fromInt (colIndex + 1)
                    )
                )
            ]

        directionToString : Direction -> String
        directionToString direction =
            case direction of
                North ->
                    "North"

                South ->
                    "South"

                East ->
                    "East"

                West ->
                    "West"
    in
    Element.el cellAttributes
        (if isRobotHere then
            viewRobot model

         else
            Element.none
        )


{-| Render the robot with directional indicator and smooth animations
-}
viewRobot : Model -> Element Main.Msg
viewRobot model =
    let
        theme : Theme
        theme =
            currentTheme model.colorScheme

        -- Calculate the rotation angle based on direction and animation state
        ( rotationAngle, animationClass ) =
            case model.animationState of
                Rotating _ toDirection ->
                    -- During rotation animation, show the target direction with animation
                    let
                        targetAngle =
                            case toDirection of
                                North ->
                                    "0"

                                East ->
                                    "90"

                                South ->
                                    "180"

                                West ->
                                    "270"
                    in
                    ( targetAngle, "robot-rotating" )

                Moving _ _ ->
                    -- During movement animation, show current direction with success animation
                    let
                        currentAngle =
                            case model.robot.facing of
                                North ->
                                    "0"

                                East ->
                                    "90"

                                South ->
                                    "180"

                                West ->
                                    "270"
                    in
                    ( currentAngle, "robot-success" )

                BlockedMovement ->
                    -- During blocked movement, show shake animation
                    let
                        currentAngle =
                            case model.robot.facing of
                                North ->
                                    "0"

                                East ->
                                    "90"

                                South ->
                                    "180"

                                West ->
                                    "270"
                    in
                    ( currentAngle, "robot-blocked" )

                Idle ->
                    -- No animation, show current direction
                    let
                        currentAngle =
                            case model.robot.facing of
                                North ->
                                    "0"

                                East ->
                                    "90"

                                South ->
                                    "180"

                                West ->
                                    "270"
                    in
                    ( currentAngle, "" )
    in
    Element.el
        [ Element.centerX
        , Element.centerY
        , Element.width Element.fill
        , Element.height Element.fill
        , Element.htmlAttribute (Html.Attributes.attribute "role" "img")
        , Element.htmlAttribute
            (Html.Attributes.attribute "aria-label"
                ("Robot facing "
                    ++ (case model.robot.facing of
                            North ->
                                "North"

                            South ->
                                "South"

                            East ->
                                "East"

                            West ->
                                "West"
                       )
                    ++ (case model.animationState of
                            Moving _ _ ->
                                ", currently moving"

                            Rotating _ _ ->
                                ", currently rotating"

                            BlockedMovement ->
                                ", movement blocked"

                            Idle ->
                                ""
                       )
                )
            )
        ]
    <|
        Element.html <|
            Svg.svg
                [ SvgAttr.viewBox "0 0 100 100"
                , SvgAttr.width "100%"
                , SvgAttr.height "100%"
                , SvgAttr.class animationClass
                ]
                [ Svg.g
                    [ SvgAttr.transform ("rotate(" ++ rotationAngle ++ " 50 50)")
                    , SvgAttr.style "transition: transform 0.2s ease-in-out;"
                    ]
                    [ -- Robot body (circle)
                      Svg.circle
                        [ SvgAttr.cx "50"
                        , SvgAttr.cy "50"
                        , SvgAttr.r "25"
                        , SvgAttr.fill theme.robotBodyColorHex
                        , SvgAttr.stroke theme.borderColorHex
                        , SvgAttr.strokeWidth "2"
                        ]
                        []

                    -- Directional arrow pointing up (North)
                    , Svg.polygon
                        [ SvgAttr.points "50,20 40,40 60,40"
                        , SvgAttr.fill theme.robotDirectionColorHex
                        , SvgAttr.stroke theme.borderColorHex
                        , SvgAttr.strokeWidth "1"
                        ]
                        []

                    -- Robot "eyes" for additional visual clarity
                    , Svg.circle
                        [ SvgAttr.cx "45"
                        , SvgAttr.cy "45"
                        , SvgAttr.r "3"
                        , SvgAttr.fill theme.iconColorHex
                        ]
                        []
                    , Svg.circle
                        [ SvgAttr.cx "55"
                        , SvgAttr.cy "45"
                        , SvgAttr.r "3"
                        , SvgAttr.fill theme.iconColorHex
                        ]
                        []
                    ]
                ]


{-| Back to Home button for navigation to landing page
-}
viewBackToHomeButton : Model -> Element Main.Msg
viewBackToHomeButton model =
    let
        theme : Theme
        theme =
            currentTheme model.colorScheme
    in
    Element.el
        [ Element.Events.onClick (Main.NavigateToRoute Route.Landing)
        , Element.pointer
        , Element.mouseOver [ Background.color theme.buttonHoverColor ]
        , Element.padding 8
        , Background.color theme.buttonBackgroundColor
        , Element.Border.rounded 4
        , Font.color theme.buttonTextColor
        , Font.size (getResponsiveFontSize model.maybeWindow 14)
        , Element.htmlAttribute (Html.Attributes.attribute "aria-label" "Navigate back to home page")
        ]
        (Element.text "← Home")


{-| Render the control buttons section with movement and rotation controls
-}
viewControlButtons : Model -> Element Main.Msg
viewControlButtons model =
    let
        theme : Theme
        theme =
            currentTheme model.colorScheme

        screenSize : ScreenSize
        screenSize =
            getScreenSize model.maybeWindow

        buttonSize : Int
        buttonSize =
            case screenSize of
                Mobile ->
                    60

                Tablet ->
                    70

                Desktop ->
                    80

        buttonSpacing : Int
        buttonSpacing =
            getResponsiveSpacing model.maybeWindow 10

        canMove : Bool
        canMove =
            RobotGame.canMoveForward model.robot && model.animationState == Idle
    in
    Element.column
        [ Element.centerX
        , Element.spacing buttonSpacing
        , Element.padding (getResponsivePadding model.maybeWindow 20)
        , Element.htmlAttribute (Html.Attributes.attribute "role" "region")
        , Element.htmlAttribute (Html.Attributes.attribute "aria-label" "Robot controls")
        ]
        [ -- Movement controls section
          Element.column
            [ Element.centerX
            , Element.spacing (buttonSpacing // 2)
            , Element.htmlAttribute (Html.Attributes.attribute "role" "group")
            , Element.htmlAttribute (Html.Attributes.attribute "aria-labelledby" "movement-heading")
            ]
            [ Element.el
                [ Element.centerX
                , Font.size (getResponsiveFontSize model.maybeWindow 18)
                , Font.color theme.fontColor
                , Font.bold
                , Element.htmlAttribute (Html.Attributes.id "movement-heading")
                , Element.htmlAttribute (Html.Attributes.attribute "role" "heading")
                , Element.htmlAttribute (Html.Attributes.attribute "aria-level" "2")
                ]
                (Element.text "Movement")
            , viewForwardButton model canMove buttonSize
            ]

        -- Rotation controls section
        , Element.column
            [ Element.centerX
            , Element.spacing (buttonSpacing // 2)
            , Element.htmlAttribute (Html.Attributes.attribute "role" "group")
            , Element.htmlAttribute (Html.Attributes.attribute "aria-labelledby" "rotation-heading")
            ]
            [ Element.el
                [ Element.centerX
                , Font.size (getResponsiveFontSize model.maybeWindow 18)
                , Font.color theme.fontColor
                , Font.bold
                , Element.htmlAttribute (Html.Attributes.id "rotation-heading")
                , Element.htmlAttribute (Html.Attributes.attribute "role" "heading")
                , Element.htmlAttribute (Html.Attributes.attribute "aria-level" "2")
                ]
                (Element.text "Rotation")
            , Element.row
                [ Element.centerX
                , Element.spacing buttonSpacing
                , Element.htmlAttribute (Html.Attributes.attribute "role" "group")
                , Element.htmlAttribute (Html.Attributes.attribute "aria-label" "Rotation buttons")
                ]
                [ viewRotateLeftButton model buttonSize
                , viewRotateRightButton model buttonSize
                ]
            ]

        -- Directional controls section
        , Element.column
            [ Element.centerX
            , Element.spacing (buttonSpacing // 2)
            , Element.htmlAttribute (Html.Attributes.attribute "role" "group")
            , Element.htmlAttribute (Html.Attributes.attribute "aria-labelledby" "direction-heading")
            ]
            [ Element.el
                [ Element.centerX
                , Font.size (getResponsiveFontSize model.maybeWindow 18)
                , Font.color theme.fontColor
                , Font.bold
                , Element.htmlAttribute (Html.Attributes.id "direction-heading")
                , Element.htmlAttribute (Html.Attributes.attribute "role" "heading")
                , Element.htmlAttribute (Html.Attributes.attribute "aria-level" "2")
                ]
                (Element.text "Face Direction")
            , viewDirectionalButtons model buttonSize buttonSpacing
            ]

        -- Keyboard instructions
        , Element.column
            [ Element.centerX
            , Element.padding (getResponsivePadding model.maybeWindow 10)
            , Element.spacing 5
            , Font.size (getResponsiveFontSize model.maybeWindow 14)
            , Font.color theme.secondaryFontColor
            , Element.htmlAttribute (Html.Attributes.attribute "role" "region")
            , Element.htmlAttribute (Html.Attributes.attribute "aria-labelledby" "keyboard-instructions-heading")
            ]
            [ Element.el
                [ Element.centerX
                , Font.bold
                , Element.htmlAttribute (Html.Attributes.id "keyboard-instructions-heading")
                , Element.htmlAttribute (Html.Attributes.attribute "role" "heading")
                , Element.htmlAttribute (Html.Attributes.attribute "aria-level" "3")
                ]
                (Element.text "Keyboard Controls")
            , Element.column
                [ Element.centerX
                , Element.spacing 3
                , Element.htmlAttribute (Html.Attributes.attribute "role" "list")
                ]
                [ Element.el
                    [ Element.htmlAttribute (Html.Attributes.attribute "role" "listitem") ]
                    (Element.text "↑ Arrow Up: Move forward")
                , Element.el
                    [ Element.htmlAttribute (Html.Attributes.attribute "role" "listitem") ]
                    (Element.text "← Arrow Left: Rotate left")
                , Element.el
                    [ Element.htmlAttribute (Html.Attributes.attribute "role" "listitem") ]
                    (Element.text "→ Arrow Right: Rotate right")
                , Element.el
                    [ Element.htmlAttribute (Html.Attributes.attribute "role" "listitem") ]
                    (Element.text "↓ Arrow Down: Turn around")
                ]
            ]
        ]


{-| Render the forward movement button
-}
viewForwardButton : Model -> Bool -> Int -> Element Main.Msg
viewForwardButton model canMove buttonSize =
    let
        theme : Theme
        theme =
            currentTheme model.colorScheme

        isShowingBlockedFeedback : Bool
        isShowingBlockedFeedback =
            model.blockedMovementFeedback && model.animationState == BlockedMovement

        buttonColor : Color
        buttonColor =
            if isShowingBlockedFeedback then
                theme.buttonBlockedColor

            else if canMove then
                theme.buttonBackgroundColor

            else
                theme.buttonDisabledColor

        textColor : Color
        textColor =
            if isShowingBlockedFeedback then
                theme.buttonBlockedTextColor

            else if canMove then
                theme.buttonTextColor

            else
                theme.buttonDisabledTextColor

        borderColor : Color
        borderColor =
            if isShowingBlockedFeedback then
                theme.blockedMovementBorderColor

            else
                theme.borderColor

        buttonAttributes : List (Element.Attr () Main.Msg)
        buttonAttributes =
            [ Element.width (Element.px buttonSize)
            , Element.height (Element.px buttonSize)
            , Background.color buttonColor
            , Element.Border.rounded 8
            , Element.Border.width
                (if isShowingBlockedFeedback then
                    3

                 else
                    2
                )
            , Element.Border.color borderColor
            , Font.color textColor
            , Font.size (getResponsiveFontSize model.maybeWindow 16)
            , Font.bold
            , Element.centerX
            , Element.centerY
            , Element.htmlAttribute (Html.Attributes.class "control-button")
            , Element.htmlAttribute (Html.Attributes.attribute "role" "button")
            , Element.htmlAttribute
                (Html.Attributes.attribute "aria-label"
                    (if canMove && not isShowingBlockedFeedback then
                        "Move robot forward (Arrow Up key)"

                     else if isShowingBlockedFeedback then
                        "Cannot move forward - robot is at boundary"

                     else
                        "Move robot forward - currently blocked by boundary"
                    )
                )
            , Element.htmlAttribute (Html.Attributes.attribute "aria-describedby" "forward-button-help")
            , Element.htmlAttribute (Html.Attributes.tabindex 0)
            , Element.htmlAttribute (Html.Attributes.attribute "aria-keyshortcuts" "ArrowUp")
            ]
                ++ (if canMove && not isShowingBlockedFeedback then
                        [ Element.Events.onClick Main.MoveForward
                        , Element.mouseOver [ Background.color theme.buttonHoverColor ]
                        , Element.focused [ Background.color theme.buttonPressedColor ]
                        , Element.pointer
                        ]

                    else if not canMove && not isShowingBlockedFeedback then
                        [ Element.Events.onClick Main.MoveForward -- Allow clicking to show blocked feedback
                        , Element.pointer
                        ]

                    else
                        []
                   )

        buttonLabel : String
        buttonLabel =
            if isShowingBlockedFeedback then
                "✗"

            else
                "↑"
    in
    Element.column
        [ Element.centerX
        , Element.spacing 5
        ]
        [ Input.button buttonAttributes
            { onPress =
                if canMove && not isShowingBlockedFeedback then
                    Just Main.MoveForward

                else if not canMove && not isShowingBlockedFeedback then
                    Just Main.MoveForward
                    -- This will trigger blocked feedback

                else
                    Nothing
            , label =
                Element.el
                    [ Element.centerX
                    , Element.centerY
                    ]
                    (Element.text buttonLabel)
            }
        , Element.el
            [ Element.htmlAttribute (Html.Attributes.id "forward-button-help")
            , Element.htmlAttribute (Html.Attributes.style "position" "absolute")
            , Element.htmlAttribute (Html.Attributes.style "left" "-10000px")
            , Element.htmlAttribute (Html.Attributes.style "width" "1px")
            , Element.htmlAttribute (Html.Attributes.style "height" "1px")
            , Element.htmlAttribute (Html.Attributes.style "overflow" "hidden")
            ]
            (Element.text "Moves the robot one cell forward in the direction it is facing")
        ]


{-| Render the rotate left button
-}
viewRotateLeftButton : Model -> Int -> Element Main.Msg
viewRotateLeftButton model buttonSize =
    let
        theme : Theme
        theme =
            currentTheme model.colorScheme

        canRotate : Bool
        canRotate =
            model.animationState == Idle

        buttonColor : Color
        buttonColor =
            if canRotate then
                theme.buttonBackgroundColor

            else
                theme.buttonDisabledColor

        textColor : Color
        textColor =
            if canRotate then
                theme.buttonTextColor

            else
                theme.buttonDisabledTextColor

        buttonAttributes : List (Element.Attr () Main.Msg)
        buttonAttributes =
            [ Element.width (Element.px buttonSize)
            , Element.height (Element.px buttonSize)
            , Background.color buttonColor
            , Element.Border.rounded 8
            , Element.Border.width 2
            , Element.Border.color theme.borderColor
            , Font.color textColor
            , Font.size (getResponsiveFontSize model.maybeWindow 16)
            , Font.bold
            , Element.centerX
            , Element.centerY
            , Element.htmlAttribute (Html.Attributes.class "control-button")
            , Element.htmlAttribute (Html.Attributes.attribute "role" "button")
            , Element.htmlAttribute
                (Html.Attributes.attribute "aria-label"
                    (if canRotate then
                        "Rotate robot left (Left Arrow key)"

                     else
                        "Rotate robot left - currently disabled during animation"
                    )
                )
            , Element.htmlAttribute (Html.Attributes.tabindex 0)
            , Element.htmlAttribute (Html.Attributes.disabled (not canRotate))
            , Element.htmlAttribute (Html.Attributes.attribute "aria-keyshortcuts" "ArrowLeft")
            ]
                ++ (if canRotate then
                        [ Element.Events.onClick Main.RotateLeft
                        , Element.mouseOver [ Background.color theme.buttonHoverColor ]
                        , Element.focused [ Background.color theme.buttonPressedColor ]
                        , Element.pointer
                        ]

                    else
                        []
                   )
    in
    Input.button buttonAttributes
        { onPress =
            if canRotate then
                Just Main.RotateLeft

            else
                Nothing
        , label =
            Element.el
                [ Element.centerX
                , Element.centerY
                ]
                (Element.text "↺")
        }


{-| Render the rotate right button
-}
viewRotateRightButton : Model -> Int -> Element Main.Msg
viewRotateRightButton model buttonSize =
    let
        theme : Theme
        theme =
            currentTheme model.colorScheme

        canRotate : Bool
        canRotate =
            model.animationState == Idle

        buttonColor : Color
        buttonColor =
            if canRotate then
                theme.buttonBackgroundColor

            else
                theme.buttonDisabledColor

        textColor : Color
        textColor =
            if canRotate then
                theme.buttonTextColor

            else
                theme.buttonDisabledTextColor

        buttonAttributes : List (Element.Attr () Main.Msg)
        buttonAttributes =
            [ Element.width (Element.px buttonSize)
            , Element.height (Element.px buttonSize)
            , Background.color buttonColor
            , Element.Border.rounded 8
            , Element.Border.width 2
            , Element.Border.color theme.borderColor
            , Font.color textColor
            , Font.size (getResponsiveFontSize model.maybeWindow 16)
            , Font.bold
            , Element.centerX
            , Element.centerY
            , Element.htmlAttribute (Html.Attributes.class "control-button")
            , Element.htmlAttribute (Html.Attributes.attribute "role" "button")
            , Element.htmlAttribute
                (Html.Attributes.attribute "aria-label"
                    (if canRotate then
                        "Rotate robot right (Right Arrow key)"

                     else
                        "Rotate robot right - currently disabled during animation"
                    )
                )
            , Element.htmlAttribute (Html.Attributes.tabindex 0)
            , Element.htmlAttribute (Html.Attributes.disabled (not canRotate))
            , Element.htmlAttribute (Html.Attributes.attribute "aria-keyshortcuts" "ArrowRight")
            ]
                ++ (if canRotate then
                        [ Element.Events.onClick Main.RotateRight
                        , Element.mouseOver [ Background.color theme.buttonHoverColor ]
                        , Element.focused [ Background.color theme.buttonPressedColor ]
                        , Element.pointer
                        ]

                    else
                        []
                   )
    in
    Input.button buttonAttributes
        { onPress =
            if canRotate then
                Just Main.RotateRight

            else
                Nothing
        , label =
            Element.el
                [ Element.centerX
                , Element.centerY
                ]
                (Element.text "↻")
        }


{-| Render the directional buttons (N, S, E, W)
-}
viewDirectionalButtons : Model -> Int -> Int -> Element Main.Msg
viewDirectionalButtons model buttonSize buttonSpacing =
    let
        theme : Theme
        theme =
            currentTheme model.colorScheme

        canRotate : Bool
        canRotate =
            model.animationState == Idle

        currentDirection : Direction
        currentDirection =
            model.robot.facing

        directionButton : Direction -> String -> Element Main.Msg
        directionButton direction label =
            let
                isCurrentDirection : Bool
                isCurrentDirection =
                    currentDirection == direction

                buttonColor : Color
                buttonColor =
                    if canRotate then
                        if isCurrentDirection then
                            theme.buttonPressedColor

                        else
                            theme.buttonBackgroundColor

                    else
                        theme.buttonDisabledColor

                textColor : Color
                textColor =
                    if canRotate then
                        theme.buttonTextColor

                    else
                        theme.buttonDisabledTextColor

                directionName : String
                directionName =
                    case direction of
                        North ->
                            "North"

                        South ->
                            "South"

                        East ->
                            "East"

                        West ->
                            "West"

                buttonAttributes : List (Element.Attr () Main.Msg)
                buttonAttributes =
                    [ Element.width (Element.px (buttonSize - 10))
                    , Element.height (Element.px (buttonSize - 10))
                    , Background.color buttonColor
                    , Element.Border.rounded 6
                    , Element.Border.width 2
                    , Element.Border.color theme.borderColor
                    , Font.color textColor
                    , Font.size (getResponsiveFontSize model.maybeWindow 14)
                    , Font.bold
                    , Element.centerX
                    , Element.centerY
                    , Element.htmlAttribute (Html.Attributes.class "control-button")
                    , Element.htmlAttribute (Html.Attributes.attribute "role" "button")
                    , Element.htmlAttribute
                        (Html.Attributes.attribute "aria-label"
                            (if isCurrentDirection then
                                "Robot is currently facing " ++ directionName

                             else if canRotate then
                                "Rotate robot to face " ++ directionName

                             else
                                "Rotate robot to face " ++ directionName ++ " - currently disabled during animation"
                            )
                        )
                    , Element.htmlAttribute
                        (Html.Attributes.attribute "aria-pressed"
                            (if isCurrentDirection then
                                "true"

                             else
                                "false"
                            )
                        )
                    , Element.htmlAttribute (Html.Attributes.tabindex 0)
                    , Element.htmlAttribute (Html.Attributes.disabled (not canRotate || isCurrentDirection))
                    , Element.htmlAttribute (Html.Attributes.attribute "aria-describedby" ("direction-" ++ String.toLower directionName ++ "-help"))
                    ]
                        ++ (if canRotate && not isCurrentDirection then
                                [ Element.Events.onClick (Main.RotateToDirection direction)
                                , Element.mouseOver [ Background.color theme.buttonHoverColor ]
                                , Element.focused [ Background.color theme.buttonPressedColor ]
                                , Element.pointer
                                ]

                            else
                                []
                           )
            in
            Element.column
                [ Element.centerX
                , Element.spacing 2
                ]
                [ Input.button buttonAttributes
                    { onPress =
                        if canRotate && not isCurrentDirection then
                            Just (Main.RotateToDirection direction)

                        else
                            Nothing
                    , label =
                        Element.el
                            [ Element.centerX
                            , Element.centerY
                            ]
                            (Element.text label)
                    }
                , Element.el
                    [ Element.htmlAttribute (Html.Attributes.id ("direction-" ++ String.toLower directionName ++ "-help"))
                    , Element.htmlAttribute (Html.Attributes.style "position" "absolute")
                    , Element.htmlAttribute (Html.Attributes.style "left" "-10000px")
                    , Element.htmlAttribute (Html.Attributes.style "width" "1px")
                    , Element.htmlAttribute (Html.Attributes.style "height" "1px")
                    , Element.htmlAttribute (Html.Attributes.style "overflow" "hidden")
                    ]
                    (Element.text ("Rotate robot to face " ++ directionName ++ " direction"))
                ]
    in
    Element.column
        [ Element.centerX
        , Element.spacing (buttonSpacing // 2)
        , Element.htmlAttribute (Html.Attributes.attribute "role" "group")
        , Element.htmlAttribute (Html.Attributes.attribute "aria-label" "Directional buttons")
        ]
        [ -- North button
          Element.el
            [ Element.centerX
            , Element.htmlAttribute (Html.Attributes.attribute "aria-label" "North direction")
            ]
            (directionButton North "N")

        -- East and West buttons
        , Element.row
            [ Element.centerX
            , Element.spacing buttonSpacing
            , Element.htmlAttribute (Html.Attributes.attribute "role" "group")
            , Element.htmlAttribute (Html.Attributes.attribute "aria-label" "East and West directions")
            ]
            [ directionButton West "W"
            , directionButton East "E"
            ]

        -- South button
        , Element.el
            [ Element.centerX
            , Element.htmlAttribute (Html.Attributes.attribute "aria-label" "South direction")
            ]
            (directionButton South "S")
        ]


{-| Render game status for screen readers (hidden visually but available to assistive technology)
-}
viewGameStatus : Model -> Element Main.Msg
viewGameStatus model =
    let
        statusText =
            "Robot is at position row "
                ++ String.fromInt (model.robot.position.row + 1)
                ++ ", column "
                ++ String.fromInt (model.robot.position.col + 1)
                ++ " of 5, facing "
                ++ directionToString model.robot.facing
                ++ ". "
                ++ animationStatusToString model.animationState
                ++ " "
                ++ movementStatusToString model

        movementStatusToString : Model -> String
        movementStatusToString m =
            if RobotGame.canMoveForward m.robot then
                "Can move forward."

            else
                "Cannot move forward - at boundary."

        directionToString : Direction -> String
        directionToString direction =
            case direction of
                North ->
                    "North"

                South ->
                    "South"

                East ->
                    "East"

                West ->
                    "West"

        animationStatusToString : AnimationState -> String
        animationStatusToString animationState =
            case animationState of
                Idle ->
                    "Ready for commands."

                Moving _ _ ->
                    "Moving forward."

                Rotating _ _ ->
                    "Rotating."

                BlockedMovement ->
                    "Movement blocked by boundary."
    in
    Element.el
        [ Element.htmlAttribute (Html.Attributes.attribute "aria-live" "polite")
        , Element.htmlAttribute (Html.Attributes.attribute "aria-atomic" "true")
        , Element.htmlAttribute (Html.Attributes.style "position" "absolute")
        , Element.htmlAttribute (Html.Attributes.style "left" "-10000px")
        , Element.htmlAttribute (Html.Attributes.style "width" "1px")
        , Element.htmlAttribute (Html.Attributes.style "height" "1px")
        , Element.htmlAttribute (Html.Attributes.style "overflow" "hidden")
        ]
        (Element.text statusText)


{-| Render success movement feedback message
-}
viewSuccessMovementFeedback : Model -> Element Main.Msg
viewSuccessMovementFeedback model =
    let
        isShowingSuccessFeedback : Bool
        isShowingSuccessFeedback =
            case model.animationState of
                Moving _ _ ->
                    True

                Rotating _ _ ->
                    True

                _ ->
                    False
    in
    if isShowingSuccessFeedback then
        let
            theme : Theme
            theme =
                currentTheme model.colorScheme

            feedbackText =
                case model.animationState of
                    Moving fromPos toPos ->
                        "✓ Robot moved from row "
                            ++ String.fromInt (fromPos.row + 1)
                            ++ ", column "
                            ++ String.fromInt (fromPos.col + 1)
                            ++ " to row "
                            ++ String.fromInt (toPos.row + 1)
                            ++ ", column "
                            ++ String.fromInt (toPos.col + 1)

                    Rotating fromDir toDir ->
                        "✓ Robot rotated from "
                            ++ directionToStringHelper fromDir
                            ++ " to "
                            ++ directionToStringHelper toDir

                    _ ->
                        ""

            directionToStringHelper : Direction -> String
            directionToStringHelper direction =
                case direction of
                    North ->
                        "North"

                    South ->
                        "South"

                    East ->
                        "East"

                    West ->
                        "West"
        in
        Element.el
            [ Element.centerX
            , Element.padding (getResponsivePadding model.maybeWindow 10)
            , Background.color theme.accentColor
            , Element.Border.rounded 8
            , Element.Border.width 2
            , Element.Border.color theme.borderColor
            , Font.color theme.buttonTextColor
            , Font.size (getResponsiveFontSize model.maybeWindow 16)
            , Font.bold
            , Element.htmlAttribute (Html.Attributes.class "success-feedback")
            , Element.htmlAttribute (Html.Attributes.attribute "role" "status")
            , Element.htmlAttribute (Html.Attributes.attribute "aria-live" "polite")
            ]
            (Element.text feedbackText)

    else
        Element.none


{-| Render blocked movement feedback message
-}
viewBlockedMovementFeedback : Model -> Element Main.Msg
viewBlockedMovementFeedback model =
    let
        isShowingBlockedFeedback : Bool
        isShowingBlockedFeedback =
            model.blockedMovementFeedback && model.animationState == BlockedMovement
    in
    if isShowingBlockedFeedback then
        let
            theme : Theme
            theme =
                currentTheme model.colorScheme
        in
        Element.el
            [ Element.centerX
            , Element.padding (getResponsivePadding model.maybeWindow 10)
            , Background.color theme.blockedMovementColor
            , Element.Border.rounded 8
            , Element.Border.width 2
            , Element.Border.color theme.blockedMovementBorderColor
            , Font.color theme.buttonBlockedTextColor
            , Font.size (getResponsiveFontSize model.maybeWindow 16)
            , Font.bold
            , Element.htmlAttribute (Html.Attributes.class "blocked-feedback")
            , Element.htmlAttribute (Html.Attributes.attribute "role" "alert")
            , Element.htmlAttribute (Html.Attributes.attribute "aria-live" "assertive")
            ]
            (Element.text "⚠ Cannot move forward - boundary reached!")

    else
        Element.none

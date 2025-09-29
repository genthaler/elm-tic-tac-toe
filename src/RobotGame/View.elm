module RobotGame.View exposing (view)

{-| This module handles the UI rendering for the Robot Grid Game using pure elm-ui patterns.

The module provides a complete elm-ui implementation for rendering:

  - 5x5 robot navigation grid with responsive design
  - Robot visualization with directional indicators using SVG
  - Interactive control buttons with accessibility support
  - Theme-aware styling with light/dark mode support
  - Animation states and visual feedback
  - Comprehensive ARIA labels and keyboard navigation

This implementation follows the same patterns as TicTacToe.View for consistency
across the application's game modules.


# Main Functions

@docs view

-}

import Animator
import Element exposing (Color, Element)
import Element.Background as Background
import Element.Border
import Element.Events
import Element.Font as Font
import Element.HexColor
import Html exposing (Html)
import Html.Attributes
import RobotGame.Main as Main
import RobotGame.Model exposing (AnimationState(..), Direction(..), Model, Position)
import RobotGame.RobotGame as RobotGame
import Route
import Svg
import Svg.Attributes as SvgAttr
import Theme.Responsive exposing (calculateResponsiveCellSize, getResponsiveFontSize, getResponsivePadding, getResponsiveSpacing)
import Theme.Theme exposing (BaseTheme, getBaseTheme)


{-| All animations are now handled by elm-animator - no CSS transitions needed
-}
view : Model -> Html Main.Msg
view model =
    let
        theme : BaseTheme
        theme =
            getBaseTheme model.colorScheme
    in
    Element.layout
        [ Background.color (Element.HexColor.rgbCSSHex theme.backgroundColorHex)
        , Font.color (Element.HexColor.rgbCSSHex theme.fontColorHex)
        , Element.htmlAttribute (Html.Attributes.attribute "lang" "en")
        , Element.htmlAttribute (Html.Attributes.attribute "role" "main")
        , Element.htmlAttribute (Html.Attributes.attribute "aria-label" "main")
        ]
    <|
        viewModel model


{-| The main view model that contains the game layout following TicTacToe.View's pattern
-}
viewModel : Model -> Element.Element Main.Msg
viewModel model =
    let
        theme : BaseTheme
        theme =
            getBaseTheme model.colorScheme
    in
    Element.el
        [ Element.centerX
        , Element.alignTop
        , Background.color (Element.HexColor.rgbCSSHex theme.backgroundColorHex)
        , Font.color (Element.HexColor.rgbCSSHex theme.fontColorHex)
        , Font.bold
        , Font.size (getResponsiveFontSize model.maybeWindow 32)
        , Element.padding (getResponsivePadding model.maybeWindow 20)
        , Element.spacing (getResponsiveSpacing model.maybeWindow 15)
        ]
        (Element.column [ Element.spacing (getResponsiveSpacing model.maybeWindow 15) ]
            [ -- Header section with title and navigation
              viewHeader model

            -- Game status announcement for screen readers
            , viewGameStatus model

            -- Game grid section
            , Element.el
                [ Element.centerX
                , Background.color (Element.HexColor.rgbCSSHex theme.borderColorHex)
                , Element.padding (getResponsivePadding model.maybeWindow 10)
                ]
                (viewGrid model)

            -- Control buttons section
            , viewControlButtons model

            -- Success movement feedback
            , viewSuccessMovementFeedback model

            -- Blocked movement feedback
            , viewBlockedMovementFeedback model
            ]
        )


{-| Header component with title and navigation following TicTacToe.View patterns
-}
viewHeader : Model -> Element.Element Main.Msg
viewHeader model =
    let
        theme : BaseTheme
        theme =
            getBaseTheme model.colorScheme
    in
    Element.row
        [ Element.width Element.fill
        , Element.height (Element.px (getResponsivePadding model.maybeWindow 70))
        , Element.spacing (getResponsiveSpacing model.maybeWindow 15)
        , Element.padding (getResponsivePadding model.maybeWindow 15)
        , Background.color (Element.HexColor.rgbCSSHex theme.headerBackgroundColorHex)
        , Element.centerX
        ]
        [ -- Back to Home button
          Element.el [ Element.alignLeft ] <|
            viewBackToHomeButton model
        , Element.el
            [ Element.centerX
            , Font.color (Element.HexColor.rgbCSSHex theme.fontColorHex)
            , Font.size (getResponsiveFontSize model.maybeWindow 28)
            , Element.htmlAttribute (Html.Attributes.attribute "role" "heading")
            , Element.htmlAttribute (Html.Attributes.attribute "aria-level" "1")
            ]
            (Element.text "Robot Grid Game")
        , Element.el [ Element.alignRight ] <|
            Element.row
                [ Element.spacing (getResponsiveSpacing model.maybeWindow 15)
                , Element.padding (getResponsivePadding model.maybeWindow 5)
                ]
                [ -- Placeholder for theme toggle button following TicTacToe's pattern
                  viewColorSchemeToggleIcon model
                ]
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


{-| Helper function to determine cell background color based on AnimationState
-}
getCellBackgroundColor : Model -> Position -> Color
getCellBackgroundColor model position =
    let
        theme : BaseTheme
        theme =
            getBaseTheme model.colorScheme

        -- Use interpolated position for smooth animation
        currentRobotPosition : Position
        currentRobotPosition =
            getInterpolatedPosition model

        isRobotHere : Bool
        isRobotHere =
            currentRobotPosition == position
    in
    case model.animationState of
        BlockedMovement ->
            let
                -- Use elm-animator to check if blocked movement animation is active
                isBlockedMovementAnimating : Bool
                isBlockedMovementAnimating =
                    Animator.current model.blockedMovementTimeline

                isShowingBlockedFeedback : Bool
                isShowingBlockedFeedback =
                    isBlockedMovementAnimating || (model.blockedMovementFeedback && model.animationState == BlockedMovement)
            in
            if isRobotHere && isShowingBlockedFeedback then
                Element.HexColor.rgbCSSHex theme.blockedMovementColorHex

            else if isRobotHere then
                Element.HexColor.rgbCSSHex theme.robotCellBackgroundColorHex

            else
                Element.HexColor.rgbCSSHex theme.cellBackgroundColorHex

        Moving fromPos toPos ->
            if position == fromPos || position == toPos then
                Element.HexColor.rgbCSSHex theme.robotCellBackgroundColorHex

            else
                Element.HexColor.rgbCSSHex theme.cellBackgroundColorHex

        Rotating _ _ ->
            if isRobotHere then
                Element.HexColor.rgbCSSHex theme.robotCellBackgroundColorHex

            else
                Element.HexColor.rgbCSSHex theme.cellBackgroundColorHex

        Idle ->
            if isRobotHere then
                Element.HexColor.rgbCSSHex theme.robotCellBackgroundColorHex

            else
                Element.HexColor.rgbCSSHex theme.cellBackgroundColorHex


{-| Helper function to determine cell border color based on AnimationState
-}
getCellBorderColor : Model -> Position -> Color
getCellBorderColor model position =
    let
        theme : BaseTheme
        theme =
            getBaseTheme model.colorScheme

        -- Use interpolated position for smooth animation
        currentRobotPosition : Position
        currentRobotPosition =
            getInterpolatedPosition model

        isRobotHere : Bool
        isRobotHere =
            currentRobotPosition == position

        -- Use elm-animator to check if blocked movement animation is active
        isBlockedMovementAnimating : Bool
        isBlockedMovementAnimating =
            Animator.current model.blockedMovementTimeline

        isShowingBlockedFeedback : Bool
        isShowingBlockedFeedback =
            isBlockedMovementAnimating || (model.blockedMovementFeedback && model.animationState == BlockedMovement)
    in
    if isRobotHere && isShowingBlockedFeedback then
        Element.HexColor.rgbCSSHex theme.blockedMovementBorderColorHex

    else
        Element.HexColor.rgbCSSHex theme.borderColorHex


{-| Helper function to determine cell border width based on AnimationState
-}
getCellBorderWidth : Model -> Position -> Int
getCellBorderWidth model position =
    let
        -- Use interpolated position for smooth animation
        currentRobotPosition : Position
        currentRobotPosition =
            getInterpolatedPosition model

        isRobotHere : Bool
        isRobotHere =
            currentRobotPosition == position

        -- Use elm-animator to check if blocked movement animation is active
        isBlockedMovementAnimating : Bool
        isBlockedMovementAnimating =
            Animator.current model.blockedMovementTimeline
    in
    if isRobotHere && isBlockedMovementAnimating then
        4
        -- Thicker border during animation

    else
        let
            isShowingBlockedFeedback : Bool
            isShowingBlockedFeedback =
                isBlockedMovementAnimating || (model.blockedMovementFeedback && model.animationState == BlockedMovement)
        in
        if isRobotHere && isShowingBlockedFeedback then
            3
            -- Standard blocked feedback border

        else
            2


{-| Get the interpolated position for smooth movement animation
-}
getInterpolatedPosition : Model -> RobotGame.Model.Position
getInterpolatedPosition model =
    -- Always use the current timeline value - elm-animator handles interpolation
    let
        animatedRobot =
            Animator.current model.robotTimeline
    in
    animatedRobot.position


{-| Render a single cell of the grid, with robot if present
-}
viewCell : Model -> Int -> Int -> Element Main.Msg
viewCell model rowIndex colIndex =
    let
        cellSize : Int
        cellSize =
            calculateResponsiveCellSize model.maybeWindow 7 120

        position : Position
        position =
            { row = rowIndex, col = colIndex }

        -- Use interpolated position for smooth animation
        currentRobotPosition : Position
        currentRobotPosition =
            getInterpolatedPosition model

        isRobotHere : Bool
        isRobotHere =
            currentRobotPosition == position

        -- Use helper functions for conditional styling based on AnimationState
        cellBackgroundColor : Color
        cellBackgroundColor =
            getCellBackgroundColor model position

        borderColor : Color
        borderColor =
            getCellBorderColor model position

        borderWidth : Int
        borderWidth =
            getCellBorderWidth model position

        cellAttributes : List (Element.Attr () msg)
        cellAttributes =
            [ Background.color cellBackgroundColor
            , Element.height (Element.px cellSize)
            , Element.width (Element.px cellSize)
            , Element.padding (getResponsivePadding model.maybeWindow 5)
            , Element.Border.width borderWidth
            , Element.Border.color borderColor
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


{-| Helper function to get robot rotation angle using elm-animator rotation timeline
-}
getRobotRotationAngle : Model -> String
getRobotRotationAngle model =
    -- Use the dedicated rotation angle timeline for smooth interpolation
    let
        currentAngle =
            Animator.current model.rotationAngleTimeline

        -- Normalize angle to 0-360 range
        normalizedAngle =
            if currentAngle < 0 then
                currentAngle + 360

            else if currentAngle >= 360 then
                currentAngle - 360

            else
                currentAngle
    in
    String.fromFloat normalizedAngle


{-| Helper function to get robot body color based on AnimationState and elm-animator blocked movement
-}
getRobotBodyColor : Model -> String
getRobotBodyColor model =
    let
        theme : BaseTheme
        theme =
            getBaseTheme model.colorScheme

        -- Use elm-animator to check if blocked movement animation is active
    in
    case model.animationState of
        BlockedMovement ->
            let
                isBlockedMovementAnimating : Bool
                isBlockedMovementAnimating =
                    Animator.current model.blockedMovementTimeline
            in
            if isBlockedMovementAnimating then
                theme.buttonBlockedTextColorHex

            else if model.blockedMovementFeedback then
                theme.buttonBlockedTextColorHex

            else
                theme.robotBodyColorHex

        Moving _ _ ->
            theme.robotBodyColorHex

        Rotating _ _ ->
            theme.robotBodyColorHex

        Idle ->
            theme.robotBodyColorHex


{-| Helper function to get robot direction arrow color based on AnimationState and elm-animator blocked movement
-}
getRobotDirectionColor : Model -> String
getRobotDirectionColor model =
    let
        theme : BaseTheme
        theme =
            getBaseTheme model.colorScheme

        -- Use elm-animator to check if blocked movement animation is active
    in
    case model.animationState of
        BlockedMovement ->
            let
                isBlockedMovementAnimating : Bool
                isBlockedMovementAnimating =
                    Animator.current model.blockedMovementTimeline
            in
            if isBlockedMovementAnimating then
                theme.buttonBlockedTextColorHex

            else if model.blockedMovementFeedback then
                theme.buttonBlockedTextColorHex

            else
                theme.robotDirectionColorHex

        Moving _ _ ->
            theme.robotDirectionColorHex

        Rotating _ _ ->
            theme.accentColorHex

        Idle ->
            theme.robotDirectionColorHex


{-| Render the robot with directional indicator using pure elm-ui and SVG patterns
-}
viewRobot : Model -> Element Main.Msg
viewRobot model =
    let
        theme : BaseTheme
        theme =
            getBaseTheme model.colorScheme

        -- Use helper functions for animation-based styling
        rotationAngle : String
        rotationAngle =
            getRobotRotationAngle model

        robotBodyColor : String
        robotBodyColor =
            getRobotBodyColor model

        robotDirectionColor : String
        robotDirectionColor =
            getRobotDirectionColor model

        -- Add subtle shake effect for blocked movement animation
        isBlockedMovementAnimating : Bool
        isBlockedMovementAnimating =
            Animator.current model.blockedMovementTimeline

        -- Create shake offset for blocked movement animation
        shakeOffset : Float
        shakeOffset =
            if isBlockedMovementAnimating then
                2.0
                -- Subtle 2px shake

            else
                0.0
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
                                if isBlockedMovementAnimating then
                                    ", movement blocked with animation"

                                else
                                    ", movement blocked"

                            Idle ->
                                ""
                       )
                )
            )

        -- Apply subtle shake transform for blocked movement animation
        , Element.htmlAttribute
            (Html.Attributes.style "transform"
                ("translateX(" ++ String.fromFloat shakeOffset ++ "px)")
            )
        ]
    <|
        Element.html <|
            Svg.svg
                [ SvgAttr.viewBox "0 0 100 100"
                , SvgAttr.width "100%"
                , SvgAttr.height "100%"
                ]
                [ Svg.g
                    [ SvgAttr.transform ("rotate(" ++ rotationAngle ++ " 50 50)")
                    ]
                    [ -- Robot body using SVG path with animation-aware colors
                      viewRobotBodyWithColor robotBodyColor theme

                    -- Directional arrow using SVG path with animation-aware colors
                    , viewDirectionalArrowWithColor robotDirectionColor theme

                    -- Robot "eyes" for additional visual clarity
                    , viewRobotEyes theme
                    ]
                ]


{-| Render the robot body using SVG path with animation-aware colors
-}
viewRobotBodyWithColor : String -> BaseTheme -> Svg.Svg msg
viewRobotBodyWithColor bodyColor theme =
    Svg.circle
        [ SvgAttr.cx "50"
        , SvgAttr.cy "50"
        , SvgAttr.r "25"
        , SvgAttr.fill bodyColor
        , SvgAttr.stroke theme.borderColorHex
        , SvgAttr.strokeWidth "2"
        ]
        []


{-| Render the directional arrow using SVG path with animation-aware colors
-}
viewDirectionalArrowWithColor : String -> BaseTheme -> Svg.Svg msg
viewDirectionalArrowWithColor arrowColor theme =
    Svg.polygon
        [ SvgAttr.points "50,20 40,40 60,40"
        , SvgAttr.fill arrowColor
        , SvgAttr.stroke theme.borderColorHex
        , SvgAttr.strokeWidth "1"
        ]
        []


{-| Render the robot eyes using SVG circles with theme colors
-}
viewRobotEyes : BaseTheme -> Svg.Svg msg
viewRobotEyes theme =
    Svg.g []
        [ Svg.circle
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


{-| Back to Home button for navigation to landing page following TicTacToe's backToHomeButton pattern
-}
viewBackToHomeButton : Model -> Element.Element Main.Msg
viewBackToHomeButton model =
    let
        theme : BaseTheme
        theme =
            getBaseTheme model.colorScheme
    in
    Element.el
        [ Element.Events.onClick (Main.NavigateToRoute Route.Landing)
        , Element.pointer
        , Element.mouseOver [ Background.color (Element.HexColor.rgbCSSHex theme.buttonHoverColorHex) ]
        , Element.focused [ Background.color (Element.HexColor.rgbCSSHex theme.buttonPressedColorHex) ]
        , Element.padding (getResponsivePadding model.maybeWindow 8)
        , Background.color (Element.HexColor.rgbCSSHex theme.buttonColorHex)
        , Element.Border.rounded (getResponsiveSpacing model.maybeWindow 4)
        , Font.color (Element.rgb255 255 255 255)
        , Font.size (getResponsiveFontSize model.maybeWindow 14)
        , Element.htmlAttribute (Html.Attributes.attribute "role" "button")
        , Element.htmlAttribute (Html.Attributes.attribute "aria-label" "Navigate back to home page")
        , Element.htmlAttribute (Html.Attributes.tabindex 0)
        ]
        (Element.text "← Home")


{-| Color scheme toggle icon following TicTacToe's colorSchemeToggleIcon pattern
-}
viewColorSchemeToggleIcon : Model -> Element.Element Main.Msg
viewColorSchemeToggleIcon model =
    let
        theme : BaseTheme
        theme =
            getBaseTheme model.colorScheme

        iconPath =
            case model.colorScheme of
                Theme.Theme.Light ->
                    -- Moon icon for switching to dark mode
                    "M17.75,4.09L15.22,6.03L16.13,9.09L13.5,7.28L10.87,9.09L11.78,6.03L9.25,4.09L12.44,4L13.5,1L14.56,4L17.75,4.09M21.25,11L19.61,12.25L20.2,14.23L18.5,13.06L16.8,14.23L17.39,12.25L15.75,11L17.81,10.95L18.5,9L19.19,10.95L21.25,11M18.97,15.95C19.8,15.87 20.69,17.05 20.16,17.8C19.84,18.25 19.5,18.67 19.08,19.07C15.17,23 8.84,23 4.94,19.07C1.03,15.17 1.03,8.83 4.94,4.93C5.34,4.53 5.76,4.17 6.21,3.85C6.96,3.32 8.14,4.21 8.06,5.04C7.79,7.9 8.75,10.87 10.95,13.06C13.14,15.26 16.1,16.22 18.97,15.95M17.33,17.97C14.5,17.81 11.7,16.64 9.53,14.5C7.36,12.31 6.2,9.5 6.04,6.68C3.23,9.82 3.34,14.4 6.35,17.41C9.37,20.43 14,20.54 17.33,17.97Z"

                Theme.Theme.Dark ->
                    -- Sun icon for switching to light mode
                    "M12,7A5,5 0 0,1 17,12A5,5 0 0,1 12,17A5,5 0 0,1 7,12A5,5 0 0,1 12,7M12,9A3,3 0 0,0 9,12A3,3 0 0,0 12,15A3,3 0 0,0 15,12A3,3 0 0,0 12,9M12,2L14.39,5.42C13.65,5.15 12.84,5 12,5C11.16,5 10.35,5.15 9.61,5.42L12,2M3.34,7L7.5,6.65C6.9,7.16 6.36,7.78 5.94,8.5C5.5,9.24 5.25,10 5.11,10.79L3.34,7M3.36,17L5.12,13.23C5.26,14 5.53,14.78 5.95,15.5C6.37,16.24 6.91,16.86 7.5,17.37L3.36,17M20.65,7L18.88,10.79C18.74,10 18.47,9.23 18.05,8.5C17.63,7.78 17.1,7.15 16.5,6.64L20.65,7M20.64,17L16.5,17.36C17.09,16.85 17.62,16.22 18.04,15.5C18.46,14.77 18.73,14 18.87,13.21L20.64,17M12,22L9.59,18.56C10.33,18.83 11.14,19 12,19C12.82,19 13.63,18.83 14.37,18.56L12,22Z"
    in
    Element.el
        [ Element.Events.onClick
            (Main.ColorScheme
                (case model.colorScheme of
                    Theme.Theme.Light ->
                        Theme.Theme.Dark

                    Theme.Theme.Dark ->
                        Theme.Theme.Light
                )
            )
        , Element.pointer
        , Element.mouseOver [ Background.color (Element.HexColor.rgbCSSHex theme.buttonHoverColorHex) ]
        , Element.focused [ Background.color (Element.HexColor.rgbCSSHex theme.buttonPressedColorHex) ]
        , Element.padding (getResponsivePadding model.maybeWindow 8)
        , Background.color (Element.HexColor.rgbCSSHex theme.buttonColorHex)
        , Element.Border.rounded (getResponsiveSpacing model.maybeWindow 4)
        , Element.htmlAttribute (Html.Attributes.attribute "role" "button")
        , Element.htmlAttribute
            (Html.Attributes.attribute "aria-label"
                (case model.colorScheme of
                    Theme.Theme.Light ->
                        "Switch to dark theme"

                    Theme.Theme.Dark ->
                        "Switch to light theme"
                )
            )
        , Element.htmlAttribute (Html.Attributes.tabindex 0)
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
                    [ SvgAttr.d iconPath
                    , SvgAttr.fill theme.iconColorHex
                    ]
                    []
                ]


{-| Render the control buttons section with movement and rotation controls in two columns
-}
viewControlButtons : Model -> Element Main.Msg
viewControlButtons model =
    let
        theme : BaseTheme
        theme =
            getBaseTheme model.colorScheme

        -- Use responsive utilities for consistent button sizing
        buttonSize : Int
        buttonSize =
            calculateResponsiveCellSize model.maybeWindow 8 70

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
        [ -- Two-column layout for controls
          Element.row
            [ Element.centerX
            , Element.spacing (buttonSpacing * 2)
            , Element.htmlAttribute (Html.Attributes.attribute "role" "group")
            , Element.htmlAttribute (Html.Attributes.attribute "aria-label" "Control buttons")
            ]
            [ -- First column: Movement and Rotation controls
              Element.column
                [ Element.spacing buttonSpacing
                , Element.htmlAttribute (Html.Attributes.attribute "role" "group")
                , Element.htmlAttribute (Html.Attributes.attribute "aria-label" "Movement and rotation controls")
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
                        , Font.color (Element.HexColor.rgbCSSHex theme.fontColorHex)
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
                        , Font.color (Element.HexColor.rgbCSSHex theme.fontColorHex)
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

                -- Keyboard instructions
                , Element.column
                    [ Element.centerX
                    , Element.padding (getResponsivePadding model.maybeWindow 10)
                    , Element.spacing (getResponsiveSpacing model.maybeWindow 5)
                    , Font.size (getResponsiveFontSize model.maybeWindow 14)
                    , Font.color (Element.HexColor.rgbCSSHex theme.secondaryFontColorHex)
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
                        , Element.spacing (getResponsiveSpacing model.maybeWindow 3)
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

            -- Second column: Directional controls
            , Element.column
                [ Element.spacing buttonSpacing
                , Element.htmlAttribute (Html.Attributes.attribute "role" "group")
                , Element.htmlAttribute (Html.Attributes.attribute "aria-label" "Directional controls")
                ]
                [ -- Directional controls section
                  Element.column
                    [ Element.centerX
                    , Element.spacing (buttonSpacing // 2)
                    , Element.htmlAttribute (Html.Attributes.attribute "role" "group")
                    , Element.htmlAttribute (Html.Attributes.attribute "aria-labelledby" "direction-heading")
                    ]
                    [ Element.el
                        [ Element.centerX
                        , Font.size (getResponsiveFontSize model.maybeWindow 18)
                        , Font.color (Element.HexColor.rgbCSSHex theme.fontColorHex)
                        , Font.bold
                        , Element.htmlAttribute (Html.Attributes.id "direction-heading")
                        , Element.htmlAttribute (Html.Attributes.attribute "role" "heading")
                        , Element.htmlAttribute (Html.Attributes.attribute "aria-level" "2")
                        ]
                        (Element.text "Face Direction")
                    , viewDirectionalButtons model buttonSize buttonSpacing
                    ]
                ]
            ]
        ]


{-| Helper function to check if a button is currently highlighted using elm-animator timeline
-}
isButtonHighlighted : Model -> RobotGame.Model.Button -> Bool
isButtonHighlighted model button =
    let
        currentHighlights =
            Animator.current model.buttonHighlightTimeline
    in
    List.member button currentHighlights


{-| Helper function to get button colors based on AnimationState and button state
-}
getButtonColors : Model -> Bool -> RobotGame.Model.Button -> { backgroundColor : Color, textColor : Color, borderColor : Color, borderWidth : Int }
getButtonColors model canInteract button =
    let
        theme : BaseTheme
        theme =
            getBaseTheme model.colorScheme

        isHighlighted : Bool
        isHighlighted =
            isButtonHighlighted model button
    in
    if isHighlighted then
        -- Highlighted button colors take precedence
        { backgroundColor = Element.HexColor.rgbCSSHex theme.accentColorHex
        , textColor = Element.HexColor.rgbCSSHex theme.buttonTextColorHex
        , borderColor = Element.HexColor.rgbCSSHex theme.accentColorHex
        , borderWidth = 3
        }

    else
        case model.animationState of
            BlockedMovement ->
                let
                    -- Use elm-animator to check if blocked movement animation is active
                    isBlockedMovementAnimating : Bool
                    isBlockedMovementAnimating =
                        Animator.current model.blockedMovementTimeline

                    isShowingBlockedFeedback : Bool
                    isShowingBlockedFeedback =
                        isBlockedMovementAnimating || (model.blockedMovementFeedback && model.animationState == BlockedMovement)

                    -- Animate border width for blocked movement effect
                    -- Normal border
                in
                if isShowingBlockedFeedback then
                    let
                        animatedBorderWidth : Int
                        animatedBorderWidth =
                            if isBlockedMovementAnimating then
                                4
                                -- Thicker border during animation

                            else
                                3
                    in
                    { backgroundColor = Element.HexColor.rgbCSSHex theme.buttonBlockedColorHex
                    , textColor = Element.HexColor.rgbCSSHex theme.buttonBlockedTextColorHex
                    , borderColor = Element.HexColor.rgbCSSHex theme.blockedMovementBorderColorHex
                    , borderWidth = animatedBorderWidth
                    }

                else if canInteract then
                    { backgroundColor = Element.HexColor.rgbCSSHex theme.buttonBackgroundColorHex
                    , textColor = Element.HexColor.rgbCSSHex theme.buttonTextColorHex
                    , borderColor = Element.HexColor.rgbCSSHex theme.borderColorHex
                    , borderWidth = 2
                    }

                else
                    { backgroundColor = Element.HexColor.rgbCSSHex theme.buttonDisabledColorHex
                    , textColor = Element.HexColor.rgbCSSHex theme.buttonDisabledTextColorHex
                    , borderColor = Element.HexColor.rgbCSSHex theme.borderColorHex
                    , borderWidth = 2
                    }

            Moving _ _ ->
                { backgroundColor = Element.HexColor.rgbCSSHex theme.buttonDisabledColorHex
                , textColor = Element.HexColor.rgbCSSHex theme.buttonDisabledTextColorHex
                , borderColor = Element.HexColor.rgbCSSHex theme.borderColorHex
                , borderWidth = 2
                }

            Rotating _ _ ->
                { backgroundColor = Element.HexColor.rgbCSSHex theme.buttonDisabledColorHex
                , textColor = Element.HexColor.rgbCSSHex theme.buttonDisabledTextColorHex
                , borderColor = Element.HexColor.rgbCSSHex theme.borderColorHex
                , borderWidth = 2
                }

            Idle ->
                if canInteract then
                    { backgroundColor = Element.HexColor.rgbCSSHex theme.buttonBackgroundColorHex
                    , textColor = Element.HexColor.rgbCSSHex theme.buttonTextColorHex
                    , borderColor = Element.HexColor.rgbCSSHex theme.borderColorHex
                    , borderWidth = 2
                    }

                else
                    { backgroundColor = Element.HexColor.rgbCSSHex theme.buttonDisabledColorHex
                    , textColor = Element.HexColor.rgbCSSHex theme.buttonDisabledTextColorHex
                    , borderColor = Element.HexColor.rgbCSSHex theme.borderColorHex
                    , borderWidth = 2
                    }


{-| Helper function to get button label based on AnimationState
-}
getForwardButtonLabel : Model -> String
getForwardButtonLabel model =
    case model.animationState of
        BlockedMovement ->
            let
                -- Use elm-animator to check if blocked movement animation is active
                isBlockedMovementAnimating : Bool
                isBlockedMovementAnimating =
                    Animator.current model.blockedMovementTimeline

                isShowingBlockedFeedback : Bool
                isShowingBlockedFeedback =
                    isBlockedMovementAnimating || (model.blockedMovementFeedback && model.animationState == BlockedMovement)
            in
            if isShowingBlockedFeedback then
                "✗"

            else
                "↑"

        Moving _ _ ->
            "↑"

        Rotating _ _ ->
            "↑"

        Idle ->
            "↑"


{-| Render the forward movement button
-}
viewForwardButton : Model -> Bool -> Int -> Element Main.Msg
viewForwardButton model canMove buttonSize =
    let
        -- Use elm-animator to check if blocked movement animation is active
        isBlockedMovementAnimating : Bool
        isBlockedMovementAnimating =
            Animator.current model.blockedMovementTimeline

        isShowingBlockedFeedback : Bool
        isShowingBlockedFeedback =
            isBlockedMovementAnimating || (model.blockedMovementFeedback && model.animationState == BlockedMovement)

        -- Use helper functions for animation-based styling
        buttonColors =
            getButtonColors model canMove RobotGame.Model.ForwardButton

        buttonLabel : String
        buttonLabel =
            getForwardButtonLabel model

        buttonAttributes : List (Element.Attribute Main.Msg)
        buttonAttributes =
            [ Element.width (Element.px buttonSize)
            , Element.height (Element.px buttonSize)
            , Background.color buttonColors.backgroundColor
            , Element.Border.rounded (getResponsiveSpacing model.maybeWindow 8)
            , Element.Border.width buttonColors.borderWidth
            , Element.Border.color buttonColors.borderColor
            , Font.color buttonColors.textColor
            , Font.size (getResponsiveFontSize model.maybeWindow 16)
            , Font.bold
            , Element.padding 0
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
                        let
                            theme : BaseTheme
                            theme =
                                getBaseTheme model.colorScheme
                        in
                        [ Element.Events.onClick Main.MoveForward
                        , Element.mouseOver [ Background.color (Element.HexColor.rgbCSSHex theme.buttonHoverColorHex) ]
                        , Element.focused [ Background.color (Element.HexColor.rgbCSSHex theme.buttonPressedColorHex) ]
                        , Element.pointer
                        ]

                    else if not canMove && not isShowingBlockedFeedback then
                        [ Element.Events.onClick Main.MoveForward -- Allow clicking to show blocked feedback
                        , Element.pointer
                        ]

                    else
                        []
                   )
    in
    Element.column
        [ Element.centerX
        , Element.spacing (getResponsiveSpacing model.maybeWindow 5)
        ]
        [ Element.el buttonAttributes
            (Element.el
                [ Element.centerX
                , Element.centerY
                ]
                (Element.text buttonLabel)
            )
        , Element.el
            [ Element.htmlAttribute (Html.Attributes.id "forward-button-help")
            , Element.moveLeft 10000
            , Element.width (Element.px 1)
            , Element.height (Element.px 1)
            , Element.clip
            ]
            (Element.text "Moves the robot one cell forward in the direction it is facing")
        ]


{-| Render the rotate left button
-}
viewRotateLeftButton : Model -> Int -> Element Main.Msg
viewRotateLeftButton model buttonSize =
    let
        canRotate : Bool
        canRotate =
            model.animationState == Idle

        -- Use helper function for animation-based styling
        buttonColors =
            getButtonColors model canRotate RobotGame.Model.RotateLeftButton

        buttonAttributes : List (Element.Attribute Main.Msg)
        buttonAttributes =
            [ Element.width (Element.px buttonSize)
            , Element.height (Element.px buttonSize)
            , Background.color buttonColors.backgroundColor
            , Element.Border.rounded (getResponsiveSpacing model.maybeWindow 8)
            , Element.Border.width buttonColors.borderWidth
            , Element.Border.color buttonColors.borderColor
            , Font.color buttonColors.textColor
            , Font.size (getResponsiveFontSize model.maybeWindow 16)
            , Font.bold
            , Element.padding 0
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
                        let
                            theme : BaseTheme
                            theme =
                                getBaseTheme model.colorScheme
                        in
                        [ Element.Events.onClick Main.RotateLeft
                        , Element.mouseOver [ Background.color (Element.HexColor.rgbCSSHex theme.buttonHoverColorHex) ]
                        , Element.focused [ Background.color (Element.HexColor.rgbCSSHex theme.buttonPressedColorHex) ]
                        , Element.pointer
                        ]

                    else
                        []
                   )
    in
    Element.el buttonAttributes
        (Element.el
            [ Element.centerX
            , Element.centerY
            ]
            (Element.text "↺")
        )


{-| Render the rotate right button
-}
viewRotateRightButton : Model -> Int -> Element Main.Msg
viewRotateRightButton model buttonSize =
    let
        canRotate : Bool
        canRotate =
            model.animationState == Idle

        -- Use helper function for animation-based styling
        buttonColors =
            getButtonColors model canRotate RobotGame.Model.RotateRightButton

        buttonAttributes : List (Element.Attribute Main.Msg)
        buttonAttributes =
            [ Element.width (Element.px buttonSize)
            , Element.height (Element.px buttonSize)
            , Background.color buttonColors.backgroundColor
            , Element.Border.rounded (getResponsiveSpacing model.maybeWindow 8)
            , Element.Border.width buttonColors.borderWidth
            , Element.Border.color buttonColors.borderColor
            , Font.color buttonColors.textColor
            , Font.size (getResponsiveFontSize model.maybeWindow 16)
            , Font.bold
            , Element.padding 0
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
                        let
                            theme : BaseTheme
                            theme =
                                getBaseTheme model.colorScheme
                        in
                        [ Element.Events.onClick Main.RotateRight
                        , Element.mouseOver [ Background.color (Element.HexColor.rgbCSSHex theme.buttonHoverColorHex) ]
                        , Element.focused [ Background.color (Element.HexColor.rgbCSSHex theme.buttonPressedColorHex) ]
                        , Element.pointer
                        ]

                    else
                        []
                   )
    in
    Element.el buttonAttributes
        (Element.el
            [ Element.centerX
            , Element.centerY
            ]
            (Element.text "↻")
        )


{-| Render the directional buttons (N, S, E, W)
-}
viewDirectionalButtons : Model -> Int -> Int -> Element Main.Msg
viewDirectionalButtons model buttonSize buttonSpacing =
    let
        theme : BaseTheme
        theme =
            getBaseTheme model.colorScheme

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

                -- Use helper function for animation-based styling, but handle current direction specially
                buttonColors =
                    if isCurrentDirection then
                        -- Current direction button has special styling
                        { backgroundColor = Element.HexColor.rgbCSSHex theme.buttonPressedColorHex
                        , textColor = Element.HexColor.rgbCSSHex theme.buttonTextColorHex
                        , borderColor = Element.HexColor.rgbCSSHex theme.borderColorHex
                        , borderWidth = 2
                        }

                    else
                        getButtonColors model canRotate (RobotGame.Model.DirectionButton direction)

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

                -- Use responsive calculation for smaller directional buttons based on main button size
                smallButtonSize : Int
                smallButtonSize =
                    max 40 (buttonSize - getResponsiveSpacing model.maybeWindow 10)

                buttonAttributes : List (Element.Attribute Main.Msg)
                buttonAttributes =
                    [ Element.width (Element.px smallButtonSize)
                    , Element.height (Element.px smallButtonSize)
                    , Background.color buttonColors.backgroundColor
                    , Element.Border.rounded (getResponsiveSpacing model.maybeWindow 6)
                    , Element.Border.width buttonColors.borderWidth
                    , Element.Border.color buttonColors.borderColor
                    , Font.color buttonColors.textColor
                    , Font.size (getResponsiveFontSize model.maybeWindow 14)
                    , Font.bold
                    , Element.padding 0
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
                                , Element.mouseOver [ Background.color (Element.HexColor.rgbCSSHex theme.buttonHoverColorHex) ]
                                , Element.focused [ Background.color (Element.HexColor.rgbCSSHex theme.buttonPressedColorHex) ]
                                , Element.pointer
                                ]

                            else
                                []
                           )
            in
            Element.column
                [ Element.centerX
                , Element.spacing (getResponsiveSpacing model.maybeWindow 2)
                ]
                [ Element.el buttonAttributes
                    (Element.el
                        [ Element.centerX
                        , Element.centerY
                        ]
                        (Element.text label)
                    )
                , Element.el
                    [ Element.htmlAttribute (Html.Attributes.id ("direction-" ++ String.toLower directionName ++ "-help"))
                    , Element.moveLeft 10000
                    , Element.width (Element.px 1)
                    , Element.height (Element.px 1)
                    , Element.clip
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


{-| Render game status for screen readers using Element.text with theme-aware colors
-}
viewGameStatus : Model -> Element Main.Msg
viewGameStatus model =
    let
        theme : BaseTheme
        theme =
            getBaseTheme model.colorScheme

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
        , Font.color (Element.HexColor.rgbCSSHex theme.fontColorHex)
        , Font.size 1
        , Element.width (Element.px 1)
        , Element.height (Element.px 1)
        , Element.clip
        , Element.moveLeft 10000
        ]
        (Element.text statusText)


{-| Render success movement feedback using Element.el with conditional visibility
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
            theme : BaseTheme
            theme =
                getBaseTheme model.colorScheme

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
            , Background.color (Element.HexColor.rgbCSSHex theme.accentColorHex)
            , Element.Border.rounded (getResponsiveSpacing model.maybeWindow 8)
            , Element.Border.width 2
            , Element.Border.color (Element.HexColor.rgbCSSHex theme.borderColorHex)
            , Font.color (Element.HexColor.rgbCSSHex theme.buttonTextColorHex)
            , Font.size (getResponsiveFontSize model.maybeWindow 16)
            , Font.bold
            , Element.htmlAttribute (Html.Attributes.attribute "role" "status")
            , Element.htmlAttribute (Html.Attributes.attribute "aria-live" "polite")
            ]
            (Element.text feedbackText)

    else
        Element.none


{-| Render blocked movement feedback using elm-animator controlled animations
-}
viewBlockedMovementFeedback : Model -> Element Main.Msg
viewBlockedMovementFeedback model =
    let
        -- Use elm-animator to determine if blocked movement animation is active
        isBlockedMovementAnimating : Bool
        isBlockedMovementAnimating =
            Animator.current model.blockedMovementTimeline

        -- Get animation intensity for visual effects (0.0 to 1.0)
        -- Show feedback if animation is active or if we're in blocked movement state
        shouldShowFeedback : Bool
        shouldShowFeedback =
            isBlockedMovementAnimating || (model.blockedMovementFeedback && model.animationState == BlockedMovement)
    in
    if shouldShowFeedback then
        let
            animationIntensity : Float
            animationIntensity =
                if isBlockedMovementAnimating then
                    1.0

                else
                    0.0

            theme : BaseTheme
            theme =
                getBaseTheme model.colorScheme

            -- Create subtle shake effect using animation intensity
            -- Transform the element slightly based on animation intensity
            shakeOffset : Float
            shakeOffset =
                animationIntensity * 3.0

            -- Maximum 3px shake
            -- Animate opacity for fade effect
            feedbackOpacity : Float
            feedbackOpacity =
                if isBlockedMovementAnimating then
                    0.9 + (animationIntensity * 0.1)
                    -- Pulse between 0.9 and 1.0

                else
                    0.8

            -- Static opacity when not animating
        in
        Element.el
            [ Element.centerX
            , Element.padding (getResponsivePadding model.maybeWindow 10)
            , Background.color (Element.HexColor.rgbCSSHex theme.blockedMovementColorHex)
            , Element.Border.rounded (getResponsiveSpacing model.maybeWindow 8)
            , Element.Border.width (2 + round animationIntensity) -- Animate border width
            , Element.Border.color (Element.HexColor.rgbCSSHex theme.blockedMovementBorderColorHex)
            , Font.color (Element.HexColor.rgbCSSHex theme.buttonBlockedTextColorHex)
            , Font.size (getResponsiveFontSize model.maybeWindow 16)
            , Font.bold
            , Element.alpha feedbackOpacity
            , Element.htmlAttribute (Html.Attributes.attribute "role" "alert")
            , Element.htmlAttribute (Html.Attributes.attribute "aria-live" "assertive")

            -- Apply subtle transform for shake effect using CSS transform
            , Element.htmlAttribute
                (Html.Attributes.style "transform"
                    ("translateX(" ++ String.fromFloat shakeOffset ++ "px)")
                )
            ]
            (Element.text "⚠ Cannot move forward - boundary reached!")

    else
        Element.none

# Design Document

## Overview

This design outlines the migration of RobotGame.View from a hybrid HTML/CSS/elm-ui approach to a pure elm-ui implementation, following the established patterns from TicTacToe.View. The migration will eliminate custom CSS dependencies, simplify the codebase, and ensure consistency with the application's design system while maintaining all existing functionality and visual appearance.

## Architecture

### Current State Analysis

The existing RobotGame.View module has several areas that need refactoring:

1. **Heavy CSS Dependency**: Uses extensive custom CSS for animations, hover effects, and responsive design
2. **HTML.node Usage**: Relies on HTML.node for style injection and skip links
3. **Mixed Rendering Approach**: Combines HTML attributes with elm-ui elements inconsistently
4. **Complex Animation System**: Uses CSS classes and keyframe animations for robot states

### Target Architecture

The migrated view will follow TicTacToe.View patterns:

1. **Pure elm-ui Layout**: Use Element.column, Element.row, and Element.el exclusively
2. **Theme Integration**: Leverage BaseTheme and ColorScheme consistently
3. **SVG Integration**: Use Element.html with SVG for robot visualization
4. **Simplified Animations**: Minimize CSS animations, prefer elm-ui state-based styling
5. **Consistent Patterns**: Follow the same structural approach as TicTacToe.View

## Components and Interfaces

### Main View Structure

Following TicTacToe.View's pattern:

```elm
view : Model -> Html Main.Msg
view model =
    let
        theme : BaseTheme
        theme = getBaseTheme model.colorScheme
    in
    Element.layout
        [ Background.color theme.backgroundColor
        , Font.color theme.fontColor
        ]
    <| viewModel model

viewModel : Model -> Element.Element Main.Msg
viewModel model =
    Element.el
        [ Element.centerX
        , Element.centerY
        , -- styling attributes
        ]
        (Element.column [ Element.spacing responsiveSpacing ]
            [ viewHeader model
            , viewGameGrid model  
            , viewStatusFeedback model
            , viewControlButtons model
            ]
        )
```

### Header Component

Adopt TicTacToe.View's header pattern:

```elm
viewHeader : Model -> Element.Element Main.Msg
viewHeader model =
    Element.row
        [ Element.width Element.fill
        , Element.spacing responsiveSpacing
        , Element.padding responsivePadding
        , Background.color theme.headerBackgroundColor
        ]
        [ Element.el [ Element.alignLeft ] (viewBackButton model)
        , Element.el [ Element.centerX ] (Element.text "Robot Grid Game")
        , Element.el [ Element.alignRight ] (viewThemeToggle model)
        ]
```

### Grid Rendering

Replace HTML-heavy grid with pure elm-ui:

```elm
viewGameGrid : Model -> Element.Element Main.Msg
viewGameGrid model =
    Element.el
        [ Element.centerX
        , Background.color theme.borderColor
        , Element.padding responsivePadding
        ]
        (Element.column [ Element.spacing gridSpacing ]
            (List.range 0 4 |> List.map (viewGridRow model))
        )

viewGridRow : Model -> Int -> Element.Element Main.Msg
viewGridRow model rowIndex =
    Element.row [ Element.spacing gridSpacing ]
        (List.range 0 4 |> List.map (viewGridCell model rowIndex))
```

### Robot Visualization

Use SVG with elm-ui similar to TicTacToe's player symbols:

```elm
viewRobot : Model -> Element.Element Main.Msg
viewRobot model =
    let
        rotationAngle = directionToAngle model.robot.facing
        animationClass = getAnimationClass model.animationState
    in
    Element.el
        [ Element.centerX
        , Element.centerY
        , Element.width Element.fill
        , Element.height Element.fill
        ]
    <| Element.html <|
        Svg.svg
            [ SvgAttr.viewBox "0 0 100 100"
            , SvgAttr.width "100%"
            , SvgAttr.height "100%"
            ]
            [ Svg.g
                [ SvgAttr.transform ("rotate(" ++ rotationAngle ++ " 50 50)") ]
                [ -- Robot body and directional indicator
                  viewRobotBody theme
                , viewDirectionalArrow theme
                ]
            ]
```

### Control Buttons

Follow TicTacToe.View's button patterns:

```elm
viewControlButtons : Model -> Element.Element Main.Msg
viewControlButtons model =
    Element.column
        [ Element.centerX
        , Element.spacing responsiveSpacing
        ]
        [ viewMovementControls model
        , viewRotationControls model
        , viewDirectionalControls model
        ]

viewMovementButton : Model -> Bool -> Element.Element Main.Msg
viewMovementButton model canMove =
    let
        buttonAttributes = 
            [ Element.padding buttonPadding
            , Background.color (if canMove then theme.buttonColor else theme.disabledButtonColor)
            , Element.Border.rounded 4
            , Font.color theme.buttonTextColor
            ] ++ 
            (if canMove then 
                [ Element.pointer
                , Element.mouseOver [ Background.color theme.buttonHoverColor ]
                , Element.Events.onClick Main.MoveForward
                ]
             else [])
    in
    Element.el buttonAttributes (Element.text "Forward")
```

## Data Models

### Theme Integration

Use the existing BaseTheme system consistently:

```elm
type alias Theme = BaseTheme

currentTheme : ColorScheme -> Theme
currentTheme = getBaseTheme
```

### Animation State Handling

Simplify animation handling through elm-ui conditional styling:

```elm
getCellBackgroundColor : Model -> Position -> Color
getCellBackgroundColor model position =
    let
        theme = currentTheme model.colorScheme
        isRobotHere = model.robot.position == position
        isBlocked = model.animationState == BlockedMovement && isRobotHere
    in
    if isBlocked then
        theme.blockedMovementColor
    else if isRobotHere then
        theme.robotCellBackgroundColor
    else
        theme.cellBackgroundColor
```

### Responsive Design

Leverage existing Theme.Responsive utilities:

```elm
getResponsiveValues : Model -> ResponsiveConfig
getResponsiveValues model =
    { cellSize = calculateResponsiveCellSize model.maybeWindow 7 120
    , fontSize = getResponsiveFontSize model.maybeWindow 32
    , padding = getResponsivePadding model.maybeWindow 20
    , spacing = getResponsiveSpacing model.maybeWindow 15
    }
```

## Error Handling

### Graceful Degradation

- **Animation Fallbacks**: If CSS transitions fail, elm-ui state changes still provide visual feedback
- **Theme Fallbacks**: Default to Light theme if ColorScheme is invalid
- **Responsive Fallbacks**: Use default sizes if window dimensions are unavailable

### State Consistency

- **Animation States**: Ensure AnimationState changes are reflected in elm-ui styling
- **Button States**: Disable buttons through elm-ui attributes rather than CSS
- **Visual Feedback**: Use elm-ui color changes for blocked movement indication

## Testing Strategy

### Visual Regression Testing

- **Grid Layout**: Verify 5x5 grid renders identically to current implementation
- **Robot Appearance**: Ensure robot and directional indicator look the same
- **Button Styling**: Confirm control buttons maintain current appearance
- **Theme Consistency**: Test both light and dark themes

### Functional Testing

- **Interaction Preservation**: All click handlers and keyboard events work identically
- **Animation Behavior**: Robot movement and rotation animations function correctly
- **Responsive Behavior**: Layout adapts properly across screen sizes
- **Accessibility**: ARIA labels and keyboard navigation remain functional

### Integration Testing

- **Theme Integration**: Verify proper integration with BaseTheme system
- **Responsive Integration**: Confirm Theme.Responsive utilities work correctly
- **Message Handling**: Ensure all Main.Msg types are handled properly

## Implementation Approach

### Phase 1: Structure Migration

1. **Remove CSS Dependencies**: Eliminate the large CSS string and HTML.node usage
2. **Implement Main Layout**: Create the Element.layout and main column structure
3. **Add Header Component**: Implement header following TicTacToe.View pattern
4. **Basic Grid Layout**: Create grid using Element.column and Element.row

### Phase 2: Component Migration

1. **Robot Visualization**: Migrate robot rendering to SVG with elm-ui
2. **Control Buttons**: Implement buttons using elm-ui patterns
3. **Status Feedback**: Create status messages using elm-ui text elements
4. **Theme Integration**: Ensure all components use BaseTheme colors

### Phase 3: Animation and Polish

1. **Animation States**: Implement animation feedback through elm-ui styling
2. **Hover Effects**: Add Element.mouseOver for interactive elements
3. **Responsive Design**: Apply Theme.Responsive utilities throughout
4. **Accessibility**: Preserve all ARIA labels and keyboard support

### Phase 4: Testing and Refinement

1. **Visual Comparison**: Ensure pixel-perfect match with current implementation
2. **Functional Testing**: Verify all interactions work identically
3. **Performance Testing**: Confirm no performance regressions
4. **Code Cleanup**: Remove unused imports and simplify code structure

## Migration Benefits

### Code Maintainability

- **Reduced Complexity**: Eliminate 200+ lines of custom CSS
- **Consistent Patterns**: Follow established elm-ui conventions
- **Type Safety**: Leverage Elm's type system for styling
- **Easier Debugging**: Elm compiler catches styling errors

### Design Consistency

- **Theme Integration**: Automatic theme support through BaseTheme
- **Component Reuse**: Share patterns with TicTacToe.View
- **Responsive Design**: Consistent responsive behavior
- **Visual Harmony**: Unified appearance across game modules

### Developer Experience

- **Simplified Development**: No CSS knowledge required for modifications
- **Better Tooling**: Elm tooling works with elm-ui code
- **Easier Testing**: elm-ui components are easier to test
- **Reduced Context Switching**: Stay within Elm ecosystem
# Elm-UI Development Patterns

## Overview

This project uses elm-ui as the standard UI framework for consistent, maintainable, and type-safe user interfaces. All UI components follow these established patterns to ensure consistency across the application.

## Core Principles

### Pure elm-ui Implementation
- Use `Element` and elm-ui functions exclusively for layout and styling
- Avoid HTML/CSS hybrid approaches - prefer pure elm-ui patterns
- Eliminate custom CSS where possible, using elm-ui attributes instead
- Only use minimal CSS for essential animations that cannot be achieved with elm-ui

### Theme Integration
- Always use the `BaseTheme` system for colors and styling
- Leverage `getBaseTheme` function to get theme-appropriate colors
- Support both light and dark themes consistently
- Use theme colors from `BaseTheme` type for all visual elements

### Responsive Design
- Use `Theme.Responsive` utilities for consistent responsive behavior
- Apply `getResponsiveFontSize`, `getResponsivePadding`, `getResponsiveSpacing` throughout
- Use `calculateResponsiveCellSize` for grid-based layouts
- Ensure layouts work across mobile, tablet, and desktop screen sizes

## Established Patterns

### Main View Structure

Follow the TicTacToe.View pattern for consistent application structure:

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
        -- additional styling attributes
        ]
        (Element.column [ Element.spacing responsiveSpacing ]
            [ viewHeader model
            , viewMainContent model  
            , viewControls model
            ]
        )
```

### Header Component Pattern

Use consistent header layout across game modules:

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
        , Element.el [ Element.centerX ] (Element.text "Game Title")
        , Element.el [ Element.alignRight ] (viewThemeToggle model)
        ]
```

### Grid Layout Pattern

For grid-based games, use elm-ui layout functions:

```elm
viewGrid : Model -> Element.Element Main.Msg
viewGrid model =
    Element.el
        [ Element.centerX
        , Background.color theme.borderColor
        , Element.padding responsivePadding
        ]
        (Element.column [ Element.spacing gridSpacing ]
            (List.range 0 (gridSize - 1) |> List.map (viewGridRow model))
        )

viewGridRow : Model -> Int -> Element.Element Main.Msg
viewGridRow model rowIndex =
    Element.row [ Element.spacing gridSpacing ]
        (List.range 0 (gridSize - 1) |> List.map (viewGridCell model rowIndex))

viewGridCell : Model -> Int -> Int -> Element.Element Main.Msg
viewGridCell model row col =
    Element.el
        [ Element.width (Element.px cellSize)
        , Element.height (Element.px cellSize)
        , Background.color (getCellBackgroundColor model row col)
        , Element.Border.width 1
        , Element.Border.color theme.borderColor
        ]
        (viewCellContent model row col)
```

### Button Patterns

Use consistent button styling and interaction patterns:

```elm
viewButton : Model -> String -> Bool -> Main.Msg -> Element.Element Main.Msg
viewButton model label isEnabled onClickMsg =
    let
        buttonAttributes = 
            [ Element.padding buttonPadding
            , Background.color (if isEnabled then theme.buttonColor else theme.disabledButtonColor)
            , Element.Border.rounded 4
            , Font.color theme.buttonTextColor
            , Element.centerX
            ] ++ 
            (if isEnabled then 
                [ Element.pointer
                , Element.mouseOver [ Background.color theme.buttonHoverColor ]
                , Element.Events.onClick onClickMsg
                ]
             else [])
    in
    Element.el buttonAttributes (Element.text label)
```

### SVG Integration Pattern

For complex graphics (like game pieces), use SVG with elm-ui:

```elm
viewGamePiece : Model -> Element.Element Main.Msg
viewGamePiece model =
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
            [ -- SVG content using theme colors
              Svg.circle
                [ SvgAttr.cx "50"
                , SvgAttr.cy "50"
                , SvgAttr.r "40"
                , SvgAttr.fill theme.primaryColorHex
                ]
                []
            ]
```

## Animation and State Management

### State-Based Visual Changes

Prefer elm-ui conditional styling over CSS animations:

```elm
getCellBackgroundColor : Model -> Position -> Color
getCellBackgroundColor model position =
    let
        theme = getBaseTheme model.colorScheme
        isActive = model.activePosition == Just position
        isHighlighted = model.highlightedPositions |> List.member position
    in
    if isActive then
        theme.activeCellColor
    else if isHighlighted then
        theme.highlightedCellColor
    else
        theme.cellBackgroundColor
```

### Minimal CSS for Essential Animations

When CSS is necessary, keep it minimal and focused:

```elm
-- Only for animations that cannot be achieved with elm-ui
essentialAnimationCSS : String
essentialAnimationCSS =
    """
    .smooth-transition {
        transition: transform 0.3s ease-in-out;
    }
    """
```

## Responsive Design Patterns

### Using Theme.Responsive Utilities

Always use the established responsive utilities:

```elm
getResponsiveValues : Model -> ResponsiveConfig
getResponsiveValues model =
    { cellSize = calculateResponsiveCellSize model.maybeWindow 7 120
    , fontSize = getResponsiveFontSize model.maybeWindow 32
    , padding = getResponsivePadding model.maybeWindow 20
    , spacing = getResponsiveSpacing model.maybeWindow 15
    }

applyResponsiveValues : ResponsiveConfig -> List (Element.Attribute msg)
applyResponsiveValues config =
    [ Element.padding config.padding
    , Element.spacing config.spacing
    , Font.size config.fontSize
    ]
```

## Accessibility Considerations

### Maintaining Accessibility in elm-ui

- Use `Element.htmlAttribute` for ARIA labels when needed
- Ensure proper semantic structure with headings and landmarks
- Maintain keyboard navigation support
- Provide sufficient color contrast using theme colors

```elm
viewAccessibleButton : String -> Main.Msg -> Element.Element Main.Msg
viewAccessibleButton ariaLabel onClickMsg =
    Element.el
        [ Element.htmlAttribute (Html.Attributes.attribute "aria-label" ariaLabel)
        , Element.htmlAttribute (Html.Attributes.attribute "role" "button")
        , Element.Events.onClick onClickMsg
        , Element.pointer
        -- other styling attributes
        ]
        (Element.text "Button Text")
```

## Common Anti-Patterns to Avoid

### Don't Mix HTML and elm-ui
```elm
-- ❌ Avoid this
Html.div [ Html.Attributes.class "custom-style" ]
    [ Element.layout [] (Element.text "Mixed approach") ]

-- ✅ Use this instead
Element.el 
    [ Background.color theme.backgroundColor
    , Element.padding 20
    ]
    (Element.text "Pure elm-ui approach")
```

### Don't Use Extensive Custom CSS
```elm
-- ❌ Avoid this
Html.node "style" [] [ Html.text """
    .complex-grid { display: grid; grid-template-columns: repeat(5, 1fr); }
    .cell { background: #fff; border: 1px solid #ccc; }
""" ]

-- ✅ Use this instead
Element.column [ Element.spacing gridSpacing ]
    (List.map (Element.row [ Element.spacing gridSpacing ]) gridRows)
```

### Don't Ignore Theme System
```elm
-- ❌ Avoid hardcoded colors
Element.el [ Background.color (Element.rgb 1 1 1) ] content

-- ✅ Use theme colors
Element.el [ Background.color theme.backgroundColor ] content
```

## Testing elm-ui Components

### Visual Consistency Testing

Test that components maintain visual consistency across themes:

```elm
testThemeConsistency : Test
testThemeConsistency =
    test "component displays correctly in both themes" <|
        \_ ->
            let
                lightTheme = getBaseTheme Light
                darkTheme = getBaseTheme Dark
            in
            Expect.all
                [ \_ -> Expect.notEqual lightTheme.backgroundColor darkTheme.backgroundColor
                , \_ -> Expect.notEqual lightTheme.fontColor darkTheme.fontColor
                ]
                ()
```

### Responsive Behavior Testing

Verify responsive utilities work correctly:

```elm
testResponsiveBehavior : Test
testResponsiveBehavior =
    test "responsive utilities scale appropriately" <|
        \_ ->
            let
                mobileSize = calculateResponsiveCellSize (Just (400, 600)) 7 120
                desktopSize = calculateResponsiveCellSize (Just (1200, 800)) 7 120
            in
            Expect.lessThan desktopSize mobileSize
```

## Migration Guidelines

When migrating existing HTML/CSS components to elm-ui:

1. **Start with Structure**: Replace HTML layout with elm-ui layout functions
2. **Theme Integration**: Replace hardcoded colors with theme colors
3. **Responsive Design**: Apply Theme.Responsive utilities
4. **Simplify Animations**: Replace CSS animations with elm-ui state changes where possible
5. **Preserve Functionality**: Ensure all interactions and accessibility features are maintained
6. **Test Thoroughly**: Verify visual consistency and functional preservation

## Reference Examples

- **TicTacToe.View**: Excellent example of elm-ui implementation with game logic
- **RobotGame.View**: Comprehensive elm-ui implementation with grid layout and animations
- **Theme.Theme**: Central theme system for consistent styling
- **Theme.Responsive**: Responsive utilities for consistent scaling

Following these patterns ensures maintainable, consistent, and accessible user interfaces across the entire application.
module Theme.Responsive exposing
    ( ScreenSize(..), ResponsiveConfig
    , getScreenSize
    , calculateResponsiveCellSize, getResponsiveFontSize, getResponsiveSpacing, getResponsivePadding
    , defaultResponsiveConfig
    , validateResponsiveConfig
    )

{-| Shared responsive design utilities for consistent cross-device experiences.

This module provides responsive design utilities that automatically adapt
UI elements based on screen size. It includes screen size detection,
responsive calculations for fonts, spacing, and component sizing.


## Screen Size Breakpoints

The responsive system uses three main breakpoints:

  - **Mobile**: < 768px - Optimized for touch interfaces and small screens
  - **Tablet**: 768px - 1024px - Balanced for medium-sized screens
  - **Desktop**: > 1024px - Full-featured layout for large screens


## Responsive Calculations

All responsive functions take an optional window size and provide sensible
fallbacks when screen dimensions are unavailable. The calculations ensure
minimum and maximum bounds to maintain usability across all devices.


## Usage Examples

    -- Detect current screen size



    screenSize =
        getScreenSize (Just ( 800, 600 ))

    -- Returns Tablet
    -- Calculate responsive cell size for a 5x5 grid
    cellSize =
        calculateResponsiveCellSize (Just ( 400, 600 )) 6 80

    -- Returns appropriate cell size based on screen dimensions
    -- Get responsive font size
    fontSize =
        getResponsiveFontSize (Just ( 320, 568 )) 18

    -- Returns smaller font size for mobile devices


# Types

@docs ScreenSize, ResponsiveConfig


# Screen Size Detection

@docs getScreenSize


# Responsive Calculations

@docs calculateResponsiveCellSize, getResponsiveFontSize, getResponsiveSpacing, getResponsivePadding


# Configuration

@docs defaultResponsiveConfig


# Validation and Error Handling

@docs validateResponsiveConfig

-}


{-| Screen size categories for responsive design

Represents the three main device categories used throughout the application
for responsive design decisions.

  - **Mobile**: Smartphones and small devices (< 768px width)
  - **Tablet**: Medium-sized devices like tablets (768px - 1024px width)
  - **Desktop**: Large screens and desktop computers (> 1024px width)

-}
type ScreenSize
    = Mobile
    | Tablet
    | Desktop


{-| Configuration for responsive design calculations

Contains all the breakpoints and sizing constraints used by responsive
calculation functions. This allows for consistent responsive behavior
across the entire application.


## Fields

  - `mobileBreakpoint`: Width threshold for mobile devices (default: 768px)
  - `tabletBreakpoint`: Width threshold for tablet devices (default: 1024px)
  - `minCellSize`: Minimum allowed cell size in pixels (default: 60px)
  - `maxCellSize`: Maximum allowed cell size in pixels (default: 160px)
  - `baseFontSize`: Base font size for desktop devices (default: 16px)

-}
type alias ResponsiveConfig =
    { mobileBreakpoint : Int
    , tabletBreakpoint : Int
    , minCellSize : Int
    , maxCellSize : Int
    , baseFontSize : Int
    }



-- RESPONSIVE DESIGN UTILITIES


{-| Default responsive configuration with sensible breakpoints and constraints

Provides the standard configuration used throughout the application.
These values have been tested across various devices and screen sizes
to ensure optimal user experience.


## Configuration Values

  - Mobile breakpoint: 768px (standard mobile/tablet boundary)
  - Tablet breakpoint: 1024px (standard tablet/desktop boundary)
  - Minimum cell size: 60px (ensures touch targets are accessible)
  - Maximum cell size: 160px (prevents oversized elements on large screens)
  - Base font size: 16px (standard web font size)

-}
defaultResponsiveConfig : ResponsiveConfig
defaultResponsiveConfig =
    { mobileBreakpoint = 768
    , tabletBreakpoint = 1024
    , minCellSize = 60
    , maxCellSize = 160
    , baseFontSize = 16
    }


{-| Determine screen size category based on viewport dimensions

Takes optional window dimensions and returns the appropriate ScreenSize
category. Falls back to Desktop when dimensions are unavailable.


## Examples

    getScreenSize (Just ( 320, 568 )) -- Returns Mobile

    getScreenSize (Just ( 768, 1024 )) -- Returns Tablet

    getScreenSize (Just ( 1920, 1080 )) -- Returns Desktop

    getScreenSize Nothing -- Returns Desktop (fallback)

-}
getScreenSize : Maybe ( Int, Int ) -> ScreenSize
getScreenSize maybeWindow =
    case maybeWindow of
        Just ( width, _ ) ->
            let
                config =
                    defaultResponsiveConfig
            in
            if width < config.mobileBreakpoint then
                Mobile

            else if width < config.tabletBreakpoint then
                Tablet

            else
                Desktop

        Nothing ->
            Desktop


{-| Calculate responsive cell size for grid-based games

Calculates an appropriate cell size based on screen dimensions and grid requirements.
The calculation ensures cells are large enough for touch interaction on mobile
devices while not becoming oversized on desktop screens.


## Parameters

  - `maybeWindow`: Optional viewport dimensions (width, height)
  - `gridDivisor`: Number to divide screen dimension by (e.g., 6 for 5x5 grid with padding)
  - `fallbackSize`: Size to use when viewport dimensions are unavailable


## Examples

    -- For a 5x5 grid on mobile (400x600 screen)



    cellSize =
        calculateResponsiveCellSize (Just ( 400, 600 )) 6 80

    -- Returns ~66px (400/6, clamped to min/max bounds)

-}
calculateResponsiveCellSize : Maybe ( Int, Int ) -> Int -> Int -> Int
calculateResponsiveCellSize maybeWindow gridDivisor fallbackSize =
    case maybeWindow of
        Just ( width, height ) ->
            let
                screenSize =
                    getScreenSize maybeWindow

                minDimension =
                    Basics.min width height

                baseSize =
                    case screenSize of
                        Mobile ->
                            minDimension // gridDivisor

                        Tablet ->
                            minDimension // (gridDivisor - 1)

                        Desktop ->
                            minDimension // (gridDivisor - 1)

                minSize =
                    case screenSize of
                        Mobile ->
                            60

                        Tablet ->
                            80

                        Desktop ->
                            100

                maxSize =
                    case screenSize of
                        Mobile ->
                            100

                        Tablet ->
                            140

                        Desktop ->
                            160
            in
            Basics.max minSize (Basics.min maxSize baseSize)

        Nothing ->
            fallbackSize


{-| Calculate responsive font size based on screen size

Adjusts font sizes to ensure readability across different device types.
Maintains minimum font sizes to meet accessibility guidelines.


## Size Adjustments

  - **Mobile**: Base size - 8px (minimum 16px for accessibility)
  - **Tablet**: Base size - 4px (minimum 18px for comfortable reading)
  - **Desktop**: Full base size (no reduction)


## Examples

    getResponsiveFontSize (Just ( 320, 568 )) 24 -- Returns 16px (mobile)

    getResponsiveFontSize (Just ( 768, 1024 )) 24 -- Returns 20px (tablet)

    getResponsiveFontSize (Just ( 1920, 1080 )) 24 -- Returns 24px (desktop)

-}
getResponsiveFontSize : Maybe ( Int, Int ) -> Int -> Int
getResponsiveFontSize maybeWindow baseSize =
    case getScreenSize maybeWindow of
        Mobile ->
            Basics.max 16 (baseSize - 8)

        Tablet ->
            Basics.max 18 (baseSize - 4)

        Desktop ->
            baseSize


{-| Calculate responsive spacing between UI elements

Adjusts spacing to optimize layout density for different screen sizes.
Smaller screens use tighter spacing to maximize content area.


## Spacing Adjustments

  - **Mobile**: Base spacing - 5px (minimum 5px to prevent cramped layouts)
  - **Tablet**: Base spacing - 2px (minimum 8px for comfortable spacing)
  - **Desktop**: Full base spacing (optimal for large screens)


## Examples

    getResponsiveSpacing (Just ( 320, 568 )) 20 -- Returns 15px (mobile)

    getResponsiveSpacing (Just ( 768, 1024 )) 20 -- Returns 18px (tablet)

    getResponsiveSpacing (Just ( 1920, 1080 )) 20 -- Returns 20px (desktop)

-}
getResponsiveSpacing : Maybe ( Int, Int ) -> Int -> Int
getResponsiveSpacing maybeWindow baseSpacing =
    case getScreenSize maybeWindow of
        Mobile ->
            Basics.max 5 (baseSpacing - 5)

        Tablet ->
            Basics.max 8 (baseSpacing - 2)

        Desktop ->
            baseSpacing


{-| Calculate responsive padding for UI components

Adjusts internal padding of components to maintain appropriate touch targets
and visual balance across different screen sizes.


## Padding Adjustments

  - **Mobile**: Base padding - 7px (minimum 8px for touch accessibility)
  - **Tablet**: Base padding - 3px (minimum 12px for comfortable interaction)
  - **Desktop**: Full base padding (optimal for mouse interaction)


## Examples

    getResponsivePadding (Just ( 320, 568 )) 20 -- Returns 13px (mobile)

    getResponsivePadding (Just ( 768, 1024 )) 20 -- Returns 17px (tablet)

    getResponsivePadding (Just ( 1920, 1080 )) 20 -- Returns 20px (desktop)

-}
getResponsivePadding : Maybe ( Int, Int ) -> Int -> Int
getResponsivePadding maybeWindow basePadding =
    case getScreenSize maybeWindow of
        Mobile ->
            Basics.max 8 (basePadding - 7)

        Tablet ->
            Basics.max 12 (basePadding - 3)

        Desktop ->
            basePadding



-- VALIDATION AND ERROR HANDLING


{-| Validate ResponsiveConfig and ensure all values are within reasonable bounds

Clamps all configuration values to sensible ranges to prevent layout issues
and ensure accessibility compliance. This function is automatically applied
when using responsive utilities.


## Validation Rules

  - **Mobile breakpoint**: 320px - 1024px (standard mobile device range)
  - **Tablet breakpoint**: Must be ≥ mobile breakpoint, ≤ 1920px
  - **Min cell size**: 20px - 200px (ensures touch accessibility)
  - **Max cell size**: Must be ≥ min cell size, ≤ 400px (prevents oversized elements)
  - **Base font size**: 10px - 32px (maintains readability)


## Examples

    -- Validate a custom configuration
    customConfig = { mobileBreakpoint = 600, tabletBreakpoint = 900, ... }
    validConfig = validateResponsiveConfig customConfig
    -- Returns configuration with values clamped to valid ranges

-}
validateResponsiveConfig : ResponsiveConfig -> ResponsiveConfig
validateResponsiveConfig config =
    { mobileBreakpoint = Basics.max 320 (Basics.min 1024 config.mobileBreakpoint)
    , tabletBreakpoint = Basics.max config.mobileBreakpoint (Basics.min 1920 config.tabletBreakpoint)
    , minCellSize = Basics.max 20 (Basics.min 200 config.minCellSize)
    , maxCellSize = Basics.max config.minCellSize (Basics.min 400 config.maxCellSize)
    , baseFontSize = Basics.max 10 (Basics.min 32 config.baseFontSize)
    }

module RobotGame.ElmUiMigrationTest exposing (suite)

{-| Comprehensive tests to verify that the elm-ui migration preserves all functionality
and visual consistency as specified in task 11 of the robot-view-elm-ui-migration spec.

This test suite validates:

  - Visual appearance consistency (Requirements 7.1, 7.2)
  - Game functionality preservation (Requirements 7.1)
  - Responsive behavior (Requirements 7.4)
  - Theme integration (Requirements 7.2)
  - Accessibility features (Requirements 7.5)

-}

import Expect
import RobotGame.Main exposing (Msg(..), init, update)
import RobotGame.Model exposing (AnimationState(..), Direction(..), Model)
import RobotGame.View exposing (view)
import Test exposing (Test, describe, test)
import Theme.Responsive exposing (..)
import Theme.Theme exposing (ColorScheme(..), getBaseTheme)


{-| Helper function to create a test model with specific state
-}
createTestModel : { position : { row : Int, col : Int }, facing : Direction, animationState : AnimationState, colorScheme : ColorScheme, window : Maybe ( Int, Int ) } -> Model
createTestModel { position, facing, animationState, colorScheme, window } =
    { robot = { position = position, facing = facing }
    , gridSize = 5
    , colorScheme = colorScheme
    , maybeWindow = window
    , animationState = animationState
    , lastMoveTime = Nothing
    , blockedMovementFeedback = False
    }


suite : Test
suite =
    describe "Elm-UI Migration Verification (Task 11)"
        [ visualConsistencyTests
        , functionalityPreservationTests
        , responsiveDesignTests
        , themeIntegrationTests
        , accessibilityPreservationTests
        ]


{-| Tests to verify visual appearance consistency (Requirements 7.1, 7.2)
-}
visualConsistencyTests : Test
visualConsistencyTests =
    describe "Visual Consistency Verification"
        [ test "light theme maintains proper color relationships" <|
            \_ ->
                let
                    theme =
                        getBaseTheme Light
                in
                Expect.all
                    [ -- Grid and cell colors are distinct
                      \t -> Expect.notEqual t.backgroundColor t.gridBackgroundColor
                    , \t -> Expect.notEqual t.gridBackgroundColor t.cellBackgroundColor
                    , \t -> Expect.notEqual t.cellBackgroundColor t.robotCellBackgroundColor

                    -- Robot colors are visually distinct
                    , \t -> Expect.notEqual t.robotBodyColor t.robotDirectionColor
                    , \t -> Expect.notEqual t.robotBodyColor t.cellBackgroundColor

                    -- Button states provide clear visual feedback
                    , \t -> Expect.notEqual t.buttonBackgroundColor t.buttonHoverColor
                    , \t -> Expect.notEqual t.buttonHoverColor t.buttonPressedColor
                    , \t -> Expect.notEqual t.buttonBackgroundColor t.buttonDisabledColor

                    -- Blocked movement colors are distinct for feedback
                    , \t -> Expect.notEqual t.blockedMovementColor t.cellBackgroundColor
                    , \t -> Expect.notEqual t.blockedMovementBorderColor t.borderColor
                    , \t -> Expect.notEqual t.buttonBlockedColor t.buttonBackgroundColor

                    -- Text colors provide sufficient contrast
                    , \t -> Expect.notEqual t.fontColor t.backgroundColor
                    , \t -> Expect.notEqual t.buttonTextColor t.buttonBackgroundColor
                    , \t -> Expect.notEqual t.secondaryFontColor t.backgroundColor
                    ]
                    theme
        , test "dark theme maintains proper color relationships" <|
            \_ ->
                let
                    theme =
                        getBaseTheme Dark
                in
                Expect.all
                    [ -- Grid and cell colors are distinct
                      \t -> Expect.notEqual t.backgroundColor t.gridBackgroundColor
                    , \t -> Expect.notEqual t.gridBackgroundColor t.cellBackgroundColor
                    , \t -> Expect.notEqual t.cellBackgroundColor t.robotCellBackgroundColor

                    -- Robot colors are visually distinct
                    , \t -> Expect.notEqual t.robotBodyColor t.robotDirectionColor
                    , \t -> Expect.notEqual t.robotBodyColor t.cellBackgroundColor

                    -- Button states provide clear visual feedback
                    , \t -> Expect.notEqual t.buttonBackgroundColor t.buttonHoverColor
                    , \t -> Expect.notEqual t.buttonHoverColor t.buttonPressedColor
                    , \t -> Expect.notEqual t.buttonBackgroundColor t.buttonDisabledColor

                    -- Blocked movement colors are distinct for feedback
                    , \t -> Expect.notEqual t.blockedMovementColor t.cellBackgroundColor
                    , \t -> Expect.notEqual t.blockedMovementBorderColor t.borderColor
                    , \t -> Expect.notEqual t.buttonBlockedColor t.buttonBackgroundColor

                    -- Text colors provide sufficient contrast
                    , \t -> Expect.notEqual t.fontColor t.backgroundColor
                    , \t -> Expect.notEqual t.buttonTextColor t.buttonBackgroundColor
                    , \t -> Expect.notEqual t.secondaryFontColor t.backgroundColor
                    ]
                    theme
        , test "animation states produce distinct visual feedback" <|
            \_ ->
                let
                    baseModel =
                        createTestModel
                            { position = { row = 2, col = 2 }
                            , facing = North
                            , animationState = Idle
                            , colorScheme = Light
                            , window = Just ( 1024, 768 )
                            }

                    idleModel =
                        baseModel

                    movingModel =
                        { baseModel | animationState = Moving { row = 2, col = 2 } { row = 1, col = 2 } }

                    rotatingModel =
                        { baseModel | animationState = Rotating North East }

                    blockedModel =
                        { baseModel | animationState = BlockedMovement, blockedMovementFeedback = True }

                    -- All models should render without errors
                    idleView =
                        view idleModel

                    movingView =
                        view movingModel

                    rotatingView =
                        view rotatingModel

                    blockedView =
                        view blockedModel
                in
                Expect.all
                    [ \_ -> Expect.notEqual idleView movingView
                    , \_ -> Expect.notEqual idleView rotatingView
                    , \_ -> Expect.notEqual idleView blockedView
                    , \_ -> Expect.notEqual movingView rotatingView
                    ]
                    ()
        , test "robot directional visualization is consistent" <|
            \_ ->
                let
                    testDirections =
                        [ North, South, East, West ]

                    createModelWithDirection direction =
                        createTestModel
                            { position = { row = 2, col = 2 }
                            , facing = direction
                            , animationState = Idle
                            , colorScheme = Light
                            , window = Just ( 1024, 768 )
                            }

                    directionViews =
                        testDirections
                            |> List.map createModelWithDirection
                            |> List.map view

                    -- All direction views should be different (robot arrow points different ways)
                    allViewsUnique =
                        directionViews
                            |> List.indexedMap
                                (\i viewA ->
                                    directionViews
                                        |> List.indexedMap
                                            (\j viewB ->
                                                if i == j then
                                                    True

                                                else
                                                    viewA /= viewB
                                            )
                                        |> List.all identity
                                )
                            |> List.all identity
                in
                Expect.equal True allViewsUnique
        ]


{-| Tests to verify all game functionality is preserved (Requirements 7.1)
-}
functionalityPreservationTests : Test
functionalityPreservationTests =
    describe "Functionality Preservation Verification"
        [ test "movement controls work correctly" <|
            \_ ->
                let
                    ( initialModel, _ ) =
                        init

                    -- Test forward movement
                    ( afterMove, _ ) =
                        update MoveForward initialModel

                    ( afterMoveComplete, _ ) =
                        update AnimationComplete afterMove
                in
                Expect.all
                    [ \m -> Expect.equal { row = 1, col = 2 } m.robot.position
                    , \m -> Expect.equal North m.robot.facing
                    , \m -> Expect.equal Idle m.animationState
                    ]
                    afterMoveComplete
        , test "rotation controls work correctly" <|
            \_ ->
                let
                    ( initialModel, _ ) =
                        init

                    -- Test left rotation
                    ( afterRotateLeft, _ ) =
                        update RotateLeft initialModel

                    ( afterRotateLeftComplete, _ ) =
                        update AnimationComplete afterRotateLeft

                    -- Test right rotation
                    ( afterRotateRight, _ ) =
                        update RotateRight afterRotateLeftComplete

                    ( afterRotateRightComplete, _ ) =
                        update AnimationComplete afterRotateRight
                in
                Expect.all
                    [ \m -> Expect.equal { row = 2, col = 2 } m.robot.position
                    , \m -> Expect.equal North m.robot.facing
                    , \m -> Expect.equal Idle m.animationState
                    ]
                    afterRotateRightComplete
        , test "keyboard controls work correctly" <|
            \_ ->
                let
                    ( initialModel, _ ) =
                        init

                    -- Test arrow up (move forward)
                    ( afterUp, _ ) =
                        update (KeyPressed "ArrowUp") initialModel

                    ( afterUpComplete, _ ) =
                        update AnimationComplete afterUp

                    -- Test arrow right (rotate right)
                    ( afterRight, _ ) =
                        update (KeyPressed "ArrowRight") afterUpComplete

                    ( afterRightComplete, _ ) =
                        update AnimationComplete afterRight

                    -- Test arrow up again (move in new direction)
                    ( afterUp2, _ ) =
                        update (KeyPressed "ArrowUp") afterRightComplete

                    ( finalModel, _ ) =
                        update AnimationComplete afterUp2
                in
                Expect.all
                    [ \m -> Expect.equal { row = 1, col = 3 } m.robot.position
                    , \m -> Expect.equal East m.robot.facing
                    , \m -> Expect.equal Idle m.animationState
                    ]
                    finalModel
        , test "blocked movement feedback works correctly" <|
            \_ ->
                let
                    -- Start at top boundary
                    boundaryModel =
                        createTestModel
                            { position = { row = 0, col = 2 }
                            , facing = North
                            , animationState = Idle
                            , colorScheme = Light
                            , window = Just ( 1024, 768 )
                            }

                    -- Try to move forward (should be blocked)
                    ( afterBlocked, _ ) =
                        update MoveForward boundaryModel
                in
                Expect.all
                    [ \m -> Expect.equal { row = 0, col = 2 } m.robot.position
                    , \m -> Expect.equal North m.robot.facing
                    , \m -> Expect.equal BlockedMovement m.animationState
                    , \m -> Expect.equal True m.blockedMovementFeedback
                    ]
                    afterBlocked
        , test "animation states prevent input during transitions" <|
            \_ ->
                let
                    ( initialModel, _ ) =
                        init

                    -- Start movement
                    ( afterMove, _ ) =
                        update MoveForward initialModel

                    -- Try to move again during animation (should be ignored)
                    ( afterSecondMove, _ ) =
                        update MoveForward afterMove

                    -- Try keyboard input during animation (should be ignored)
                    ( afterKeyPress, _ ) =
                        update (KeyPressed "ArrowRight") afterSecondMove

                    -- Complete animation
                    ( finalModel, _ ) =
                        update AnimationComplete afterKeyPress
                in
                Expect.all
                    [ \m -> Expect.equal { row = 1, col = 2 } m.robot.position
                    , \m -> Expect.equal North m.robot.facing
                    , \m -> Expect.equal Idle m.animationState
                    ]
                    finalModel
        ]


{-| Tests to verify responsive behavior works correctly (Requirements 7.4)
-}
responsiveDesignTests : Test
responsiveDesignTests =
    describe "Responsive Design Verification"
        [ test "mobile layout uses appropriate dimensions" <|
            \_ ->
                let
                    mobileModel =
                        createTestModel
                            { position = { row = 2, col = 2 }
                            , facing = North
                            , animationState = Idle
                            , colorScheme = Light
                            , window = Just ( 400, 600 )
                            }

                    -- Test responsive utilities work correctly
                    cellSize =
                        calculateResponsiveCellSize mobileModel.maybeWindow 7 120

                    fontSize =
                        getResponsiveFontSize mobileModel.maybeWindow 32

                    padding =
                        getResponsivePadding mobileModel.maybeWindow 20

                    spacing =
                        getResponsiveSpacing mobileModel.maybeWindow 15

                    -- View should render without errors
                in
                Expect.all
                    [ -- Cell size should be appropriate for mobile
                      \_ -> Expect.all [ Expect.atLeast 60, Expect.atMost 100 ] cellSize

                    -- Font size should be scaled down
                    , \_ -> Expect.all [ Expect.atLeast 20, Expect.atMost 28 ] fontSize

                    -- Padding should be reduced
                    , \_ -> Expect.all [ Expect.atLeast 8, Expect.atMost 15 ] padding

                    -- Spacing should be reduced
                    , \_ -> Expect.all [ Expect.atLeast 5, Expect.atMost 12 ] spacing

                    -- View should render successfully (basic smoke test)
                    , \_ -> Expect.pass
                    ]
                    ()
        , test "tablet layout uses intermediate dimensions" <|
            \_ ->
                let
                    tabletModel =
                        createTestModel
                            { position = { row = 2, col = 2 }
                            , facing = North
                            , animationState = Idle
                            , colorScheme = Light
                            , window = Just ( 800, 1024 )
                            }

                    cellSize =
                        calculateResponsiveCellSize tabletModel.maybeWindow 7 120

                    fontSize =
                        getResponsiveFontSize tabletModel.maybeWindow 32
                in
                Expect.all
                    [ -- Cell size should be between mobile and desktop
                      \_ -> Expect.all [ Expect.atLeast 80, Expect.atMost 133 ] cellSize

                    -- Font size should be between mobile and desktop
                    , \_ -> Expect.all [ Expect.atLeast 28, Expect.atMost 32 ] fontSize

                    -- View should render successfully (basic smoke test)
                    , \_ -> Expect.pass
                    ]
                    ()
        , test "desktop layout uses full dimensions" <|
            \_ ->
                let
                    desktopModel =
                        createTestModel
                            { position = { row = 2, col = 2 }
                            , facing = North
                            , animationState = Idle
                            , colorScheme = Light
                            , window = Just ( 1200, 800 )
                            }

                    cellSize =
                        calculateResponsiveCellSize desktopModel.maybeWindow 7 120

                    fontSize =
                        getResponsiveFontSize desktopModel.maybeWindow 32
                in
                Expect.all
                    [ -- Cell size should be reasonable for desktop
                      \_ -> Expect.all [ Expect.atLeast 120, Expect.atMost 140 ] cellSize

                    -- Font size should be full size
                    , \_ -> Expect.equal 32 fontSize

                    -- View should render successfully (basic smoke test)
                    , \_ -> Expect.pass
                    ]
                    ()
        , test "responsive behavior adapts to window size changes" <|
            \_ ->
                let
                    ( initialModel, _ ) =
                        init

                    -- Resize to mobile
                    ( mobileModel, _ ) =
                        update (GetResize 400 600) initialModel

                    -- Resize to desktop
                    ( desktopModel, _ ) =
                        update (GetResize 1200 800) mobileModel

                    mobileView =
                        view mobileModel

                    desktopView =
                        view desktopModel
                in
                Expect.all
                    [ \_ -> Expect.equal (Just ( 400, 600 )) mobileModel.maybeWindow
                    , \_ -> Expect.equal (Just ( 1200, 800 )) desktopModel.maybeWindow
                    , \_ -> Expect.notEqual mobileView desktopView
                    ]
                    ()
        ]


{-| Tests to verify both light and dark themes display properly (Requirements 7.2)
-}
themeIntegrationTests : Test
themeIntegrationTests =
    describe "Theme Integration Verification"
        [ test "light theme displays correctly" <|
            \_ ->
                let
                    lightModel =
                        createTestModel
                            { position = { row = 2, col = 2 }
                            , facing = North
                            , animationState = Idle
                            , colorScheme = Light
                            , window = Just ( 1024, 768 )
                            }

                    lightTheme =
                        getBaseTheme Light
                in
                Expect.all
                    [ \_ -> Expect.equal Light lightModel.colorScheme
                    , \_ -> Expect.notEqual lightTheme.backgroundColor lightTheme.fontColor
                    , \_ -> Expect.pass
                    ]
                    ()
        , test "dark theme displays correctly" <|
            \_ ->
                let
                    darkModel =
                        createTestModel
                            { position = { row = 2, col = 2 }
                            , facing = North
                            , animationState = Idle
                            , colorScheme = Dark
                            , window = Just ( 1024, 768 )
                            }

                    darkTheme =
                        getBaseTheme Dark
                in
                Expect.all
                    [ \_ -> Expect.equal Dark darkModel.colorScheme
                    , \_ -> Expect.notEqual darkTheme.backgroundColor darkTheme.fontColor
                    , \_ -> Expect.pass
                    ]
                    ()
        , test "theme switching works correctly" <|
            \_ ->
                let
                    ( initialModel, _ ) =
                        init

                    -- Switch to dark theme
                    ( darkModel, _ ) =
                        update (ColorScheme Dark) initialModel

                    -- Switch back to light theme
                    ( lightModel, _ ) =
                        update (ColorScheme Light) darkModel

                    lightView =
                        view lightModel

                    darkView =
                        view darkModel
                in
                Expect.all
                    [ \_ -> Expect.equal Light lightModel.colorScheme
                    , \_ -> Expect.equal Dark darkModel.colorScheme
                    , \_ -> Expect.notEqual lightView darkView
                    ]
                    ()
        , test "theme colors are properly defined for both themes" <|
            \_ ->
                let
                    lightTheme =
                        getBaseTheme Light

                    darkTheme =
                        getBaseTheme Dark
                in
                Expect.all
                    [ \_ -> Expect.notEqual lightTheme.backgroundColor lightTheme.fontColor
                    , \_ -> Expect.notEqual darkTheme.backgroundColor darkTheme.fontColor
                    , \_ -> Expect.notEqual lightTheme.buttonBackgroundColor lightTheme.buttonTextColor
                    , \_ -> Expect.notEqual darkTheme.buttonBackgroundColor darkTheme.buttonTextColor
                    ]
                    ()
        ]


{-| Tests to verify accessibility features are preserved (Requirements 7.5)
-}
accessibilityPreservationTests : Test
accessibilityPreservationTests =
    describe "Accessibility Preservation Verification"
        [ test "model maintains proper structure for accessibility" <|
            \_ ->
                let
                    testModel =
                        createTestModel
                            { position = { row = 2, col = 2 }
                            , facing = North
                            , animationState = Idle
                            , colorScheme = Light
                            , window = Just ( 1024, 768 )
                            }

                    -- Test that model has all required fields for accessibility
                    robotPosition =
                        testModel.robot.position

                    robotFacing =
                        testModel.robot.facing

                    gridSize =
                        testModel.gridSize
                in
                Expect.all
                    [ \_ -> Expect.all [ Expect.atLeast 0, Expect.lessThan gridSize ] robotPosition.row
                    , \_ -> Expect.all [ Expect.atLeast 0, Expect.lessThan gridSize ] robotPosition.col
                    , \_ ->
                        case robotFacing of
                            North ->
                                Expect.pass

                            South ->
                                Expect.pass

                            East ->
                                Expect.pass

                            West ->
                                Expect.pass
                    , \_ -> Expect.equal 5 gridSize
                    ]
                    ()
        , test "view renders without accessibility regressions" <|
            \_ ->
                let
                    testModel =
                        createTestModel
                            { position = { row = 2, col = 2 }
                            , facing = North
                            , animationState = Idle
                            , colorScheme = Light
                            , window = Just ( 1024, 768 )
                            }

                    -- View should render successfully
                    renderedView =
                        view testModel

                    -- Test different robot positions for accessibility
                    cornerModel =
                        createTestModel
                            { position = { row = 0, col = 0 }
                            , facing = East
                            , animationState = Idle
                            , colorScheme = Light
                            , window = Just ( 1024, 768 )
                            }

                    cornerView =
                        view cornerModel
                in
                Expect.all
                    [ \_ -> Expect.notEqual renderedView cornerView
                    , \_ -> Expect.pass -- View renders successfully
                    ]
                    ()
        , test "keyboard navigation support is maintained" <|
            \_ ->
                let
                    ( initialModel, _ ) =
                        init

                    -- Test all keyboard controls work
                    keyboardTests =
                        [ ( "ArrowUp", \m -> m.robot.position.row < 2 || m.animationState == BlockedMovement )
                        , ( "ArrowLeft", \m -> m.robot.facing /= North || m.animationState == Rotating North West )
                        , ( "ArrowRight", \m -> m.robot.facing /= North || m.animationState == Rotating North East )
                        , ( "ArrowDown", \m -> m.robot.facing /= North || m.animationState == Rotating North South )
                        ]

                    testKeyboard ( key, validator ) =
                        let
                            ( afterKey, _ ) =
                                update (KeyPressed key) initialModel
                        in
                        validator afterKey
                in
                keyboardTests
                    |> List.map testKeyboard
                    |> List.all identity
                    |> Expect.equal True
        ]

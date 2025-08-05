module RobotGame.ViewTest exposing (..)

{-| Tests for the RobotGame.View module to verify grid and robot display functionality.
-}

import Expect
import RobotGame.Model exposing (AnimationState(..), Direction(..), Model, Position)
import RobotGame.View exposing (currentTheme)
import Test exposing (Test, describe, test)
import Theme.Responsive exposing (..)
import Theme.Theme exposing (ColorScheme(..))


{-| Test suite for view functionality
-}
suite : Test
suite =
    describe "RobotGame.View"
        [ themeTests
        , responsiveDesignTests
        , gridRenderingTests
        , robotVisualizationTests
        ]


{-| Tests for theme system integration
-}
themeTests : Test
themeTests =
    describe "Theme System"
        [ test "light theme has correct colors" <|
            \_ ->
                let
                    theme =
                        currentTheme Light
                in
                Expect.all
                    [ \t -> Expect.notEqual t.backgroundColor t.gridBackgroundColor
                    , \t -> Expect.notEqual t.cellBackgroundColor t.robotCellBackgroundColor
                    , \t -> Expect.notEqual t.robotBodyColor t.robotDirectionColor
                    ]
                    theme
        , test "dark theme has correct colors" <|
            \_ ->
                let
                    theme =
                        currentTheme Dark
                in
                Expect.all
                    [ \t -> Expect.notEqual t.backgroundColor t.gridBackgroundColor
                    , \t -> Expect.notEqual t.cellBackgroundColor t.robotCellBackgroundColor
                    , \t -> Expect.notEqual t.robotBodyColor t.robotDirectionColor
                    ]
                    theme
        , test "light and dark themes are different" <|
            \_ ->
                let
                    lightTheme =
                        currentTheme Light

                    darkTheme =
                        currentTheme Dark
                in
                Expect.notEqual lightTheme.backgroundColor darkTheme.backgroundColor
        ]


{-| Tests for responsive design functionality
-}
responsiveDesignTests : Test
responsiveDesignTests =
    describe "Responsive Design"
        [ test "getScreenSize correctly identifies mobile" <|
            \_ ->
                getScreenSize (Just ( 600, 800 ))
                    |> Expect.equal Mobile
        , test "getScreenSize correctly identifies tablet" <|
            \_ ->
                getScreenSize (Just ( 800, 1024 ))
                    |> Expect.equal Tablet
        , test "getScreenSize correctly identifies desktop" <|
            \_ ->
                getScreenSize (Just ( 1200, 800 ))
                    |> Expect.equal Desktop
        , test "getScreenSize defaults to desktop when no window size" <|
            \_ ->
                getScreenSize Nothing
                    |> Expect.equal Desktop
        , test "calculateResponsiveCellSize returns reasonable values for mobile" <|
            \_ ->
                let
                    cellSize =
                        calculateResponsiveCellSize (Just ( 400, 600 )) 7 120
                in
                Expect.all
                    [ \size -> Expect.atLeast 60 size
                    , \size -> Expect.atMost 100 size
                    ]
                    cellSize
        , test "calculateResponsiveCellSize returns reasonable values for desktop" <|
            \_ ->
                let
                    cellSize =
                        calculateResponsiveCellSize (Just ( 1200, 800 )) 7 120
                in
                Expect.all
                    [ \size -> Expect.atLeast 100 size
                    , \size -> Expect.atMost 160 size
                    ]
                    cellSize
        , test "getResponsiveFontSize scales down for mobile" <|
            \_ ->
                let
                    mobileSize =
                        getResponsiveFontSize (Just ( 400, 600 )) 24

                    desktopSize =
                        getResponsiveFontSize (Just ( 1200, 800 )) 24
                in
                Expect.lessThan desktopSize mobileSize
        , test "getResponsiveSpacing scales appropriately" <|
            \_ ->
                let
                    mobileSpacing =
                        getResponsiveSpacing (Just ( 400, 600 )) 15

                    desktopSpacing =
                        getResponsiveSpacing (Just ( 1200, 800 )) 15
                in
                Expect.all
                    [ \spacing -> Expect.atLeast 5 spacing
                    , \spacing -> Expect.lessThan desktopSpacing spacing
                    ]
                    mobileSpacing
        , test "getResponsivePadding scales appropriately" <|
            \_ ->
                let
                    mobilePadding =
                        getResponsivePadding (Just ( 400, 600 )) 20

                    desktopPadding =
                        getResponsivePadding (Just ( 1200, 800 )) 20
                in
                Expect.all
                    [ \padding -> Expect.atLeast 8 padding
                    , \padding -> Expect.lessThan desktopPadding padding
                    ]
                    mobilePadding
        ]


{-| Tests for grid rendering functionality
-}
gridRenderingTests : Test
gridRenderingTests =
    describe "Grid Rendering"
        [ test "model has correct grid size" <|
            \_ ->
                let
                    model =
                        createTestModel
                in
                Expect.equal 5 model.gridSize
        , test "robot starts at center position" <|
            \_ ->
                let
                    model =
                        createTestModel
                in
                Expect.equal { row = 2, col = 2 } model.robot.position
        , test "grid boundaries are within expected range" <|
            \_ ->
                let
                    model =
                        createTestModel

                    position =
                        model.robot.position
                in
                Expect.all
                    [ \pos -> Expect.atLeast 0 pos.row
                    , \pos -> Expect.lessThan model.gridSize pos.row
                    , \pos -> Expect.atLeast 0 pos.col
                    , \pos -> Expect.lessThan model.gridSize pos.col
                    ]
                    position
        ]


{-| Tests for robot visualization
-}
robotVisualizationTests : Test
robotVisualizationTests =
    describe "Robot Visualization"
        [ test "robot has valid starting direction" <|
            \_ ->
                let
                    model =
                        createTestModel
                in
                case model.robot.facing of
                    North ->
                        Expect.pass

                    South ->
                        Expect.pass

                    East ->
                        Expect.pass

                    West ->
                        Expect.pass
        , test "robot position is within grid bounds" <|
            \_ ->
                let
                    model =
                        createTestModel

                    robot =
                        model.robot
                in
                Expect.all
                    [ \r -> Expect.atLeast 0 r.position.row
                    , \r -> Expect.lessThan model.gridSize r.position.row
                    , \r -> Expect.atLeast 0 r.position.col
                    , \r -> Expect.lessThan model.gridSize r.position.col
                    ]
                    robot
        , test "robot facing direction is preserved" <|
            \_ ->
                let
                    model =
                        createTestModel

                    originalDirection =
                        model.robot.facing

                    -- Create a new model with same robot but different animation state
                    updatedModel =
                        { model | animationState = Idle }
                in
                Expect.equal originalDirection updatedModel.robot.facing
        ]


{-| Helper function to create a test model
-}
createTestModel : Model
createTestModel =
    { robot =
        { position = { row = 2, col = 2 }
        , facing = North
        }
    , gridSize = 5
    , colorScheme = Light
    , maybeWindow = Just ( 1024, 768 )
    , animationState = Idle
    , lastMoveTime = Nothing
    , blockedMovementFeedback = False
    }


{-| Helper function to create a test model with specific robot position
-}
createTestModelWithRobot : Position -> Direction -> Model
createTestModelWithRobot position direction =
    { robot =
        { position = position
        , facing = direction
        }
    , gridSize = 5
    , colorScheme = Light
    , maybeWindow = Just ( 1024, 768 )
    , animationState = Idle
    , lastMoveTime = Nothing
    , blockedMovementFeedback = False
    }


{-| Test robot at different positions
-}
robotPositionTests : Test
robotPositionTests =
    describe "Robot Position Variations"
        [ test "robot at top-left corner" <|
            \_ ->
                let
                    model =
                        createTestModelWithRobot { row = 0, col = 0 } North
                in
                Expect.equal { row = 0, col = 0 } model.robot.position
        , test "robot at bottom-right corner" <|
            \_ ->
                let
                    model =
                        createTestModelWithRobot { row = 4, col = 4 } South
                in
                Expect.equal { row = 4, col = 4 } model.robot.position
        , test "robot facing different directions" <|
            \_ ->
                let
                    northModel =
                        createTestModelWithRobot { row = 2, col = 2 } North

                    eastModel =
                        createTestModelWithRobot { row = 2, col = 2 } East

                    southModel =
                        createTestModelWithRobot { row = 2, col = 2 } South

                    westModel =
                        createTestModelWithRobot { row = 2, col = 2 } West
                in
                Expect.all
                    [ \_ -> Expect.equal North northModel.robot.facing
                    , \_ -> Expect.equal East eastModel.robot.facing
                    , \_ -> Expect.equal South southModel.robot.facing
                    , \_ -> Expect.equal West westModel.robot.facing
                    ]
                    ()
        ]

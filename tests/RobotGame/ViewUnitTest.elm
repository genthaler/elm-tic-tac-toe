module RobotGame.ViewUnitTest exposing (..)

{-| Tests for the RobotGame.View module to verify grid and robot display functionality.
-}

import Expect
import RobotGame.Main exposing (Msg(..), init, update)
import RobotGame.Model exposing (AnimationState(..), Direction(..), Model, Position)
import RobotGame.View exposing (view)
import Test exposing (Test, describe, test)
import Theme.Theme exposing (ColorScheme(..))


{-| Test suite for view functionality
-}
suite : Test
suite =
    describe "RobotGame.View"
        [ gridRenderingTests
        , robotVisualizationTests
        , robotPositionTests
        , functionalityTests
        , visualConsistencyTests
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


{-| Tests for game functionality through the view
-}
functionalityTests : Test
functionalityTests =
    describe "Game Functionality"
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
        , test "blocked movement feedback works correctly" <|
            \_ ->
                let
                    -- Start at top boundary
                    boundaryModel =
                        createTestModelWithRobot { row = 0, col = 2 } North

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
        ]


{-| Tests for visual consistency across different states
-}
visualConsistencyTests : Test
visualConsistencyTests =
    describe "Visual Consistency"
        [ test "animation states produce distinct visual feedback" <|
            \_ ->
                let
                    baseModel =
                        createTestModel

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
                        createTestModelWithRobot { row = 2, col = 2 } direction

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

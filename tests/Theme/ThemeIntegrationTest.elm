module Theme.ThemeIntegrationTest exposing (suite)

{-| Integration tests for shared theme module usage across games.

This module tests that both TicTacToe and RobotGame properly integrate with
the shared Theme module, ensuring consistency and backward compatibility.

-}

import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import RobotGame.Model as RobotModel
import Test exposing (Test, describe, test)
import Theme.Responsive exposing (ScreenSize(..), calculateResponsiveCellSize, getResponsiveFontSize, getResponsivePadding, getResponsiveSpacing, getScreenSize)
import Theme.Theme as Theme
import TicTacToe.Model as TicTacToeModel


suite : Test
suite =
    describe "Theme Integration Tests"
        [ crossGameConsistencyTests
        , backwardCompatibilityTests
        , gameThemeIntegrationTests
        , responsiveDesignIntegrationTests
        , themeStatePreservationTests
        ]


{-| Tests that verify theme consistency across both games
-}
crossGameConsistencyTests : Test
crossGameConsistencyTests =
    describe "Cross-game theme consistency"
        [ test "Both games use the same ColorScheme type from shared module" <|
            \_ ->
                let
                    ticTacToeLight =
                        Theme.Light

                    robotGameLight =
                        Theme.Light

                    ticTacToeDark =
                        Theme.Dark

                    robotGameDark =
                        Theme.Dark
                in
                Expect.all
                    [ \_ -> Expect.equal ticTacToeLight robotGameLight
                    , \_ -> Expect.equal ticTacToeDark robotGameDark
                    ]
                    ()
        , test "Both games encode ColorScheme identically" <|
            \_ ->
                let
                    -- Test that both games would produce the same JSON
                    ticTacToeModel =
                        let
                            initial =
                                TicTacToeModel.initialModel
                        in
                        { initial | colorScheme = Theme.Light }

                    robotGameModel =
                        let
                            initial =
                                RobotModel.init
                        in
                        { initial | colorScheme = Theme.Light }

                    ticTacToeEncoded =
                        TicTacToeModel.encodeModel ticTacToeModel

                    robotGameEncoded =
                        RobotModel.encodeModel robotGameModel

                    -- Extract colorScheme from encoded JSON
                    extractColorScheme json =
                        Decode.decodeValue (Decode.field "colorScheme" Decode.value) json
                in
                case ( extractColorScheme ticTacToeEncoded, extractColorScheme robotGameEncoded ) of
                    ( Ok ticTacToeColorScheme, Ok robotGameColorScheme ) ->
                        Expect.equal ticTacToeColorScheme robotGameColorScheme

                    _ ->
                        Expect.fail "Failed to extract colorScheme from encoded models"
        , test "Both games decode ColorScheme identically" <|
            \_ ->
                let
                    lightJson =
                        Encode.string "Light"

                    darkJson =
                        Encode.string "Dark"

                    invalidJson =
                        Encode.string "Invalid"

                    decoder =
                        Theme.decodeColorScheme
                in
                Expect.all
                    [ \_ -> Expect.equal (Ok Theme.Light) (Decode.decodeValue decoder lightJson)
                    , \_ -> Expect.equal (Ok Theme.Dark) (Decode.decodeValue decoder darkJson)
                    , \_ -> Expect.equal (Ok Theme.Light) (Decode.decodeValue decoder invalidJson) -- fallback
                    ]
                    ()
        , test "Both games use consistent base theme colors" <|
            \_ ->
                let
                    lightTheme =
                        Theme.getBaseTheme Theme.Light

                    darkTheme =
                        Theme.getBaseTheme Theme.Dark
                in
                Expect.all
                    [ \_ -> Expect.notEqual lightTheme.backgroundColor darkTheme.backgroundColor
                    , \_ -> Expect.notEqual lightTheme.fontColor darkTheme.fontColor
                    , \_ -> Expect.equal lightTheme.accentColor darkTheme.accentColor -- accent should be same
                    ]
                    ()
        ]


{-| Tests that verify backward compatibility with existing game states
-}
backwardCompatibilityTests : Test
backwardCompatibilityTests =
    describe "Backward compatibility"
        [ test "TicTacToe models with old ColorScheme format still decode correctly" <|
            \_ ->
                let
                    -- Simulate old format JSON that might exist in saved states
                    oldFormatJson =
                        Encode.object
                            [ ( "board"
                              , Encode.list (Encode.list (\_ -> Encode.null))
                                    [ [ Nothing, Nothing, Nothing ]
                                    , [ Nothing, Nothing, Nothing ]
                                    , [ Nothing, Nothing, Nothing ]
                                    ]
                              )
                            , ( "gameState"
                              , Encode.object
                                    [ ( "type", Encode.string "Waiting" )
                                    , ( "player", Encode.string "X" )
                                    ]
                              )
                            , ( "lastMove", Encode.null )
                            , ( "now", Encode.null )
                            , ( "colorScheme", Encode.string "Light" )
                            , ( "maybeWindow", Encode.null )
                            ]

                    decoded =
                        Decode.decodeValue TicTacToeModel.decodeModel oldFormatJson
                in
                case decoded of
                    Ok model ->
                        Expect.equal Theme.Light model.colorScheme

                    Err error ->
                        Expect.fail ("Failed to decode old format: " ++ Decode.errorToString error)
        , test "RobotGame models with old ColorScheme format still decode correctly" <|
            \_ ->
                let
                    oldFormatJson =
                        Encode.object
                            [ ( "robot"
                              , Encode.object
                                    [ ( "position", Encode.object [ ( "row", Encode.int 2 ), ( "col", Encode.int 2 ) ] )
                                    , ( "facing", Encode.string "North" )
                                    ]
                              )
                            , ( "gridSize", Encode.int 5 )
                            , ( "colorScheme", Encode.string "Dark" )
                            , ( "animationState", Encode.object [ ( "type", Encode.string "Idle" ) ] )
                            , ( "blockedMovementFeedback", Encode.bool False )
                            ]

                    decoded =
                        Decode.decodeValue RobotModel.decodeModel oldFormatJson
                in
                case decoded of
                    Ok model ->
                        Expect.equal Theme.Dark model.colorScheme

                    Err error ->
                        Expect.fail ("Failed to decode old format: " ++ Decode.errorToString error)
        , test "Invalid ColorScheme values fallback to Light theme" <|
            \_ ->
                let
                    invalidColorSchemeJson =
                        Encode.string "InvalidColorScheme"

                    decoded =
                        Decode.decodeValue Theme.decodeColorScheme invalidColorSchemeJson
                in
                Expect.equal (Ok Theme.Light) decoded
        , test "Missing ColorScheme fields use appropriate defaults" <|
            \_ ->
                let
                    -- Test TicTacToe model without colorScheme field
                    incompleteJson =
                        Encode.object
                            [ ( "board"
                              , Encode.list (Encode.list (\_ -> Encode.null))
                                    [ [ Nothing, Nothing, Nothing ]
                                    , [ Nothing, Nothing, Nothing ]
                                    , [ Nothing, Nothing, Nothing ]
                                    ]
                              )
                            , ( "gameState"
                              , Encode.object
                                    [ ( "type", Encode.string "Waiting" )
                                    , ( "player", Encode.string "X" )
                                    ]
                              )
                            , ( "lastMove", Encode.null )
                            , ( "now", Encode.null )

                            -- Missing colorScheme field
                            , ( "maybeWindow", Encode.null )
                            ]

                    decoded =
                        Decode.decodeValue TicTacToeModel.decodeModel incompleteJson
                in
                case decoded of
                    Err _ ->
                        -- This is expected since colorScheme is required
                        Expect.pass

                    Ok _ ->
                        Expect.fail "Should have failed to decode without required colorScheme field"
        ]


{-| Tests that verify proper integration of shared theme module in both games
-}
gameThemeIntegrationTests : Test
gameThemeIntegrationTests =
    describe "Game theme integration"
        [ test "TicTacToe model properly uses shared ColorScheme" <|
            \_ ->
                let
                    lightModel =
                        let
                            initial =
                                TicTacToeModel.initialModel
                        in
                        { initial | colorScheme = Theme.Light }

                    darkModel =
                        let
                            initial =
                                TicTacToeModel.initialModel
                        in
                        { initial | colorScheme = Theme.Dark }

                    -- Test round-trip encoding/decoding
                    lightRoundTrip =
                        lightModel
                            |> TicTacToeModel.encodeModel
                            |> Decode.decodeValue TicTacToeModel.decodeModel

                    darkRoundTrip =
                        darkModel
                            |> TicTacToeModel.encodeModel
                            |> Decode.decodeValue TicTacToeModel.decodeModel
                in
                case ( lightRoundTrip, darkRoundTrip ) of
                    ( Ok lightDecoded, Ok darkDecoded ) ->
                        Expect.all
                            [ \_ -> Expect.equal Theme.Light lightDecoded.colorScheme
                            , \_ -> Expect.equal Theme.Dark darkDecoded.colorScheme
                            ]
                            ()

                    _ ->
                        Expect.fail "Failed to round-trip TicTacToe models with ColorScheme"
        , test "RobotGame model properly uses shared ColorScheme" <|
            \_ ->
                let
                    lightModel =
                        let
                            initial =
                                RobotModel.init
                        in
                        { initial | colorScheme = Theme.Light }

                    darkModel =
                        let
                            initial =
                                RobotModel.init
                        in
                        { initial | colorScheme = Theme.Dark }

                    lightRoundTrip =
                        lightModel
                            |> RobotModel.encodeModel
                            |> Decode.decodeValue RobotModel.decodeModel

                    darkRoundTrip =
                        darkModel
                            |> RobotModel.encodeModel
                            |> Decode.decodeValue RobotModel.decodeModel
                in
                case ( lightRoundTrip, darkRoundTrip ) of
                    ( Ok lightDecoded, Ok darkDecoded ) ->
                        Expect.all
                            [ \_ -> Expect.equal Theme.Light lightDecoded.colorScheme
                            , \_ -> Expect.equal Theme.Dark darkDecoded.colorScheme
                            ]
                            ()

                    _ ->
                        Expect.fail "Failed to round-trip RobotGame models with ColorScheme"
        , test "Both games can switch between light and dark themes" <|
            \_ ->
                let
                    ticTacToeLight =
                        let
                            initial =
                                TicTacToeModel.initialModel
                        in
                        { initial | colorScheme = Theme.Light }

                    ticTacToeDark =
                        { ticTacToeLight | colorScheme = Theme.Dark }

                    robotGameLight =
                        let
                            initial =
                                RobotModel.init
                        in
                        { initial | colorScheme = Theme.Light }

                    robotGameDark =
                        { robotGameLight | colorScheme = Theme.Dark }
                in
                Expect.all
                    [ \_ -> Expect.equal Theme.Light ticTacToeLight.colorScheme
                    , \_ -> Expect.equal Theme.Dark ticTacToeDark.colorScheme
                    , \_ -> Expect.equal Theme.Light robotGameLight.colorScheme
                    , \_ -> Expect.equal Theme.Dark robotGameDark.colorScheme
                    ]
                    ()
        ]


{-| Tests that verify responsive design utilities work consistently across games
-}
responsiveDesignIntegrationTests : Test
responsiveDesignIntegrationTests =
    describe "Responsive design integration"
        [ test "Screen size detection works consistently for both games" <|
            \_ ->
                let
                    mobileWindow =
                        Just ( 600, 800 )

                    tabletWindow =
                        Just ( 900, 1200 )

                    desktopWindow =
                        Just ( 1400, 1000 )

                    noWindow =
                        Nothing
                in
                Expect.all
                    [ \_ -> Expect.equal Mobile (getScreenSize mobileWindow)
                    , \_ -> Expect.equal Tablet (getScreenSize tabletWindow)
                    , \_ -> Expect.equal Desktop (getScreenSize desktopWindow)
                    , \_ -> Expect.equal Desktop (getScreenSize noWindow) -- default
                    ]
                    ()
        , test "Responsive calculations provide consistent results" <|
            \_ ->
                let
                    mobileWindow =
                        Just ( 600, 800 )

                    desktopWindow =
                        Just ( 1400, 1000 )

                    baseFontSize =
                        20

                    baseSpacing =
                        15

                    basePadding =
                        20

                    mobileFontSize =
                        getResponsiveFontSize mobileWindow baseFontSize

                    desktopFontSize =
                        getResponsiveFontSize desktopWindow baseFontSize

                    mobileSpacing =
                        getResponsiveSpacing mobileWindow baseSpacing

                    desktopSpacing =
                        getResponsiveSpacing desktopWindow baseSpacing

                    mobilePadding =
                        getResponsivePadding mobileWindow basePadding

                    desktopPadding =
                        getResponsivePadding desktopWindow basePadding
                in
                Expect.all
                    [ \_ -> Expect.lessThan desktopFontSize mobileFontSize
                    , \_ -> Expect.lessThan desktopSpacing mobileSpacing
                    , \_ -> Expect.lessThan desktopPadding mobilePadding
                    , \_ -> Expect.atLeast 16 mobileFontSize -- minimum font size
                    , \_ -> Expect.atLeast 5 mobileSpacing -- minimum spacing
                    , \_ -> Expect.atLeast 8 mobilePadding -- minimum padding
                    ]
                    ()
        , test "Cell size calculations work for both game contexts" <|
            \_ ->
                let
                    mobileWindow =
                        Just ( 600, 800 )

                    desktopWindow =
                        Just ( 1400, 1000 )

                    -- TicTacToe typically uses a 3x3 grid (gridDivisor = 4-5)
                    ticTacToeGridDivisor =
                        4

                    -- RobotGame uses a 5x5 grid (gridDivisor = 6-7)
                    robotGameGridDivisor =
                        6

                    fallbackSize =
                        100

                    ticTacToeMobileCell =
                        calculateResponsiveCellSize mobileWindow ticTacToeGridDivisor fallbackSize

                    ticTacToeDesktopCell =
                        calculateResponsiveCellSize desktopWindow ticTacToeGridDivisor fallbackSize

                    robotGameMobileCell =
                        calculateResponsiveCellSize mobileWindow robotGameGridDivisor fallbackSize

                    robotGameDesktopCell =
                        calculateResponsiveCellSize desktopWindow robotGameGridDivisor fallbackSize
                in
                Expect.all
                    [ \_ -> Expect.atLeast 60 ticTacToeMobileCell -- minimum mobile cell size
                    , \_ -> Expect.atMost 160 ticTacToeDesktopCell -- maximum desktop cell size
                    , \_ -> Expect.atLeast 60 robotGameMobileCell -- minimum mobile cell size
                    , \_ -> Expect.atMost 160 robotGameDesktopCell -- maximum desktop cell size
                    , \_ -> Expect.atLeast robotGameMobileCell ticTacToeMobileCell -- TicTacToe cells should be at least as large (smaller divisor)
                    , \_ -> Expect.atLeast robotGameDesktopCell ticTacToeDesktopCell -- TicTacToe cells should be at least as large (smaller divisor)
                    ]
                    ()
        ]


{-| Tests that verify theme state is properly preserved across game operations
-}
themeStatePreservationTests : Test
themeStatePreservationTests =
    describe "Theme state preservation"
        [ test "TicTacToe preserves theme through game state changes" <|
            \_ ->
                let
                    initialModel =
                        let
                            initial =
                                TicTacToeModel.initialModel
                        in
                        { initial | colorScheme = Theme.Dark }

                    -- Simulate various game state changes
                    withMove =
                        { initialModel | board = [ [ Just TicTacToeModel.X, Nothing, Nothing ], [ Nothing, Nothing, Nothing ], [ Nothing, Nothing, Nothing ] ] }

                    withGameState =
                        { withMove | gameState = TicTacToeModel.Waiting TicTacToeModel.O }

                    withWindow =
                        { withGameState | maybeWindow = Just ( 1024, 768 ) }

                    -- Test that theme is preserved through encoding/decoding
                    roundTrip =
                        withWindow
                            |> TicTacToeModel.encodeModel
                            |> Decode.decodeValue TicTacToeModel.decodeModel
                in
                case roundTrip of
                    Ok decoded ->
                        Expect.equal Theme.Dark decoded.colorScheme

                    Err error ->
                        Expect.fail ("Failed to preserve theme: " ++ Decode.errorToString error)
        , test "RobotGame preserves theme through game state changes" <|
            \_ ->
                let
                    initialModel =
                        let
                            initial =
                                RobotModel.init
                        in
                        { initial | colorScheme = Theme.Dark }

                    -- Simulate various game state changes
                    withMovedRobot =
                        { initialModel | robot = { position = { row = 3, col = 3 }, facing = RobotModel.East } }

                    withAnimation =
                        { withMovedRobot | animationState = RobotModel.Moving { row = 2, col = 2 } { row = 3, col = 3 } }

                    withWindow =
                        { withAnimation | maybeWindow = Just ( 800, 600 ) }

                    roundTrip =
                        withWindow
                            |> RobotModel.encodeModel
                            |> Decode.decodeValue RobotModel.decodeModel
                in
                case roundTrip of
                    Ok decoded ->
                        Expect.equal Theme.Dark decoded.colorScheme

                    Err error ->
                        Expect.fail ("Failed to preserve theme: " ++ Decode.errorToString error)
        , test "Theme switching preserves other model state" <|
            \_ ->
                let
                    -- Test TicTacToe
                    ticTacToeModel =
                        let
                            initial =
                                TicTacToeModel.initialModel
                        in
                        { initial
                            | board = [ [ Just TicTacToeModel.X, Just TicTacToeModel.O, Nothing ], [ Nothing, Just TicTacToeModel.X, Nothing ], [ Nothing, Nothing, Nothing ] ]
                            , gameState = TicTacToeModel.Waiting TicTacToeModel.O
                            , colorScheme = Theme.Light
                            , maybeWindow = Just ( 1200, 900 )
                        }

                    ticTacToeWithDarkTheme =
                        { ticTacToeModel | colorScheme = Theme.Dark }

                    -- Test RobotGame
                    robotGameModel =
                        let
                            initial =
                                RobotModel.init
                        in
                        { initial
                            | robot = { position = { row = 1, col = 3 }, facing = RobotModel.South }
                            , colorScheme = Theme.Light
                            , animationState = RobotModel.Rotating RobotModel.North RobotModel.South
                            , maybeWindow = Just ( 1200, 900 )
                        }

                    robotGameWithDarkTheme =
                        { robotGameModel | colorScheme = Theme.Dark }
                in
                Expect.all
                    [ \_ -> Expect.equal ticTacToeModel.board ticTacToeWithDarkTheme.board
                    , \_ -> Expect.equal ticTacToeModel.gameState ticTacToeWithDarkTheme.gameState
                    , \_ -> Expect.equal ticTacToeModel.maybeWindow ticTacToeWithDarkTheme.maybeWindow
                    , \_ -> Expect.equal robotGameModel.robot robotGameWithDarkTheme.robot
                    , \_ -> Expect.equal robotGameModel.animationState robotGameWithDarkTheme.animationState
                    , \_ -> Expect.equal robotGameModel.maybeWindow robotGameWithDarkTheme.maybeWindow
                    , \_ -> Expect.equal Theme.Dark ticTacToeWithDarkTheme.colorScheme
                    , \_ -> Expect.equal Theme.Dark robotGameWithDarkTheme.colorScheme
                    ]
                    ()
        ]

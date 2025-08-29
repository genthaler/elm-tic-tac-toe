module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

Performance optimizations:
- Rules are ordered from fastest to slowest for optimal performance
- Test directories have relaxed rules to avoid unnecessary analysis
- Unused rules are configured to minimize false positives

-}

import Docs.ReviewAtDocs
import NoConfusingPrefixOperator
import NoDebug.Log
import NoDebug.TodoOrToString
import NoExposingEverything
import NoImportingEverything
import NoMissingTypeAnnotation
import NoMissingTypeAnnotationInLetIn
import NoMissingTypeExpose
import NoPrematureLetComputation
import NoSimpleLetBody
import NoUnused.CustomTypeConstructorArgs
import NoUnused.CustomTypeConstructors
import NoUnused.Dependencies
import NoUnused.Exports
import NoUnused.Modules
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
import Review.Rule as Rule exposing (Rule)
import Simplify


config : List Rule
config =
    -- Fast syntax-based rules first
    [ NoConfusingPrefixOperator.rule
    , NoDebug.Log.rule
    , NoDebug.TodoOrToString.rule
        |> Rule.ignoreErrorsForDirectories [ "tests/" ]
    , NoSimpleLetBody.rule
    , NoPrematureLetComputation.rule
    
    -- Module structure rules (medium performance impact)
    , NoExposingEverything.rule
        |> Rule.ignoreErrorsForDirectories [ "tests/" ]
    , NoImportingEverything.rule []
        |> Rule.ignoreErrorsForDirectories [ "tests/" ]
    , NoMissingTypeAnnotation.rule
        |> Rule.ignoreErrorsForDirectories [ "tests/" ]
    , NoMissingTypeExpose.rule
    
    -- Unused detection rules (more expensive, run later)
    , NoUnused.Variables.rule
    , NoUnused.Parameters.rule
    , NoUnused.Patterns.rule
    , NoUnused.CustomTypeConstructorArgs.rule
    , NoUnused.CustomTypeConstructors.rule []
    , NoUnused.Exports.rule
        |> Rule.ignoreErrorsForDirectories [ "tests/" ]
    , NoUnused.Modules.rule
    , NoUnused.Dependencies.rule
    
    -- Documentation rules (can be expensive on large codebases)
    , Docs.ReviewAtDocs.rule
        |> Rule.ignoreErrorsForDirectories [ "tests/" ]
    
    -- Most expensive rules last
    , Simplify.rule Simplify.defaults
        |> Rule.ignoreErrorsForDirectories [ "tests/" ]
    ]

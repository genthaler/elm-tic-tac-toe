---
name: elm-core
description: Use for Elm source changes in this repository. Covers idiomatic Elm, MVU structure, ports, type-driven debugging, extensible records, and project-specific expectations such as using the shared theme utilities and established Elm patterns.
---

# Elm Core

Use this skill for general `.elm` edits.

- Follow Model-View-Update and keep effects in commands or subscriptions.
- Prefer custom types over stringly typed state and model domain concepts explicitly.
- Use extensible records when helpers only require a subset of fields.
- Favor specific event helpers over generic event wiring.
- Keep ports JSON-serializable and validate incoming data with decoders.
- For styling and layout, follow the repo's `elm-ui` conventions rather than mixing in ad hoc HTML/CSS.
- For project behavior questions, check `docs/specs/` before changing semantics.

Debugging and refinement:

- Read Elm compiler messages closely and fix the root type mismatch instead of layering workarounds.
- Keep pattern matches exhaustive.
- Prefer small, idiomatic changes over clever abstractions.

---
name: robot-game-animation-testing
description: Use for Robot Game animation tests in this repository. Covers deterministic animation tests, integration workflows, regression coverage, and performance checks for the elm-animator-based robot game.
---

# Robot Game Animation Testing

Use this skill when adding or debugging robot animation tests.

- Prefer deterministic tests that assert animation state transitions without depending on wall-clock timing.
- Cover unit, integration, regression, and performance concerns when animation behavior changes materially.
- Verify cleanup paths and final state preservation after completed animations.
- Keep animation tests focused on one workflow or failure mode at a time.
- Confirm that animation changes do not regress blocked movement handling or responsiveness.

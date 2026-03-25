---
name: robot-game-animation
description: Use for Robot Game animation work in this repository. Covers RobotGame.Animation utilities, timeline management, animation-state coordination, interpolation helpers, and preventing conflicting animation inputs.
---

# Robot Game Animation

Use this skill for `RobotGame.Animation` or adjacent animation work.

- Keep animation logic separate from core game logic.
- Use shared animation helpers for movement, rotation, button highlights, and blocked movement.
- Make animation state explicit so input gating and cleanup stay understandable.
- Prefer deterministic state transitions over timing-dependent logic where possible.
- Preserve the final robot state independently of the animation path.

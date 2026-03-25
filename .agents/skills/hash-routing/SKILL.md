---
name: hash-routing
description: Use for navigation or routing changes in this repository. Covers Browser.Hash.application patterns, route parsing and generation, fallback behavior, route tests, and state preservation across hash-based navigation.
---

# Hash Routing

Use this skill when editing routing behavior or route-aware tests.

- Keep route definitions centralized and consistent.
- Use hash URLs with stable kebab-case paths.
- Preserve fallback behavior for invalid URLs.
- Keep URL parsing and generation round-trippable where practical.
- Verify both unit and integration routing coverage when behavior changes.
- Account for production-only routing concerns when workers or hash refresh behavior are involved.

# Nopush

Nopush is an iOS habit-building app that turns task completion into immediate game-like feedback and long-term progression.

## Product direction

The core loop is:

`Create task → Start timer → Complete task → Receive rating → Earn EXP → Grow attributes → Review progress`

Nopush is the only product name going forward. Legacy names such as `Habit Quest`, `HabitQuest`, and `Version1.0` are historical project names and should not be used for new product-facing code or documentation.

## Current canonical implementation

The most complete implementation currently lives under:

`Habit Quest MVP1.0/Habit Quest L/Habit Quest MVP/`

This codebase contains the current Core Data stack, main tab interface, timer flow, habit formation flow, progression views, and gameplay managers. It is the source we will consolidate into the final Nopush project structure.

## Technology

- iOS / SwiftUI
- MVVM-style separation
- Core Data persistence
- Local-first architecture

## Core systems

- Habit and task management
- Task timer
- S / A / B / C performance rating
- EXP progression
- Four growth attributes
- Delay package mechanic
- Habit formation / challenge mechanics
- Feature unlocking and level-up feedback

## Migration status

We are currently consolidating several historical project versions into one Nopush codebase.

For now:

- Do not delete legacy directories until the canonical project builds successfully.
- New work should target the canonical implementation above.
- Product-facing naming should use **Nopush**.
- `Quest` may remain as an in-product gameplay term, but not as the app name.

## Immediate engineering priorities

1. Restore and verify a complete Xcode project for the canonical implementation.
2. Consolidate duplicated source files and backup files.
3. Standardize naming and project structure under Nopush.
4. Verify the full MVP loop end to end.
5. Add tests around rating, EXP, delay packages, and persistence.

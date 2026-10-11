# Nopush

Nopush is an iOS habit-building app that turns task completion into immediate game-like feedback and long-term progression.

## Product direction

The core loop is:

`Create task → Start timer → Complete task → Receive rating → Earn EXP → Grow attributes → Review progress`

Nopush is the only product name going forward. Legacy names such as `Habit Quest`, `HabitQuest`, and `Version1.0` are historical project names and should not be used for new product-facing code or documentation.

## Current canonical implementation

The most complete implementation currently lives under:

`Habit Quest MVP1.0/Habit Quest L/Habit Quest MVP/`

The canonical Xcode project is:

`Habit Quest MVP1.0/Habit Quest L/Habit Quest MVP/Nopush.xcodeproj`

This codebase contains the Core Data stack, main tab interface, timer flow, habit formation flow, progression views, gameplay managers, and a complete `project.pbxproj`. The Swift app entry file is `NopushApp.swift`.

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

We are consolidating several historical project versions into one Nopush codebase.

For now:

- Use `Nopush.xcodeproj` as the canonical project.
- Keep legacy directories until the canonical app has been launched and the core loop verified in an iOS Simulator.
- New work should target the canonical implementation above.
- Product-facing naming should use **Nopush**.
- `Quest` may remain as an in-product gameplay term, but not as the app name.

## Immediate engineering priorities

1. Launch the canonical app in an iOS Simulator; its CI build now passes.
2. Verify the full MVP loop end to end.
3. Consolidate duplicated source files and backup files.
4. Add tests around rating, EXP, delay packages, and persistence.
5. Move the canonical project into a clean top-level `Nopush/` structure after build verification.

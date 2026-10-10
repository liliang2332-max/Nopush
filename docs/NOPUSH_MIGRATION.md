# Nopush migration plan

## Canonical source

The current feature-complete source of truth is:

`Habit Quest MVP1.0/Habit Quest L/Habit Quest MVP/`

This directory contains the canonical implementation and its Xcode project.

## Legacy project areas

The repository currently also contains:

- `Habit Quest MVP1.0/App`, `Models`, `Views`, `ViewModels`, and related top-level folders: an earlier clean MVP scaffold.
- `Habit Quest MVP1.0/Version1.0/`: an Xcode starter project using SwiftData and the default `Item` model.

These should be treated as legacy/reference material until the canonical Nopush project is fully restored and verified.

## Target structure

```text
Nopush/
  Nopush.xcodeproj
  Nopush/
    App/
    CoreData/
    Models/
    ViewModels/
    Views/
    Managers/
    Shared/
    Assets.xcassets
  NopushTests/
  NopushUITests/
```

## Naming rules

- Product/app name: `Nopush`
- Swift app entry: `NopushApp`
- Xcode project: `Nopush.xcodeproj`
- `Quest` may be used only as an in-app gameplay concept.
- Do not introduce new symbols prefixed with `HabitQuest`, `Habit_Quest`, or `Version1_0`.

## Current project status

`Nopush.xcodeproj/project.pbxproj` is present in the canonical directory. App and test target names now use Nopush; the legacy directory names and Core Data model identifier remain in place to preserve existing project paths and stored data. The project has not yet been build-verified.

## Safe migration sequence

1. Build and launch the canonical app in Xcode.
3. Verify the MVP loop: task creation → timer → completion → rating → EXP → attribute growth → stats.
4. Move canonical files into the target Nopush directory structure.
5. Update Xcode file references and product/display names.
6. Run build/tests again.
7. Move superseded versions into `Archive/` or remove them in a separate cleanup PR.

## Known repository issue

The project file exists, but a successful build has not been confirmed. Build validation is the next gate before moving or deleting legacy directories.

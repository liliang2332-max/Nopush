# Nopush migration plan

## Canonical source

The current feature-complete source of truth is:

`Habit Quest MVP1.0/Habit Quest L/Habit Quest MVP/`

This directory contains the implementation we will migrate into a clean Nopush project.

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

## Safe migration sequence

1. Keep legacy sources untouched while restoring a valid canonical Xcode project.
2. Verify the canonical app compiles and launches.
3. Verify the MVP loop: task creation → timer → completion → rating → EXP → attribute growth → stats.
4. Move canonical files into the target Nopush directory structure.
5. Update Xcode file references and product/display names.
6. Run build/tests again.
7. Move superseded versions into `Archive/` or remove them in a separate cleanup PR.

## Known repository issue

The feature-complete historical Xcode project currently appears to be missing `project.pbxproj` from GitHub. The source code is present, but the project bundle is incomplete. The next engineering task is to reconstruct or restore a valid Xcode project before aggressive file moves or deletions.

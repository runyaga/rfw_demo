# CLAUDE.md

Guidance for Claude Code when working with this repository.

## Project Overview

Remote Flutter Widgets (RFW) implementation spike. Server-driven UI architecture enabling OTA widget updates without app store releases.

**Status:** Stages 1-10 complete, Stage 11 in progress (10/15 forms), 135 tests passing.

## Documentation Structure

| File | Purpose |
|------|---------|
| **PLAN.md** | Current work (Stage 11+) and future stages |
| **COMPLETED_PLAN.md** | Archived stages 1-10 with full details |
| **DESIGN.md** | Architecture decisions, RFW patterns |
| **RFW-KNOWLEDGE.md** | **Debugging bible** - hard-won RFW gotchas and workarounds |
| **CLAUDE.md** | This file: quick reference and pointers |

**When a stage is completed:** Archive its details to COMPLETED_PLAN.md, keep PLAN.md focused on current/future work.

**When debugging RFW issues:** Consult RFW-KNOWLEDGE.md first - it contains solutions to most common problems.

## Commands

```bash
flutter pub get                    # Install dependencies
flutter test                       # Run all tests
flutter analyze                    # Static analysis
dart run tool/compile_rfw.dart     # Compile .rfwtxt -> .rfw (REQUIRED after edits)

flutter run -d macos               # Run on macOS
flutter run -d chrome              # Run on web
```

## Architecture (Quick Reference)

```
lib/core/rfw/registry/             # Widget registries (core, material, map)
lib/core/rfw/runtime/              # Runtime, ActionHandler, Debouncer
lib/core/network/                  # Cache manager, Repository
lib/features/                      # Demo pages per stage

assets/rfw/source/                 # .rfwtxt source files
assets/rfw/defaults/               # .rfw compiled binaries
```

## RFW Quick Reference

**Full details in [RFW-KNOWLEDGE.md](RFW-KNOWLEDGE.md)**

### Must-Know Basics

1. **Every .rfwtxt needs imports:**
   ```
   import core;
   import material;
   ```

2. **Always recompile after edits:**
   ```bash
   dart run tool/compile_rfw.dart
   ```

3. **data vs args:**
   - `data.X` = Root DynamicContent from Flutter
   - `args.X` = Parameters passed to nested widget
   - `<missing>` in events? You used `data.*` instead of `args.*`

4. **Only primitives in source.v<T>():** `int`, `double`, `bool`, `String`

5. **Colors as integers:** `color: 0xFF1976D2`

### Common Fixes

| Problem | Solution |
|---------|----------|
| "Could not find remote widget" | Add `import core;` and `import material;` |
| Container color not showing | Use `ColoredBox` + `SizedBox` instead |
| Icon shows as ? | Add `fontFamily: "MaterialIcons"` |
| Text illegible | Always set explicit `color` in style |
| Column overflow | Add `mainAxisSize: "min"` |
| `<missing>` in event args | Use `args.X` not `data.X` |

### Widgets NOT in RFW Defaults

These are added in `material_registry.dart`:
- Switch, TextField, ExpansionTile, DropdownMenu, BottomNavigationBar

These are NOT registered (use alternatives):
- Checkbox → InkWell + checkbox icons
- Radio → InkWell + radio icons
- IconButton → InkWell + Icon

## When Things Go Wrong

1. **First:** Check [RFW-KNOWLEDGE.md](RFW-KNOWLEDGE.md) - most issues are documented
2. **Compilation errors:** Look at the line number, usually missing import or syntax
3. **Runtime errors:** Check data vs args, missing fontFamily, type constraints
4. **Visual bugs:** Check explicit colors, mainAxisSize, ColoredBox pattern

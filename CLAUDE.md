# CLAUDE.md

Guidance for Claude Code when working with this repository.

## Project Overview

Remote Flutter Widgets (RFW) implementation spike. Server-driven UI architecture enabling OTA widget updates without app store releases.

**Status:** Stages 1-9 complete, Stage 10 next (of 12), 139 tests passing.

## Common Commands

```bash
flutter pub get              # Install dependencies
flutter test                 # Run all tests (114)
flutter analyze              # Static analysis
dart run tool/compile_rfw.dart  # Compile .rfwtxt -> .rfw binary

flutter run -d macos         # Run on macOS
flutter run -d chrome        # Run on web
```

## Architecture

```
lib/
├── core/
│   ├── rfw/
│   │   ├── registry/           # Widget registries
│   │   │   ├── core_registry.dart      # Core widgets (Container, Text, etc.)
│   │   │   ├── material_registry.dart  # Material widgets + Switch, TextField, ExpansionTile, etc.
│   │   │   └── map_registry.dart       # FlutterMap widget for GIS (Stage 9)
│   │   └── runtime/
│   │       ├── rfw_environment.dart    # Runtime singleton
│   │       ├── action_handler.dart     # Event handling infrastructure
│   │       └── debouncer.dart          # High-frequency event utilities
│   └── network/
│       ├── rfw_cache_manager.dart      # File-based cache with TTL, atomic writes
│       └── rfw_repository.dart         # Network fetch with fallback chain
├── features/
│   ├── remote_view/        # RemoteView, SafeRemoteView, NetworkRemoteView
│   ├── demo/               # Stage 5: Data binding demo
│   ├── events/             # Stage 6: Event system demo
│   ├── network/            # Stage 7: Network & caching demo
│   ├── inventory/          # Stage 8: Widget inventory demo
│   └── widgets_extended/   # Stage 9: Extended widget library demo
assets/rfw/
├── source/                 # .rfwtxt source files (human-readable)
└── defaults/               # .rfw compiled binaries (production)
```

## Critical: RFW Source File Requirements

**Every `.rfwtxt` file MUST have these imports at the top:**
```
import core;
import material;
```

Without these imports, the compiled `.rfw` binary will fail at runtime with errors like:
```
Could not find remote widget named Card in [library_name]
```

The imports tell the RFW compiler how to resolve widget references (Card, Container, Text, etc.) to the `core` and `material` libraries.

## RFW Compilation Pipeline

```
.rfwtxt (source) --[dart run tool/compile_rfw.dart]--> .rfw (binary)
```

**ALWAYS recompile after editing source files:**
```bash
dart run tool/compile_rfw.dart
```

The compile script:
1. Reads all `.rfwtxt` files from `assets/rfw/source/`
2. Parses with `parseLibraryFile()` from `package:rfw/formats.dart`
3. Encodes to binary with `encodeLibraryBlob()`
4. Writes `.rfw` files to `assets/rfw/defaults/`

## Testing RFW Widgets

### Using Compiled Binaries (Preferred for Widget Tests)
```dart
// Load compiled binary - tests actual production artifacts
final bytes = File('assets/rfw/defaults/widget_name.rfw').readAsBytesSync();
final lib = decodeLibraryBlob(bytes);
runtime.update(const LibraryName(<String>['widget_name']), lib);
```

### Using Source Files (For Quick Iteration)
```dart
// Parse source directly - faster iteration but skips compilation step
import 'package:rfw/formats.dart';
final lib = parseLibraryFile(File('assets/rfw/source/widget.rfwtxt').readAsStringSync());
```

**Important:** If using source files in tests, the source MUST have `import core;` and `import material;` statements, otherwise you'll get "Could not find remote widget" errors.

### Test Setup Pattern
```dart
void main() {
  setUpAll(() {
    if (!rfwEnvironment.isInitialized) {
      rfwEnvironment.initialize();
    }
  });

  group('WidgetName', () {
    late WidgetLibrary lib;

    setUpAll(() {
      final bytes = File('assets/rfw/defaults/widget_name.rfw').readAsBytesSync();
      lib = decodeLibraryBlob(bytes);
    });

    testWidgets('renders correctly', (tester) async {
      final runtime = Runtime();
      runtime.update(const LibraryName(<String>['core']), createCoreWidgets());
      runtime.update(const LibraryName(<String>['material']), createMaterialWidgets());
      runtime.update(const LibraryName(<String>['widget_name']), lib);

      final content = DynamicContent();
      content.update('field', 'value');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteWidget(
              runtime: runtime,
              data: content,
              widget: const FullyQualifiedWidgetName(
                LibraryName(<String>['widget_name']),
                'WidgetName',
              ),
              onEvent: (name, args) {},
            ),
          ),
        ),
      );

      expect(find.text('value'), findsOneWidget);
    });
  });
}
```

## Critical: RFW DataSource Type Constraints

**`source.v<T>()` ONLY supports primitive types:**
- `int`
- `double`
- `bool`
- `String`

**You CANNOT use complex types like `EdgeInsets`, `Color`, `TextStyle`, etc.**

If you try `source.v<EdgeInsets>(['padding'])`, you'll get:
```
Failed assertion: 'T == int || T == double || T == bool || T == String': is not true.
```

### Workarounds for Complex Types

**EdgeInsets/Padding:** Parse from array or individual values:
```dart
// In widget registration (material_registry.dart):
final paddingValue = source.v<double>(['padding']);
final paddingLeft = source.v<double>(['padding', 0]);
final paddingTop = source.v<double>(['padding', 1]);
// ... construct EdgeInsets manually

// In .rfwtxt file - use array notation:
padding: [16.0, 8.0, 16.0, 16.0],  // LTRB
// or single value:
padding: [16.0],  // All sides
```

**Color:** Use int (hex color code):
```dart
// In widget registration:
final color = source.v<int>(['color']);
if (color != null) Color(color);

// In .rfwtxt:
color: 0xFF1976D2,
```

**Icons:** Use int (icon code point) AND specify fontFamily:
```dart
// In widget registration:
final iconCode = source.v<int>(['icon']);
Icon(IconData(iconCode, fontFamily: 'MaterialIcons'))

// In .rfwtxt - MUST include fontFamily for icons to render:
Icon(icon: 0xe88a, fontFamily: "MaterialIcons", size: 24.0, color: 0xFF000000)

// Common icon code points:
// Icons.check = 0xe156
// Icons.home = 0xe88a
// Icons.settings = 0xe8b8
// Icons.search = 0xe8b6
// Icons.person = 0xe7fd
```

## Critical: `data` vs `args` in RFW Widgets

**`data.X`** - References the DynamicContent passed to the ROOT widget from Flutter
**`args.X`** - References parameters passed when calling a NESTED widget

```
// WRONG - data.index refers to root DynamicContent, not widget params
widget TabButton = InkWell(
  onTap: event "tab_selected" { index: data.index },  // <missing>!
  child: Text(text: data.label),
);

// CORRECT - args.index refers to params passed to TabButton
widget TabButton = InkWell(
  onTap: event "tab_selected" { index: args.index },  // Works!
  child: Text(text: args.label),
);

// When calling TabButton, these become args.*
widget MyLayout = TabButton(
  index: 0,           // -> args.index
  label: "Tab 1",     // -> args.label
  isSelected: true,   // -> args.isSelected
);
```

**Rule of thumb:**
- Use `data.*` in root widgets to access DynamicContent from Flutter
- Use `args.*` in nested/reusable widgets to access passed parameters
- If you see `<missing>` in event args, you're using `data.*` when you need `args.*`

## Key Patterns

### RFW Widget Registration
Widgets must be registered in `material_registry.dart` or `core_registry.dart`. RFW's `createMaterialWidgets()` doesn't include `Switch` or `TextField` - we add them manually.

**Import conflict:** RFW exports `Switch` (control flow). Use:
```dart
import 'package:flutter/material.dart' hide Switch;
import 'package:flutter/material.dart' as material show Switch;
// Then use: material.Switch(...)
```

### Event Handlers in RFW Widgets
```dart
// Correct pattern for handlers:
onChanged: source.handler(
  ['onChanged'],
  (HandlerTrigger trigger) => (bool value) => trigger({'value': value}),
),
```

### RFW Widget Definition (.rfwtxt)
```
// Comment describing the widget
import core;
import material;

widget MyWidget = ElevatedButton(
  onPressed: event "button_pressed" { action: data.action },
  child: Text(text: data.label),
);
```

### Conditional Styling with Switch Expression
```
Text(
  text: data.change,
  style: {
    color: switch data.trend {
      "up": 0xFF4CAF50,
      "down": 0xFFF44336,
      default: 0xFF757575,
    },
  },
),
```

### Stateless Round-Trip (Toggle Pattern)
RFW widgets are stateless. Toggle state lives in Flutter:
1. User taps Switch → fires `toggle_changed` event
2. Handler updates local state + `DynamicContent.update()`
3. RemoteWidget rebuilds with new value

## Network Layer

### Fallback Chain
Cache → Network → Bundled Assets

The `RfwRepository` tries sources in order:
1. Check disk cache for non-expired entry
2. Fetch from network with conditional headers (ETag/If-None-Match)
3. Fall back to bundled asset in `assets/rfw/defaults/`

### HTTP Headers Sent
- `X-Client-Version`: App version for capability handshake
- `X-Client-Widget-Version`: Widget registry version
- `If-None-Match`: ETag from cached version (for 304 responses)

### Cache Manager
- File-based cache in app's cache directory
- Atomic writes: temp file + rename pattern
- LRU eviction when exceeding max size (default 50MB)
- TTL-based expiration (default 24 hours)

## Common Errors and Fixes

### "Could not find remote widget named X"
**Cause:** Missing imports in `.rfwtxt` file
**Fix:** Add `import core;` and `import material;` at top of source file, then recompile

### "setState() or markNeedsBuild() called during build"
**Cause:** Calling setState inside a FutureBuilder's builder or similar
**Fix:** Pre-load data in `initState()` instead of using FutureBuilder, or use `addPostFrameCallback` carefully

### RenderFlex overflow errors
**Cause:** Container height too small for RFW widget content
**Fix:** Increase SizedBox height or use flexible layout

### Tests fail but app works
**Cause:** Tests using source files without imports, while app uses compiled binaries
**Fix:** Ensure test uses compiled `.rfw` files or source files with imports

### White/illegible text on widgets
**Cause:** Material 3 themes inherit text colors that may not contrast with backgrounds
**Fix:** Always specify explicit text colors in `.rfwtxt`: `style: { color: 0xFF212121 }` for dark text

### Gradient not rendering
**Cause:** RFW does not support `gradient` in Container decoration
**Fix:** Use solid `color` on Card instead: `Card(color: 0xFF7B1FA2, ...)`

### "Failed assertion: 'T == int || T == double || T == bool || T == String'"
**Cause:** Using `source.v<T>()` with a non-primitive type like `EdgeInsets`, `Color`, `TextStyle`
**Fix:** Only use primitive types with `source.v<T>()`. For complex types:
- `EdgeInsets`: Parse from array indices `source.v<double>(['padding', 0])`
- `Color`: Use `Color(source.v<int>(['color'])!)`
- `IconData`: Use `IconData(source.v<int>(['icon'])!, fontFamily: 'MaterialIcons')`

### Container decoration color not rendering
**Cause:** RFW's core `Container` widget doesn't always apply `decoration.color` correctly
**Fix:** Use `ColoredBox` with a child `SizedBox` instead of Container with decoration:
```
// WRONG - color may not render
Container(
  height: 100.0,
  width: 200.0,
  decoration: { color: 0xFFBDBDBD, borderRadius: [4.0] },
)

// CORRECT - color renders reliably
ColoredBox(
  color: 0xFFBDBDBD,
  child: SizedBox(height: 100.0, width: 200.0),
)

// For rounded corners, wrap with ClipRRect
ClipRRect(
  borderRadius: [4.0],
  child: ColoredBox(
    color: 0xFFBDBDBD,
    child: SizedBox(height: 100.0, width: 200.0),
  ),
)
```

## Testing Commands

```bash
flutter test                                    # All tests (114)
flutter test test/rfw/inventory/                # Widget inventory (17 tests)
flutter test test/core/network/                 # Network layer (30 tests)
flutter test test/rfw/events/                   # Event system (32 tests)
flutter test test/rfw/goldens/                  # Visual regression (4 tests)
```

## Documentation

- `PLAN.md` - Implementation stages with gate criteria and results
- `DESIGN.md` - Architecture decisions, RFW patterns
- `QUESTIONS.md` - Design rationale
- `README.md` - Quick start, test groups, current status

## Gotchas

1. **Compile RFW after changes:** `dart run tool/compile_rfw.dart`
2. **Always add imports:** Every `.rfwtxt` needs `import core;` and `import material;`
3. **Switch/TextField missing:** Add to `material_registry.dart`, not in RFW's default set
4. **Empty errorText:** Return `null` not `''` to hide error state in TextField
5. **Handler pattern:** Must return function: `(trigger) => (value) => trigger({...})`
6. **Test with binaries:** Use `decodeLibraryBlob()` with `.rfw` files for reliable tests
7. **DynamicContent per widget:** Each RemoteWidget instance needs its own DynamicContent
8. **macOS network:** Requires `com.apple.security.network.client` entitlement
9. **Explicit text colors:** Always set `color` in text styles - Material 3 themes cause illegible text
10. **No gradients:** RFW doesn't support gradient decoration - use Card `color` property
11. **Column expansion:** Use `mainAxisSize: "min"` to prevent Column from expanding in constrained layouts
12. **source.v<T>() primitives only:** Only `int`, `double`, `bool`, `String` - NO `EdgeInsets`, `Color`, etc.
13. **EdgeInsets workaround:** Parse from array indices: `source.v<double>(['padding', 0])` for left, etc.
14. **Stage 9 widgets:** ExpansionTile, DropdownMenu, BottomNavigationBar, DateTimePicker, FlutterMap added
15. **data vs args:** Use `data.*` for root DynamicContent, `args.*` for nested widget parameters
16. **<missing> in events:** If event args show `<missing>`, you used `data.X` instead of `args.X`
17. **Container decoration color:** Use `ColoredBox` + `SizedBox` instead of Container with decoration.color
18. **Rounded colored boxes:** Wrap `ColoredBox` in `ClipRRect` for border radius
19. **Icon fontFamily required:** In `.rfwtxt`, Icon MUST have `fontFamily: "MaterialIcons"` or icons show as `?` or wrong glyphs
20. **Icon code points:** Use correct hex codes - `Icons.check` = `0xe156`, NOT `0xe876` or `0xe5ca`. Look up correct values.

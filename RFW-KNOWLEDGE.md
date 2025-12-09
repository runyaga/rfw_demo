# RFW Knowledge Base

Hard-won knowledge about Remote Flutter Widgets (RFW) quirks, workarounds, and debugging tips. Reference this when things aren't working as expected.

---

## Table of Contents

1. [Source File Requirements](#source-file-requirements)
2. [Compilation Pipeline](#compilation-pipeline)
3. [DataSource Type Constraints](#datasource-type-constraints)
4. [data vs args](#data-vs-args)
5. [Widget Registration](#widget-registration)
6. [Styling and Layout](#styling-and-layout)
7. [Icons](#icons)
8. [Forms and Text Input](#forms-and-text-input)
9. [Event Handling](#event-handling)
10. [Common Errors and Fixes](#common-errors-and-fixes)
11. [Testing Patterns](#testing-patterns)
12. [Network Layer](#network-layer)

---

## Source File Requirements

### Every .rfwtxt file MUST have these imports:
```
import core;
import material;
```

Without these imports, the compiled `.rfw` binary will fail at runtime with:
```
Could not find remote widget named Card in [library_name]
```

The imports tell the RFW compiler how to resolve widget references (Card, Container, Text, etc.) to the `core` and `material` libraries.

---

## Compilation Pipeline

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

---

## DataSource Type Constraints

### source.v<T>() ONLY supports primitive types:
- ✅ `int`
- ✅ `double`
- ✅ `bool`
- ✅ `String`

### You CANNOT use complex types:
- ❌ `EdgeInsets`
- ❌ `Color`
- ❌ `TextStyle`
- ❌ `IconData`

If you try `source.v<EdgeInsets>(['padding'])`, you'll get:
```
Failed assertion: 'T == int || T == double || T == bool || T == String': is not true.
```

### Workarounds for Complex Types

**EdgeInsets/Padding:** Parse from array or individual values:
```dart
// In widget registration (material_registry.dart):
final paddingLeft = source.v<double>(['padding', 0]);
final paddingTop = source.v<double>(['padding', 1]);
final paddingRight = source.v<double>(['padding', 2]);
final paddingBottom = source.v<double>(['padding', 3]);
// Construct EdgeInsets manually

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

// In .rfwtxt - MUST include fontFamily:
Icon(icon: 0xe88a, fontFamily: "MaterialIcons", size: 24.0, color: 0xFF000000)
```

---

## data vs args

This is one of the most common sources of bugs!

- **`data.X`** - References the DynamicContent passed to the ROOT widget from Flutter
- **`args.X`** - References parameters passed when calling a NESTED widget

```
// WRONG - data.index refers to root DynamicContent, not widget params
widget TabButton = InkWell(
  onTap: event "tab_selected" { index: data.index },  // Shows <missing>!
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

---

## Widget Registration

### Missing Widgets in RFW Defaults

RFW's `createMaterialWidgets()` does NOT include many common widgets. We add them manually in `material_registry.dart`:

- `Switch` - Added manually
- `TextField` - Added manually (plus `_ControlledTextField` wrapper)
- `Checkbox` - Not registered (use InkWell + checkbox icons)
- `Radio` - Not registered (use InkWell + radio icons)
- `IconButton` - Not registered (use InkWell + Icon)
- `ExpansionTile` - Added in Stage 9
- `DropdownMenu` - Added in Stage 9
- `BottomNavigationBar` - Added in Stage 9

### Import Conflict with Switch

RFW exports `Switch` as a control flow construct. Use this pattern:
```dart
import 'package:flutter/material.dart' hide Switch;
import 'package:flutter/material.dart' as material show Switch;
// Then use: material.Switch(...)
```

### Event Handler Pattern

The correct pattern for handlers in widget registration:
```dart
onChanged: source.handler(
  ['onChanged'],
  (HandlerTrigger trigger) => (bool value) => trigger({'value': value}),
),
```

Must return a function that returns a function!

---

## Styling and Layout

### Container decoration.color Doesn't Work

RFW's core `Container` widget doesn't always apply `decoration.color` correctly.

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

### No Gradient Support

RFW does not support `gradient` in Container decoration.
**Fix:** Use solid `color` on Card instead: `Card(color: 0xFF7B1FA2, ...)`

### Column/Row Expansion

Use `mainAxisSize: "min"` to prevent Column/Row from expanding in constrained layouts. Without this, you'll get overflow errors.

```
Column(
  mainAxisSize: "min",  // IMPORTANT!
  children: [...],
)
```

### Explicit Text Colors Required

Material 3 themes inherit text colors that may not contrast with backgrounds.
**Always** specify explicit text colors:
```
Text(
  text: "Hello",
  style: { color: 0xFF212121 },  // Dark text
)
```

### Conditional Styling with Switch

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

### No == Operator in Property Values

RFW doesn't support `==` operator in property values. Compute comparisons in host:

```dart
// Host code - compute the boolean
_content.update('emailSelected', _selectedMethod == 'email');
_content.update('statusColor', isValid ? 0xFF4CAF50 : 0xFFF44336);

// RFW widget - use the pre-computed value
isSelected: data.emailSelected,  // NOT: data.selectedMethod == "email"
color: data.statusColor,         // NOT: switch with complex logic
```

---

## Icons

### fontFamily is REQUIRED

In `.rfwtxt`, Icon MUST have `fontFamily: "MaterialIcons"` or icons show as `?` or wrong glyphs:

```
// WRONG - icon won't render correctly
Icon(icon: 0xe88a, size: 24.0)

// CORRECT
Icon(icon: 0xe88a, fontFamily: "MaterialIcons", size: 24.0, color: 0xFF000000)
```

### Icon Codepoints are Unreliable - USE TEXT CHARACTERS

Material Icons codepoints vary between Flutter versions and platforms. The same codepoint may render differently or not at all. **After extensive testing, we recommend using Unicode text characters instead of icon codepoints for custom controls.**

**Recommended approach - Unicode text characters:**
```
// Radio buttons
switch args.isSelected {
  true: Text(text: "●", style: { fontSize: 20.0, color: 0xFF1976D2 }),
  default: Text(text: "○", style: { fontSize: 20.0, color: 0xFF757575 }),
}

// Checkboxes
switch args.isChecked {
  true: Text(text: "☑", style: { fontSize: 20.0, color: 0xFF1976D2 }),
  default: Text(text: "☐", style: { fontSize: 20.0, color: 0xFF757575 }),
}

// Other useful characters
Text(text: "+", style: { fontSize: 20.0 })   // Add
Text(text: "−", style: { fontSize: 20.0 })   // Remove (minus sign)
Text(text: "✓", style: { fontSize: 20.0 })   // Checkmark
Text(text: "✕", style: { fontSize: 20.0 })   // X mark
```

**Why not icons?** The codepoints below often render as wrong glyphs or boxes with X:
```
// UNRELIABLE - may show wrong icons or fail entirely:
Icons.radio_button_checked = 0xe837    // Often shows wrong glyph
Icons.radio_button_unchecked = 0xe836  // Often shows box with X
Icons.check_box = 0xe834               // Inconsistent
Icons.check_box_outline_blank = 0xe835 // Often shows box with X
```

**If you must use icons**, these tend to be more reliable (but still verify):
```
Icons.arrow_drop_down = 0xe313
Icons.chevron_left = 0xe5cb
Icons.close = 0xe5cd
```

---

## Forms and Text Input

### Controlled TextField

RFW TextField doesn't support `value` prop by default. We created `_ControlledTextField` wrapper in `material_registry.dart` that:
- Accepts `value` prop for initial/controlled value
- Only syncs from host when value is empty (clear/reset action)
- Syncing during typing breaks cursor position and focus

### TextField Sync Pattern

```dart
// Host: Only update when clearing
void _clearForm() {
  _textValue = '';
  _content.update('text', '');  // TextField will sync because empty
}

// During typing - don't sync back, just store the value
void _onTextChanged(String value) {
  _textValue = value;  // Store but don't update content
}
```

### Empty errorText

Return `null` not `''` to hide error state in TextField:
```dart
decoration: {
  errorText: data.hasError ? data.errorMessage : null,  // NOT: ''
}
```

### Form Validation Events

Use `form_submit_denied` event for invalid form submissions, not `form_submit` with `isValid: false`:

```
// WRONG
event "form_submit" { formId: "myform", isValid: false }

// CORRECT - separate event for denied submissions
switch data.isValid {
  true: ElevatedButton(
    onPressed: event "form_submit" { formId: "myform", data: {...} },
  ),
  default: ElevatedButton(
    onPressed: event "form_submit_denied" { formId: "myform", reason: "invalid" },
  ),
}
```

---

## Event Handling

### Stateless Round-Trip Pattern

RFW widgets are stateless. Toggle state lives in Flutter:
1. User taps Switch → fires `toggle_changed` event
2. Handler updates local state + `DynamicContent.update()`
3. RemoteWidget rebuilds with new value

### Each RemoteWidget Needs Its Own DynamicContent

Don't share DynamicContent between widgets:
```dart
// WRONG
final sharedContent = DynamicContent();
RemoteWidget(data: sharedContent, ...);
RemoteWidget(data: sharedContent, ...);  // Will conflict!

// CORRECT
final content1 = DynamicContent();
final content2 = DynamicContent();
RemoteWidget(data: content1, ...);
RemoteWidget(data: content2, ...);
```

---

## Common Errors and Fixes

### "Could not find remote widget named X"
**Cause:** Missing imports in `.rfwtxt` file
**Fix:** Add `import core;` and `import material;` at top, then recompile

### "setState() or markNeedsBuild() called during build"
**Cause:** Calling setState inside a FutureBuilder's builder or similar
**Fix:** Pre-load data in `initState()` instead of using FutureBuilder

### RenderFlex overflow errors
**Cause:** Container height too small or Column expanding
**Fix:** Use `mainAxisSize: "min"` on Column/Row, or increase container size

### Tests fail but app works
**Cause:** Tests using source files without imports, while app uses compiled binaries
**Fix:** Ensure test uses compiled `.rfw` files or source files with imports

### "Failed assertion: 'T == int || T == double || T == bool || T == String'"
**Cause:** Using `source.v<T>()` with a non-primitive type
**Fix:** Only use primitive types. See [DataSource Type Constraints](#datasource-type-constraints)

### <missing> in event arguments
**Cause:** Using `data.X` when you need `args.X`
**Fix:** See [data vs args](#data-vs-args)

### Icons showing as ? or wrong glyph
**Cause:** Missing `fontFamily` or wrong codepoint
**Fix:** Add `fontFamily: "MaterialIcons"` and verify codepoint

### Text illegible (white on white, etc.)
**Cause:** Material 3 theme inheritance
**Fix:** Always specify explicit `color` in text style

---

## Testing Patterns

### Test Setup with Compiled Binaries (Preferred)
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

### Using Source Files (Quick Iteration)
```dart
import 'package:rfw/formats.dart';
final lib = parseLibraryFile(File('assets/rfw/source/widget.rfwtxt').readAsStringSync());
```

**Important:** Source files MUST have `import core;` and `import material;` statements.

---

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

### macOS Network Entitlement
Requires `com.apple.security.network.client` entitlement in `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`.

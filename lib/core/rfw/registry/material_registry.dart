import 'package:flutter/material.dart' hide Switch;
import 'package:flutter/material.dart' as material show Switch;
import 'package:rfw/rfw.dart';

/// Version constant for Material widgets capability handshake
const String kMaterialRegistryVersion = '1.0.0';

/// Creates the Material widget library with design-system constraints.
///
/// Per DESIGN.md Section 3 Phase 1 Step 2:
/// Wraps `createMaterialWidgets()` and exposes design-system versions
/// of Material widgets.
LocalWidgetLibrary createAppMaterialWidgets() {
  // Start with the standard Material widgets from RFW
  final materialWidgets = createMaterialWidgets();

  return LocalWidgetLibrary(<String, LocalWidgetBuilder>{
    // Include all standard Material widgets
    ...materialWidgets.widgets,

    // Design-system ElevatedButton
    'DesignSystemButton': (BuildContext context, DataSource source) {
      return ElevatedButton(
        onPressed: source.voidHandler(['onPressed']),
        style: ElevatedButton.styleFrom(
          backgroundColor: source.v<int>(['backgroundColor']) != null
              ? Color(source.v<int>(['backgroundColor'])!)
              : null,
          foregroundColor: source.v<int>(['foregroundColor']) != null
              ? Color(source.v<int>(['foregroundColor'])!)
              : null,
          padding: source.v<EdgeInsets>(['padding']),
        ),
        child: source.child(['child']),
      );
    },

    // Design-system Card
    'DesignSystemCard': (BuildContext context, DataSource source) {
      return Card(
        elevation: source.v<double>(['elevation']) ?? 1.0,
        margin: source.v<EdgeInsets>(['margin']),
        color: source.v<int>(['color']) != null
            ? Color(source.v<int>(['color'])!)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            source.v<double>(['borderRadius']) ?? 4.0,
          ),
        ),
        child: source.child(['child']),
      );
    },

    // Design-system TextField
    'DesignSystemTextField': (BuildContext context, DataSource source) {
      return TextField(
        decoration: InputDecoration(
          labelText: source.v<String>(['label']),
          hintText: source.v<String>(['hint']),
          errorText: source.v<String>(['error']),
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) {
          final handler = source.voidHandler(['onChanged']);
          if (handler != null) {
            handler();
          }
        },
        obscureText: source.v<bool>(['obscureText']) ?? false,
        maxLines: source.v<int>(['maxLines']) ?? 1,
      );
    },

    // Design-system AppBar
    'DesignSystemAppBar': (BuildContext context, DataSource source) {
      return AppBar(
        title: source.child(['title']),
        backgroundColor: source.v<int>(['backgroundColor']) != null
            ? Color(source.v<int>(['backgroundColor'])!)
            : null,
        elevation: source.v<double>(['elevation']),
        centerTitle: source.v<bool>(['centerTitle']),
        leading: source.optionalChild(['leading']),
        actions: source.childList(['actions']),
      );
    },

    // Design-system Scaffold
    'DesignSystemScaffold': (BuildContext context, DataSource source) {
      return Scaffold(
        appBar: source.optionalChild(['appBar']) as PreferredSizeWidget?,
        body: source.child(['body']),
        floatingActionButton: source.optionalChild(['floatingActionButton']),
        bottomNavigationBar: source.optionalChild(['bottomNavigationBar']),
      );
    },

    // Design-system ListTile
    'DesignSystemListTile': (BuildContext context, DataSource source) {
      return ListTile(
        leading: source.optionalChild(['leading']),
        title: source.child(['title']),
        subtitle: source.optionalChild(['subtitle']),
        trailing: source.optionalChild(['trailing']),
        onTap: source.voidHandler(['onTap']),
      );
    },

    // Switch widget (not included in createMaterialWidgets)
    'Switch': (BuildContext context, DataSource source) {
      final activeColor = source.v<int>(['activeColor']);
      final activeTrackColor = source.v<int>(['activeTrackColor']);
      return material.Switch(
        value: source.v<bool>(['value']) ?? false,
        onChanged: source.handler(
          ['onChanged'],
          (HandlerTrigger trigger) => (bool value) => trigger(<String, Object?>{'value': value}),
        ),
        thumbColor: activeColor != null
            ? WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected) ? Color(activeColor) : null)
            : null,
        trackColor: activeTrackColor != null
            ? WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected) ? Color(activeTrackColor) : null)
            : null,
      );
    },

    // TextField widget (not included in createMaterialWidgets)
    // Note: RFW only supports primitive types (int, double, bool, String)
    // Access nested decoration properties via path: ['decoration', 'labelText']
    'TextField': (BuildContext context, DataSource source) {
      final prefixIconCode = source.v<int>(['decoration', 'prefixIcon']);
      final suffixIconCode = source.v<int>(['decoration', 'suffixIcon']);
      final value = source.v<String>(['value']);

      return _ControlledTextField(
        initialValue: value ?? '',
        decoration: InputDecoration(
          labelText: source.v<String>(['decoration', 'labelText']),
          hintText: source.v<String>(['decoration', 'hintText']),
          errorText: _nullIfEmpty(source.v<String>(['decoration', 'errorText'])),
          helperText: source.v<String>(['decoration', 'helperText']),
          prefixIcon: prefixIconCode != null
              ? Icon(IconData(prefixIconCode, fontFamily: 'MaterialIcons'))
              : null,
          suffixIcon: suffixIconCode != null && suffixIconCode != 0
              ? Icon(IconData(suffixIconCode, fontFamily: 'MaterialIcons'))
              : null,
        ),
        keyboardType: _parseKeyboardType(source.v<String>(['keyboardType'])),
        obscureText: source.v<bool>(['obscureText']) ?? false,
        onChanged: source.handler(
          ['onChanged'],
          (HandlerTrigger trigger) => (String value) => trigger(<String, Object?>{'value': value}),
        ),
        onSubmitted: source.handler(
          ['onSubmitted'],
          (HandlerTrigger trigger) => (String value) => trigger(<String, Object?>{'value': value}),
        ),
      );
    },

    // Design-system Icon
    'DesignSystemIcon': (BuildContext context, DataSource source) {
      final iconName = source.v<String>(['icon']) ?? 'error';
      final size = source.v<double>(['size']) ?? 24.0;
      final color = source.v<int>(['color']) != null
          ? Color(source.v<int>(['color'])!)
          : null;

      return Icon(
        _parseIconData(iconName),
        size: size,
        color: color,
      );
    },

    // ExpansionTile for Accordions (Stage 9)
    // Note: RFW only supports primitives (int, double, bool, String)
    // EdgeInsets must be constructed from individual values
    'ExpansionTile': (BuildContext context, DataSource source) {
      // Parse tile padding from array [left, top, right, bottom] or single value
      final tilePaddingValue = source.v<double>(['tilePadding']);
      final tilePaddingLeft = source.v<double>(['tilePadding', 0]);
      final tilePaddingTop = source.v<double>(['tilePadding', 1]);
      final tilePaddingRight = source.v<double>(['tilePadding', 2]);
      final tilePaddingBottom = source.v<double>(['tilePadding', 3]);

      EdgeInsetsGeometry? tilePadding;
      if (tilePaddingLeft != null) {
        tilePadding = EdgeInsets.fromLTRB(
          tilePaddingLeft,
          tilePaddingTop ?? tilePaddingLeft,
          tilePaddingRight ?? tilePaddingLeft,
          tilePaddingBottom ?? tilePaddingTop ?? tilePaddingLeft,
        );
      } else if (tilePaddingValue != null) {
        tilePadding = EdgeInsets.all(tilePaddingValue);
      }

      // Parse children padding similarly
      final childrenPaddingValue = source.v<double>(['childrenPadding']);
      final childrenPaddingLeft = source.v<double>(['childrenPadding', 0]);
      final childrenPaddingTop = source.v<double>(['childrenPadding', 1]);
      final childrenPaddingRight = source.v<double>(['childrenPadding', 2]);
      final childrenPaddingBottom = source.v<double>(['childrenPadding', 3]);

      EdgeInsetsGeometry? childrenPadding;
      if (childrenPaddingLeft != null) {
        childrenPadding = EdgeInsets.fromLTRB(
          childrenPaddingLeft,
          childrenPaddingTop ?? childrenPaddingLeft,
          childrenPaddingRight ?? childrenPaddingLeft,
          childrenPaddingBottom ?? childrenPaddingTop ?? childrenPaddingLeft,
        );
      } else if (childrenPaddingValue != null) {
        childrenPadding = EdgeInsets.all(childrenPaddingValue);
      }

      return ExpansionTile(
        title: source.child(['title']),
        subtitle: source.optionalChild(['subtitle']),
        leading: source.optionalChild(['leading']),
        trailing: source.optionalChild(['trailing']),
        initiallyExpanded: source.v<bool>(['initiallyExpanded']) ?? false,
        maintainState: source.v<bool>(['maintainState']) ?? false,
        tilePadding: tilePadding,
        childrenPadding: childrenPadding,
        backgroundColor: source.v<int>(['backgroundColor']) != null
            ? Color(source.v<int>(['backgroundColor'])!)
            : null,
        collapsedBackgroundColor: source.v<int>(['collapsedBackgroundColor']) != null
            ? Color(source.v<int>(['collapsedBackgroundColor'])!)
            : null,
        iconColor: source.v<int>(['iconColor']) != null
            ? Color(source.v<int>(['iconColor'])!)
            : null,
        collapsedIconColor: source.v<int>(['collapsedIconColor']) != null
            ? Color(source.v<int>(['collapsedIconColor'])!)
            : null,
        textColor: source.v<int>(['textColor']) != null
            ? Color(source.v<int>(['textColor'])!)
            : null,
        collapsedTextColor: source.v<int>(['collapsedTextColor']) != null
            ? Color(source.v<int>(['collapsedTextColor'])!)
            : null,
        onExpansionChanged: source.handler(
          ['onExpansionChanged'],
          (HandlerTrigger trigger) => (bool expanded) => trigger(<String, Object?>{'expanded': expanded}),
        ),
        children: source.childList(['children']),
      );
    },

    // DropdownButton for selection (Stage 9)
    // Note: Uses a simplified pattern where options are passed via data
    'DropdownMenu': (BuildContext context, DataSource source) {
      final selectedValue = source.v<String>(['selectedValue']);
      final label = source.v<String>(['label']);
      final enabled = source.v<bool>(['enabled']) ?? true;
      final width = source.v<double>(['width']);

      // Get options from childList as a workaround for complex data
      // Each child should contain 'value' and 'label' in its data
      final optionCount = source.v<int>(['optionCount']) ?? 0;
      final List<DropdownMenuEntry<String>> entries = [];

      for (int i = 0; i < optionCount; i++) {
        final value = source.v<String>(['options', i, 'value']) ?? '';
        final optionLabel = source.v<String>(['options', i, 'label']) ?? value;
        final optionEnabled = source.v<bool>(['options', i, 'enabled']) ?? true;
        entries.add(DropdownMenuEntry<String>(
          value: value,
          label: optionLabel,
          enabled: optionEnabled,
        ));
      }

      return DropdownMenu<String>(
        initialSelection: selectedValue,
        label: label != null ? Text(label) : null,
        enabled: enabled,
        width: width,
        dropdownMenuEntries: entries,
        onSelected: source.handler(
          ['onSelected'],
          (HandlerTrigger trigger) => (String? value) => trigger(<String, Object?>{'value': value}),
        ),
      );
    },

    // BottomNavigationBar (Stage 9)
    'BottomNavigationBar': (BuildContext context, DataSource source) {
      final currentIndex = source.v<int>(['currentIndex']) ?? 0;
      final itemCount = source.v<int>(['itemCount']) ?? 0;
      final backgroundColor = source.v<int>(['backgroundColor']);
      final selectedItemColor = source.v<int>(['selectedItemColor']);
      final unselectedItemColor = source.v<int>(['unselectedItemColor']);
      final showLabels = source.v<bool>(['showLabels']) ?? true;

      final List<BottomNavigationBarItem> items = [];
      for (int i = 0; i < itemCount; i++) {
        final iconCode = source.v<int>(['items', i, 'icon']) ?? 0xe88a;
        final label = source.v<String>(['items', i, 'label']) ?? '';
        final activeIconCode = source.v<int>(['items', i, 'activeIcon']);

        items.add(BottomNavigationBarItem(
          icon: Icon(IconData(iconCode, fontFamily: 'MaterialIcons')),
          activeIcon: activeIconCode != null
              ? Icon(IconData(activeIconCode, fontFamily: 'MaterialIcons'))
              : null,
          label: label,
        ));
      }

      return BottomNavigationBar(
        currentIndex: currentIndex.clamp(0, items.isNotEmpty ? items.length - 1 : 0),
        items: items.isEmpty ? [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ] : items,
        backgroundColor: backgroundColor != null ? Color(backgroundColor) : null,
        selectedItemColor: selectedItemColor != null ? Color(selectedItemColor) : null,
        unselectedItemColor: unselectedItemColor != null ? Color(unselectedItemColor) : null,
        showSelectedLabels: showLabels,
        showUnselectedLabels: showLabels,
        onTap: source.handler(
          ['onTap'],
          (HandlerTrigger trigger) => (int index) => trigger(<String, Object?>{'index': index}),
        ),
      );
    },

    // DateTimePicker - displays selected value and emits pick event (Stage 9)
    // Host intercepts event and shows native picker dialog
    'DateTimePicker': (BuildContext context, DataSource source) {
      final label = source.v<String>(['label']) ?? 'Select';
      final mode = source.v<String>(['mode']) ?? 'date';
      final selectedDate = source.v<String>(['selectedDate']) ?? '';
      final selectedTime = source.v<String>(['selectedTime']) ?? '';
      final displayValue = source.v<String>(['displayValue']) ??
          (mode == 'time' ? selectedTime :
           mode == 'datetime' ? '$selectedDate $selectedTime' : selectedDate);
      final iconCode = source.v<int>(['icon']) ??
          (mode == 'time' ? 0xe8b5 : 0xe916); // access_time or calendar_today
      final enabled = source.v<bool>(['enabled']) ?? true;
      final backgroundColor = source.v<int>(['backgroundColor']);
      final textColor = source.v<int>(['textColor']) ?? 0xFF212121;

      return InkWell(
        onTap: enabled ? source.handler(
          ['onTap'],
          (HandlerTrigger trigger) => () => trigger(<String, Object?>{
            'mode': mode,
            'currentDate': selectedDate,
            'currentTime': selectedTime,
          }),
        ) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor != null ? Color(backgroundColor) : null,
            border: Border.all(color: const Color(0xFFBDBDBD)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                IconData(iconCode, fontFamily: 'MaterialIcons'),
                color: enabled ? Color(textColor) : const Color(0xFF9E9E9E),
                size: 20,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: enabled ? const Color(0xFF757575) : const Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayValue.isNotEmpty ? displayValue : 'Not selected',
                    style: TextStyle(
                      fontSize: 16,
                      color: enabled ? Color(textColor) : const Color(0xFF9E9E9E),
                      fontWeight: displayValue.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_drop_down,
                color: enabled ? Color(textColor) : const Color(0xFF9E9E9E),
              ),
            ],
          ),
        ),
      );
    },

    // Tab with custom content (Stage 9)
    // Used within TabBar to represent individual tabs
    'Tab': (BuildContext context, DataSource source) {
      final text = source.v<String>(['text']);
      final iconCode = source.v<int>(['icon']);

      return Tab(
        text: text,
        icon: iconCode != null
            ? Icon(IconData(iconCode, fontFamily: 'MaterialIcons'))
            : null,
        child: source.optionalChild(['child']),
      );
    },

    // Chip widget for breadcrumbs and tags (Stage 9)
    'Chip': (BuildContext context, DataSource source) {
      final label = source.v<String>(['label']) ?? '';
      final backgroundColor = source.v<int>(['backgroundColor']);
      final labelColor = source.v<int>(['labelColor']) ?? 0xFF212121;
      final deleteIconColor = source.v<int>(['deleteIconColor']);
      final showDelete = source.v<bool>(['showDelete']) ?? false;

      return Chip(
        label: Text(
          label,
          style: TextStyle(color: Color(labelColor)),
        ),
        backgroundColor: backgroundColor != null ? Color(backgroundColor) : null,
        deleteIcon: showDelete ? Icon(
          Icons.close,
          size: 18,
          color: deleteIconColor != null ? Color(deleteIconColor) : null,
        ) : null,
        onDeleted: showDelete ? source.handler(
          ['onDeleted'],
          (HandlerTrigger trigger) => () => trigger(<String, Object?>{}),
        ) : null,
      );
    },

    // ActionChip for interactive chips (Stage 9)
    'ActionChip': (BuildContext context, DataSource source) {
      final label = source.v<String>(['label']) ?? '';
      final backgroundColor = source.v<int>(['backgroundColor']);
      final labelColor = source.v<int>(['labelColor']) ?? 0xFF212121;
      final iconCode = source.v<int>(['icon']);

      return ActionChip(
        label: Text(
          label,
          style: TextStyle(color: Color(labelColor)),
        ),
        backgroundColor: backgroundColor != null ? Color(backgroundColor) : null,
        avatar: iconCode != null
            ? Icon(IconData(iconCode, fontFamily: 'MaterialIcons'), size: 18)
            : null,
        onPressed: source.voidHandler(['onPressed']),
      );
    },
  });
}

/// Parse icon name string to IconData
/// Supports common Material icons
IconData _parseIconData(String name) {
  const icons = <String, IconData>{
    'home': Icons.home,
    'settings': Icons.settings,
    'person': Icons.person,
    'search': Icons.search,
    'add': Icons.add,
    'remove': Icons.remove,
    'edit': Icons.edit,
    'delete': Icons.delete,
    'close': Icons.close,
    'check': Icons.check,
    'arrow_back': Icons.arrow_back,
    'arrow_forward': Icons.arrow_forward,
    'menu': Icons.menu,
    'more_vert': Icons.more_vert,
    'refresh': Icons.refresh,
    'error': Icons.error,
    'warning': Icons.warning,
    'info': Icons.info,
    'favorite': Icons.favorite,
    'star': Icons.star,
  };

  return icons[name] ?? Icons.error;
}

/// Returns null if the string is empty, otherwise returns the string.
/// Used for errorText which should be null (not empty string) to hide error state.
String? _nullIfEmpty(String? value) {
  if (value == null || value.isEmpty) return null;
  return value;
}

/// Parse keyboard type string to TextInputType
TextInputType _parseKeyboardType(String? type) {
  switch (type) {
    case 'emailAddress':
      return TextInputType.emailAddress;
    case 'number':
      return TextInputType.number;
    case 'phone':
      return TextInputType.phone;
    case 'url':
      return TextInputType.url;
    case 'multiline':
      return TextInputType.multiline;
    default:
      return TextInputType.text;
  }
}

/// A TextField that supports controlled value from host.
/// When initialValue changes, the text field updates.
class _ControlledTextField extends StatefulWidget {
  final String initialValue;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final bool obscureText;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;

  const _ControlledTextField({
    super.key,
    required this.initialValue,
    this.decoration,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<_ControlledTextField> createState() => _ControlledTextFieldState();
}

class _ControlledTextFieldState extends State<_ControlledTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_ControlledTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only sync from host when value is cleared (reset/clear action)
    // Don't sync during normal typing to avoid cursor/focus issues
    if (widget.initialValue.isEmpty && _controller.text.isNotEmpty) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: widget.decoration,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}

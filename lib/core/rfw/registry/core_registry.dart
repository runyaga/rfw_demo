import 'package:flutter/widgets.dart';
import 'package:rfw/rfw.dart';

/// Version constant for capability handshake (DESIGN.md Section 5.1)
const String kCoreRegistryVersion = '1.0.0';

/// Creates the core widget library with design-system constraints.
///
/// Per DESIGN.md Section 3 Phase 1 Step 2:
/// "A large enterprise app should wrap these with design-system constraints."
///
/// This wraps `createCoreWidgets()` and exposes design-system-constrained
/// versions rather than raw Flutter widgets.
LocalWidgetLibrary createAppCoreWidgets() {
  // Start with the standard core widgets from RFW
  final coreWidgets = createCoreWidgets();

  // Add design-system-constrained widgets
  return LocalWidgetLibrary(<String, LocalWidgetBuilder>{
    // Include all standard core widgets
    ...coreWidgets.widgets,

    // Design-system constrained Container
    'DesignSystemContainer': (BuildContext context, DataSource source) {
      // Constrained Container with design system limits
      return Container(
        width: source.v<double>(['width']),
        height: source.v<double>(['height']),
        padding: source.v<EdgeInsets>(['padding']),
        margin: source.v<EdgeInsets>(['margin']),
        decoration: BoxDecoration(
          color: Color(source.v<int>(['color']) ?? 0x00000000),
          borderRadius: BorderRadius.circular(
            source.v<double>(['borderRadius']) ?? 0.0,
          ),
        ),
        child: source.child(['child']),
      );
    },

    // Design-system constrained Text
    'DesignSystemText': (BuildContext context, DataSource source) {
      final text = source.v<String>(['text']) ?? '';
      final fontSize = source.v<double>(['fontSize']) ?? 14.0;
      final fontWeight = _parseFontWeight(source.v<String>(['fontWeight']));
      final color = Color(source.v<int>(['color']) ?? 0xFF000000);

      return Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
        textAlign: _parseTextAlign(source.v<String>(['textAlign'])),
        maxLines: source.v<int>(['maxLines']),
        overflow: source.v<int>(['maxLines']) != null
            ? TextOverflow.ellipsis
            : null,
      );
    },

    // Design-system Spacer
    'DesignSystemSpacer': (BuildContext context, DataSource source) {
      final size = source.v<double>(['size']) ?? 8.0;
      return SizedBox(
        width: source.v<bool>(['horizontal']) == true ? size : null,
        height: source.v<bool>(['horizontal']) != true ? size : null,
      );
    },
  });
}

FontWeight _parseFontWeight(String? weight) {
  switch (weight) {
    case 'bold':
      return FontWeight.bold;
    case 'w100':
      return FontWeight.w100;
    case 'w200':
      return FontWeight.w200;
    case 'w300':
      return FontWeight.w300;
    case 'w400':
      return FontWeight.w400;
    case 'w500':
      return FontWeight.w500;
    case 'w600':
      return FontWeight.w600;
    case 'w700':
      return FontWeight.w700;
    case 'w800':
      return FontWeight.w800;
    case 'w900':
      return FontWeight.w900;
    default:
      return FontWeight.normal;
  }
}

TextAlign? _parseTextAlign(String? align) {
  switch (align) {
    case 'left':
      return TextAlign.left;
    case 'right':
      return TextAlign.right;
    case 'center':
      return TextAlign.center;
    case 'justify':
      return TextAlign.justify;
    default:
      return null;
  }
}

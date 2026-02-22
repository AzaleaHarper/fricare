import 'package:flutter/material.dart';

/// Predefined accent/seed colors shared across main app and overlay.
const accentColorOptions = <Color>[
  Colors.deepPurple,
  Colors.blue,
  Colors.teal,
  Colors.green,
  Colors.orange,
  Colors.red,
  Colors.pink,
  Colors.indigo,
];

/// Builds a themed [ThemeData] from accent color index, brightness, and AMOLED
/// preference. Used by both the main app and the overlay engine.
ThemeData buildAppTheme({
  required int accentColorIndex,
  required Brightness brightness,
  bool amoledDark = false,
}) {
  final seedColor =
      accentColorOptions[accentColorIndex.clamp(
        0,
        accentColorOptions.length - 1,
      )];
  final base = ThemeData(
    colorSchemeSeed: seedColor,
    useMaterial3: true,
    brightness: brightness,
  );
  if (brightness != Brightness.dark || !amoledDark) return base;

  return base.copyWith(
    scaffoldBackgroundColor: Colors.black,
    colorScheme: base.colorScheme.copyWith(
      surface: Colors.black,
      onSurface: Colors.white,
    ),
  );
}

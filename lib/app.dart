import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/home_screen.dart';

class FricareApp extends ConsumerWidget {
  const FricareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final seedColor = accentColorOptions[
        settings.accentColorIndex.clamp(0, accentColorOptions.length - 1)];
    final themeMode = ThemeMode.values[settings.themeModeIndex.clamp(0, 2)];

    return MaterialApp(
      title: 'Fricare',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        colorSchemeSeed: seedColor,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: _buildDarkTheme(seedColor, settings.amoledDark),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildDarkTheme(Color seedColor, bool amoled) {
    final base = ThemeData(
      colorSchemeSeed: seedColor,
      useMaterial3: true,
      brightness: Brightness.dark,
    );
    if (!amoled) return base;

    return base.copyWith(
      scaffoldBackgroundColor: Colors.black,
      colorScheme: base.colorScheme.copyWith(
        surface: Colors.black,
        onSurface: Colors.white,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/theme/app_theme.dart';

class FricareApp extends ConsumerWidget {
  const FricareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeMode = ThemeMode.values[settings.themeModeIndex.clamp(0, 2)];

    return MaterialApp(
      title: 'Fricare',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: buildAppTheme(
        accentColorIndex: settings.accentColorIndex,
        brightness: Brightness.light,
      ),
      darkTheme: buildAppTheme(
        accentColorIndex: settings.accentColorIndex,
        brightness: Brightness.dark,
        amoledDark: settings.amoledDark,
      ),
      home: const HomeScreen(),
    );
  }
}

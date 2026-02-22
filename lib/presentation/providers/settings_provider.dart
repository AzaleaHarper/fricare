import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/friction_settings.dart';
import 'friction_apps_provider.dart';

/// Predefined accent/seed colors for the color picker.
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

final settingsProvider =
    NotifierProvider<SettingsNotifier, FrictionSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<FrictionSettings> {
  @override
  FrictionSettings build() {
    return ref.read(repositoryProvider).getSettings();
  }

  Future<void> _save(FrictionSettings settings) async {
    state = settings;
    await ref.read(repositoryProvider).saveSettings(settings);
  }

  Future<void> toggleGlobal(bool enabled) async {
    await _save(FrictionSettings(
      globalEnabled: enabled,
      themeModeIndex: state.themeModeIndex,
      accentColorIndex: state.accentColorIndex,
      amoledDark: state.amoledDark,
    ));
  }

  Future<void> setThemeMode(int modeIndex) async {
    await _save(FrictionSettings(
      globalEnabled: state.globalEnabled,
      themeModeIndex: modeIndex,
      accentColorIndex: state.accentColorIndex,
      amoledDark: state.amoledDark,
    ));
  }

  Future<void> setAccentColor(int colorIndex) async {
    await _save(FrictionSettings(
      globalEnabled: state.globalEnabled,
      themeModeIndex: state.themeModeIndex,
      accentColorIndex: colorIndex,
      amoledDark: state.amoledDark,
    ));
  }

  Future<void> setAmoledDark(bool enabled) async {
    await _save(FrictionSettings(
      globalEnabled: state.globalEnabled,
      themeModeIndex: state.themeModeIndex,
      accentColorIndex: state.accentColorIndex,
      amoledDark: enabled,
    ));
  }
}

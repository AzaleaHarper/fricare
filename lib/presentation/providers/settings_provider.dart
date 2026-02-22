import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/friction_settings.dart';
import '../../infrastructure/services/app_sync_service.dart';
import 'friction_apps_provider.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, FrictionSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<FrictionSettings> {
  @override
  FrictionSettings build() {
    return ref.read(repositoryProvider).getSettings();
  }

  Future<void> _save(FrictionSettings settings) async {
    state = settings;
    await ref.read(repositoryProvider).saveSettings(settings);
    await AppSyncService.syncThemeToNative(settings);
  }

  Future<void> toggleGlobal(bool enabled) =>
      _save(state.copyWith(globalEnabled: enabled));

  Future<void> setThemeMode(int modeIndex) =>
      _save(state.copyWith(themeModeIndex: modeIndex));

  Future<void> setAccentColor(int colorIndex) =>
      _save(state.copyWith(accentColorIndex: colorIndex));

  Future<void> setAmoledDark(bool enabled) =>
      _save(state.copyWith(amoledDark: enabled));
}

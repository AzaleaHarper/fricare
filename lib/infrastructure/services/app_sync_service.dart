import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/friction_app.dart';
import '../../domain/models/friction_settings.dart';

/// Syncs friction app configs to SharedPreferences so the native Android
/// foreground service can read them without a Flutter engine.
class AppSyncService {
  static const _channel = MethodChannel('com.fricare/sync');

  /// Push theme settings so the overlay service can apply them.
  static Future<void> syncThemeToNative(FrictionSettings settings) async {
    await _channel.invokeMethod('syncTheme', {
      'themeModeIndex': settings.themeModeIndex,
      'accentColorIndex': settings.accentColorIndex,
      'amoledDark': settings.amoledDark,
    });
  }

  static Future<void> syncToNative(List<FrictionApp> apps) async {
    final data =
        apps.where((a) => a.enabled).map((a) {
          final cfg = a.frictionConfig;
          return {
            'packageName': a.packageName,
            'appName': a.appName,
            'kind': cfg.kind.index,
            'delaySeconds': cfg.effectiveDelay,
            'confirmationSteps': cfg.confirmationSteps,
            'puzzleTaps': cfg.puzzleTaps,
            'mathProblems': cfg.mathProblems,
            'chainSteps': cfg.chainSteps.map((s) => s.toJson()).toList(),
            'cooldownMinutes': cfg.cooldownMinutes,
          };
        }).toList();

    await _channel.invokeMethod('syncApps', {'json': jsonEncode(data)});
  }
}

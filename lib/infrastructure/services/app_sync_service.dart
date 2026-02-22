import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/friction_app.dart';

/// Syncs friction app configs to SharedPreferences so the native Android
/// foreground service can read them without a Flutter engine.
class AppSyncService {
  static const _channel = MethodChannel('com.fricare/sync');

  static Future<void> syncToNative(List<FrictionApp> apps) async {
    final data = apps
        .where((a) => a.enabled)
        .map((a) {
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
            'mode': cfg.mode.index,
            'openThreshold': cfg.openThreshold,
            'escalationSteps': cfg.escalationSteps
                .map((s) => {
                      'fromOpen': s.fromOpen,
                      'kind': s.kind.index,
                      'delaySeconds': s.delaySeconds,
                    })
                .toList(),
          };
        })
        .toList();

    await _channel.invokeMethod('syncApps', {'json': jsonEncode(data)});
  }
}

import 'package:flutter/foundation.dart';
import 'package:installed_apps/installed_apps.dart';

class InstalledAppInfo {
  final String packageName;
  final String appName;
  final Uint8List? icon;

  const InstalledAppInfo({
    required this.packageName,
    required this.appName,
    this.icon,
  });
}

class InstalledAppsService {
  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 1);
  static const _timeout = Duration(seconds: 10);

  Future<List<InstalledAppInfo>> getLaunchableApps() async {
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final apps = await InstalledApps.getInstalledApps(
          true,
          true,
        ).timeout(_timeout);

        return apps
            .map(
              (app) => InstalledAppInfo(
                packageName: app.packageName,
                appName: app.name,
                icon: app.icon,
              ),
            )
            .where((app) => app.packageName.isNotEmpty)
            .toList()
          ..sort((a, b) => a.appName.compareTo(b.appName));
      } catch (e) {
        debugPrint('InstalledAppsService: attempt ${attempt + 1} failed: $e');
        if (attempt < _maxRetries - 1) {
          await Future<void>.delayed(_retryDelay);
        } else {
          rethrow;
        }
      }
    }
    // Unreachable, but satisfies the analyzer.
    return [];
  }
}

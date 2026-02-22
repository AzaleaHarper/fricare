import 'dart:typed_data';

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
  Future<List<InstalledAppInfo>> getLaunchableApps() async {
    final apps = await InstalledApps.getInstalledApps(true, true);

    return apps
        .map((app) => InstalledAppInfo(
              packageName: app.packageName,
              appName: app.name,
              icon: app.icon,
            ))
        .where((app) => app.packageName.isNotEmpty)
        .toList()
      ..sort((a, b) => a.appName.compareTo(b.appName));
  }
}

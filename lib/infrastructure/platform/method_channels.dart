import 'package:flutter/services.dart';

/// Communicates with native Android code for app launch detection and overlay.
class FricarePlatform {
  static const _channel = MethodChannel('com.fricare/friction');

  /// Start the foreground service that monitors app launches.
  static Future<void> startMonitoringService() async {
    await _channel.invokeMethod('startMonitoringService');
  }

  /// Stop the foreground service.
  static Future<void> stopMonitoringService() async {
    await _channel.invokeMethod('stopMonitoringService');
  }

  /// Check if the monitoring service is currently running.
  static Future<bool> isServiceRunning() async {
    final result = await _channel.invokeMethod<bool>('isServiceRunning');
    return result ?? false;
  }

  /// Request usage stats permission (opens system settings).
  static Future<void> requestUsageStatsPermission() async {
    await _channel.invokeMethod('requestUsageStatsPermission');
  }

  /// Check if usage stats permission is granted.
  static Future<bool> hasUsageStatsPermission() async {
    final result =
        await _channel.invokeMethod<bool>('hasUsageStatsPermission');
    return result ?? false;
  }

  /// Check if overlay (draw over other apps) permission is granted.
  static Future<bool> hasOverlayPermission() async {
    final result = await _channel.invokeMethod<bool>('hasOverlayPermission');
    return result ?? false;
  }

  /// Request overlay permission (opens system settings for this app).
  static Future<void> requestOverlayPermission() async {
    await _channel.invokeMethod('requestOverlayPermission');
  }

  /// Launch a specific app by package name.
  static Future<void> launchApp(String packageName) async {
    await _channel.invokeMethod('launchApp', {'packageName': packageName});
  }
}

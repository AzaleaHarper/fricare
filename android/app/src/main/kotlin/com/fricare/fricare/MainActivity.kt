package com.fricare.fricare

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        const val CHANNEL = "com.fricare/friction"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Sync channel: Flutter writes app configs to SharedPreferences
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.fricare/sync")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "syncApps" -> {
                        val json = call.argument<String>("json")
                        if (json != null) {
                            getSharedPreferences(AppLaunchDetectorService.PREFS_NAME, Context.MODE_PRIVATE)
                                .edit()
                                .putString(AppLaunchDetectorService.KEY_MONITORED_APPS, json)
                                .apply()
                            result.success(null)
                        } else {
                            result.error("INVALID_ARG", "json required", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // Main friction channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startMonitoringService" -> {
                        startMonitoringService()
                        result.success(null)
                    }
                    "stopMonitoringService" -> {
                        stopMonitoringService()
                        result.success(null)
                    }
                    "isServiceRunning" -> {
                        result.success(AppLaunchDetectorService.isRunning)
                    }
                    "requestUsageStatsPermission" -> {
                        requestUsageStatsPermission()
                        result.success(null)
                    }
                    "hasUsageStatsPermission" -> {
                        result.success(hasUsageStatsPermission())
                    }
                    "hasOverlayPermission" -> {
                        result.success(Settings.canDrawOverlays(this))
                    }
                    "requestOverlayPermission" -> {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            android.net.Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                        result.success(null)
                    }
                    "launchApp" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName != null) {
                            launchApp(packageName)
                            result.success(null)
                        } else {
                            result.error("INVALID_ARG", "packageName required", null)
                        }
                    }
                    "isBatteryOptimized" -> {
                        result.success(isBatteryOptimized())
                    }
                    "requestBatteryOptimizationExemption" -> {
                        requestBatteryOptimizationExemption()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startMonitoringService() {
        val intent = Intent(this, AppLaunchDetectorService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopMonitoringService() {
        val intent = Intent(this, AppLaunchDetectorService::class.java)
        stopService(intent)
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageStatsPermission() {
        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
    }

    private fun isBatteryOptimized(): Boolean {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        return !pm.isIgnoringBatteryOptimizations(packageName)
    }

    @android.annotation.SuppressLint("BatteryLife")
    private fun requestBatteryOptimizationExemption() {
        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
            data = android.net.Uri.parse("package:$packageName")
        }
        startActivity(intent)
    }

    private fun launchApp(targetPackageName: String) {
        val launchIntent = packageManager.getLaunchIntentForPackage(targetPackageName)
        if (launchIntent != null) {
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(launchIntent)
        }
    }
}

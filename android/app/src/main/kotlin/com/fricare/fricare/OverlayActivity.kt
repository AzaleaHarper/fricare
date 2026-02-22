package com.fricare.fricare

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Fullscreen activity that shows the friction challenge.
 * Launched by AppLaunchDetectorService when a monitored app is detected.
 * Uses a Flutter view to render the friction UI.
 */
class OverlayActivity : FlutterActivity() {
    companion object {
        const val CHANNEL = "com.fricare/overlay"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // Send friction config to the Flutter overlay UI
        val kind = intent.getIntExtra("kind", 0)
        val delaySeconds = intent.getIntExtra("delaySeconds", 3)
        val confirmationSteps = intent.getIntExtra("confirmationSteps", 2)
        val puzzleTaps = intent.getIntExtra("puzzleTaps", 5)
        val mathProblems = intent.getIntExtra("mathProblems", 3)
        val appName = intent.getStringExtra("appName") ?: ""
        val packageName = intent.getStringExtra("packageName") ?: ""
        val chainStepsJson = intent.getStringExtra("chainStepsJson") ?: "[]"

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getFrictionConfig" -> {
                    result.success(mapOf(
                        "kind" to kind,
                        "delaySeconds" to delaySeconds,
                        "confirmationSteps" to confirmationSteps,
                        "puzzleTaps" to puzzleTaps,
                        "mathProblems" to mathProblems,
                        "appName" to appName,
                        "packageName" to packageName,
                        "chainStepsJson" to chainStepsJson
                    ))
                }
                "frictionComplete" -> {
                    // Friction passed - close overlay, let the app continue
                    finish()
                    result.success(null)
                }
                "frictionCancelled" -> {
                    // User cancelled - go home instead
                    val homeIntent = android.content.Intent(android.content.Intent.ACTION_MAIN)
                    homeIntent.addCategory(android.content.Intent.CATEGORY_HOME)
                    homeIntent.flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(homeIntent)
                    finish()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun getDartEntrypointFunctionName(): String {
        return "overlayMain"
    }

    override fun getDartEntrypointLibraryUri(): String {
        return "package:fricare/overlay/overlay_main.dart"
    }
}

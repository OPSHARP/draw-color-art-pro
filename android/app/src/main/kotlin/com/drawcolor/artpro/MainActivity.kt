package com.drawcolor.artpro

import android.media.MediaScannerConnection
import android.os.Build
import android.view.Display
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val GALLERY_CHANNEL = "com.drawcolor.artpro/gallery"
    private val DISPLAY_CHANNEL = "com.drawcolor.artpro/display"

    override fun onResume() {
        super.onResume()
        // Ensure highest display refresh rate (90Hz, 120Hz, 144Hz, 165Hz) whenever app resumes
        enableHighestRefreshRate()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Enable highest refresh rate as soon as engine is initialized
        enableHighestRefreshRate()

        // Gallery Scanner Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GALLERY_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "scanFile") {
                val path = call.argument<String>("path")
                if (path != null) {
                    try {
                        MediaScannerConnection.scanFile(this, arrayOf(path), null) { _, uri ->
                            runOnUiThread {
                                result.success(uri?.toString() ?: path)
                            }
                        }
                    } catch (e: Exception) {
                        runOnUiThread {
                            result.error("SCAN_ERROR", e.localizedMessage, null)
                        }
                    }
                } else {
                    result.error("INVALID_PATH", "Path cannot be null", null)
                }
            } else {
                result.notImplemented()
            }
        }

        // Display High Refresh Rate Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DISPLAY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setHighestRefreshRate" -> {
                    val rate = enableHighestRefreshRate()
                    result.success(rate.toDouble())
                }
                "getCurrentRefreshRate" -> {
                    val rate = getCurrentRefreshRate()
                    result.success(rate.toDouble())
                }
                "getSupportedRefreshRates" -> {
                    val rates = getSupportedRefreshRates()
                    result.success(rates.map { it.toDouble() })
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun enableHighestRefreshRate(): Float {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val disp = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    display
                } else {
                    @Suppress("DEPRECATION")
                    windowManager.defaultDisplay
                }

                if (disp != null) {
                    val modes = disp.supportedModes
                    // Find the mode with the highest refresh rate and highest resolution
                    val bestMode = modes.maxWithOrNull(
                        compareBy<Display.Mode> { it.refreshRate }
                            .thenBy { it.physicalWidth * it.physicalHeight }
                    )

                    if (bestMode != null) {
                        val layoutParams = window.attributes
                        layoutParams.preferredDisplayModeId = bestMode.modeId
                        window.attributes = layoutParams
                        return bestMode.refreshRate
                    }
                }
            } catch (e: Exception) {
                // Fallback gracefully without throwing
            }
        }
        return 60.0f
    }

    private fun getCurrentRefreshRate(): Float {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val disp = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    display
                } else {
                    @Suppress("DEPRECATION")
                    windowManager.defaultDisplay
                }
                if (disp != null) {
                    return disp.mode.refreshRate
                }
            } catch (e: Exception) {
                // Fallback
            }
        }
        return 60.0f
    }

    private fun getSupportedRefreshRates(): List<Float> {
        val rates = mutableListOf<Float>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val disp = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    display
                } else {
                    @Suppress("DEPRECATION")
                    windowManager.defaultDisplay
                }
                if (disp != null) {
                    disp.supportedModes.forEach { mode ->
                        if (!rates.contains(mode.refreshRate)) {
                            rates.add(mode.refreshRate)
                        }
                    }
                }
            } catch (e: Exception) {
                // Fallback
            }
        }
        if (rates.isEmpty()) {
            rates.add(60.0f)
        }
        return rates.sorted()
    }
}

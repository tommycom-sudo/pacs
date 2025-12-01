package com.tundralabs.flutterttsexample

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "native.overlay"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isPermissionGranted" -> {
                    val granted = Settings.canDrawOverlays(this)
                    result.success(granted)
                }
                "requestPermission" -> {
                    try {
                        val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("REQUEST_PERMISSION_ERROR", e.message, null)
                    }
                }
                "showMask" -> {
                    val heightDp = call.argument<Int>("heightDp") ?: 80
                    val alpha = call.argument<Int>("alpha") ?: 230
                    val intent = Intent(this, OverlayService::class.java).apply {
                        action = OverlayService.ACTION_SHOW
                        putExtra(OverlayService.EXTRA_HEIGHT_DP, heightDp)
                        putExtra(OverlayService.EXTRA_ALPHA, alpha)
                    }
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("START_SERVICE_ERROR", e.message, null)
                    }
                }
                "hideMask" -> {
                    val intent = Intent(this, OverlayService::class.java).apply {
                        action = OverlayService.ACTION_HIDE
                    }
                    try {
                        startService(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("STOP_SERVICE_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}


package com.example.shourk_application

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL = "zoom_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "joinZoomSession" -> {
                    val token = call.argument<String>("token")
                    val sessionName = call.argument<String>("sessionName")
                    val userName = call.argument<String>("userName")
                    val userIdentity = call.argument<String>("userIdentity")
                    val role = call.argument<Int>("role") ?: 0
                    runOnUiThread {
                        joinZoomSession(token, sessionName, userName, userIdentity, role, result)
                    }
                }
                "leaveZoomSession" -> {
                    runOnUiThread {
                        leaveZoomSession(result)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun joinZoomSession(
        token: String?,
        sessionName: String?,
        userName: String?,
        userIdentity: String?,
        role: Int,
        result: MethodChannel.Result
    ) {
        if (token == null || sessionName == null || userName == null) {
            result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
            return
        }

        try {
            // For now, we'll simulate the Zoom SDK integration
            // TODO: Replace this with actual Zoom Video SDK implementation
            Log.d("ZoomSDK", "Simulating Zoom session join")
            Log.d("ZoomSDK", "Token: $token")
            Log.d("ZoomSDK", "Session Name: $sessionName")
            Log.d("ZoomSDK", "User Name: $userName")
            Log.d("ZoomSDK", "User Identity: $userIdentity")
            Log.d("ZoomSDK", "Role: $role")
            
            // Simulate successful join
            result.success(null)
        } catch (e: Exception) {
            result.error("JOIN_FAILED", "Failed to join session: ${e.message}", null)
        }
    }

    // NOTE: You must include the following .so files in your project under src/main/jniLibs/<abi>/
    // - libzoom_video_sdk.so
    // - libc++_shared.so
    // - libcrypto.so
    // - libssl.so
    // - libzlib.so
    // - libzoom_sdk_render.so
    // (Check your Zoom Video SDK package for the exact .so files and ABIs: arm64-v8a, armeabi-v7a, x86, x86_64)
    private fun leaveZoomSession(result: MethodChannel.Result) {
        try {
            // For now, we'll simulate the Zoom SDK leave session
            // TODO: Replace this with actual Zoom Video SDK implementation
            Log.d("ZoomSDK", "Simulating Zoom session leave")
            result.success(null)
        } catch (e: Exception) {
            result.error("LEAVE_FAILED", "Failed to leave session: ${e.message}", null)
        }
    }
}

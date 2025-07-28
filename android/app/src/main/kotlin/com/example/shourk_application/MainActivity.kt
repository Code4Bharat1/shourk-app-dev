package com.example.shourk_application

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL = "zoom_channel"
    private var isInSession = false

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
                "toggleMic" -> {
                    val on = call.argument<Boolean>("on") ?: false
                    runOnUiThread {
                        toggleMic(on, result)
                    }
                }
                "toggleCam" -> {
                    val on = call.argument<Boolean>("on") ?: false
                    runOnUiThread {
                        toggleCam(on, result)
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
            // Mock implementation for now - will be replaced with real Zoom SDK
            Log.d("ZoomSDK", "Mock: Joining Zoom session")
            Log.d("ZoomSDK", "Token: $token")
            Log.d("ZoomSDK", "Session Name: $sessionName")
            Log.d("ZoomSDK", "User Name: $userName")
            Log.d("ZoomSDK", "User Identity: $userIdentity")
            Log.d("ZoomSDK", "Role: $role")
            
            isInSession = true
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
            // Mock implementation for now
            Log.d("ZoomSDK", "Mock: Leaving Zoom session")
            isInSession = false
            result.success(null)
        } catch (e: Exception) {
            result.error("LEAVE_FAILED", "Failed to leave session: ${e.message}", null)
        }
    }

    private fun toggleMic(on: Boolean, result: MethodChannel.Result) {
        try {
            // Mock implementation for now
            Log.d("ZoomSDK", "Mock: Toggle mic to ${if (on) "ON" else "OFF"}")
            result.success(null)
        } catch (e: Exception) {
            result.error("MIC_TOGGLE_FAILED", "Failed to toggle mic: ${e.message}", null)
        }
    }

    private fun toggleCam(on: Boolean, result: MethodChannel.Result) {
        try {
            // Mock implementation for now
            Log.d("ZoomSDK", "Mock: Toggle camera to ${if (on) "ON" else "OFF"}")
            result.success(null)
        } catch (e: Exception) {
            result.error("CAM_TOGGLE_FAILED", "Failed to toggle camera: ${e.message}", null)
        }
    }
}

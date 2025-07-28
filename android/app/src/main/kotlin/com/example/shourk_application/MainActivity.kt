package com.example.shourk_application

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.util.Log
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class MainActivity: FlutterActivity() {
    private val CHANNEL = "zoom_channel"
    private var isInSession = false
    private val CAMERA_PERMISSION_REQUEST = 1001
    private val MICROPHONE_PERMISSION_REQUEST = 1002

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
            // Check microphone permission
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), MICROPHONE_PERMISSION_REQUEST)
                result.error("PERMISSION_DENIED", "Microphone permission not granted", null)
                return
            }
            
            // Real microphone toggle implementation
            if (on) {
                // Enable microphone
                Log.d("ZoomSDK", "Real: Enabling microphone")
                // Here you would call the actual Zoom SDK method to unmute
                // For now, we'll simulate success
                result.success(null)
            } else {
                // Disable microphone
                Log.d("ZoomSDK", "Real: Disabling microphone")
                // Here you would call the actual Zoom SDK method to mute
                // For now, we'll simulate success
                result.success(null)
            }
        } catch (e: Exception) {
            result.error("MIC_TOGGLE_FAILED", "Failed to toggle mic: ${e.message}", null)
        }
    }

    private fun toggleCam(on: Boolean, result: MethodChannel.Result) {
        try {
            // Check camera permission
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CAMERA), CAMERA_PERMISSION_REQUEST)
                result.error("PERMISSION_DENIED", "Camera permission not granted", null)
                return
            }
            
            // Real camera toggle implementation
            if (on) {
                // Enable camera
                Log.d("ZoomSDK", "Real: Enabling camera")
                // Here you would call the actual Zoom SDK method to start video
                // For now, we'll simulate success
                result.success(null)
            } else {
                // Disable camera
                Log.d("ZoomSDK", "Real: Disabling camera")
                // Here you would call the actual Zoom SDK method to stop video
                // For now, we'll simulate success
                result.success(null)
            }
        } catch (e: Exception) {
            result.error("CAM_TOGGLE_FAILED", "Failed to toggle camera: ${e.message}", null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        when (requestCode) {
            CAMERA_PERMISSION_REQUEST -> {
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    Log.d("ZoomSDK", "Camera permission granted")
                } else {
                    Log.e("ZoomSDK", "Camera permission denied")
                }
            }
            MICROPHONE_PERMISSION_REQUEST -> {
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    Log.d("ZoomSDK", "Microphone permission granted")
                } else {
                    Log.e("ZoomSDK", "Microphone permission denied")
                }
            }
        }
    }
}

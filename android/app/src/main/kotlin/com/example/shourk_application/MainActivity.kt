package com.example.shourk_application

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.util.Log
import us.zoom.sdk.*
import us.zoom.videosdk.*
import us.zoom.videosdk.audio.ZoomVideoSDKAudioHelper
import us.zoom.videosdk.video.ZoomVideoSDKVideoHelper
import us.zoom.videosdk.video.ZoomVideoSDKVideoHelperListener
import us.zoom.videosdk.video.ZoomVideoSDKVideoView
import us.zoom.videosdk.video.ZoomVideoSDKVideoViewListener

class MainActivity: FlutterActivity() {
    private val CHANNEL = "zoom_channel"
    private var zoomVideoSDK: ZoomVideoSDK? = null
    private var currentSession: ZoomVideoSDKSession? = null
    private var isInitialized = false

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

    private fun initializeZoomSDK(): Boolean {
        if (isInitialized) return true
        
        try {
            // Initialize Zoom Video SDK
            val initParams = ZoomVideoSDKInitParams().apply {
                domain = "zoom.us"
                enableLog = true
            }
            
            val initResult = ZoomVideoSDK.getInstance().initialize(this, initParams)
            if (initResult == ZoomVideoSDKError.SUCCESS) {
                isInitialized = true
                zoomVideoSDK = ZoomVideoSDK.getInstance()
                Log.d("ZoomSDK", "Zoom Video SDK initialized successfully")
                return true
            } else {
                Log.e("ZoomSDK", "Failed to initialize Zoom Video SDK: $initResult")
                return false
            }
        } catch (e: Exception) {
            Log.e("ZoomSDK", "Exception during Zoom SDK initialization: ${e.message}")
            return false
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
            // Initialize Zoom SDK if not already done
            if (!initializeZoomSDK()) {
                result.error("INIT_FAILED", "Failed to initialize Zoom SDK", null)
                return
            }
            
            // Join session
            val joinParams = ZoomVideoSDKJoinParams().apply {
                sessionName = sessionName
                token = token
                userName = userName
                userType = if (role == 1) ZoomVideoSDKUserType.ZoomVideoSDKUserType_APIUser else ZoomVideoSDKUserType.ZoomVideoSDKUserType_ZoomUser
            }
            
            zoomVideoSDK?.joinSession(joinParams, object : ZoomVideoSDKJoinSessionListener {
                override fun onSessionJoin() {
                    Log.d("ZoomSDK", "Successfully joined Zoom session")
                    currentSession = zoomVideoSDK?.getSession()
                    result.success(null)
                }
                
                override fun onSessionJoinFail(error: ZoomVideoSDKError) {
                    Log.e("ZoomSDK", "Failed to join session: $error")
                    result.error("JOIN_FAILED", "Failed to join session: $error", null)
                }
            })
            
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
            currentSession?.let { session ->
                session.leaveSession(object : ZoomVideoSDKSessionLeaveListener {
                    override fun onSessionLeave() {
                        Log.d("ZoomSDK", "Successfully left Zoom session")
                        currentSession = null
                        result.success(null)
                    }
                    
                    override fun onSessionLeaveFail(error: ZoomVideoSDKError) {
                        Log.e("ZoomSDK", "Failed to leave session: $error")
                        result.error("LEAVE_FAILED", "Failed to leave session: $error", null)
                    }
                })
            } ?: run {
                Log.d("ZoomSDK", "No active session to leave")
                result.success(null)
            }
        } catch (e: Exception) {
            result.error("LEAVE_FAILED", "Failed to leave session: ${e.message}", null)
        }
    }

    private fun toggleMic(on: Boolean, result: MethodChannel.Result) {
        try {
            currentSession?.let { session ->
                val audioHelper = session.getAudioHelper()
                if (on) {
                    audioHelper.unmuteAudio()
                    Log.d("ZoomSDK", "Microphone unmuted")
                } else {
                    audioHelper.muteAudio()
                    Log.d("ZoomSDK", "Microphone muted")
                }
                result.success(null)
            } ?: run {
                result.error("NO_SESSION", "No active session", null)
            }
        } catch (e: Exception) {
            result.error("MIC_TOGGLE_FAILED", "Failed to toggle mic: ${e.message}", null)
        }
    }

    private fun toggleCam(on: Boolean, result: MethodChannel.Result) {
        try {
            currentSession?.let { session ->
                val videoHelper = session.getVideoHelper()
                if (on) {
                    videoHelper.startVideo()
                    Log.d("ZoomSDK", "Camera started")
                } else {
                    videoHelper.stopVideo()
                    Log.d("ZoomSDK", "Camera stopped")
                }
                result.success(null)
            } ?: run {
                result.error("NO_SESSION", "No active session", null)
            }
        } catch (e: Exception) {
            result.error("CAM_TOGGLE_FAILED", "Failed to toggle camera: ${e.message}", null)
        }
    }
}

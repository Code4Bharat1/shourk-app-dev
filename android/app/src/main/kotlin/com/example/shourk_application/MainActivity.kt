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
import us.zoom.videosdk.*
import us.zoom.videosdk.ZoomVideoSDK
import us.zoom.videosdk.ZoomVideoSDKInitListener
import us.zoom.videosdk.ZoomVideoSDKErrors
import us.zoom.videosdk.ZoomVideoSDKInitParams
import us.zoom.videosdk.ZoomVideoSDKJoinParams
import us.zoom.videosdk.ZoomVideoSDKUser
import us.zoom.videosdk.ZoomVideoSDKUserType
import us.zoom.videosdk.ZoomVideoSDKJoinSessionListener
import us.zoom.videosdk.ZoomVideoSDKSessionLeaveListener
import us.zoom.videosdk.ZoomVideoSDKVideoHelper
import us.zoom.videosdk.ZoomVideoSDKAudioHelper
import us.zoom.videosdk.ZoomVideoSDKCallback

class MainActivity: FlutterActivity() {
    private val CHANNEL = "zoom_channel"
    private var isInSession = false
    private val CAMERA_PERMISSION_REQUEST = 1001
    private val MICROPHONE_PERMISSION_REQUEST = 1002
    private var currentSession: ZoomVideoSDKSession? = null
    private var currentUser: ZoomVideoSDKUser? = null
    private var videoHelper: ZoomVideoSDKVideoHelper? = null
    private var audioHelper: ZoomVideoSDKAudioHelper? = null

    companion object {
        // TODO: Replace with your actual Zoom Video SDK credentials
        // Get these from https://marketplace.zoom.us/develop/create
        private const val ZOOM_SDK_KEY = "YOUR_ZOOM_VIDEO_SDK_KEY_HERE"
        private const val ZOOM_SDK_SECRET = "YOUR_ZOOM_VIDEO_SDK_SECRET_HERE"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Initialize Zoom Video SDK
        initializeZoomSDK()
        
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

    private fun initializeZoomSDK() {
        try {
            val initParams = ZoomVideoSDKInitParams().apply {
                appKey = ZOOM_SDK_KEY
                appSecret = ZOOM_SDK_SECRET
                domain = "zoom.us"
                enableLog = true
            }
            
            val initResult = ZoomVideoSDK.getInstance().initialize(this, initParams, object : ZoomVideoSDKInitListener {
                override fun onSDKInitializeError(error: ZoomVideoSDKErrors) {
                    Log.e("ZoomSDK", "SDK initialization failed: $error")
                }
                
                override fun onSDKInitializeSuccess() {
                    Log.d("ZoomSDK", "SDK initialized successfully")
                }
            })
            
            if (initResult != ZoomVideoSDKErrors.ZoomVideoSDKErrors_Success) {
                Log.e("ZoomSDK", "Failed to initialize SDK: $initResult")
            }
        } catch (e: Exception) {
            Log.e("ZoomSDK", "Exception during SDK initialization: ${e.message}")
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
            // Real Zoom SDK session join
            Log.d("ZoomSDK", "Joining real Zoom session: $sessionName")
            
            val joinParams = ZoomVideoSDKJoinParams().apply {
                sessionName = sessionName
                token = token
                userName = userName
                userType = if (role == 1) ZoomVideoSDKUserType.ZoomVideoSDKUserType_APIUser else ZoomVideoSDKUserType.ZoomVideoSDKUserType_ZoomUser
            }
            
            currentSession = ZoomVideoSDK.getInstance().joinSession(joinParams, object : ZoomVideoSDKJoinSessionListener {
                override fun onSessionJoin() {
                    Log.d("ZoomSDK", "Successfully joined session")
                    currentUser = ZoomVideoSDK.getInstance().session?.mySelf
                    videoHelper = ZoomVideoSDK.getInstance().videoHelper
                    audioHelper = ZoomVideoSDK.getInstance().audioHelper
                    
                    isInSession = true
                    runOnUiThread {
                        result.success(null)
                    }
                }
                
                override fun onSessionJoinFail(error: ZoomVideoSDKErrors) {
                    Log.e("ZoomSDK", "Failed to join session: $error")
                    runOnUiThread {
                        result.error("JOIN_FAILED", "Failed to join session: $error", null)
                    }
                }
            })
            
        } catch (e: Exception) {
            result.error("JOIN_FAILED", "Failed to join session: ${e.message}", null)
        }
    }

    private fun leaveZoomSession(result: MethodChannel.Result) {
        try {
            // Real Zoom SDK session leave
            Log.d("ZoomSDK", "Leaving real Zoom session")
            
            currentSession?.leaveSession(object : ZoomVideoSDKSessionLeaveListener {
                override fun onSessionLeave() {
                    Log.d("ZoomSDK", "Successfully left session")
                    currentSession = null
                    currentUser = null
                    videoHelper = null
                    audioHelper = null
                    isInSession = false
                    
                    runOnUiThread {
                        result.success(null)
                    }
                }
                
                override fun onSessionLeaveFail(error: ZoomVideoSDKErrors) {
                    Log.e("ZoomSDK", "Failed to leave session: $error")
                    runOnUiThread {
                        result.error("LEAVE_FAILED", "Failed to leave session: $error", null)
                    }
                }
            })
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
            
            // Real Zoom SDK microphone toggle
            if (on) {
                // Unmute microphone
                Log.d("ZoomSDK", "Unmuting microphone")
                audioHelper?.unmuteAudio(object : ZoomVideoSDKCallback {
                    override fun onSuccess() {
                        Log.d("ZoomSDK", "Microphone unmuted successfully")
                        runOnUiThread {
                            result.success(null)
                        }
                    }
                    
                    override fun onError(error: ZoomVideoSDKErrors) {
                        Log.e("ZoomSDK", "Failed to unmute microphone: $error")
                        runOnUiThread {
                            result.error("MIC_TOGGLE_FAILED", "Failed to unmute: $error", null)
                        }
                    }
                })
            } else {
                // Mute microphone
                Log.d("ZoomSDK", "Muting microphone")
                audioHelper?.muteAudio(object : ZoomVideoSDKCallback {
                    override fun onSuccess() {
                        Log.d("ZoomSDK", "Microphone muted successfully")
                        runOnUiThread {
                            result.success(null)
                        }
                    }
                    
                    override fun onError(error: ZoomVideoSDKErrors) {
                        Log.e("ZoomSDK", "Failed to mute microphone: $error")
                        runOnUiThread {
                            result.error("MIC_TOGGLE_FAILED", "Failed to mute: $error", null)
                        }
                    }
                })
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
            
            // Real Zoom SDK camera toggle
            if (on) {
                // Start video
                Log.d("ZoomSDK", "Starting camera")
                videoHelper?.startVideo(object : ZoomVideoSDKCallback {
                    override fun onSuccess() {
                        Log.d("ZoomSDK", "Camera started successfully")
                        runOnUiThread {
                            result.success(null)
                        }
                    }
                    
                    override fun onError(error: ZoomVideoSDKErrors) {
                        Log.e("ZoomSDK", "Failed to start camera: $error")
                        runOnUiThread {
                            result.error("CAM_TOGGLE_FAILED", "Failed to start camera: $error", null)
                        }
                    }
                })
            } else {
                // Stop video
                Log.d("ZoomSDK", "Stopping camera")
                videoHelper?.stopVideo(object : ZoomVideoSDKCallback {
                    override fun onSuccess() {
                        Log.d("ZoomSDK", "Camera stopped successfully")
                        runOnUiThread {
                            result.success(null)
                        }
                    }
                    
                    override fun onError(error: ZoomVideoSDKErrors) {
                        Log.e("ZoomSDK", "Failed to stop camera: $error")
                        runOnUiThread {
                            result.error("CAM_TOGGLE_FAILED", "Failed to stop camera: $error", null)
                        }
                    }
                })
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

    override fun onDestroy() {
        super.onDestroy()
        // Clean up Zoom SDK
        if (isInSession) {
            currentSession?.leaveSession(null)
        }
        ZoomVideoSDK.getInstance().cleanUp()
    }
}

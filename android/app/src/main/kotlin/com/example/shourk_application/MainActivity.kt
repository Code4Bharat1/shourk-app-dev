package com.example.shourk_application

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.util.Log
import android.Manifest
import android.content.pm.PackageManager
import android.content.Intent
import android.content.Context
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat


class MainActivity: FlutterActivity() {
    private val CHANNEL = "zoom_channel"
    private var isInSession = false
    private val CAMERA_PERMISSION_REQUEST = 1001
    private val MICROPHONE_PERMISSION_REQUEST = 1002
    private var currentSession: Any? = null
    private var currentUser: Any? = null
    private var videoHelper: Any? = null
    private var audioHelper: Any? = null
    private var cameraService: CameraService? = null

    companion object {
        // Real Zoom Video SDK credentials from your .env file
        private const val ZOOM_SDK_KEY = "YIpt60fa5SeNP604nMooFeQxAJZSdr6bz0bR"
        private const val ZOOM_SDK_SECRET = "Fxdu9TYkCPBGMeh8Mqbp4FSrrlsBxsBzWVEP"
    }

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
                "checkCameraAvailable" -> {
                    runOnUiThread {
                        checkCameraAvailable(result)
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
            Log.d("ZoomSDK", "Joining real Zoom session: $sessionName")
            
            // Initialize Zoom SDK if not already done
            try {
                // Try to find Zoom SDK classes using reflection (REAL approach for AAR files)
                val zoomSDKClass = Class.forName("us.zoom.videosdk.ZoomVideoSDK")
                val getInstanceMethod = zoomSDKClass.getMethod("getInstance")
                val zoomSDKInstance = getInstanceMethod.invoke(null)
                
                // Initialize SDK if needed
                val isInitializedMethod = zoomSDKClass.getMethod("isInitialized")
                val isInitialized = isInitializedMethod.invoke(zoomSDKInstance) as Boolean
                
                if (!isInitialized) {
                    Log.d("ZoomSDK", "Initializing Zoom SDK...")
                    val initParamsClass = Class.forName("us.zoom.videosdk.ZoomVideoSDKInitParams")
                    val initParams = initParamsClass.newInstance()
                    
                    // Set SDK key and secret
                    initParamsClass.getMethod("setDomain", String::class.java).invoke(initParams, "zoom.us")
                    initParamsClass.getMethod("setEnableLog", Boolean::class.java).invoke(initParams, true)
                    
                    val initMethod = zoomSDKClass.getMethod("initialize", initParamsClass, Class.forName("us.zoom.videosdk.ZoomVideoSDKInitListener"))
                    initMethod.invoke(zoomSDKInstance, initParams, object : Any() {
                        fun onSDKInitializeResult(error: Any) {
                            if (error == null || (error is Int && error == 0)) {
                                Log.d("ZoomSDK", "SDK initialized successfully")
                                joinSessionAfterInit(zoomSDKInstance, token, sessionName, userName, userIdentity, role, result)
                            } else {
                                Log.e("ZoomSDK", "SDK initialization failed: $error")
                                result.error("INIT_FAILED", "Failed to initialize SDK: $error", null)
                            }
                        }
                    })
                } else {
                    joinSessionAfterInit(zoomSDKInstance, token, sessionName, userName, userIdentity, role, result)
                }
            } catch (e: ClassNotFoundException) {
                Log.e("ZoomSDK", "Zoom SDK classes not found: ${e.message}")
                result.error("SDK_NOT_AVAILABLE", "Zoom Video SDK is not properly integrated. Please contact support.", null)
            } catch (e: Exception) {
                Log.e("ZoomSDK", "Failed to initialize Zoom SDK: ${e.message}")
                result.error("INIT_FAILED", "Failed to initialize Zoom SDK: ${e.message}", null)
            }
            
        } catch (e: Exception) {
            result.error("JOIN_FAILED", "Failed to join session: ${e.message}", null)
        }
    }

    private fun joinSessionAfterInit(
        zoomSDKInstance: Any,
        token: String?,
        sessionName: String?,
        userName: String?,
        userIdentity: String?,
        role: Int,
        result: MethodChannel.Result
    ) {
        try {
            // Validate required parameters
            if (token == null || sessionName == null || userName == null) {
                Log.e("ZoomSDK", "Missing required arguments: token=$token, sessionName=$sessionName, userName=$userName")
                result.error("INVALID_ARGUMENTS", "Missing required arguments for session join", null)
                return
            }
            
            Log.d("ZoomSDK", "Joining session with: sessionName=$sessionName, userName=$userName, role=$role")
            
            try {
                // Create join params
                val joinParamsClass = Class.forName("us.zoom.videosdk.ZoomVideoSDKJoinParams")
                val joinParams = joinParamsClass.newInstance()
                
                joinParamsClass.getMethod("setSessionName", String::class.java).invoke(joinParams, sessionName)
                joinParamsClass.getMethod("setToken", String::class.java).invoke(joinParams, token)
                joinParamsClass.getMethod("setUserName", String::class.java).invoke(joinParams, userName)
                joinParamsClass.getMethod("setUserType", Int::class.java).invoke(joinParams, role)
                
                Log.d("ZoomSDK", "Join params created successfully")
                
                // Join session
                val joinSessionMethod = zoomSDKInstance::class.java.getMethod("joinSession", joinParamsClass, Class.forName("us.zoom.videosdk.ZoomVideoSDKJoinSessionListener"))
                
                currentSession = joinSessionMethod.invoke(zoomSDKInstance, joinParams, object : Any() {
                    fun onSessionJoin() {
                        Log.d("ZoomSDK", "Successfully joined session")
                        isInSession = true
                        
                        // Initialize video and audio helpers after successful join
                        try {
                            // Get the session object
                            val sessionClass = Class.forName("us.zoom.videosdk.ZoomVideoSDKSession")
                            val getSessionMethod = zoomSDKInstance::class.java.getMethod("getSession")
                            val session = getSessionMethod.invoke(zoomSDKInstance)
                            
                            // Get the local participant
                            val getLocalParticipantMethod = sessionClass.getMethod("getLocalParticipant")
                            currentUser = getLocalParticipantMethod.invoke(session)
                            
                            // Initialize video helper
                            val participantClass = Class.forName("us.zoom.videosdk.ZoomVideoSDKParticipant")
                            val getVideoHelperMethod = participantClass.getMethod("getVideoHelper")
                            videoHelper = getVideoHelperMethod.invoke(currentUser)
                            
                            // Initialize audio helper
                            val getAudioHelperMethod = participantClass.getMethod("getAudioHelper")
                            audioHelper = getAudioHelperMethod.invoke(currentUser)
                            
                            Log.d("ZoomSDK", "Video and audio helpers initialized successfully")
                        } catch (e: Exception) {
                            Log.e("ZoomSDK", "Failed to initialize helpers: ${e.message}")
                            // Continue anyway, helpers will be null but app won't crash
                        }
                        
                        runOnUiThread { result.success(null) }
                    }
                    
                    fun onSessionJoinFail(error: Any) {
                        Log.e("ZoomSDK", "Failed to join session: $error")
                        runOnUiThread { result.error("JOIN_FAILED", "Failed to join session: $error", null) }
                    }
                })
                
                Log.d("ZoomSDK", "Join session method invoked successfully")
                
            } catch (e: ClassNotFoundException) {
                Log.e("ZoomSDK", "Zoom SDK classes not found: ${e.message}")
                result.error("SDK_NOT_AVAILABLE", "Zoom Video SDK is not properly integrated. Please contact support.", null)
            } catch (e: Exception) {
                Log.e("ZoomSDK", "Failed to join session after init: ${e.message}")
                Log.e("ZoomSDK", "Exception stack trace: ${e.stackTrace}")
                
                // Provide more specific error messages based on the exception
                val errorMessage = when {
                    e.message?.contains("ClassNotFoundException") == true -> "Zoom SDK not properly initialized"
                    e.message?.contains("NoSuchMethodException") == true -> "Zoom SDK method not found"
                    e.message?.contains("IllegalArgumentException") == true -> "Invalid session parameters"
                    else -> "Failed to join session: ${e.message}"
                }
                
                result.error("JOIN_FAILED", errorMessage, null)
            }
            
        } catch (e: Exception) {
            Log.e("ZoomSDK", "Failed to join session after init: ${e.message}")
            result.error("JOIN_FAILED", "Failed to join session: ${e.message}", null)
        }
    }

    private fun leaveZoomSession(result: MethodChannel.Result) {
        try {
            Log.d("ZoomSDK", "Leaving real Zoom session")
            
            if (currentSession != null) {
                val leaveSessionMethod = currentSession!!::class.java.getMethod("leaveSession", Class.forName("us.zoom.videosdk.ZoomVideoSDKSessionLeaveListener"))
                leaveSessionMethod.invoke(currentSession, object : Any() {
                    fun onSessionLeave() {
                        Log.d("ZoomSDK", "Successfully left session")
                        currentSession = null
                        currentUser = null
                        videoHelper = null
                        audioHelper = null
                        isInSession = false
                        runOnUiThread { result.success(null) }
                    }
                    
                    fun onSessionLeaveFail(error: Any) {
                        Log.e("ZoomSDK", "Failed to leave session: $error")
                        runOnUiThread { result.error("LEAVE_FAILED", "Failed to leave session: $error", null) }
                    }
                })
            } else {
                isInSession = false
                result.success(null)
            }
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
            
            Log.d("ZoomSDK", "Toggling microphone: $on")
            
            // Try real Zoom SDK first
            try {
                if (audioHelper != null) {
                    if (on) {
                        // Unmute microphone
                        Log.d("ZoomSDK", "Unmuting microphone using Zoom SDK")
                        val unmuteMethod = audioHelper!!::class.java.getMethod("unmuteAudio", Class.forName("us.zoom.videosdk.ZoomVideoSDKCallback"))
                        unmuteMethod.invoke(audioHelper, object : Any() {
                            fun onSuccess() {
                                Log.d("ZoomSDK", "Microphone unmuted successfully")
                                runOnUiThread { result.success(null) }
                            }
                            
                            fun onError(error: Any) {
                                Log.e("ZoomSDK", "Failed to unmute microphone: $error")
                                runOnUiThread { result.error("MIC_TOGGLE_FAILED", "Failed to unmute: $error", null) }
                            }
                        })
                    } else {
                        // Mute microphone
                        Log.d("ZoomSDK", "Muting microphone using Zoom SDK")
                        val muteMethod = audioHelper!!::class.java.getMethod("muteAudio", Class.forName("us.zoom.videosdk.ZoomVideoSDKCallback"))
                        muteMethod.invoke(audioHelper, object : Any() {
                            fun onSuccess() {
                                Log.d("ZoomSDK", "Microphone muted successfully")
                                runOnUiThread { result.success(null) }
                            }
                            
                            fun onError(error: Any) {
                                Log.e("ZoomSDK", "Failed to mute microphone: $error")
                                runOnUiThread { result.error("MIC_TOGGLE_FAILED", "Failed to mute: $error", null) }
                            }
                        })
                    }
                } else {
                    // Audio helper not available - return error instead of fake simulation
                    Log.e("ZoomSDK", "Audio helper not available")
                    result.error("AUDIO_HELPER_NOT_AVAILABLE", "Audio functionality not available. Please rejoin the session.", null)
                }
            } catch (e: Exception) {
                Log.e("ZoomSDK", "Failed to toggle mic using Zoom SDK: ${e.message}")
                result.error("MIC_TOGGLE_FAILED", "Failed to toggle microphone: ${e.message}", null)
            }
        } catch (e: Exception) {
            Log.e("ZoomSDK", "Failed to toggle mic: ${e.message}")
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
            
            Log.d("ZoomSDK", "Toggling camera: $on")
            
            // Try real Zoom SDK first
            try {
                if (videoHelper != null) {
                    if (on) {
                        // Start video
                        Log.d("ZoomSDK", "Starting camera using Zoom SDK")
                        val startVideoMethod = videoHelper!!::class.java.getMethod("startVideo", Class.forName("us.zoom.videosdk.ZoomVideoSDKCallback"))
                        startVideoMethod.invoke(videoHelper, object : Any() {
                            fun onSuccess() {
                                Log.d("ZoomSDK", "Camera started successfully")
                                runOnUiThread { result.success(null) }
                            }
                            
                            fun onError(error: Any) {
                                Log.e("ZoomSDK", "Failed to start camera: $error")
                                runOnUiThread { result.error("CAM_TOGGLE_FAILED", "Failed to start camera: $error", null) }
                            }
                        })
                    } else {
                        // Stop video
                        Log.d("ZoomSDK", "Stopping camera using Zoom SDK")
                        val stopVideoMethod = videoHelper!!::class.java.getMethod("stopVideo", Class.forName("us.zoom.videosdk.ZoomVideoSDKCallback"))
                        stopVideoMethod.invoke(videoHelper, object : Any() {
                            fun onSuccess() {
                                Log.d("ZoomSDK", "Camera stopped successfully")
                                runOnUiThread { result.success(null) }
                            }
                            
                            fun onError(error: Any) {
                                Log.e("ZoomSDK", "Failed to stop camera: $error")
                                runOnUiThread { result.error("CAM_TOGGLE_FAILED", "Failed to stop camera: $error", null) }
                            }
                        })
                    }
                } else {
                    // Video helper not available - return error instead of fake camera
                    Log.e("ZoomSDK", "Video helper not available")
                    result.error("VIDEO_HELPER_NOT_AVAILABLE", "Camera functionality not available. Please rejoin the session.", null)
                }
            } catch (e: Exception) {
                Log.e("ZoomSDK", "Failed to toggle camera using Zoom SDK: ${e.message}")
                result.error("CAM_TOGGLE_FAILED", "Failed to toggle camera: ${e.message}", null)
            }
        } catch (e: Exception) {
            Log.e("ZoomSDK", "Failed to toggle camera: ${e.message}")
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
            try {
                currentSession?.let { session ->
                    val leaveSessionMethod = session::class.java.getMethod("leaveSession", Class.forName("us.zoom.videosdk.ZoomVideoSDKSessionLeaveListener"))
                    leaveSessionMethod.invoke(session, null)
                }
            } catch (e: Exception) {
                Log.e("ZoomSDK", "Failed to leave session on destroy: ${e.message}")
            }
        }
        try {
            // Try to cleanup Zoom SDK using reflection with better error handling
            try {
                val zoomSDKClass = Class.forName("us.zoom.videosdk.ZoomVideoSDK")
                val getInstanceMethod = zoomSDKClass.getMethod("getInstance")
                val zoomSDKInstance = getInstanceMethod.invoke(null)
                val cleanUpMethod = zoomSDKClass.getMethod("cleanUp")
                cleanUpMethod.invoke(zoomSDKInstance)
                Log.d("ZoomSDK", "Successfully cleaned up Zoom SDK")
            } catch (e: ClassNotFoundException) {
                Log.d("ZoomSDK", "Zoom SDK classes not found, skipping cleanup")
            } catch (e: Exception) {
                Log.e("ZoomSDK", "Failed to cleanup SDK: ${e.message}")
            }
        } catch (e: Exception) {
            Log.d("ZoomSDK", "Zoom SDK cleanup skipped: ${e.message}")
        }
    }
    
    private fun checkCameraAvailable(result: MethodChannel.Result) {
        try {
            Log.d("ZoomSDK", "Checking camera availability")
            
            // Check if camera permission is granted
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
                Log.e("ZoomSDK", "Camera permission not granted")
                result.error("PERMISSION_DENIED", "Camera permission not granted", null)
                return
            }
            
            // Check if camera is available on device
            val cameraManager = getSystemService(CAMERA_SERVICE) as android.hardware.camera2.CameraManager
            val cameraIdList = cameraManager.cameraIdList
            
            if (cameraIdList.isEmpty()) {
                Log.e("ZoomSDK", "No camera available on device")
                result.error("NO_CAMERA", "No camera available on device", null)
                return
            }
            
            Log.d("ZoomSDK", "Camera available: ${cameraIdList.size} cameras found")
            result.success(true)
            
        } catch (e: Exception) {
            Log.e("ZoomSDK", "Failed to check camera availability: ${e.message}")
            result.error("CAMERA_CHECK_FAILED", "Failed to check camera: ${e.message}", null)
        }
    }
}

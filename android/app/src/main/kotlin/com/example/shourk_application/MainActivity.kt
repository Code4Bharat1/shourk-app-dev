package com.example.shourk_application

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import us.zoom.sdk.*
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.shourk_application/zoom_sdk"

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

        // Zoom Video SDK Key and Secret
        val sdkKey = "YIpt60fa5SeNP604nMooFeQxAJZSdr6bz0bR"
        val sdkSecret = "Fxdu9TYkCPBGMeh8Mqbp4FSrrlsBxsBzWVEP"

        val initParams = ZoomVideoSDKInitParams().apply {
            domain = "zoom.us"
            appKey = sdkKey
            appSecret = sdkSecret
            enableLog = true
        }
        val initResult = ZoomVideoSDK.getInstance().initialize(this, initParams)
        if (initResult != ZoomVideoSDKError.ZOOM_VIDEO_SDK_ERROR_SUCCESS) {
            result.error("INIT_FAILED", "Zoom SDK init failed: $initResult", null)
            return
        }

        val sessionContext = ZoomVideoSDKSessionContext().apply {
            this.sessionName = sessionName
            this.userName = userName
            this.token = token
            this.sessionPassword = "" // If you use a password
            this.audioOption = ZoomVideoSDKAudioOption().apply { connect = true }
            this.videoOption = ZoomVideoSDKVideoOption().apply { localVideoOn = true }
        }

        val joinResult = ZoomVideoSDK.getInstance().joinSession(sessionContext)
        if (joinResult != ZoomVideoSDKError.ZOOM_VIDEO_SDK_ERROR_SUCCESS) {
            result.error("JOIN_FAILED", "Zoom SDK join failed: $joinResult", null)
            return
        }

        ZoomVideoSDK.getInstance().addListener(object : ZoomVideoSDKDelegate {
            override fun onSessionJoin() {
                Log.d("ZoomSDK", "Session joined")
            }
            override fun onSessionLeave(reason: ZoomVideoSDKError?) {
                Log.d("ZoomSDK", "Session left: $reason")
            }
            // Implement other delegate methods as needed
        })

        result.success(null)
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
        ZoomVideoSDK.getInstance().leaveSession(false)
        result.success(null)
    }
}

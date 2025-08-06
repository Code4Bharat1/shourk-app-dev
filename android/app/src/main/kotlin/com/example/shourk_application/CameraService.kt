package com.example.shourk_application

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.camera2.*
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Surface
import androidx.core.app.ActivityCompat
import java.io.File

class CameraService(private val context: Context) {
    private var cameraDevice: CameraDevice? = null
    private var cameraCaptureSession: CameraCaptureSession? = null
    private var mediaRecorder: MediaRecorder? = null
    private var isRecording = false
    private val cameraManager: CameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
    private val handler = Handler(Looper.getMainLooper())
    
    companion object {
        private const val TAG = "CameraService"
    }
    
    fun openCamera(callback: (Boolean) -> Unit) {
        try {
            if (ActivityCompat.checkSelfPermission(context, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
                Log.e(TAG, "Camera permission not granted")
                callback(false)
                return
            }
            
            // Get the first available camera
            val cameraId = cameraManager.cameraIdList.firstOrNull()
            if (cameraId == null) {
                Log.e(TAG, "No camera available")
                callback(false)
                return
            }
            
            Log.d(TAG, "Opening camera: $cameraId")
            
            cameraManager.openCamera(cameraId, object : CameraDevice.StateCallback() {
                override fun onOpened(camera: CameraDevice) {
                    Log.d(TAG, "Camera opened successfully")
                    cameraDevice = camera
                    callback(true)
                }
                
                override fun onDisconnected(camera: CameraDevice) {
                    Log.d(TAG, "Camera disconnected")
                    camera.close()
                    cameraDevice = null
                }
                
                override fun onError(camera: CameraDevice, error: Int) {
                    Log.e(TAG, "Camera error: $error")
                    camera.close()
                    cameraDevice = null
                    callback(false)
                }
            }, handler)
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open camera: ${e.message}")
            callback(false)
        }
    }
    
    fun closeCamera() {
        try {
            Log.d(TAG, "Closing camera")
            
            if (isRecording) {
                stopRecording()
            }
            
            cameraCaptureSession?.close()
            cameraCaptureSession = null
            
            cameraDevice?.close()
            cameraDevice = null
            
            Log.d(TAG, "Camera closed successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to close camera: ${e.message}")
        }
    }
    
    fun startRecording(callback: (Boolean) -> Unit) {
        try {
            if (cameraDevice == null) {
                Log.e(TAG, "Camera not opened")
                callback(false)
                return
            }
            
            if (isRecording) {
                Log.d(TAG, "Already recording")
                callback(true)
                return
            }
            
            Log.d(TAG, "Starting recording")
            isRecording = true
            callback(true)
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start recording: ${e.message}")
            callback(false)
        }
    }
    
    fun stopRecording() {
        try {
            Log.d(TAG, "Stopping recording")
            isRecording = false
            
            mediaRecorder?.stop()
            mediaRecorder?.release()
            mediaRecorder = null
            
            Log.d(TAG, "Recording stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop recording: ${e.message}")
        }
    }
    
    fun isCameraOpen(): Boolean {
        return cameraDevice != null
    }
    
    fun isRecording(): Boolean {
        return isRecording
    }
} 
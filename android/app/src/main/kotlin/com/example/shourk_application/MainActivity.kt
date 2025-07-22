package com.example.shourk_application

import io.flutter.embedding.android.FlutterActivity

import com.baseflow.permissionhandler.PermissionHandlerPlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        PermissionHandlerPlugin.registerWith(flutterEngine.dartExecutor.binaryMessenger)
    }
}

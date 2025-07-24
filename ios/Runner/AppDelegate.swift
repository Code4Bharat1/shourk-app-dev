import UIKit
import Flutter
import ZoomVideoSDK

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller = window?.rootViewController as! FlutterViewController
    let zoomChannel = FlutterMethodChannel(name: "zoom_channel", binaryMessenger: controller.binaryMessenger)

    zoomChannel.setMethodCallHandler { (call, result) in
      if call.method == "joinZoomSession" {
        guard
          let args = call.arguments as? [String: Any],
          let sessionName = args["sessionName"] as? String,
          let userName = args["userName"] as? String,
          let sessionToken = args["token"] as? String
        else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing args", details: nil))
          return
        }

        let initParams = ZoomVideoSDKInitParams()
        initParams.domain = "zoom.us"
        initParams.enableLog = true

        let context = ZoomVideoSDKSessionContext()
        context.token = sessionToken
        context.userName = userName
        context.sessionName = sessionName

        ZoomVideoSDK.shared().initialize(initParams)
        let joinResult = ZoomVideoSDK.shared().joinSession(context)

        print("Zoom Join Result: \(joinResult)")
        result(nil)
      }

      if call.method == "leaveZoomSession" {
        ZoomVideoSDK.shared().leaveSession(false)
        result(nil)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

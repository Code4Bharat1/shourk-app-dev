# Zoom Video SDK Setup Instructions

## ✅ What's Already Done:
- ✅ `mobilertc.aar` file is in place
- ✅ Build configuration updated in `build.gradle.kts`
- ✅ Method channel implementation in `MainActivity.kt`
- ✅ Folder structure created for `jniLibs`

## 🔧 Current Setup:
The AAR file should automatically extract the required `.so` files during the build process. The build configuration includes:

```kotlin
// In build.gradle.kts
implementation(files("libs/mobilertc.aar"))
packagingOptions {
    pickFirst("lib/*/libc++_shared.so")
    pickFirst("lib/*/libzoom_video_sdk.so")
    pickFirst("lib/*/libcrypto.so")
    pickFirst("lib/*/libssl.so")
    pickFirst("lib/*/libzlib.so")
    pickFirst("lib/*/libzoom_sdk_render.so")
}
```

## 🚀 Next Steps:

### 1. Test the Current Setup
```bash
flutter clean
flutter pub get
flutter run -d android
```

### 2. If You Get Build Errors:
The AAR file should automatically handle the native libraries. If you encounter issues:

#### Option A: Use Maven Dependency (Recommended)
Replace the AAR implementation with Maven in `build.gradle.kts`:
```kotlin
dependencies {
    // Remove: implementation(files("libs/mobilertc.aar"))
    // Add: implementation 'us.zoom.videosdk:zoomvideosdk-core:1.10.5'
}
```

#### Option B: Manual .so File Extraction
If the AAR doesn't work automatically:
1. Use a ZIP tool to extract `mobilertc.aar`
2. Look for the `jni/` folder inside
3. Copy `.so` files to `android/app/src/main/jniLibs/<abi>/`

### 3. iOS Setup:
- Add `ZoomVideoSDK.framework` to `ios/Frameworks/`
- Configure in Xcode: Embed & Sign

## 📁 Expected File Structure:
```
android/app/libs/mobilertc.aar
android/app/src/main/jniLibs/
├── arm64-v8a/
├── armeabi-v7a/
├── x86/
└── x86_64/
```

## 🔍 Troubleshooting:
- If you get "duplicate .so file" errors, the `packagingOptions` should handle it
- If you get "missing .so file" errors, try the Maven dependency approach
- Make sure you're testing on a real Android device or emulator (not web)

## ✅ Verification:
The setup is complete when:
1. App builds successfully on Android
2. Method channel calls work without `MissingPluginException`
3. Zoom SDK initialization succeeds 
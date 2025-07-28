plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.shourk_application"
    // compileSdk = flutter.compileSdkVersion
    // ndkVersion = flutter.ndkVersion
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.shourk_application"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // minSdk = flutter.minSdkVersion
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Enable native library support
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86", "x86_64")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    sourceSets {
        getByName("main") {
            jniLibs.srcDirs("libs", "src/main/jniLibs")
        }
    }

    packagingOptions {
        pickFirst("lib/*/libc++_shared.so")
        pickFirst("lib/*/libzoom_video_sdk.so")
        pickFirst("lib/*/libcrypto.so")
        pickFirst("lib/*/libssl.so")
        pickFirst("lib/*/libzlib.so")
        pickFirst("lib/*/libzoom_sdk_render.so")
    }
}

repositories {
    flatDir {
        dirs("libs")
    }
    google()
    mavenCentral()
}

dependencies {
    // Real Zoom Video SDK integration
    implementation(files("libs/mobilertc.aar"))
    implementation("androidx.appcompat:appcompat:1.2.0")
    implementation("androidx.core:core-ktx:1.7.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    implementation("com.google.android.material:material:1.5.0")
    // Additional dependencies for Zoom SDK
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("com.google.code.gson:gson:2.8.9")
    implementation("com.squareup.okhttp3:okhttp:4.9.1")
    implementation("com.squareup.retrofit2:retrofit:2.9.0")
    implementation("com.squareup.retrofit2:converter-gson:2.9.0")
    // Add any other required dependencies for Zoom SDK here
}

flutter {
    source = "../.."
}

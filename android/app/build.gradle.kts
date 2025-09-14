plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.http_request_generator"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.http_request_generator"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Konfiguracja nazw plików APK
    applicationVariants.all { variant ->
        variant.outputs.all { output ->
            val appName = "HTTP_Request_Generator"
            val versionName = variant.versionName
            val versionCode = variant.versionCode
            val buildType = variant.buildType.name
            val date = java.text.SimpleDateFormat("yyyyMMdd_HHmm").format(java.util.Date())
            
            // Konstrukcja nowej nazwy pliku APK
            val newApkName = "${appName}_${buildType}_v${versionName}_${date}.apk"
            
            // Ustawienie nowej nazwy pliku
            (output as com.android.build.gradle.internal.api.BaseVariantOutputImpl).outputFileName = newApkName
        }
    }
}

flutter {
    source = "../.."
}

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")      // <-- Kotlin plugin đúng cho Kotlin DSL
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Đặt namespace TƯƠNG ỨNG VỚI package MainActivity (không để đuôi .wikipedia_client)
    namespace = "edu.usth.group7.wikipedia"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // AGP mới khuyến nghị Java 17 (Flutter 3.22+ build bằng JDK 17)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // applicationId phải trùng “gốc” với namespace
        applicationId = "edu.usth.group7.wikipedia"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // Nếu cần shrinker: minifyEnabled = true; proguardFiles(...)
        }
    }
}

flutter {
    source = "../.."
}

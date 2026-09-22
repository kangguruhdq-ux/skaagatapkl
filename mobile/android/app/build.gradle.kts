plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "id.sch.smkn3jogja.skagata_pkl"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        manifestPlaceholders["MAPS_API_KEY"] = providers.environmentVariable("GOOGLE_MAPS_ANDROID_API_KEY").orNull
            ?: providers.gradleProperty("MAPS_API_KEY").orNull ?: ""
        applicationId = "id.sch.smkn3jogja.skagata_pkl"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

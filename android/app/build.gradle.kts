import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing comes from android/key.properties (git-ignored), written by
// scripts/create-keystore.ps1. The keystore itself lives in .secrets/.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val buildingRelease = gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }
if (buildingRelease && keystoreProperties.isEmpty) {
    throw GradleException(
        "android/key.properties is missing. Run scripts/create-keystore.ps1 first " +
            "(release builds are never signed with the debug key).",
    )
}

// Values passed with --dart-define-from-file=.env reach Gradle as the
// comma-separated, base64-encoded "dart-defines" property. Used only for the
// optional Firebase (push) configuration, so no google-services.json is needed.
val dartDefines: Map<String, String> =
    (project.findProperty("dart-defines") as String?)
        ?.split(",")
        ?.mapNotNull { entry ->
            runCatching { String(Base64.getDecoder().decode(entry), Charsets.UTF_8) }.getOrNull()
        }
        ?.mapNotNull { pair ->
            val parts = pair.split("=", limit = 2)
            if (parts.size == 2) parts[0] to parts[1] else null
        }
        ?.toMap()
        ?: emptyMap()

android {
    namespace = "app.bvm.messenger"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications.
        isCoreLibraryDesugaringEnabled = true
    }

    buildFeatures {
        resValues = true
    }

    defaultConfig {
        // Change before the first Google Play upload if you want another id;
        // it can never change afterwards.
        applicationId = "app.bvm.messenger"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        val firebaseAppId = dartDefines["FIREBASE_APP_ID"].orEmpty()
        if (firebaseAppId.isNotEmpty()) {
            resValue("string", "google_app_id", firebaseAppId)
            resValue("string", "google_api_key", dartDefines["FIREBASE_API_KEY"].orEmpty())
            resValue("string", "gcm_defaultSenderId", dartDefines["FIREBASE_MESSAGING_SENDER_ID"].orEmpty())
            resValue("string", "project_id", dartDefines["FIREBASE_PROJECT_ID"].orEmpty())
        }
    }

    signingConfigs {
        create("release") {
            if (!keystoreProperties.isEmpty) {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

import java.util.Properties

plugins {
    id("com.android.application")
    // `flutterfire configure` inserts the Google Services plugin directly below
    // the line above (and registers its version in settings.gradle.kts), so
    // keep that line exactly as is.
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---------------------------------------------------------------------------
// Release signing
//
// Resolution order:
//   1. Codemagic: `android_signing: [upload_keystore]` in codemagic.yaml
//      exports CM_KEYSTORE_PATH / CM_KEYSTORE_PASSWORD / CM_KEY_ALIAS /
//      CM_KEY_PASSWORD.
//   2. Local: android/key.properties (gitignored, written by
//      scripts/create_upload_keystore.sh) with keys storeFile, storePassword,
//      keyAlias, keyPassword. A relative storeFile is resolved against
//      android/app/ (Flutter convention); absolute paths also work.
//   3. Otherwise the debug key is used so `flutter run --release` still works.
//      Such a build is NOT uploadable to Google Play.
// ---------------------------------------------------------------------------
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties =
    Properties().apply {
        if (keyPropertiesFile.isFile) {
            keyPropertiesFile.inputStream().use { load(it) }
        }
    }
val ciKeystorePath: String? = System.getenv("CM_KEYSTORE_PATH")?.takeIf { it.isNotBlank() }
val hasReleaseSigning = ciKeystorePath != null || keyPropertiesFile.isFile

android {
    namespace = "com.mfbservicesinc.mfb_think_tank"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.mfbservicesinc.mfb_think_tank"
        // firebase_auth needs API 23+, google_sign_in_android needs API 24+.
        // Never go below 24, but follow Flutter if its default is ever higher.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        // Both come from pubspec.yaml `version:` unless overridden with
        // --build-name / --build-number (Codemagic sets the build number).
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                if (ciKeystorePath != null) {
                    storeFile = file(ciKeystorePath)
                    storePassword = System.getenv("CM_KEYSTORE_PASSWORD")
                    keyAlias = System.getenv("CM_KEY_ALIAS")
                    keyPassword = System.getenv("CM_KEY_PASSWORD")
                } else {
                    storeFile = file(keyProperties.getProperty("storeFile"))
                    storePassword = keyProperties.getProperty("storePassword")
                    keyAlias = keyProperties.getProperty("keyAlias")
                    keyPassword = keyProperties.getProperty("keyPassword")
                }
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (hasReleaseSigning) "release" else "debug")
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

import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    val stream = keystorePropertiesFile.inputStream()
    keystoreProperties.load(stream)
    stream.close()
}

android {
    namespace = "com.freeway.ticketvalidator" //Must be changed before migrating to another release.
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.freeway.ticketvalidator"  //Must be changed before migrating to another release.
        minSdk = flutter.minSdkVersion
        targetSdk = 36

        val localProperties = Properties()
        val localPropertiesFile = rootProject.file("local.properties")
        if (localPropertiesFile.exists()) {
            val stream = localPropertiesFile.inputStream()
            localProperties.load(stream)
            stream.close()
        }
        val flutterVersionCode = localProperties.getProperty("flutter.versionCode")?.toInt() ?: 1
        val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

        versionCode = flutterVersionCode
        versionName = flutterVersionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storePassword = keystoreProperties.getProperty("storePassword")
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            if (storeFilePath != null) {
                storeFile = rootProject.file(storeFilePath)
            }
        }
    }

    buildTypes {
        getByName("release") {
            val alias = keystoreProperties.getProperty("keyAlias")
            signingConfig = if (alias != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}

tasks.withType<KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

project.setProperty("archivesBaseName", "Ticket Validator")

flutter {
    source = "../.."
}

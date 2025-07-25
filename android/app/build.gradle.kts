import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Função para ler as propriedades locais de forma segura
fun localProperties(): Properties {
    val properties = Properties()
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { stream ->
            properties.load(stream)
        }
    }
    return properties
}

val flutterVersionCode: Int by lazy {
    localProperties().getProperty("flutter.versionCode")?.toInt() ?: 1
}

val flutterVersionName: String by lazy {
    localProperties().getProperty("flutter.versionName") ?: "1.0"
}

android {
    namespace = "com.example.prado_negocios"
    // ✅ CORRIGIDO: Atualizado de 34 para 35, conforme o erro pedia
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.prado_negocios"
        minSdk = 23
        // ✅ CORRIGIDO: É boa prática manter o targetSdk igual ao compileSdk
        targetSdk = 35
        versionCode = flutterVersionCode
        versionName = flutterVersionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")
    implementation("com.google.firebase:firebase-messaging")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
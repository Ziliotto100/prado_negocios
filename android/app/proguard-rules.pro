# =========================================================================
# == SECTION 1: ESSENTIAL DEBUGGING AND GLOBAL ATTRIBUTES
# =========================================================================
# These rules are CRITICAL for debugging. They preserve metadata needed to
# de-obfuscate stack traces from release builds. Without these, crash
# reports in Firebase Crashlytics or Google Play Console are useless.
# [9, 30]
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses,EnclosingMethod

# =========================================================================
# == SECTION 2: FLUTTER ENGINE AND CORE PLUGINS
# =========================================================================
# These are the standard, non-negotiable rules for any Flutter app.
# They prevent R8 from removing the native code that the Flutter engine
# uses to bootstrap and communicate with the Dart VM.
# [1, 19, 31]
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Required for the Flutter engine on newer Android versions.
# [1]
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# =========================================================================
# == SECTION 3: FIREBASE SDKs (COMPREHENSIVE)
# =========================================================================
# Firebase relies heavily on reflection. These rules are more specific than a
# single -keep command to allow for better shrinking.

# General Firebase and Google Play Services rules.
# [1, 20, 21]
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.perf.v1.FirebasePerfMetric$Builder
-keepnames class com.google.android.gms.internal.firebase_auth.*
-keepnames class com.google.firebase.auth.*
-keepnames class com.google.firebase.firestore.*
-keepnames class com.google.firebase.storage.*
-keepnames class com.google.firebase.messaging.*

# CRITICAL: Keep your data model classes (POJOs/data classes).
# R8 will obfuscate the field names in your data classes, which will
# cause Firestore/Realtime Database to fail when serializing/deserializing.
# You MUST replace 'com.example.myapp.models.**' with the actual package
# name of your data models. [8, 20, 21]
-keepclassmembers class com.example.myapp.models.** {
  <fields>;
  <init>(...);
}

# CRITICAL: Keep rules for Protobuf Lite, a core dependency of Firestore.
# Failure to include these is a very common cause of release crashes.
# [22, 23, 24]
-dontwarn com.google.protobuf.**
-keepclassmembers class * extends com.google.protobuf.GeneratedMessageLite {
    <fields>;
}

# =========================================================================
# == SECTION 4: COMMON THIRD-PARTY FLUTTER PLUGINS
# =========================================================================

# --- cached_network_image ---
# This plugin has native dependencies on Glide (for image loading) and
# sqflite (for caching). Both need their own rules.

# Official Glide rules [26, 27]
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep public class * extends com.bumptech.glide.module.AppGlideModule
-keep public enum com.bumptech.glide.load.ImageHeaderParser$** {
  ** $VALUES;
  public *;
}

# sqflite / sqlcipher rules [29]
# This is a known issue where R8 breaks sqflite if not preserved.
-keep class net.sqlcipher.** { *; }

# --- url_launcher ---
# This is a defensive rule. The main configuration for modern Android
# is in AndroidManifest.xml via <queries> tags. [25]
-keep class io.flutter.plugins.urllauncher.** { *; }

# =========================================================================
# == SECTION 5: COMMON NATIVE ANDROID LIBRARIES (TRANSITIVE DEPENDENCIES)
# =========================================================================
# Many Flutter plugins use these libraries under the hood.

# OkHttp (used by many networking libraries)
# [9, 32, 33]
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase
-dontwarn okhttp3.**
-dontwarn okio.**

# gRPC (used by Firestore)
# [34, 35]
-dontwarn io.grpc.**
-dontwarn com.google.common.**
-dontwarn javax.naming.**
-dontwarn sun.misc.Unsafe

# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
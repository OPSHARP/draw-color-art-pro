# Flutter Wrapper Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# WorkManager & Room Database Rules (Prevents startup reflection crash)
-keep class * extends androidx.room.RoomDatabase {
    public <init>();
    *;
}
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class androidx.work.impl.WorkDatabase_Impl {
    public <init>();
    *;
}
-keepclassmembers class * extends androidx.room.RoomDatabase {
    public void <init>();
    public static ** create*(...);
}
-dontwarn androidx.work.**
-dontwarn androidx.room.**

# Google Mobile Ads / AdMob
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Audio & Camera Plugins
-keep class xyz.luan.audioplayers.** { *; }
-keep class io.flutter.plugins.camerax.** { *; }

# JNI & FFI (Used by path_provider_android)
-keep class com.github.dart_lang.jni.** { *; }
-dontwarn com.github.dart_lang.jni.**

# Play Core (Deferred components not used)
-dontwarn com.google.android.play.core.**

# Flutter's engine is reached through JNI, so keep its entry points.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

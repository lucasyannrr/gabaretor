-dontwarn com.google.android.play.core.**
-keep class com.hugocornellier.flutter_litert.** { *; }
-keep class org.tensorflow.** { *; }
-keep class com.google.ai.edge.** { *; }
-keep class androidx.camera.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

-dontwarn org.tensorflow.**
-dontwarn com.google.ai.edge.**
-dontwarn androidx.camera.**

# Keep all ML Kit Text Recognition classes
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.**

# Optional: Keep these only if you plan to support them
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-dontwarn com.google.mlkit.vision.text.chinese.**

-keep class com.google.mlkit.vision.text.japanese.** { *; }
-dontwarn com.google.mlkit.vision.text.japanese.**

-keep class com.google.mlkit.vision.text.korean.** { *; }
-dontwarn com.google.mlkit.vision.text.korean.**

-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-dontwarn com.google.mlkit.vision.text.devanagari.**

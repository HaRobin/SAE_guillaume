# Keep TensorFlow Lite GPU classes
-keep class org.tensorflow.** { *; }

# Keep TensorFlow Lite annotations
-keep @org.tensorflow.lite.** class * { *; }

# Keep TensorFlow Lite methods and classes referenced in native code
-keepclassmembers class ** {
    native <methods>;
}

-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options
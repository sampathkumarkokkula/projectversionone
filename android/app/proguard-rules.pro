# Release builds keep no logs: calls to android.util.Log are removed by R8.
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
    public static int e(...);
    public static int wtf(...);
    public static int println(...);
}

# flutter_local_notifications serialises notification details with Gson.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# WorkManager instantiates workers reflectively.
-keep class * extends androidx.work.ListenableWorker { <init>(...); }

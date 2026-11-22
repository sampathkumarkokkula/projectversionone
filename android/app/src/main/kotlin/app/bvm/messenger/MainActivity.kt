package app.bvm.messenger

import android.content.pm.ApplicationInfo
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Blocks screenshots, screen recording and casting of the app window,
        // and keeps the app-switcher (recents) thumbnail blank. Debuggable
        // builds (`flutter run`, never distributed) skip it so store
        // screenshots can be taken; release APKs and AABs always set it.
        val debuggable = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (!debuggable) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE,
            )
        }
        super.onCreate(savedInstanceState)
        if (!debuggable && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Android 13+: never take a recents screenshot at all.
            setRecentsScreenshotEnabled(false)
        }
    }
}

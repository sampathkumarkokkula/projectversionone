import 'package:flutter/foundation.dart';

/// Debug-only diagnostics.
///
/// Compiles to a no-op in release builds. Callers must never pass message
/// text, keys, passwords, user ids or ciphertext; log event names only.
void logDebug(String event) {
  if (kDebugMode) {
    debugPrint('[bvm] $event');
  }
}

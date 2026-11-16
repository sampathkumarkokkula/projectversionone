/// Build-time configuration, injected with `--dart-define-from-file=.env`
/// (see `.env.example` and `scripts/build-apk.ps1`). Nothing is hard-coded in
/// source.
///
/// None of these values grants privileged access: the Supabase publishable
/// key is designed to ship inside client apps (Row Level Security protects
/// the data), and the Firebase values only identify the app to FCM.
abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Firebase app settings (from google-services.json via
  /// scripts/firebase-env.ps1). Passed to Firebase directly at start-up, so
  /// push does not depend on Gradle-generated Android resources.
  static const String firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String firebaseSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

  static bool get isConfigured {
    final uri = Uri.tryParse(supabaseUrl);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        supabasePublishableKey.isNotEmpty;
  }

  static bool get pushConfigured => firebaseAppId.isNotEmpty;

  /// Names of Firebase values missing from the build (empty when complete).
  static List<String> get missingFirebaseValues => [
        if (firebaseAppId.isEmpty) 'FIREBASE_APP_ID',
        if (firebaseApiKey.isEmpty) 'FIREBASE_API_KEY',
        if (firebaseSenderId.isEmpty) 'FIREBASE_MESSAGING_SENDER_ID',
        if (firebaseProjectId.isEmpty) 'FIREBASE_PROJECT_ID',
      ];
}

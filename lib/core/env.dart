/// Build-time configuration, injected with `--dart-define-from-file=.env`
/// (see `.env.example` and `scripts/build-apk.ps1`). Nothing is hard-coded in
/// source.
///
/// None of these values grants privileged access: the Supabase publishable
/// key is designed to ship inside client apps (Row Level Security protects
/// the data), and the Firebase app id only identifies the app to FCM.
abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Set when a Firebase project is configured. The native Firebase options
  /// are compiled into Android resources by Gradle from the same `.env` file.
  static const String firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');

  static bool get isConfigured {
    final uri = Uri.tryParse(supabaseUrl);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        supabasePublishableKey.isNotEmpty;
  }

  static bool get pushConfigured => firebaseAppId.isNotEmpty;
}

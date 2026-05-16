import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads Firebase options that were entered by the user in SetupScreen
/// and persisted in SharedPreferences.
class DynamicFirebaseOptions {
  static Future<FirebaseOptions> get currentPlatform async {
    final prefs = await SharedPreferences.getInstance();
    return FirebaseOptions(
      apiKey:           prefs.getString('firebase_api_key')        ?? '',
      appId:            prefs.getString('firebase_app_id')         ?? '',
      messagingSenderId: prefs.getString('firebase_sender_id')     ?? '',
      projectId:        prefs.getString('firebase_project_id')     ?? '',
      storageBucket:    prefs.getString('firebase_storage_bucket') ?? '',
      databaseURL:      prefs.getString('firebase_database_url'),
    );
  }

  static Future<bool> isConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('firebase_api_key') ?? '').isNotEmpty;
  }
}

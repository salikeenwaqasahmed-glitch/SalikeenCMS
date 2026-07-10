import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'core/config/app_config.dart';
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_prod.dart' as prod;

/// Picks Firebase options for the active [AppConfig] environment.
class FirebaseOptionsForEnv {
  FirebaseOptionsForEnv._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return AppConfig.isProd
          ? prod.DefaultFirebaseOptions.web
          : dev.DefaultFirebaseOptions.web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AppConfig.isProd
            ? prod.DefaultFirebaseOptions.android
            : dev.DefaultFirebaseOptions.android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase options for $defaultTargetPlatform are not configured. '
          'Use Android dev/prod flavors.',
        );
      default:
        throw UnsupportedError(
          'Firebase options are not supported for this platform.',
        );
    }
  }

  /// Android auto-inits from `google-services.json`; skip duplicate init.
  static Future<void> ensureInitialized() async {
    if (Firebase.apps.isNotEmpty) return;
    try {
      await Firebase.initializeApp(options: currentPlatform);
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app' && Firebase.apps.isEmpty) rethrow;
    }
  }
}

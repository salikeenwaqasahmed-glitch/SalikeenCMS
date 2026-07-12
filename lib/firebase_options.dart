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
    throw UnsupportedError(
      'Use native Firebase config on mobile (google-services.json). '
      'Call FirebaseOptionsForEnv.ensureInitialized() instead.',
    );
  }

  /// Android reads flavor `google-services.json`; web uses Dart options.
  static Future<void> ensureInitialized() async {
    if (Firebase.apps.isNotEmpty) return;
    try {
      if (kIsWeb) {
        await Firebase.initializeApp(options: currentPlatform);
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        await Firebase.initializeApp();
      } else {
        throw UnsupportedError(
          'Firebase is only configured for Android flavors and web.',
        );
      }
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app' && Firebase.apps.isEmpty) rethrow;
    }
  }
}

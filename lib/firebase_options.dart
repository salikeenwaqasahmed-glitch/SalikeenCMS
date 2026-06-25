import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Generated from android/app/google-services.json (project: salikeencms).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDwRf2LoxVtzrHDjCTm1aTJcLIH5fQgS28',
    appId: '1:475949341237:android:6036ce344860dea8262f7c',
    messagingSenderId: '475949341237',
    projectId: 'salikeencms',
    authDomain: 'salikeencms.firebaseapp.com',
    storageBucket: 'salikeencms.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDwRf2LoxVtzrHDjCTm1aTJcLIH5fQgS28',
    appId: '1:475949341237:android:6036ce344860dea8262f7c',
    messagingSenderId: '475949341237',
    projectId: 'salikeencms',
    storageBucket: 'salikeencms.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDwRf2LoxVtzrHDjCTm1aTJcLIH5fQgS28',
    appId: '1:475949341237:android:6036ce344860dea8262f7c',
    messagingSenderId: '475949341237',
    projectId: 'salikeencms',
    storageBucket: 'salikeencms.firebasestorage.app',
    iosBundleId: 'com.example.salikManagementSystem',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDwRf2LoxVtzrHDjCTm1aTJcLIH5fQgS28',
    appId: '1:475949341237:android:6036ce344860dea8262f7c',
    messagingSenderId: '475949341237',
    projectId: 'salikeencms',
    storageBucket: 'salikeencms.firebasestorage.app',
    iosBundleId: 'com.example.salikManagementSystem',
  );
}

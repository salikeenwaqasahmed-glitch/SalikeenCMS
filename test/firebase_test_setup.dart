import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

typedef FirebaseAppPlatformFactory = FirebaseAppPlatform Function();

class _MockFirebaseApp extends FirebaseAppPlatform {
  _MockFirebaseApp()
      : super(
          defaultFirebaseAppName,
          const FirebaseOptions(
            apiKey: 'test',
            appId: '1:123:android:test',
            messagingSenderId: '123',
            projectId: 'test',
          ),
        );

  @override
  Future<void> delete() async {}
}

void setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FirebasePlatform.instance = _MockFirebasePlatform();
}

class _MockFirebasePlatform extends FirebasePlatform {
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return _MockFirebaseApp();
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return _MockFirebaseApp();
  }

  @override
  List<FirebaseAppPlatform> get apps => [_MockFirebaseApp()];
}

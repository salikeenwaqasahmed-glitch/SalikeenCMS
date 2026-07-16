import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salik_management_system/core/network/connectivity_service.dart';

void main() {
  group('ConnectivityService', () {
    test('treats a DNS failure as offline even when connectivity shows Wi-Fi', () async {
      final service = ConnectivityService(
        null,
        connectivityCheck: (_) async => [ConnectivityResult.wifi],
        lookupHost: (_) async => throw const SocketException('dns failed'),
      );

      expect(await service.isOnline, isFalse);
    });

    test('treats a successful DNS lookup as online', () async {
      final service = ConnectivityService(
        null,
        connectivityCheck: (_) async => [ConnectivityResult.wifi],
        lookupHost: (_) async => [InternetAddress('8.8.8.8')],
      );

      expect(await service.isOnline, isTrue);
    });
  });
}

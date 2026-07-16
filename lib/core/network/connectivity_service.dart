import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(Connectivity());
});

final connectivityStatusProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onlineStream;
});

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityStatusProvider).valueOrNull ?? true;
});

class ConnectivityService {
  ConnectivityService(
    this._connectivity, {
    Future<List<ConnectivityResult>> Function(Connectivity?)? connectivityCheck,
    Future<List<InternetAddress>> Function(String host)? lookupHost,
    Duration lookupTimeout = const Duration(seconds: 4),
  })  : _connectivityCheck = connectivityCheck ?? ((c) => c == null ? Future.value(const []) : c.checkConnectivity()),
        _lookupHost = lookupHost ?? InternetAddress.lookup,
        _lookupTimeout = lookupTimeout;

  final Connectivity? _connectivity;
  final Future<List<ConnectivityResult>> Function(Connectivity?) _connectivityCheck;
  final Future<List<InternetAddress>> Function(String host) _lookupHost;
  final Duration _lookupTimeout;

  Stream<bool> get onlineStream async* {
    yield await isOnline;
    if (_connectivity == null) {
      yield await isOnline;
      return;
    }
    yield* _connectivity.onConnectivityChanged.asyncMap((_) => isOnline);
  }

  Future<bool> get isOnline async {
    final connectivity = _connectivity;
    final results = await _connectivityCheck(connectivity);
    if (!_hasConnection(results)) return false;

    try {
      await _lookupHost('firestore.googleapis.com').timeout(_lookupTimeout);
      return true;
    } on TimeoutException {
      return false;
    } on SocketException catch (_) {
      return false;
    } on OSError catch (_) {
      return false;
    }
  }

  /// Wi‑Fi/mobile link up — not guaranteed internet, but good enough to try sync.
  Future<bool> get shouldAttemptSync => isOnline;

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn,
    );
  }
}

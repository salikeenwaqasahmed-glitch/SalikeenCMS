import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../../features/auth/domain/user_session.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Signs out when the user is idle longer than [AppConfig.sessionIdleTimeout].
class SessionIdleTimeout extends ConsumerStatefulWidget {
  const SessionIdleTimeout({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<SessionIdleTimeout> createState() => _SessionIdleTimeoutState();
}

class _SessionIdleTimeoutState extends ConsumerState<SessionIdleTimeout>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _lastActivity = DateTime.now();
  bool _expiring = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncTimer());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncTimer();
    }
  }

  void _recordActivity() {
    if (ref.read(currentSessionProvider) == null) return;
    final now = DateTime.now();
    if (now.difference(_lastActivity) < const Duration(seconds: 1)) return;
    _lastActivity = now;
    _syncTimer();
  }

  void _syncTimer() {
    _timer?.cancel();
    final session = ref.read(currentSessionProvider);
    if (session == null) return;

    final repo = ref.read(authRepositoryProvider);
    if (repo.isSessionPinned) {
      _timer = Timer(const Duration(seconds: 30), _syncTimer);
      return;
    }

    final elapsed = DateTime.now().difference(_lastActivity);
    if (elapsed >= AppConfig.sessionIdleTimeout) {
      unawaited(_expireSession());
      return;
    }

    _timer = Timer(AppConfig.sessionIdleTimeout - elapsed, _expireSession);
  }

  Future<void> _expireSession() async {
    if (!mounted || _expiring) return;
    if (ref.read(currentSessionProvider) == null) return;

    _expiring = true;
    try {
      await ref.read(authControllerProvider.notifier).signOut();
    } finally {
      _expiring = false;
      if (mounted) {
        _lastActivity = DateTime.now();
        _syncTimer();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UserSession?>(currentSessionProvider, (prev, next) {
      if (next == null) {
        _timer?.cancel();
        return;
      }
      if (prev == null) {
        _lastActivity = DateTime.now();
      }
      _syncTimer();
    });

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _recordActivity(),
      onPointerMove: (_) => _recordActivity(),
      onPointerSignal: (_) => _recordActivity(),
      child: widget.child,
    );
  }
}

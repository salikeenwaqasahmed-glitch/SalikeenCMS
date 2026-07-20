import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_localizations.dart';
import '../network/connectivity_service.dart';
import '../../features/saliks/presentation/providers/area_provider.dart';
import 'sync_service.dart';

/// Pull-to-refresh: full sync when online, cached-data message when offline.
Future<void> pullToRefreshSync(
  WidgetRef ref, {
  BuildContext? context,
}) async {
  final online = await ref.read(connectivityServiceProvider).isOnline;
  if (!online) {
    if (context != null && context.mounted) {
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('offline_cached_data'))),
      );
    }
    return;
  }

  await ref.read(syncServiceProvider).syncNow();
  ref.invalidate(areasProvider);
}

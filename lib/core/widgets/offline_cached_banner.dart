import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/app_localizations.dart';
import '../network/connectivity_service.dart';
import '../theme/app_spacing.dart';
import 'app_text.dart';

class OfflineCachedBanner extends ConsumerWidget {
  const OfflineCachedBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider);
    if (online) return const SizedBox.shrink();

    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Material(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(Icons.cloud_off, size: 18, color: Colors.orange.shade800),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AppText(
                  l10n.t('offline_cached_data'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_spacing.dart';

/// Small env label — dev or production — shown on splash, login, settings.
class EnvBadge extends StatelessWidget {
  const EnvBadge({super.key, this.compact = false, this.showProject = false});

  final bool compact;
  final bool showProject;

  @override
  Widget build(BuildContext context) {
    if (AppConfig.isProd) {
      return const SizedBox.shrink();
    }

    final label = compact || !showProject
        ? AppConfig.envDisplayName
        : '${AppConfig.envDisplayName} · ${AppConfig.firebaseProjectId}';

    final background = AppConfig.isProd
        ? const Color(0xFF1B5E20)
        : Colors.orange.shade700;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? 4 : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Top-centered env chip for splash / full-screen loaders.
class EnvBadgeTop extends StatelessWidget {
  const EnvBadgeTop({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: AppSpacing.sm),
          child: EnvBadge(compact: true),
        ),
      ),
    );
  }
}

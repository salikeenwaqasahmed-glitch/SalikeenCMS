import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_logo.dart';

enum AppLoaderSize { small, medium, large }

class _LoaderMetrics {
  const _LoaderMetrics({
    required this.total,
    required this.logo,
    required this.stroke,
  });

  final double total;
  final double logo;
  final double stroke;
}

/// App icon with animated ring — use for all loading states.
class AppLoader extends StatelessWidget {
  const AppLoader({
    super.key,
    this.size = AppLoaderSize.medium,
    this.color,
    this.message,
  });

  final AppLoaderSize size;
  final Color? color;
  final String? message;

  static _LoaderMetrics _metricsFor(AppLoaderSize size) {
    return switch (size) {
      AppLoaderSize.small => const _LoaderMetrics(
          total: 24,
          logo: 14,
          stroke: 2,
        ),
      AppLoaderSize.medium => const _LoaderMetrics(
          total: 56,
          logo: 34,
          stroke: 3,
        ),
      AppLoaderSize.large => const _LoaderMetrics(
          total: 88,
          logo: 52,
          stroke: 3.5,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _metricsFor(size);
    final ringColor = color ?? Theme.of(context).colorScheme.primary;

    final loader = SizedBox(
      width: metrics.total,
      height: metrics.total,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: metrics.total,
            height: metrics.total,
            child: CircularProgressIndicator(
              strokeWidth: metrics.stroke,
              color: ringColor,
            ),
          ),
          AppLogo(size: metrics.logo),
        ],
      ),
    );

    if (message == null || message!.isEmpty) {
      return loader;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        loader,
        const SizedBox(height: AppSpacing.md),
        Text(
          message!,
          textAlign: TextAlign.center,
          style: AppTextStyles.forLocale(
            Localizations.localeOf(context).languageCode == 'ur',
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Button that shows [AppLoader] while [loading].
class AppActionButton extends StatelessWidget {
  const AppActionButton({
    required this.onPressed,
    required this.loading,
    required this.child,
    this.outlined = false,
    this.loaderColor,
    super.key,
  });

  final VoidCallback? onPressed;
  final bool loading;
  final Widget child;
  final bool outlined;
  final Color? loaderColor;

  @override
  Widget build(BuildContext context) {
    final content = loading
        ? AppLoader(
            size: AppLoaderSize.small,
            color: loaderColor ??
                (outlined
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white),
          )
        : child;

    if (outlined) {
      return OutlinedButton(
        onPressed: loading ? null : onPressed,
        child: content,
      );
    }
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: content,
    );
  }
}

/// Full-area loading placeholder (lists, screens, bootstrap).
class AppLoadingPage extends StatelessWidget {
  const AppLoadingPage({super.key, this.message, this.color});

  final String? message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppLoader(
        size: AppLoaderSize.large,
        color: color,
        message: message,
      ),
    );
  }
}

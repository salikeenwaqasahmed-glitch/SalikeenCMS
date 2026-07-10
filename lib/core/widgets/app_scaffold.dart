import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'app_text.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.body,
    super.key,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = false,
    this.bottom,
    this.onBack,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onBack;

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/saliks');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText(title, maxLines: 1),
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _handleBack(context),
              )
            : null,
        actions: actions,
        bottom: bottom,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

class BrandedBackground extends StatelessWidget {
  const BrandedBackground({
    required this.child,
    this.safeArea = true,
    super.key,
  });

  final Widget child;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final content = safeArea ? SafeArea(child: child) : child;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
        ),
      ),
      child: content,
    );
  }
}

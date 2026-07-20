import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/auth/session_idle_timeout.dart';
import 'core/auth/local_auth_store.dart';
import 'core/auth/local_user_seed.dart';
import 'core/config/app_config.dart';
import 'core/data/local_data_seed.dart';
import 'core/database/app_database.dart';
import 'core/localization/app_localizations.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/sync/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_loader.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseOptionsForEnv.ensureInitialized();

  final bootstrapContainer = ProviderContainer();
  final authStore = bootstrapContainer.read(localAuthStoreProvider);
  final database = bootstrapContainer.read(appDatabaseProvider);
  await LocalUserSeed.ensureUsers(authStore);
  await LocalDataSeed.ensureReferenceData(database);
  debugPrint('Local seed done: users + reference data ready for offline use');
  debugPrint(
    'App env: ${AppConfig.env} firebase=${AppConfig.firebaseProjectId} '
    'staffDomain=${AppConfig.staffEmailDomain}',
  );

  runApp(
    UncontrolledProviderScope(
      container: bootstrapContainer,
      child: const SalikManagementApp(),
    ),
  );
}

class SalikManagementApp extends ConsumerWidget {
  const SalikManagementApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncBootstrapProvider);

    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    const locale = Locale('en');
    final l10n = AppLocalizations(locale);

    return MaterialApp.router(
      title: l10n.t('title'),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => SessionIdleTimeout(
        child: LoginSyncErrorListener(
          child: AuthLoadingGate(child: child),
        ),
      ),
      routerConfig: router,
    );
  }
}

/// Shows SnackBar when post-login Firestore sync fails.
class LoginSyncErrorListener extends ConsumerWidget {
  const LoginSyncErrorListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(loginSyncErrorProvider, (prev, next) {
      if (next == null || next.isEmpty || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(next)),
      );
      ref.read(loginSyncErrorProvider.notifier).state = null;
    });

    ref.listen<String?>(seedMessageProvider, (prev, next) {
      if (next == null || !context.mounted) return;
      final l10n = AppLocalizations(const Locale('en'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t(next))),
      );
      ref.read(seedMessageProvider.notifier).state = null;
    });

    return child;
  }
}

/// Full-screen loader only while sign-in request is in flight.
class AuthLoadingGate extends ConsumerWidget {
  const AuthLoadingGate({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showGate = ref.watch(authControllerProvider).isLoading;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          if (child != null) child!,
          if (showGate)
            const ColoredBox(
              color: AppTheme.primaryColor,
              child: AppLoadingPage(color: Colors.white),
            ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/auth/local_auth_store.dart';
import 'core/auth/local_user_seed.dart';
import 'core/data/local_data_seed.dart';
import 'core/database/app_database.dart';
import 'core/localization/app_localizations.dart';
import 'core/network/connectivity_service.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/sync/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_loader.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/domain/user_session.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  final bootstrapContainer = ProviderContainer();
  final authStore = bootstrapContainer.read(localAuthStoreProvider);
  final database = bootstrapContainer.read(appDatabaseProvider);
  await LocalUserSeed.ensureUsers(authStore);
    await LocalDataSeed.ensureReferenceData(database);
  debugPrint('Local seed done: users + reference data ready for offline use');

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
    ref.watch(appDatabaseHydrationProvider);

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
      builder: (context, child) {
        final signingIn = ref.watch(authControllerProvider).isLoading;
        final auth = ref.watch(authStateProvider);
        final bootstrapping = auth.isLoading;
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              if (child != null) child,
              if (bootstrapping || signingIn)
                const ColoredBox(
                  color: AppTheme.primaryColor,
                  child: AppLoadingPage(color: Colors.white),
                ),
            ],
          ),
        );
      },
      routerConfig: router,
    );
  }
}

final appDatabaseHydrationProvider = Provider<void>((ref) {
  Future<void> syncWhenOnline({UserSession? session}) async {
    if (!await ref.read(connectivityServiceProvider).isOnline) return;

    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.promoteOfflineSessionIfOnline();

    final active = session ?? ref.read(authStateProvider).valueOrNull;
    if (active == null) return;

    final sync = ref.read(syncServiceProvider);
    await sync.hydrate(active);
    await sync.repairSyncQueue();
    await sync.syncNow(sessionOverride: active);
  }

  ref.listen(authStateProvider, (prev, next) {
    final session = next.valueOrNull;
    if (session == null) return;
    if (prev?.valueOrNull?.uid == session.uid) return;
    unawaited(syncWhenOnline(session: session));
  });

  ref.listen(connectivityStatusProvider, (prev, next) {
    final online = next.valueOrNull ?? false;
    final wasOnline = prev?.valueOrNull ?? false;
    if (online && !wasOnline) {
      unawaited(syncWhenOnline());
    }
  });

  unawaited(syncWhenOnline());
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/saliks/presentation/screens/add_salik_form_screen.dart';
import '../../features/saliks/presentation/screens/bazam_areas_screen.dart';
import '../../features/saliks/presentation/screens/duplicate_saliks_screen.dart';
import '../../features/saliks/presentation/screens/pending_approvals_screen.dart';
import '../../features/saliks/presentation/screens/salik_directory_screen.dart';
import '../../features/saliks/presentation/screens/salik_message_queue_screen.dart';
import '../../features/saliks/presentation/screens/salik_profile_screen.dart';
import '../../features/saliks/presentation/providers/salik_provider.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../localization/app_localizations.dart';
import '../utils/access_control.dart';
import '../utils/firebase_errors.dart';
import '../widgets/offline_banner.dart';
import '../widgets/salik_widgets.dart';

/// Safe before [GoRouter] has matched its first route (avoids `No element`).
String routerMatchedLocation(GoRouter router, {String fallback = '/login'}) {
  final config = router.routerDelegate.currentConfiguration;
  if (config.isEmpty) return fallback;
  final path = config.uri.path;
  return path.isEmpty ? fallback : path;
}

final routerRefreshNotifierProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier(0);
  ref.listen(authStateProvider, (prev, next) {
    if (prev?.isLoading == true && next.isLoading == false) {
      notifier.value++;
      return;
    }

    final prevSession = prev?.valueOrNull;
    final nextSession = next.valueOrNull;
    if (prevSession == null && nextSession == null) return;
    if (prevSession != null &&
        nextSession != null &&
        prevSession.uid == nextSession.uid &&
        prevSession.email == nextSession.email) {
      return;
    }
    notifier.value++;
  });
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// Nudge GoRouter redirect after sign-in before [authStateProvider] stream catches up.
void notifyRouterAuthChanged(Ref ref) {
  ref.read(routerRefreshNotifierProvider).value++;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final onLogin = state.matchedLocation == '/login';

      if (authState.isLoading) {
        return onLogin ? null : '/login';
      }

      final isLoggedIn = authState.valueOrNull != null;

      if (!isLoggedIn && !onLogin) return '/login';
      if (isLoggedIn && onLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return NavigationShellScaffold(
            navigationShell: navigationShell,
            location: state.uri.path,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'bazams/:bazamId',
                    builder: (context, state) {
                      final id = state.pathParameters['bazamId'] ?? '';
                      return BazamAreasScreen(bazamId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/saliks',
                builder: (context, state) => const SalikDirectoryScreen(),
                routes: [
                  GoRoute(
                    path: 'profile/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return SalikProfileScreen(salikId: id);
                    },
                  ),
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const AddSalikFormScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return AddSalikFormScreen(salikId: id);
                    },
                  ),
                  GoRoute(
                    path: 'duplicates',
                    builder: (context, state) =>
                        const DuplicateSaliksScreen(),
                  ),
                  GoRoute(
                    path: 'pending',
                    builder: (context, state) =>
                        const PendingApprovalsScreen(),
                  ),
                  GoRoute(
                    path: 'message-queue',
                    builder: (context, state) {
                      final args = state.extra;
                      if (args is! SalikMessageQueueArgs ||
                          args.saliks.isEmpty) {
                        return const SalikDirectoryScreen();
                      }
                      return SalikMessageQueueScreen(args: args);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class NavigationShellScaffold extends ConsumerWidget {
  const NavigationShellScaffold({
    required this.navigationShell,
    required this.location,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final String location;

  static const _syncDestinationIndex = 3;

  bool get _hideBottomNav =>
      location.contains('/saliks/profile/') ||
      location.contains('/saliks/add') ||
      location.contains('/saliks/edit/') ||
      location.contains('/saliks/pending') ||
      location.contains('/saliks/duplicates') ||
      location.contains('/saliks/message-queue') ||
      location.contains('/bazams/');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(currentSessionProvider);
    final canViewPending =
        session != null && AccessControl.canViewPending(session.role);
    final pendingCount =
        canViewPending ? ref.watch(pendingCountProvider) : 0;
    final syncState = ref.watch(syncNowControllerProvider);

    ref.listen(syncNowControllerProvider, (prev, next) {
      if (prev?.isLoading == true && next.hasValue) {
        final result = next.value ?? const SyncNowResult(ok: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_navSyncSnackMessage(l10n, result))),
        );
      }
    });

    Widget saliksNavIcon(IconData icon) {
      if (!canViewPending || pendingCount == 0) {
        return Icon(icon);
      }
      return PendingSaliksBadge(
        count: pendingCount,
        child: Icon(icon),
      );
    }

    Widget syncNavIcon({required bool selected}) {
      if (syncState.isLoading) {
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }
      return Icon(selected ? Icons.sync : Icons.sync_outlined);
    }

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: _hideBottomNav
          ? null
          : NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) {
                if (index == _syncDestinationIndex) {
                  if (!syncState.isLoading) {
                    ref.read(syncNowControllerProvider.notifier).syncNow();
                  }
                  return;
                }
                navigationShell.goBranch(index, initialLocation: true);
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon: const Icon(Icons.dashboard),
                  label: l10n.t('nav_dashboard'),
                ),
                NavigationDestination(
                  icon: saliksNavIcon(Icons.people_outline),
                  selectedIcon: saliksNavIcon(Icons.people),
                  label: l10n.t('nav_saliks'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: l10n.t('nav_settings'),
                ),
                NavigationDestination(
                  icon: syncNavIcon(selected: false),
                  selectedIcon: syncNavIcon(selected: true),
                  label: l10n.t('nav_sync'),
                ),
              ],
            ),
    );
  }
}

String _navSyncSnackMessage(AppLocalizations l10n, SyncNowResult result) {
  if (result.ok) {
    return l10n.t('sync_success');
  }
  final err = result.error;
  if (err != null) {
    if (err.contains('permission-denied')) {
      return '${l10n.t('error_permission_denied')} ${l10n.t('sync_permission_hint')}';
    }
    return mapFirebaseError(err, l10n);
  }
  return l10n.t('sync_failed');
}

bool isSubRoute(String location) =>
    location.contains('/saliks/profile/') ||
    location.contains('/saliks/add') ||
    location.contains('/saliks/edit/') ||
    location.contains('/saliks/pending') ||
    location.contains('/saliks/duplicates') ||
    location.contains('/saliks/message-queue');

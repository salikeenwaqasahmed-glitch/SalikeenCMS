import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/saliks/presentation/screens/add_salik_form_screen.dart';
import '../../features/saliks/presentation/screens/duplicate_saliks_screen.dart';
import '../../features/saliks/presentation/screens/pending_approvals_screen.dart';
import '../../features/saliks/presentation/screens/salik_directory_screen.dart';
import '../../features/saliks/presentation/screens/salik_profile_screen.dart';
import '../../features/saliks/presentation/providers/salik_provider.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../localization/app_localizations.dart';
import '../utils/access_control.dart';
import '../widgets/offline_banner.dart';
import '../widgets/salik_widgets.dart';

final _routerRefreshProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier(0);
  ref.listen(authStateProvider, (prev, next) {
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

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_routerRefreshProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      if (authState.isLoading) return null;

      final isLoggedIn = authState.valueOrNull != null;
      final loggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !loggingIn) return '/login';
      if (isLoggedIn && loggingIn) return '/';
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

  bool get _hideBottomNav =>
      location.contains('/saliks/profile/') ||
      location.contains('/saliks/add') ||
      location.contains('/saliks/edit/') ||
      location.contains('/saliks/pending') ||
      location.contains('/saliks/duplicates');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(currentSessionProvider);
    final canViewPending =
        session != null && AccessControl.canViewPending(session.role);
    final pendingCount =
        canViewPending ? ref.watch(pendingCountProvider) : 0;

    Widget saliksNavIcon(IconData icon) {
      if (!canViewPending || pendingCount == 0) {
        return Icon(icon);
      }
      return PendingSaliksBadge(
        count: pendingCount,
        child: Icon(icon),
      );
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
              onDestinationSelected: (index) =>
                  navigationShell.goBranch(index, initialLocation: true),
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
              ],
            ),
    );
  }
}

bool isSubRoute(String location) =>
    location.contains('/saliks/profile/') ||
    location.contains('/saliks/add') ||
    location.contains('/saliks/edit/') ||
    location.contains('/saliks/pending') ||
    location.contains('/saliks/duplicates');

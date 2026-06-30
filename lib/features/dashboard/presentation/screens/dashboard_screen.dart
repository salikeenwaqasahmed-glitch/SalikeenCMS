import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/form_navigation.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/access_control.dart';
import '../../../../core/utils/firebase_errors.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../../core/widgets/salik_widgets.dart';
import '../../../../core/widgets/user_scope_banner.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../saliks/presentation/providers/area_provider.dart';
import '../../../saliks/presentation/providers/salik_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/stat_count_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(currentSessionProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final cityCounts = ref.watch(dashboardCityCountsProvider);
    final saliksAsync = ref.watch(saliksStreamProvider);
    final canCreate =
        session != null && AccessControl.canCreate(session.role);
    final canViewPending =
        session != null && AccessControl.canViewPending(session.role);
    final pendingCount =
        canViewPending ? ref.watch(pendingCountProvider) : 0;

    return AppScaffold(
      title: l10n.t('dashboard'),
      actions: canCreate
          ? [
              IconButton(
                icon: const Icon(Icons.person_add),
                tooltip: l10n.t('add_salik'),
                onPressed: () =>
                    context.go(addSalikRoute(from: FormReturnRoute.dashboard)),
              ),
            ]
          : null,
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () =>
                  context.go(addSalikRoute(from: FormReturnRoute.dashboard)),
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(saliksStreamProvider);
          ref.invalidate(citiesProvider);
        },
        child: saliksAsync.when(
          loading: () => const AppLoadingPage(),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.5,
                child: Center(child: Text(mapFirebaseError(e, l10n))),
              ),
            ],
          ),
          data: (_) => ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (session != null) ...[
                Text(
                  '${l10n.t('welcome')}, ${session.name}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                UserScopeBanner(session: session),
              ],
              const SizedBox(height: AppSpacing.lg),
              SectionTitle(l10n.t('stats_overview')),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  StatCountCard(
                    label: l10n.t('stat_total'),
                    count: stats.total,
                    icon: Icons.people,
                  ),
                  if (session == null ||
                      AccessControl.canViewAllGenders(session.role)) ...[
                    const SizedBox(width: AppSpacing.sm),
                    StatCountCard(
                      label: l10n.t('stat_male'),
                      count: stats.maleCount,
                      icon: Icons.man,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StatCountCard(
                      label: l10n.t('stat_female'),
                      count: stats.femaleCount,
                      icon: Icons.woman,
                    ),
                  ] else ...[
                    const SizedBox(width: AppSpacing.sm),
                    StatCountCard(
                      label: session.gender == 'Female'
                          ? l10n.t('stat_female')
                          : l10n.t('stat_male'),
                      count: stats.total,
                      icon: session.gender == 'Female'
                          ? Icons.woman
                          : Icons.man,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  StatCountCard(
                    label: l10n.t('nafi_asbat'),
                    count: stats.nafiAsbatCount,
                    icon: Icons.volunteer_activism,
                    onTap: () => _openSaliksFiltered(
                      ref,
                      context,
                      segment: SalikBrowseSegment.nafiAsbat,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  StatCountCard(
                    label: l10n.t('sahib_e_mehfil'),
                    count: stats.sahibMehfilCount,
                    icon: Icons.star,
                    onTap: () => _openSaliksFiltered(
                      ref,
                      context,
                      segment: SalikBrowseSegment.sahibMehfil,
                    ),
                  ),
                ],
              ),
              if (cityCounts.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                SectionTitle(l10n.t('stats_by_city')),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 132,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: cityCounts.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final city = cityCounts[index];
                      final label = city.cityName.trim();
                      return StatCountCard(
                        expanded: false,
                        width: 132,
                        labelMaxLines: 3,
                        labelFontSize: 12,
                        label: label,
                        count: city.count,
                        icon: Icons.location_city,
                        colorIndex: index,
                        onTap: () => _openSaliksFiltered(
                          ref,
                          context,
                          segment: SalikBrowseSegment.area,
                          cityId: city.cityId,
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SectionTitle(l10n.t('quick_actions')),
              const SizedBox(height: AppSpacing.sm),
              if (canViewPending)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/saliks/pending'),
                    icon: PendingSaliksBadge(
                      count: pendingCount,
                      child: const Icon(Icons.pending_actions),
                    ),
                    label: Text(
                      AccessControl.isEditor(session.role)
                          ? l10n.t('my_submissions')
                          : l10n.t('pending_approvals'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/saliks'),
                      icon: const Icon(Icons.people),
                      label: Text(l10n.t('saliks')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  void _openSaliksFiltered(
    WidgetRef ref,
    BuildContext context, {
    required SalikBrowseSegment segment,
    String cityId = 'all',
  }) {
    final notifier = ref.read(salikFilterProvider.notifier);
    notifier.setSegment(segment);
    if (cityId != 'all') {
      notifier.setCity(cityId);
    }
    context.go('/saliks');
  }
}

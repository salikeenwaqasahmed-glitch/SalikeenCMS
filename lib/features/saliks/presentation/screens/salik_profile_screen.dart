import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/data/reference_data.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/form_navigation.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/access_control.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../../core/utils/firebase_errors.dart';
import '../../../../core/utils/submitter_display.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/whatsapp_icon.dart';
import '../../../../core/widgets/salik_widgets.dart';
import '../../../auth/domain/user_session.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/salik_repository.dart';
import '../../domain/entities/salik.dart';
import '../providers/area_provider.dart';
import '../providers/salik_provider.dart';

class SalikProfileScreen extends ConsumerStatefulWidget {
  const SalikProfileScreen({required this.salikId, super.key});

  final String salikId;

  @override
  ConsumerState<SalikProfileScreen> createState() => _SalikProfileScreenState();
}

class _SalikProfileScreenState extends ConsumerState<SalikProfileScreen> {
  bool _approving = false;
  bool _rejecting = false;
  bool _deleting = false;
  bool _togglingActive = false;

  bool get _busy => _approving || _rejecting || _deleting || _togglingActive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(currentSessionProvider);
    final salikAsync = ref.watch(salikByIdProvider(widget.salikId));
    final cities = ref.watch(citiesProvider).valueOrNull ?? [];

    return PopScope(
      canPop: !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _busy) return;
        context.go('/saliks');
      },
      child: AppScaffold(
        title: l10n.t('profile'),
        showBackButton: true,
        onBack: _busy ? () {} : () => context.go('/saliks'),
        actions: [
          salikAsync.whenOrNull(
            data: (salik) {
              if (salik == null || session == null || _busy) return null;
              if (!AccessControl.canUpdate(session.role)) return null;
              return IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.go(
                  editSalikRoute(widget.salikId, from: FormReturnRoute.profile),
                ),
              );
            },
          ) ??
              const SizedBox.shrink(),
        ],
        body: salikAsync.when(
          loading: () => const AppLoadingPage(),
          error: (e, _) => ErrorState(
            message: mapFirebaseError(e, l10n),
            onRetry: () => ref.invalidate(salikByIdProvider(widget.salikId)),
          ),
          data: (salik) {
            if (salik == null) {
              return EmptyState(message: l10n.t('not_found'));
            }

            final city =
                ref.watch(cityByIdProvider(salik.cityId)).valueOrNull ??
                    findCityInList(salik.cityId, cities);
            final area = ref.watch(areaByIdProvider(salik.areaId)).valueOrNull ??
                findAreaInList(
                  salik.areaId,
                  ref.watch(areasByCityProvider(salik.cityId)).valueOrNull ?? [],
                );
            final samePhone =
                phonesMatch(salik.mobileNumber, salik.whatsappNumber);

            Widget? headerBadge;
            if (salik.isPending) {
              headerBadge = Chip(
                label: Text(l10n.t('approval_pending')),
                backgroundColor: Colors.orange.shade50,
              );
            } else if (salik.isRejected) {
              headerBadge = Chip(
                label: Text(l10n.t('approval_rejected')),
                backgroundColor: Colors.grey.shade200,
              );
            } else if (!salik.isActive) {
              headerBadge = Chip(
                label: Text(l10n.t('inactive')),
                backgroundColor: Colors.red.shade50,
              );
            } else if (salik.isSahibEMehfil) {
              headerBadge = Chip(
                label: Text(l10n.t('sahib_e_mehfil')),
                backgroundColor: Colors.amber.shade50,
              );
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ProfileHeader(
                          name: salik.name,
                          fatherName: salik.fatherName,
                          badge: headerBadge,
                        ),
                        _AddedByLine(salik: salik),
                        if (salik.approvedByName.isNotEmpty &&
                            salik.isApproved) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(
                              l10n
                                  .t('approved_by')
                                  .replaceAll('{name}', salik.approvedByName),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        InfoGroupCard(
                          title: l10n.t('step_personal'),
                          children: [
                            InfoRow(
                              icon: Icons.calendar_today,
                              label: l10n.t('date_of_baith'),
                              value: salik.dateOfBaith,
                              colorIndex: 0,
                            ),
                            InfoRow(
                              icon: Icons.wc,
                              label: l10n.t('gender'),
                              value: salik.genderId == 'Male'
                                  ? l10n.t('male')
                                  : l10n.t('female'),
                              colorIndex: 1,
                            ),
                            if (salik.referenceName.trim().isNotEmpty)
                              InfoRow(
                                icon: Icons.person_outline,
                                label: l10n.t('reference'),
                                value: salik.referenceName,
                                colorIndex: 2,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        InfoGroupCard(
                          title: l10n.t('contact_info'),
                          children: [
                            InfoRow(
                              icon: Icons.phone,
                              label: l10n.t('mobile'),
                              value: salik.mobileNumber,
                              colorIndex: 0,
                              onTap: () =>
                                  ContactLauncher.call(salik.mobileNumber),
                            ),
                            InfoRow(
                              leading: const WhatsAppMessageIcon(size: 20),
                              label: l10n.t('whatsapp'),
                              value: samePhone
                                  ? l10n.t('whatsapp_same_hint')
                                  : salik.whatsappNumber,
                              colorIndex: 1,
                              onTap: () => ContactLauncher.whatsappMessage(
                                samePhone
                                    ? salik.mobileNumber
                                    : salik.whatsappNumber,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        InfoGroupCard(
                          title: l10n.t('location_info'),
                          children: [
                            InfoRow(
                              icon: Icons.location_city,
                              label: l10n.t('city'),
                              value: city?.cityName ?? '',
                              colorIndex: 0,
                            ),
                            InfoRow(
                              icon: Icons.map,
                              label: l10n.t('area'),
                              value: area?.areaName ?? '',
                              colorIndex: 1,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        InfoGroupCard(
                          title: l10n.t('spiritual_info'),
                          children: [
                            InfoRow(
                              icon: Icons.volunteer_activism,
                              label: l10n.t('nafi_asbat'),
                              value:
                                  salik.isNafiAsbat ? l10n.t('yes') : l10n.t('no'),
                              colorIndex: 0,
                            ),
                            InfoRow(
                              icon: Icons.star,
                              label: l10n.t('sahib_e_mehfil'),
                              value: salik.isSahibEMehfil
                                  ? l10n.t('yes')
                                  : l10n.t('no'),
                              colorIndex: 1,
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(l10n.t('active')),
                              secondary: _togglingActive
                                  ? const AppLoader(size: AppLoaderSize.small)
                                  : null,
                              value: salik.isActive,
                              onChanged: session != null &&
                                      AccessControl.canUpdate(session.role) &&
                                      salik.isApproved &&
                                      !_busy
                                  ? (value) => _toggleActive(
                                        session,
                                        salik.salikId,
                                        value,
                                        l10n,
                                      )
                                  : null,
                            ),
                          ],
                        ),
                        if (session != null &&
                            AccessControl.canDelete(session.role) &&
                            salik.isApproved) ...[
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton.icon(
                            onPressed: _busy ? null : () => _deleteSalik(session, l10n),
                            icon: _deleting
                                ? const AppLoader(size: AppLoaderSize.small)
                                : const Icon(Icons.delete, color: Colors.red),
                            label: Text(
                              l10n.t('delete_confirm'),
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (session != null &&
                    salik.isPending &&
                    AccessControl.canApprove(session.role))
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppActionButton(
                              outlined: true,
                              loading: _rejecting,
                              onPressed: _busy
                                  ? null
                                  : () => _rejectSalik(session, l10n),
                              child: Text(
                                l10n.t('reject'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: AppActionButton(
                              loading: _approving,
                              onPressed: _busy
                                  ? null
                                  : () => _approveSalik(session, l10n),
                              child: Text(
                                l10n.t('approve'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (salik.isApproved)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: SalikContactActions(
                        mobileNumber: salik.mobileNumber,
                        whatsappNumber: salik.whatsappNumber,
                        iconSize: 22,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _approveSalik(UserSession session, AppLocalizations l10n) async {
    setState(() => _approving = true);
    try {
      await ref.read(salikRepositoryProvider).approveSalik(
            widget.salikId,
            session: session,
          );
      ref.invalidate(salikByIdProvider(widget.salikId));
      ref.invalidate(saliksStreamProvider);
      ref.invalidate(pendingSaliksStreamProvider);
      ref.invalidate(pendingCountProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.t('approve_success'))),
        );
        context.go('/saliks');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _approving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapFirebaseError(e, l10n))),
        );
      }
    }
  }

  Future<void> _rejectSalik(UserSession session, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('reject_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('reject')),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _rejecting = true);
    try {
      await ref.read(salikRepositoryProvider).rejectSalik(
            widget.salikId,
            session: session,
          );
      ref.invalidate(salikByIdProvider(widget.salikId));
      ref.invalidate(pendingSaliksStreamProvider);
      ref.invalidate(pendingCountProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.t('reject_success'))),
        );
        context.go('/saliks/pending');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _rejecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapFirebaseError(e, l10n))),
        );
      }
    }
  }

  Future<void> _deleteSalik(UserSession session, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('submit')),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref
          .read(salikRepositoryProvider)
          .deleteSalik(widget.salikId, session: session);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.t('delete_success'))),
        );
        context.go('/saliks');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapFirebaseError(e, l10n))),
        );
      }
    }
  }

  Future<void> _toggleActive(
    UserSession session,
    String salikId,
    bool value,
    AppLocalizations l10n,
  ) async {
    setState(() => _togglingActive = true);
    try {
      await ref.read(salikRepositoryProvider).toggleActive(
            salikId,
            value,
            session: session,
          );
      ref.invalidate(salikByIdProvider(widget.salikId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapFirebaseError(e, l10n))),
        );
      }
    } finally {
      if (mounted) setState(() => _togglingActive = false);
    }
  }
}

class _AddedByLine extends ConsumerWidget {
  const _AddedByLine({required this.salik});

  final Salik salik;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(currentSessionProvider);
    if (session != null &&
        AccessControl.isEditor(session.role) &&
        SalikRepository.editorOwnsSalik(salik, session)) {
      return const SizedBox.shrink();
    }

    final addedByAsync = ref.watch(salikAddedByNameProvider(salik));

    return addedByAsync.when(
      data: (name) {
        final display = resolveSubmitterLineName(name);
        if (display == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            l10n.t('added_by').replaceAll('{name}', display),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(top: AppSpacing.sm),
        child: Center(child: AppLoader(size: AppLoaderSize.small)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/user_session.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/access_control.dart';
import '../../data/salik_repository.dart';
import '../../domain/entities/salik.dart';
import '../../domain/entities/salik_duplicate_group.dart';
import 'area_provider.dart';

/// Extra client-side gender guard for genderAdmin / editor (admin = all genders).
List<Salik> scopeSaliksToSession(List<Salik> saliks, UserSession? session) {
  final gender = AccessControl.genderFilter(session);
  if (gender == null) return saliks;
  return saliks.where((s) => s.genderId == gender).toList();
}

enum SalikBrowseSegment { all, area, nafiAsbat, sahibMehfil }

final duplicateSaliksStreamProvider =
    StreamProvider<List<SalikDuplicateGroup>>((ref) {
  final session = ref.watch(currentSessionProvider);
  final repo = ref.watch(salikRepositoryProvider);
  if (session == null || !AccessControl.canResolveDuplicates(session.role)) {
    return Stream.value([]);
  }
  return repo.watchDuplicateGroups(session);
});

final duplicateSalikCountProvider = Provider<int>((ref) {
  final groups = ref.watch(duplicateSaliksStreamProvider).valueOrNull ?? [];
  return groups.length;
});

final saliksStreamProvider = StreamProvider<List<Salik>>((ref) {
  final session = ref.watch(currentSessionProvider);
  final repo = ref.watch(salikRepositoryProvider);
  final Stream<List<Salik>> source;
  if (session != null && AccessControl.isEditor(session.role)) {
    source = repo.watchEditorDirectorySaliks(session);
  } else {
    source = repo.watchGenderScopedSaliks(session);
  }
  return source.map((saliks) => scopeSaliksToSession(saliks, session));
});

final pendingSaliksStreamProvider = StreamProvider<List<Salik>>((ref) {
  final session = ref.watch(currentSessionProvider);
  final repo = ref.watch(salikRepositoryProvider);
  return repo
      .watchPendingSaliks(session)
      .map((saliks) => scopeSaliksToSession(saliks, session));
});

final pendingCountProvider = Provider<int>((ref) {
  final pending = ref.watch(pendingSaliksStreamProvider).valueOrNull ?? [];
  return pending.where((s) => s.isPending).length;
});

final salikByIdProvider =
    FutureProvider.family<Salik?, String>((ref, id) async {
  ref.watch(saliksStreamProvider);
  ref.watch(pendingSaliksStreamProvider);
  final repo = ref.read(salikRepositoryProvider);

  for (final list in [
    ref.read(saliksStreamProvider).valueOrNull,
    ref.read(pendingSaliksStreamProvider).valueOrNull,
  ]) {
    if (list == null) continue;
    for (final salik in list) {
      if (salik.salikId == id) {
        final resolved = await repo.resolveSalik(id);
        return preferSalikLocationFields(salik, resolved);
      }
    }
  }

  return await repo.resolveSalik(id);
});

final salikAddedByNameProvider =
    FutureProvider.family<String, Salik>((ref, salik) async {
  return ref.read(authRepositoryProvider).resolveUserDisplayName(
        salik.addedByUid,
        fallback: salik.addedByName,
      );
});

class SalikFilter {
  const SalikFilter({
    this.search = '',
    this.areaId = 'all',
    this.genderId = 'all',
    this.status = 'all',
    this.segment = SalikBrowseSegment.all,
  });

  final String search;
  final String areaId;
  final String genderId;
  final String status;
  final SalikBrowseSegment segment;

  SalikFilter copyWith({
    String? search,
    String? areaId,
    String? genderId,
    String? status,
    SalikBrowseSegment? segment,
  }) {
    return SalikFilter(
      search: search ?? this.search,
      areaId: areaId ?? this.areaId,
      genderId: genderId ?? this.genderId,
      status: status ?? this.status,
      segment: segment ?? this.segment,
    );
  }
}

final salikFilterProvider =
    StateNotifierProvider<SalikFilterNotifier, SalikFilter>((ref) {
  return SalikFilterNotifier();
});

class SalikFilterNotifier extends StateNotifier<SalikFilter> {
  SalikFilterNotifier() : super(const SalikFilter());

  void setSearch(String value) => state = state.copyWith(search: value);

  void setArea(String areaId) => state = state.copyWith(areaId: areaId);

  void setGender(String genderId) => state = state.copyWith(genderId: genderId);

  void setStatus(String status) => state = state.copyWith(status: status);

  void setSegment(SalikBrowseSegment segment) {
    state = state.copyWith(
      segment: segment,
      areaId: segment == SalikBrowseSegment.area ? state.areaId : 'all',
    );
  }

  void reset() => state = const SalikFilter();
}

List<Salik> applySalikFilters(List<Salik> saliks, SalikFilter filter) {
  return saliks.where((s) {
    final q = filter.search.trim().toLowerCase();
    final matchesSearch = q.isEmpty ||
        s.name.toLowerCase().contains(q) ||
        s.fatherName.toLowerCase().contains(q) ||
        s.mobileNumber.contains(filter.search) ||
        s.referenceName.toLowerCase().contains(q) ||
        s.address.toLowerCase().contains(q);

    final matchesArea = filter.areaId == 'all' || s.areaId == filter.areaId;
    final matchesGender =
        filter.genderId == 'all' || s.genderId == filter.genderId;

    var matchesStatus = true;
    if (filter.status == 'active') matchesStatus = s.isActive;
    if (filter.status == 'inactive') matchesStatus = !s.isActive;

    final matchesSegment = switch (filter.segment) {
      SalikBrowseSegment.all => true,
      SalikBrowseSegment.area => true,
      SalikBrowseSegment.nafiAsbat => s.isNafiAsbat,
      SalikBrowseSegment.sahibMehfil => s.isSahibEMehfil,
    };

    return matchesSearch &&
        matchesArea &&
        matchesGender &&
        matchesStatus &&
        matchesSegment;
  }).toList();
}

final filteredSaliksProvider = Provider<List<Salik>>((ref) {
  final saliks = ref.watch(saliksStreamProvider).valueOrNull ?? [];
  final filter = ref.watch(salikFilterProvider);
  return applySalikFilters(saliks, filter);
});

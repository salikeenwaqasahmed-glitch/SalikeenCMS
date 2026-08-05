import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/user_session.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/data/reference_data.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/access_control.dart';
import '../../../../core/utils/text_field_merge.dart';
import '../../data/salik_repository.dart';
import '../../domain/entities/area.dart';
import '../../domain/entities/salik.dart';
import '../../domain/entities/salik_duplicate_group.dart';
import 'area_provider.dart';

/// Extra client-side gender guard for genderAdmin / editor (admin = all genders).
List<Salik> scopeSaliksToSession(List<Salik> saliks, UserSession? session) {
  final gender = AccessControl.genderFilter(session);
  if (gender == null) return saliks;
  return saliks.where((s) => s.genderId == gender).toList();
}

enum SalikBrowseSegment { all, bazam, nafiAsbat, sahibMehfil }

const kSaliksPageSize = 20;

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
    this.bazamId = 'all',
    this.genderId = 'all',
    this.status = 'all',
    this.segment = SalikBrowseSegment.all,
  });

  final String search;
  final String areaId;
  final String bazamId;
  final String genderId;
  final String status;
  final SalikBrowseSegment segment;

  /// Location / status / gender only (not segment or search).
  int get activeAdvancedFilterCount {
    var n = 0;
    if (bazamId != 'all') n++;
    if (areaId != 'all') n++;
    if (status != 'all') n++;
    if (genderId != 'all') n++;
    return n;
  }

  SalikFilter copyWith({
    String? search,
    String? areaId,
    String? bazamId,
    String? genderId,
    String? status,
    SalikBrowseSegment? segment,
  }) {
    return SalikFilter(
      search: search ?? this.search,
      areaId: areaId ?? this.areaId,
      bazamId: bazamId ?? this.bazamId,
      genderId: genderId ?? this.genderId,
      status: status ?? this.status,
      segment: segment ?? this.segment,
    );
  }
}

final salikFilterProvider =
    StateNotifierProvider<SalikFilterNotifier, SalikFilter>((ref) {
  return SalikFilterNotifier(ref);
});

class SalikFilterNotifier extends StateNotifier<SalikFilter> {
  SalikFilterNotifier(this._ref) : super(const SalikFilter());

  final Ref _ref;
  Timer? _searchDebounce;

  static const _searchDebounceDuration = Duration(milliseconds: 250);

  void _resetPage() {
    _ref.read(salikListPageProvider.notifier).state = 0;
  }

  void setSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, () {
      state = state.copyWith(search: value);
      _resetPage();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void setArea(String areaId) {
    state = state.copyWith(areaId: areaId);
    _resetPage();
  }

  void setBazam(String bazamId) {
    final keepLocationSegment = state.segment == SalikBrowseSegment.all ||
        state.segment == SalikBrowseSegment.bazam;
    state = state.copyWith(
      bazamId: bazamId,
      areaId: 'all',
      segment: keepLocationSegment ? state.segment : SalikBrowseSegment.all,
    );
    _resetPage();
  }

  void setGender(String genderId) {
    state = state.copyWith(genderId: genderId);
    _resetPage();
  }

  void setStatus(String status) {
    state = state.copyWith(status: status);
    _resetPage();
  }

  void setSegment(SalikBrowseSegment segment) {
    final keepLocation = segment == SalikBrowseSegment.all ||
        segment == SalikBrowseSegment.bazam;
    state = state.copyWith(
      segment: segment,
      areaId: keepLocation ? state.areaId : 'all',
      bazamId: keepLocation ? state.bazamId : 'all',
    );
    _resetPage();
  }

  void reset() {
    state = const SalikFilter();
    _resetPage();
  }

  /// Clears bazam / area / status / gender; keeps search + segment.
  void clearAdvancedFilters() {
    state = state.copyWith(
      bazamId: 'all',
      areaId: 'all',
      status: 'all',
      genderId: 'all',
    );
    _resetPage();
  }
}

String _sortKeyForName(String value, {required bool isUrdu}) {
  final label = localeBilingualLabel(value, isUrdu: isUrdu).trim();
  if (label.isNotEmpty) return label.toLowerCase();
  return value.trim().toLowerCase();
}

int compareSaliksByLocaleName(Salik a, Salik b, {required bool isUrdu}) {
  final nameCmp = _sortKeyForName(a.name, isUrdu: isUrdu)
      .compareTo(_sortKeyForName(b.name, isUrdu: isUrdu));
  if (nameCmp != 0) return nameCmp;

  final fatherCmp = _sortKeyForName(a.fatherName, isUrdu: isUrdu)
      .compareTo(_sortKeyForName(b.fatherName, isUrdu: isUrdu));
  if (fatherCmp != 0) return fatherCmp;

  return a.createdDate.compareTo(b.createdDate);
}

void sortSaliksByLocale(List<Salik> saliks, {required bool isUrdu}) {
  saliks.sort((a, b) {
    if (a.isPending != b.isPending) {
      return a.isPending ? -1 : 1;
    }
    return compareSaliksByLocaleName(a, b, isUrdu: isUrdu);
  });
}

bool _matchesNonSearchFilters(
  Salik s,
  SalikFilter filter, {
  List<Area>? areas,
}) {
  final matchesArea = filter.areaId == 'all' || s.areaId == filter.areaId;
  final matchesBazam = filter.bazamId == 'all' ||
      resolveSalikBazamId(
            salikBazamId: s.bazamId,
            areaId: s.areaId,
            areas: areas,
          ) ==
          filter.bazamId;
  final matchesGender =
      filter.genderId == 'all' || s.genderId == filter.genderId;

  var matchesStatus = true;
  if (filter.status == 'active') matchesStatus = s.isActive;
  if (filter.status == 'inactive') matchesStatus = !s.isActive;

  final matchesSegment = switch (filter.segment) {
    SalikBrowseSegment.all => true,
    SalikBrowseSegment.bazam => true,
    SalikBrowseSegment.nafiAsbat => s.isNafiAsbat,
    SalikBrowseSegment.sahibMehfil => s.isSahibEMehfil,
  };

  return matchesArea &&
      matchesBazam &&
      matchesGender &&
      matchesStatus &&
      matchesSegment;
}

int? _searchTier(Salik s, String q, String rawSearch) {
  final nameHit = s.name.toLowerCase().contains(q) ||
      s.fatherName.toLowerCase().contains(q);
  if (nameHit) return 1;

  if (s.referenceName.toLowerCase().contains(q)) return 2;

  if (s.mobileNumber.contains(rawSearch) ||
      s.address.toLowerCase().contains(q)) {
    return 3;
  }
  return null;
}

/// Filters + ranks search (name/father → reference → mobile/address) + locale sort.
List<Salik> applySalikFilters(
  List<Salik> saliks,
  SalikFilter filter, {
  bool isUrdu = false,
  List<Area>? areas,
}) {
  final scoped = saliks.where(
    (s) => _matchesNonSearchFilters(s, filter, areas: areas),
  );
  final q = filter.search.trim().toLowerCase();
  final rawSearch = filter.search.trim();

  if (q.isEmpty) {
    final list = scoped.toList();
    sortSaliksByLocale(list, isUrdu: isUrdu);
    return list;
  }

  final tier1 = <Salik>[];
  final tier2 = <Salik>[];
  final tier3 = <Salik>[];

  for (final s in scoped) {
    final tier = _searchTier(s, q, rawSearch);
    if (tier == 1) {
      tier1.add(s);
    } else if (tier == 2) {
      tier2.add(s);
    } else if (tier == 3) {
      tier3.add(s);
    }
  }

  sortSaliksByLocale(tier1, isUrdu: isUrdu);
  sortSaliksByLocale(tier2, isUrdu: isUrdu);
  sortSaliksByLocale(tier3, isUrdu: isUrdu);
  return [...tier1, ...tier2, ...tier3];
}

List<Salik> pageSaliks(List<Salik> saliks, int page, {int pageSize = kSaliksPageSize}) {
  if (saliks.isEmpty || pageSize <= 0) return const [];
  final start = page * pageSize;
  if (start >= saliks.length) return const [];
  final end = (start + pageSize).clamp(0, saliks.length);
  return saliks.sublist(start, end);
}

int salikPageCount(int total, {int pageSize = kSaliksPageSize}) {
  if (total <= 0 || pageSize <= 0) return 1;
  return ((total + pageSize - 1) / pageSize).floor();
}

final salikListPageProvider = StateProvider<int>((ref) => 0);

final sortedFilteredSaliksProvider = Provider<List<Salik>>((ref) {
  final saliks = ref.watch(saliksStreamProvider).valueOrNull ?? [];
  final filter = ref.watch(salikFilterProvider);
  final isUrdu = ref.watch(appLocalizationsProvider).isUrdu;
  final areas = ref.watch(areasProvider).valueOrNull ?? kAreas;
  return applySalikFilters(saliks, filter, isUrdu: isUrdu, areas: areas);
});

/// Alias kept for existing call sites; now sorted + ranked.
final filteredSaliksProvider = sortedFilteredSaliksProvider;

final salikListPageCountProvider = Provider<int>((ref) {
  final total = ref.watch(sortedFilteredSaliksProvider).length;
  return salikPageCount(total);
});

final pagedSaliksProvider = Provider<List<Salik>>((ref) {
  final sorted = ref.watch(sortedFilteredSaliksProvider);
  final page = ref.watch(salikListPageProvider);
  final pageCount = salikPageCount(sorted.length);
  final safePage = page.clamp(0, pageCount - 1);
  if (safePage != page) {
    Future.microtask(() {
      ref.read(salikListPageProvider.notifier).state = safePage;
    });
  }
  return pageSaliks(sorted, safePage);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../saliks/presentation/providers/area_provider.dart';
import '../../../saliks/presentation/providers/salik_provider.dart';
import '../../../../core/data/reference_data.dart';

class DashboardStats {
  const DashboardStats({
    required this.total,
    required this.maleCount,
    required this.femaleCount,
    required this.nafiAsbatCount,
    required this.sahibMehfilCount,
  });

  final int total;
  final int maleCount;
  final int femaleCount;
  final int nafiAsbatCount;
  final int sahibMehfilCount;
}

class BazamSalikCount {
  const BazamSalikCount({
    required this.bazamId,
    required this.bazamName,
    required this.count,
  });

  final String bazamId;
  final String bazamName;
  final int count;
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final saliks = ref.watch(saliksStreamProvider).valueOrNull ?? [];
  final maleCount = saliks.where((s) => s.genderId == 'Male').length;
  final femaleCount = saliks.where((s) => s.genderId == 'Female').length;
  final nafiAsbatCount = saliks.where((s) => s.isNafiAsbat).length;
  final sahibMehfilCount = saliks.where((s) => s.isSahibEMehfil).length;
  return DashboardStats(
    total: saliks.length,
    maleCount: maleCount,
    femaleCount: femaleCount,
    nafiAsbatCount: nafiAsbatCount,
    sahibMehfilCount: sahibMehfilCount,
  );
});

final dashboardBazamCountsProvider = Provider<List<BazamSalikCount>>((ref) {
  final saliks = ref.watch(saliksStreamProvider).valueOrNull ?? [];
  final areas = ref.watch(areasProvider).valueOrNull ?? kAreas;
  final bazams = ref.watch(bazamsProvider).valueOrNull ?? kBazams;

  final counts = <String, int>{};
  for (final salik in saliks) {
    final bazamId = resolveSalikBazamId(
      salikBazamId: salik.bazamId,
      areaId: salik.areaId,
      areas: areas,
    );
    counts[bazamId] = (counts[bazamId] ?? 0) + 1;
  }

  final list = bazams.isEmpty ? kBazams : bazams;
  final result = list
      .map(
        (bazam) => BazamSalikCount(
          bazamId: bazam.bazamId,
          bazamName: bazam.bazamName,
          count: counts[bazam.bazamId] ?? 0,
        ),
      )
      .toList()
    ..sort((a, b) => b.count.compareTo(a.count));

  return result;
});

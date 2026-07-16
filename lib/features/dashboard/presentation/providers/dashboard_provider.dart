import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../saliks/presentation/providers/area_provider.dart';
import '../../../saliks/presentation/providers/salik_provider.dart';

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

class AreaSalikCount {
  const AreaSalikCount({
    required this.areaId,
    required this.areaName,
    required this.count,
  });

  final String areaId;
  final String areaName;
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

final dashboardAreaCountsProvider = Provider<List<AreaSalikCount>>((ref) {
  final saliks = ref.watch(saliksStreamProvider).valueOrNull ?? [];
  final areas = ref.watch(areasProvider).valueOrNull ?? [];

  final counts = <String, int>{};
  for (final salik in saliks) {
    counts[salik.areaId] = (counts[salik.areaId] ?? 0) + 1;
  }

  final result = areas
      .where((area) => area.isMajor)
      .map(
        (area) => AreaSalikCount(
          areaId: area.areaId,
          areaName: area.areaName,
          count: counts[area.areaId] ?? 0,
        ),
      )
      .toList()
    ..sort((a, b) => b.count.compareTo(a.count));

  return result;
});

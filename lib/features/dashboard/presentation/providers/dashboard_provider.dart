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

class CitySalikCount {
  const CitySalikCount({
    required this.cityId,
    required this.cityName,
    required this.cityNameUrdu,
    required this.count,
  });

  final String cityId;
  final String cityName;
  final String cityNameUrdu;
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

final dashboardCityCountsProvider = Provider<List<CitySalikCount>>((ref) {
  final saliks = ref.watch(saliksStreamProvider).valueOrNull ?? [];
  final cities = ref.watch(citiesProvider).valueOrNull ?? [];

  final counts = <String, int>{};
  for (final salik in saliks) {
    counts[salik.cityId] = (counts[salik.cityId] ?? 0) + 1;
  }

  final result = cities
      .map(
        (city) => CitySalikCount(
          cityId: city.cityId,
          cityName: city.cityName,
          cityNameUrdu: city.cityNameUrdu,
          count: counts[city.cityId] ?? 0,
        ),
      )
      .toList()
    ..sort((a, b) => b.count.compareTo(a.count));

  return result;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/area_repository.dart';
import '../../domain/entities/area.dart';
import '../../domain/entities/city.dart';

final citiesProvider = StreamProvider<List<City>>((ref) {
  final repo = ref.watch(areaRepositoryProvider);
  return repo.watchCities();
});

final areasByCityProvider =
    StreamProvider.family<List<Area>, String>((ref, cityId) {
  final repo = ref.watch(areaRepositoryProvider);
  return repo.watchAreasByCity(cityId);
});

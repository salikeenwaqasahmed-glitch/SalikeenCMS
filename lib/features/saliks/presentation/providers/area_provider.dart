import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/reference_data.dart';
import '../../data/area_repository.dart';
import '../../domain/entities/area.dart';
import '../../domain/entities/salik.dart';

final areaByIdProvider = FutureProvider.family<Area?, String>((ref, areaId) {
  final repo = ref.watch(areaRepositoryProvider);
  return repo.resolveArea(areaId);
});

final areasProvider = StreamProvider<List<Area>>((ref) {
  final repo = ref.watch(areaRepositoryProvider);
  return repo.watchAreas();
});

/// Resolves the area shown on the add form area picker.
final salikAreaProvider = FutureProvider.family<Area?, Salik>((ref, salik) async {
  final repo = ref.watch(areaRepositoryProvider);

  if (salik.areaId.trim().isNotEmpty) {
    final resolved = await repo.resolveArea(salik.areaId);
    if (resolved != null) return resolved;
  }

  return findAreaForLegacyLocation(
    areaId: salik.areaId,
    address: salik.address,
  );
});

/// Sync fallback while area providers load; keeps profile area row filled.
String salikAreaDisplayName(
  Salik salik, {
  Area? resolved,
  List<Area>? areas,
}) {
  final fromResolved = resolved?.areaName.trim() ?? '';
  if (fromResolved.isNotEmpty) return fromResolved;

  if (areas != null && salik.areaId.trim().isNotEmpty) {
    final fromList = findAreaInList(salik.areaId, areas);
    if (fromList != null && fromList.areaName.trim().isNotEmpty) {
      return fromList.areaName.trim();
    }
  }

  final legacy = findAreaForLegacyLocation(
    areaId: salik.areaId,
    address: salik.address,
  );
  if (legacy != null && legacy.areaName.trim().isNotEmpty) {
    return legacy.areaName.trim();
  }

  final canonical = findArea(salik.areaId);
  if (canonical != null && canonical.areaName.trim().isNotEmpty) {
    return canonical.areaName.trim();
  }

  return '';
}

Salik preferSalikLocationFields(Salik primary, Salik? secondary) {
  if (secondary == null) return primary;

  final primaryArea = primary.areaId.trim();
  final secondaryArea = secondary.areaId.trim();
  final primaryAddress = primary.address.trim();
  final secondaryAddress = secondary.address.trim();

  final areaId = primaryArea.isNotEmpty
      ? primary.areaId
      : (secondaryArea.isNotEmpty ? secondary.areaId : primary.areaId);
  final address = primaryAddress.isNotEmpty
      ? primary.address
      : (secondaryAddress.isNotEmpty ? secondary.address : primary.address);

  if (areaId == primary.areaId && address == primary.address) return primary;

  return primary.copyWith(areaId: areaId, address: address);
}

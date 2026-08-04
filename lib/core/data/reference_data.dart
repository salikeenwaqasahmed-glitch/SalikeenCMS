import '../../features/saliks/domain/entities/area.dart';
import '../../features/saliks/domain/entities/bazam.dart';

export '../../features/saliks/domain/entities/bazam.dart' show kDefaultBazamId;

const List<Bazam> kBazams = [
  Bazam(bazamId: kDefaultBazamId, bazamName: 'I-10'),
];

const List<Area> kAreas = [];

Bazam? findBazam(String bazamId) {
  for (final bazam in kBazams) {
    if (bazam.bazamId == bazamId) return bazam;
  }
  return null;
}

Bazam? findBazamInList(String bazamId, List<Bazam> bazams) {
  for (final bazam in bazams) {
    if (bazam.bazamId == bazamId) return bazam;
  }
  return findBazam(bazamId);
}

Area? findArea(String areaId) {
  for (final area in kAreas) {
    if (area.areaId == areaId) return area;
  }
  return null;
}

Area? findAreaForLegacyLocation({
  required String areaId,
  String? address,
}) {
  final resolved = findArea(areaId);
  if (resolved != null) return resolved;

  final normalizedAddress = (address ?? '').trim().toLowerCase();
  if (normalizedAddress.isEmpty) return null;

  for (final area in kAreas) {
    final normalizedArea = area.areaName.toLowerCase();
    if (normalizedArea.contains(normalizedAddress) ||
        normalizedAddress.contains(normalizedArea)) {
      return area;
    }
  }

  return null;
}

Area? findAreaInList(String areaId, List<Area> areas) {
  for (final area in areas) {
    if (area.areaId == areaId) return area;
  }
  return findArea(areaId);
}

String normalizeAreaLabel(String value) => value.trim().toLowerCase();

Set<String> _nameTokens(String value) {
  return value
      .split('/')
      .map(normalizeAreaLabel)
      .where((s) => s.isNotEmpty)
      .toSet();
}

bool areaNamesOverlap(Area a, Area b) {
  return _nameTokens(a.areaName).intersection(_nameTokens(b.areaName)).isNotEmpty;
}

Area? findCanonicalAreaMatch(Area area) {
  for (final canonical in kAreas) {
    if (areaNamesOverlap(canonical, area)) return canonical;
  }
  return null;
}

/// Resolve salik bazam: explicit field, else area ownership, else default.
String resolveSalikBazamId({
  required String salikBazamId,
  required String areaId,
  List<Area>? areas,
}) {
  final explicit = salikBazamId.trim();
  if (explicit.isNotEmpty) return explicit;

  final area = areas != null
      ? findAreaInList(areaId, areas)
      : findArea(areaId);
  final fromArea = area?.bazamId.trim() ?? '';
  if (fromArea.isNotEmpty) return fromArea;
  return kDefaultBazamId;
}

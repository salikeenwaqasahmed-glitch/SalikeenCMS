import '../../features/saliks/domain/entities/area.dart';

const List<Area> kAreas = [
  Area(areaId: 'a1', areaName: 'Gulshan-e-Iqbal / گلشن اقبال', isMajor: true),
  Area(areaId: 'a2', areaName: 'Karachi Central / کراچی سینٹرل', isMajor: true),
  Area(areaId: 'a3', areaName: 'Karachi West / کراچی ویسٹ'),
  Area(areaId: 'a4', areaName: 'Clifton / کلفٹن'),
  Area(areaId: 'a5', areaName: 'Model Town / ماڈل ٹاؤن', isMajor: true),
  Area(areaId: 'a6', areaName: 'Lahore South / لاہور ساؤتھ'),
  Area(areaId: 'a7', areaName: 'Gulberg / گلبرگ', isMajor: true),
  Area(areaId: 'a8', areaName: 'F-7/2 / ایف 7/2', isMajor: true),
  Area(areaId: 'a9', areaName: 'Islamabad North / اسلام آباد نارتھ'),
  Area(areaId: 'a10', areaName: 'Hayatabad / حیات آباد', isMajor: true),
  Area(areaId: 'a11', areaName: 'Multan Sector B / ملتان سیکٹر بی'),
];

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

import '../../features/saliks/domain/entities/area.dart';
import '../../features/saliks/domain/entities/city.dart';

const List<City> kCities = [
  City(cityId: 'c1', cityName: 'Karachi / کراچی'),
  City(cityId: 'c2', cityName: 'Lahore / لاہور'),
  City(cityId: 'c3', cityName: 'Islamabad / اسلام آباد'),
  City(cityId: 'c4', cityName: 'Peshawar / پیشاور'),
  City(cityId: 'c5', cityName: 'Multan / ملتان'),
];

const List<Area> kAreas = [
  Area(areaId: 'a1', cityId: 'c1', areaName: 'Gulshan-e-Iqbal / گلشن اقبال', isMajor: true),
  Area(areaId: 'a2', cityId: 'c1', areaName: 'Karachi Central / کراچی سینٹرل', isMajor: true),
  Area(areaId: 'a3', cityId: 'c1', areaName: 'Karachi West / کراچی ویسٹ'),
  Area(areaId: 'a4', cityId: 'c1', areaName: 'Clifton / کلفٹن'),
  Area(areaId: 'a5', cityId: 'c2', areaName: 'Model Town / ماڈل ٹاؤن', isMajor: true),
  Area(areaId: 'a6', cityId: 'c2', areaName: 'Lahore South / لاہور ساؤتھ'),
  Area(areaId: 'a7', cityId: 'c2', areaName: 'Gulberg / گلبرگ', isMajor: true),
  Area(areaId: 'a8', cityId: 'c3', areaName: 'F-7/2 / ایف 7/2', isMajor: true),
  Area(areaId: 'a9', cityId: 'c3', areaName: 'Islamabad North / اسلام آباد نارتھ'),
  Area(areaId: 'a10', cityId: 'c4', areaName: 'Hayatabad / حیات آباد', isMajor: true),
  Area(areaId: 'a11', cityId: 'c5', areaName: 'Multan Sector B / ملتان سیکٹر بی'),
];

City? findCity(String cityId) {
  for (final city in kCities) {
    if (city.cityId == cityId) return city;
  }
  return null;
}

Area? findArea(String areaId) {
  for (final area in kAreas) {
    if (area.areaId == areaId) return area;
  }
  return null;
}

City? findCityInList(String cityId, List<City> cities) {
  for (final city in cities) {
    if (city.cityId == cityId) return city;
  }
  return findCity(cityId);
}

Area? findAreaInList(String areaId, List<Area> areas) {
  for (final area in areas) {
    if (area.areaId == areaId) return area;
  }
  return findArea(areaId);
}

List<Area> areasForCity(String cityId) =>
    kAreas.where((a) => a.cityId == cityId).toList();

String normalizeCityLabel(String value) => value.trim().toLowerCase();

Set<String> _nameTokens(String value) {
  return value
      .split('/')
      .map(normalizeCityLabel)
      .where((s) => s.isNotEmpty)
      .toSet();
}

bool cityNamesOverlap(City a, City b) {
  return _nameTokens(a.cityName).intersection(_nameTokens(b.cityName)).isNotEmpty;
}

bool cityMatchesNames(City city, {String name = ''}) {
  final normalized = normalizeCityLabel(name);
  if (normalized.isEmpty) return false;
  return _nameTokens(city.cityName).contains(normalized);
}

City? findCanonicalCityByName({String name = ''}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return null;
  final normalized = normalizeCityLabel(trimmed);
  for (final city in kCities) {
    if (cityMatchesNames(city, name: trimmed)) {
      return city;
    }
    if (normalizeCityLabel(city.cityName) == normalized) {
      return city;
    }
  }
  return null;
}

bool isCanonicalCityId(String cityId) =>
    kCities.any((city) => city.cityId == cityId);

bool isDuplicateCanonicalCity(City city) {
  if (isCanonicalCityId(city.cityId)) return false;
  for (final canonical in kCities) {
    if (cityNamesOverlap(canonical, city)) return true;
  }
  return false;
}

String normalizeAreaLabel(String value) => value.trim().toLowerCase();

bool areaNamesOverlap(Area a, Area b) {
  return _nameTokens(a.areaName).intersection(_nameTokens(b.areaName)).isNotEmpty;
}

Area? findCanonicalAreaByName({
  required String cityId,
  String name = '',
}) {
  final normalized = normalizeAreaLabel(name);
  if (normalized.isEmpty) return null;

  for (final area in kAreas) {
    if (area.cityId != cityId) continue;
    if (_nameTokens(area.areaName).contains(normalized)) return area;
  }
  return null;
}

Area? findCanonicalAreaMatch(Area area) {
  for (final canonical in kAreas) {
    if (areaNamesOverlap(canonical, area)) return canonical;
  }
  return null;
}

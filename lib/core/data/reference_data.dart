import '../../features/saliks/domain/entities/area.dart';
import '../../features/saliks/domain/entities/city.dart';

const List<City> kCities = [
  City(cityId: 'c1', cityName: 'Karachi', cityNameUrdu: 'کراچی'),
  City(cityId: 'c2', cityName: 'Lahore', cityNameUrdu: 'لاہور'),
  City(cityId: 'c3', cityName: 'Islamabad', cityNameUrdu: 'اسلام آباد'),
  City(cityId: 'c4', cityName: 'Peshawar', cityNameUrdu: 'پیشاور'),
  City(cityId: 'c5', cityName: 'Multan', cityNameUrdu: 'ملتان'),
];

const List<Area> kAreas = [
  Area(areaId: 'a1', cityId: 'c1', areaName: 'Gulshan-e-Iqbal', areaNameUrdu: 'گلشن اقبال', isMajor: true),
  Area(areaId: 'a2', cityId: 'c1', areaName: 'Karachi Central', areaNameUrdu: 'کراچی سینٹرل', isMajor: true),
  Area(areaId: 'a3', cityId: 'c1', areaName: 'Karachi West', areaNameUrdu: 'کراچی ویسٹ'),
  Area(areaId: 'a4', cityId: 'c1', areaName: 'Clifton', areaNameUrdu: 'کلفٹن'),
  Area(areaId: 'a5', cityId: 'c2', areaName: 'Model Town', areaNameUrdu: 'ماڈل ٹاؤن', isMajor: true),
  Area(areaId: 'a6', cityId: 'c2', areaName: 'Lahore South', areaNameUrdu: 'لاہور ساؤتھ'),
  Area(areaId: 'a7', cityId: 'c2', areaName: 'Gulberg', areaNameUrdu: 'گلبرگ', isMajor: true),
  Area(areaId: 'a8', cityId: 'c3', areaName: 'F-7/2', areaNameUrdu: 'ایف 7/2', isMajor: true),
  Area(areaId: 'a9', cityId: 'c3', areaName: 'Islamabad North', areaNameUrdu: 'اسلام آباد نارتھ'),
  Area(areaId: 'a10', cityId: 'c4', areaName: 'Hayatabad', areaNameUrdu: 'حیات آباد', isMajor: true),
  Area(areaId: 'a11', cityId: 'c5', areaName: 'Multan Sector B', areaNameUrdu: 'ملتان سیکٹر بی'),
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

bool cityNamesOverlap(City a, City b) {
  final aNames = {
    normalizeCityLabel(a.cityName),
    normalizeCityLabel(a.cityNameUrdu),
  }..removeWhere((s) => s.isEmpty);
  final bNames = {
    normalizeCityLabel(b.cityName),
    normalizeCityLabel(b.cityNameUrdu),
  }..removeWhere((s) => s.isEmpty);
  return aNames.intersection(bNames).isNotEmpty;
}

bool cityMatchesNames(City city, {String nameEn = '', String nameUr = ''}) {
  final inputs = {
    normalizeCityLabel(nameEn),
    normalizeCityLabel(nameUr),
  }..removeWhere((s) => s.isEmpty);
  if (inputs.isEmpty) return false;
  final cityNames = {
    normalizeCityLabel(city.cityName),
    normalizeCityLabel(city.cityNameUrdu),
  };
  return inputs.any(cityNames.contains);
}

City? findCanonicalCityByName({String nameEn = '', String nameUr = ''}) {
  for (final city in kCities) {
    if (cityMatchesNames(city, nameEn: nameEn, nameUr: nameUr)) {
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
  final aNames = {
    normalizeAreaLabel(a.areaName),
    normalizeAreaLabel(a.areaNameUrdu),
  }..removeWhere((s) => s.isEmpty);
  final bNames = {
    normalizeAreaLabel(b.areaName),
    normalizeAreaLabel(b.areaNameUrdu),
  }..removeWhere((s) => s.isEmpty);
  return aNames.intersection(bNames).isNotEmpty;
}

Area? findCanonicalAreaByName({
  required String cityId,
  String nameEn = '',
  String nameUr = '',
}) {
  final inputs = {
    normalizeAreaLabel(nameEn),
    normalizeAreaLabel(nameUr),
  }..removeWhere((s) => s.isEmpty);
  if (inputs.isEmpty) return null;

  for (final area in kAreas) {
    if (area.cityId != cityId) continue;
    final areaNames = {
      normalizeAreaLabel(area.areaName),
      normalizeAreaLabel(area.areaNameUrdu),
    };
    if (inputs.any(areaNames.contains)) return area;
  }
  return null;
}

Area? findCanonicalAreaMatch(Area area) {
  for (final canonical in kAreas) {
    if (areaNamesOverlap(canonical, area)) return canonical;
  }
  return null;
}

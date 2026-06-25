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

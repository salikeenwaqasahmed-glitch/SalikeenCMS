import '../../../../core/utils/text_field_merge.dart';

class City {
  const City({
    required this.cityId,
    required this.cityName,
  });

  final String cityId;
  final String cityName;

  factory City.fromMap(Map<String, dynamic> map, {String? id}) {
    final cityId = (map['cityId'] as String?) ?? id;
    if (cityId == null || cityId.isEmpty) {
      throw const FormatException('City document missing cityId');
    }
    return City(
      cityId: cityId,
      cityName: mergeLegacyBilingual(
        primary: map['cityName'] as String? ?? '',
        secondary: map['cityNameUrdu'] as String? ?? '',
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'cityId': cityId,
        'cityName': cityName,
      };
}

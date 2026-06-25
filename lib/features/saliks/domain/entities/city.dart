class City {
  const City({
    required this.cityId,
    required this.cityName,
    required this.cityNameUrdu,
  });

  final String cityId;
  final String cityName;
  final String cityNameUrdu;

  factory City.fromMap(Map<String, dynamic> map, {String? id}) {
    final cityId = (map['cityId'] as String?) ?? id;
    if (cityId == null || cityId.isEmpty) {
      throw const FormatException('City document missing cityId');
    }
    return City(
      cityId: cityId,
      cityName: map['cityName'] as String? ?? '',
      cityNameUrdu: map['cityNameUrdu'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'cityId': cityId,
        'cityName': cityName,
        'cityNameUrdu': cityNameUrdu,
      };
}

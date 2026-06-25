class Area {
  const Area({
    required this.areaId,
    required this.cityId,
    required this.areaName,
    required this.areaNameUrdu,
    this.isMajor = false,
  });

  final String areaId;
  final String cityId;
  final String areaName;
  final String areaNameUrdu;
  final bool isMajor;

  factory Area.fromMap(Map<String, dynamic> map, {String? id}) {
    final areaId = (map['areaId'] as String?) ?? id;
    if (areaId == null || areaId.isEmpty) {
      throw const FormatException('Area document missing areaId');
    }
    return Area(
      areaId: areaId,
      cityId: map['cityId'] as String? ?? '',
      areaName: map['areaName'] as String? ?? '',
      areaNameUrdu: map['areaNameUrdu'] as String? ?? '',
      isMajor: map['isMajor'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'areaId': areaId,
        'cityId': cityId,
        'areaName': areaName,
        'areaNameUrdu': areaNameUrdu,
        'isMajor': isMajor,
      };
}

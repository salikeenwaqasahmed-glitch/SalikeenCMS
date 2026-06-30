import '../../../../core/utils/text_field_merge.dart';

class Area {
  const Area({
    required this.areaId,
    required this.cityId,
    required this.areaName,
    this.isMajor = false,
  });

  final String areaId;
  final String cityId;
  final String areaName;
  final bool isMajor;

  factory Area.fromMap(Map<String, dynamic> map, {String? id}) {
    final areaId = (map['areaId'] as String?) ?? id;
    if (areaId == null || areaId.isEmpty) {
      throw const FormatException('Area document missing areaId');
    }
    return Area(
      areaId: areaId,
      cityId: map['cityId'] as String? ?? '',
      areaName: mergeLegacyBilingual(
        primary: map['areaName'] as String? ?? '',
        secondary: map['areaNameUrdu'] as String? ?? '',
      ),
      isMajor: map['isMajor'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'areaId': areaId,
        'cityId': cityId,
        'areaName': areaName,
        'isMajor': isMajor,
      };
}

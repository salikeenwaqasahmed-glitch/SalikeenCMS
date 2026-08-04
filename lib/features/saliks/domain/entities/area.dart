import '../../../../core/utils/text_field_merge.dart';
import 'bazam.dart';

class Area {
  const Area({
    required this.areaId,
    required this.areaName,
    this.bazamId = kDefaultBazamId,
  });

  final String areaId;
  final String areaName;
  final String bazamId;

  factory Area.fromMap(Map<String, dynamic> map, {String? id}) {
    final areaId = (map['areaId'] as String?) ?? id;
    if (areaId == null || areaId.isEmpty) {
      throw const FormatException('Area document missing areaId');
    }
    final rawBazam = (map['bazamId'] as String?)?.trim() ?? '';
    return Area(
      areaId: areaId,
      areaName: mergeLegacyBilingual(
        primary: map['areaName'] as String? ?? '',
        secondary: map['areaNameUrdu'] as String? ?? '',
      ),
      bazamId: rawBazam.isEmpty ? kDefaultBazamId : rawBazam,
    );
  }

  Map<String, dynamic> toMap() {
    final split = splitBilingualLabel(areaName);
    return {
      'areaId': areaId,
      if (split.english.isNotEmpty) 'areaName': split.english,
      if (split.urdu.isNotEmpty) 'areaNameUrdu': split.urdu,
      'bazamId': bazamId.isEmpty ? kDefaultBazamId : bazamId,
    };
  }
}

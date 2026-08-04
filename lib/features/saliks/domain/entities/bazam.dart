/// Default bazam assigned to seeded areas and new areas without an explicit id.
const kDefaultBazamId = 'i-10';

class Bazam {
  const Bazam({
    required this.bazamId,
    required this.bazamName,
  });

  final String bazamId;
  final String bazamName;

  factory Bazam.fromMap(Map<String, dynamic> map, {String? id}) {
    final bazamId = (map['bazamId'] as String?) ?? id;
    if (bazamId == null || bazamId.isEmpty) {
      throw const FormatException('Bazam document missing bazamId');
    }
    return Bazam(
      bazamId: bazamId,
      bazamName: (map['bazamName'] as String?)?.trim() ?? bazamId,
    );
  }

  Map<String, dynamic> toMap() => {
        'bazamId': bazamId,
        'bazamName': bazamName,
      };
}

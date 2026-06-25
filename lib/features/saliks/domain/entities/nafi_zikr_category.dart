class NafiZikrCategory {
  const NafiZikrCategory({
    required this.zikrId,
    required this.zikrName,
    required this.zikrNameUrdu,
  });

  final String zikrId;
  final String zikrName;
  final String zikrNameUrdu;

  factory NafiZikrCategory.fromMap(Map<String, dynamic> map) {
    return NafiZikrCategory(
      zikrId: map['zikrId'] as String,
      zikrName: map['zikrName'] as String,
      zikrNameUrdu: map['zikrNameUrdu'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'zikrId': zikrId,
        'zikrName': zikrName,
        'zikrNameUrdu': zikrNameUrdu,
      };
}

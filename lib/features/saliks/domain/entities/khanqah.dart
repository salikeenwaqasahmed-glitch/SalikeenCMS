class Khanqah {
  const Khanqah({
    required this.khanqahId,
    required this.khanqahName,
    required this.khanqahNameUrdu,
  });

  final String khanqahId;
  final String khanqahName;
  final String khanqahNameUrdu;

  factory Khanqah.fromMap(Map<String, dynamic> map) {
    return Khanqah(
      khanqahId: map['khanqahId'] as String,
      khanqahName: map['khanqahName'] as String,
      khanqahNameUrdu: map['khanqahNameUrdu'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'khanqahId': khanqahId,
        'khanqahName': khanqahName,
        'khanqahNameUrdu': khanqahNameUrdu,
      };
}

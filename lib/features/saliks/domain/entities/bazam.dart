class Bazam {
  const Bazam({
    required this.bazamId,
    required this.bazamName,
    required this.bazamNameUrdu,
  });

  final String bazamId;
  final String bazamName;
  final String bazamNameUrdu;

  factory Bazam.fromMap(Map<String, dynamic> map) {
    return Bazam(
      bazamId: map['bazamId'] as String,
      bazamName: map['bazamName'] as String,
      bazamNameUrdu: map['bazamNameUrdu'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'bazamId': bazamId,
        'bazamName': bazamName,
        'bazamNameUrdu': bazamNameUrdu,
      };
}

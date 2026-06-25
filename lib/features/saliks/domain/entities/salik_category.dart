class SalikCategory {
  const SalikCategory({
    required this.categoryId,
    required this.categoryName,
  });

  final String categoryId;
  final String categoryName;

  factory SalikCategory.fromMap(Map<String, dynamic> map) {
    return SalikCategory(
      categoryId: map['categoryId'] as String,
      categoryName: map['categoryName'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'categoryId': categoryId,
        'categoryName': categoryName,
      };
}

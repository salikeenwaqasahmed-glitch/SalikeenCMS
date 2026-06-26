/// Read-only labels: show saved EN + UR together (not locale-picked).
String savedBilingualText({
  required String english,
  required String urdu,
}) {
  final en = english.trim();
  final ur = urdu.trim();
  if (en.isEmpty) return ur;
  if (ur.isEmpty) return en;
  if (en == ur) return en;
  return '$en / $ur';
}

String savedCityLabel({
  required String cityName,
  required String cityNameUrdu,
}) {
  return savedBilingualText(english: cityName, urdu: cityNameUrdu);
}

String savedAreaLabel({
  required String areaName,
  required String areaNameUrdu,
}) {
  return savedBilingualText(english: areaName, urdu: areaNameUrdu);
}

String savedSalikName({
  required String nameEnglish,
  required String nameUrdu,
}) {
  return savedBilingualText(english: nameEnglish, urdu: nameUrdu);
}

String savedFatherName({
  required String fatherNameEnglish,
  required String fatherNameUrdu,
}) {
  return savedBilingualText(
    english: fatherNameEnglish,
    urdu: fatherNameUrdu,
  );
}

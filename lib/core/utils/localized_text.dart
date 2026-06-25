/// Picks display text for bilingual fields without copying across locales on save.
String localizedText({
  required String english,
  required String urdu,
  required bool preferUrdu,
}) {
  if (preferUrdu) {
    return urdu.isNotEmpty ? urdu : english;
  }
  return english.isNotEmpty ? english : urdu;
}

String localizedCityName({
  required String cityName,
  required String cityNameUrdu,
  required bool preferUrdu,
}) {
  return localizedText(
    english: cityName,
    urdu: cityNameUrdu,
    preferUrdu: preferUrdu,
  );
}

String localizedAreaName({
  required String areaName,
  required String areaNameUrdu,
  required bool preferUrdu,
}) {
  return localizedText(
    english: areaName,
    urdu: areaNameUrdu,
    preferUrdu: preferUrdu,
  );
}

String localizedSalikName({
  required String nameEnglish,
  required String nameUrdu,
  required bool preferUrdu,
}) {
  return localizedText(
    english: nameEnglish,
    urdu: nameUrdu,
    preferUrdu: preferUrdu,
  );
}

String localizedFatherName({
  required String fatherNameEnglish,
  required String fatherNameUrdu,
  required bool preferUrdu,
}) {
  return localizedText(
    english: fatherNameEnglish,
    urdu: fatherNameUrdu,
    preferUrdu: preferUrdu,
  );
}

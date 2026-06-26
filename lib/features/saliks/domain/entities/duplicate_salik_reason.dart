enum DuplicateSalikReason { mobile, nameEnglish, nameUrdu }

class DuplicateSalikException implements Exception {
  DuplicateSalikException(this.reason);

  final DuplicateSalikReason reason;
}

enum DuplicateSalikReason { mobile, name }

class DuplicateSalikException implements Exception {
  DuplicateSalikException(this.reason);

  final DuplicateSalikReason reason;

  @override
  String toString() => 'DuplicateSalikException($reason)';
}

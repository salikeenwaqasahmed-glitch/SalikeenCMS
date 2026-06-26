import 'duplicate_salik_reason.dart';
import 'salik.dart';

class SalikDuplicateGroup {
  const SalikDuplicateGroup({
    required this.id,
    required this.reasons,
    required this.label,
    required this.saliks,
  });

  final String id;
  final Set<DuplicateSalikReason> reasons;
  final String label;
  final List<Salik> saliks;
}

import '../domain/entities/approval_status.dart';
import '../domain/entities/duplicate_salik_reason.dart';
import '../domain/entities/salik.dart';
import '../domain/entities/salik_duplicate_group.dart';

String _normalizePhone(String phone) => phone.replaceAll(RegExp(r'[^0-9]'), '');

String _normalizeEnglish(String value) => value.trim().toLowerCase();

String _normalizeUrdu(String value) => value.trim();

List<SalikDuplicateGroup> findSalikDuplicateGroups(List<Salik> saliks) {
  final active = saliks
      .where((s) => s.approvalStatus != ApprovalStatus.rejected)
      .toList();
  if (active.length < 2) return [];

  final parent = List<int>.generate(active.length, (i) => i);

  int find(int x) {
    while (parent[x] != x) {
      parent[x] = parent[parent[x]];
      x = parent[x];
    }
    return x;
  }

  void union(int a, int b) {
    final ra = find(a);
    final rb = find(b);
    if (ra != rb) parent[rb] = ra;
  }

  for (var i = 0; i < active.length; i++) {
    for (var j = i + 1; j < active.length; j++) {
      if (_pairReason(active[i], active[j]) != null) {
        union(i, j);
      }
    }
  }

  final buckets = <int, List<Salik>>{};
  for (var i = 0; i < active.length; i++) {
    buckets.putIfAbsent(find(i), () => []).add(active[i]);
  }

  final groups = <SalikDuplicateGroup>[];
  for (final members in buckets.values) {
    if (members.length < 2) continue;
    groups.add(_groupFromMembers(members));
  }

  groups.sort((a, b) => a.label.compareTo(b.label));
  return groups;
}

DuplicateSalikReason? _pairReason(Salik a, Salik b) {
  if (a.salikId == b.salikId) return null;

  final mobileA = _normalizePhone(a.mobileNumber);
  final mobileB = _normalizePhone(b.mobileNumber);
  if (mobileA.isNotEmpty && mobileA == mobileB) {
    return DuplicateSalikReason.mobile;
  }

  final nameEnA = _normalizeEnglish(a.nameEnglish);
  final fatherEnA = _normalizeEnglish(a.fatherNameEnglish);
  final nameEnB = _normalizeEnglish(b.nameEnglish);
  final fatherEnB = _normalizeEnglish(b.fatherNameEnglish);
  if (nameEnA.isNotEmpty &&
      fatherEnA.isNotEmpty &&
      nameEnA == nameEnB &&
      fatherEnA == fatherEnB) {
    return DuplicateSalikReason.nameEnglish;
  }

  final nameUrA = _normalizeUrdu(a.nameUrdu);
  final fatherUrA = _normalizeUrdu(a.fatherNameUrdu);
  final nameUrB = _normalizeUrdu(b.nameUrdu);
  final fatherUrB = _normalizeUrdu(b.fatherNameUrdu);
  if (nameUrA.isNotEmpty &&
      fatherUrA.isNotEmpty &&
      nameUrA == nameUrB &&
      fatherUrA == fatherUrB) {
    return DuplicateSalikReason.nameUrdu;
  }

  return null;
}

SalikDuplicateGroup _groupFromMembers(List<Salik> members) {
  final reasons = <DuplicateSalikReason>{};
  for (var i = 0; i < members.length; i++) {
    for (var j = i + 1; j < members.length; j++) {
      final reason = _pairReason(members[i], members[j]);
      if (reason != null) reasons.add(reason);
    }
  }

  final sorted = [...members]
    ..sort((a, b) => a.createdDate.compareTo(b.createdDate));
  final label = _labelForGroup(sorted, reasons);
  final id = sorted.map((s) => s.salikId).join('|');

  return SalikDuplicateGroup(
    id: id,
    reasons: reasons,
    label: label,
    saliks: sorted,
  );
}

String _labelForGroup(List<Salik> members, Set<DuplicateSalikReason> reasons) {
  final first = members.first;
  if (reasons.contains(DuplicateSalikReason.mobile)) {
    return first.mobileNumber.trim();
  }
  if (reasons.contains(DuplicateSalikReason.nameEnglish)) {
    return '${first.nameEnglish.trim()} / ${first.fatherNameEnglish.trim()}';
  }
  return '${first.nameUrdu.trim()} / ${first.fatherNameUrdu.trim()}';
}

Salik mergeSalikRecords(Salik keep, Salik other) {
  String pick(String primary, String secondary) {
    final left = primary.trim();
    if (left.isNotEmpty) return left;
    return secondary.trim();
  }

  String? pickNotes(String? primary, String? secondary) {
    final left = primary?.trim() ?? '';
    final right = secondary?.trim() ?? '';
    if (left.isEmpty) return right.isEmpty ? null : right;
    if (right.isEmpty || left.contains(right)) return left;
    return '$left\n$right';
  }

  final keepApproved = keep.isApproved;
  final otherApproved = other.isApproved;

  return keep.copyWith(
    nameEnglish: pick(keep.nameEnglish, other.nameEnglish),
    nameUrdu: pick(keep.nameUrdu, other.nameUrdu),
    fatherNameEnglish: pick(keep.fatherNameEnglish, other.fatherNameEnglish),
    fatherNameUrdu: pick(keep.fatherNameUrdu, other.fatherNameUrdu),
    mobileNumber: pick(keep.mobileNumber, other.mobileNumber),
    whatsappNumber: pick(keep.whatsappNumber, other.whatsappNumber),
    cityId: pick(keep.cityId, other.cityId),
    areaId: pick(keep.areaId, other.areaId),
    bazamId: pick(keep.bazamId, other.bazamId),
    khanqahId: pick(keep.khanqahId, other.khanqahId),
    salikCategoryId: pick(keep.salikCategoryId, other.salikCategoryId),
    dateOfBaith: pick(keep.dateOfBaith, other.dateOfBaith),
    referenceName: pick(keep.referenceName, other.referenceName),
    referenceMobile: pick(keep.referenceMobile, other.referenceMobile),
    nafiZikrId: pick(keep.nafiZikrId, other.nafiZikrId),
    profilePicture: pick(keep.profilePicture, other.profilePicture),
    createdDate: pick(keep.createdDate, other.createdDate),
    notes: pickNotes(keep.notes, other.notes),
    isNafiAsbat: keep.isNafiAsbat || other.isNafiAsbat,
    isSahibEMehfil: keep.isSahibEMehfil || other.isSahibEMehfil,
    isActive: keep.isActive || other.isActive,
    approvalStatus: keepApproved
        ? keep.approvalStatus
        : (otherApproved ? other.approvalStatus : keep.approvalStatus),
    approvedByUid: pick(keep.approvedByUid, other.approvedByUid),
    approvedByName: pick(keep.approvedByName, other.approvedByName),
    approvedAt: pick(keep.approvedAt, other.approvedAt),
    modifiedDate: DateTime.now().toIso8601String().split('T').first,
  );
}

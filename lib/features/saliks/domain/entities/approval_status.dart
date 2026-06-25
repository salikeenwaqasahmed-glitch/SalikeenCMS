enum ApprovalStatus {
  pending,
  approved,
  rejected;

  static ApprovalStatus fromString(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'pending':
        return ApprovalStatus.pending;
      case 'rejected':
        return ApprovalStatus.rejected;
      default:
        return ApprovalStatus.approved;
    }
  }

  String toFirestore() => name;
}

import 'approval_status.dart';
import '../../../../core/utils/text_field_merge.dart';

class Salik {
  const Salik({
    required this.salikId,
    required this.name,
    required this.fatherName,
    required this.mobileNumber,
    required this.whatsappNumber,
    required this.areaId,
    this.address = '',
    required this.genderId,
    required this.bazamId,
    required this.khanqahId,
    required this.salikCategoryId,
    required this.dateOfBaith,
    required this.referenceName,
    required this.referenceMobile,
    required this.isNafiAsbat,
    required this.isSahibEMehfil,
    required this.profilePicture,
    required this.createdDate,
    required this.modifiedDate,
    required this.isActive,
    this.nafiZikrId = '',
    this.notes,
    this.addedByUid = '',
    this.addedByName = '',
    this.approvalStatus = ApprovalStatus.approved,
    this.approvedByUid = '',
    this.approvedByName = '',
    this.approvedAt = '',
  });

  final String salikId;
  final String name;
  final String fatherName;
  final String mobileNumber;
  final String whatsappNumber;
  final String areaId;
  final String address;
  final String genderId;
  final String bazamId;
  final String khanqahId;
  final String salikCategoryId;
  final String dateOfBaith;
  final String referenceName;
  final String referenceMobile;
  final bool isNafiAsbat;
  final bool isSahibEMehfil;
  final String nafiZikrId;
  final String profilePicture;
  final String createdDate;
  final String modifiedDate;
  final bool isActive;
  final String? notes;
  final String addedByUid;
  final String addedByName;
  final ApprovalStatus approvalStatus;
  final String approvedByUid;
  final String approvedByName;
  final String approvedAt;

  bool get isApproved => approvalStatus == ApprovalStatus.approved;
  bool get isPending => approvalStatus == ApprovalStatus.pending;
  bool get isRejected => approvalStatus == ApprovalStatus.rejected;

  Salik copyWith({
    String? salikId,
    String? name,
    String? fatherName,
    String? mobileNumber,
    String? whatsappNumber,
    String? areaId,
    String? address,
    String? genderId,
    String? bazamId,
    String? khanqahId,
    String? salikCategoryId,
    String? dateOfBaith,
    String? referenceName,
    String? referenceMobile,
    bool? isNafiAsbat,
    bool? isSahibEMehfil,
    String? nafiZikrId,
    String? profilePicture,
    String? createdDate,
    String? modifiedDate,
    bool? isActive,
    String? notes,
    String? addedByUid,
    String? addedByName,
    ApprovalStatus? approvalStatus,
    String? approvedByUid,
    String? approvedByName,
    String? approvedAt,
  }) {
    return Salik(
      salikId: salikId ?? this.salikId,
      name: name ?? this.name,
      fatherName: fatherName ?? this.fatherName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      areaId: areaId ?? this.areaId,
      address: address ?? this.address,
      genderId: genderId ?? this.genderId,
      bazamId: bazamId ?? this.bazamId,
      khanqahId: khanqahId ?? this.khanqahId,
      salikCategoryId: salikCategoryId ?? this.salikCategoryId,
      dateOfBaith: dateOfBaith ?? this.dateOfBaith,
      referenceName: referenceName ?? this.referenceName,
      referenceMobile: referenceMobile ?? this.referenceMobile,
      isNafiAsbat: isNafiAsbat ?? this.isNafiAsbat,
      isSahibEMehfil: isSahibEMehfil ?? this.isSahibEMehfil,
      nafiZikrId: nafiZikrId ?? this.nafiZikrId,
      profilePicture: profilePicture ?? this.profilePicture,
      createdDate: createdDate ?? this.createdDate,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      addedByUid: addedByUid ?? this.addedByUid,
      addedByName: addedByName ?? this.addedByName,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedByUid: approvedByUid ?? this.approvedByUid,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  factory Salik.fromMap(Map<String, dynamic> map, {String? id}) {
    return Salik(
      salikId: id ?? map['salikId'] as String? ?? '',
      name: readUnifiedText(
        map,
        key: 'name',
        legacyPrimaryKey: 'nameEnglish',
        legacySecondaryKey: 'nameUrdu',
      ),
      fatherName: readUnifiedText(
        map,
        key: 'fatherName',
        legacyPrimaryKey: 'fatherNameEnglish',
        legacySecondaryKey: 'fatherNameUrdu',
      ),
      mobileNumber: map['mobileNumber'] as String? ?? '',
      whatsappNumber: map['whatsappNumber'] as String? ?? '',
      areaId: (map['areaId'] as String? ?? map['cityId'] as String?)?.trim() ?? '',
      address: map['address'] as String? ?? '',
      genderId: map['genderId'] as String? ?? 'Male',
      bazamId: map['bazamId'] as String? ?? '',
      khanqahId: map['khanqahId'] as String? ?? '',
      salikCategoryId: map['salikCategoryId'] as String? ?? '',
      dateOfBaith: map['dateOfBaith'] as String? ?? '',
      referenceName: map['referenceName'] as String? ?? '',
      referenceMobile: map['referenceMobile'] as String? ?? '',
      isNafiAsbat: map['isNafiAsbat'] as bool? ?? false,
      isSahibEMehfil: map['isSahibEMehfil'] as bool? ?? false,
      nafiZikrId: map['nafiZikrId'] as String? ?? '',
      profilePicture: map['profilePicture'] as String? ?? '',
      createdDate: map['createdDate'] as String? ?? '',
      modifiedDate: map['modifiedDate'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      notes: map['notes'] as String?,
      addedByUid: map['addedByUid'] as String? ?? '',
      addedByName: map['addedByName'] as String? ?? '',
      approvalStatus: ApprovalStatus.fromString(
        map['approvalStatus'] as String?,
      ),
      approvedByUid: map['approvedByUid'] as String? ?? '',
      approvedByName: map['approvedByName'] as String? ?? '',
      approvedAt: map['approvedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'salikId': salikId,
        'name': name,
        'fatherName': fatherName,
        'mobileNumber': mobileNumber,
        'whatsappNumber': whatsappNumber,
        'areaId': areaId,
        'address': address,
        'genderId': genderId,
        'bazamId': bazamId,
        'khanqahId': khanqahId,
        'salikCategoryId': salikCategoryId,
        'dateOfBaith': dateOfBaith,
        'referenceName': referenceName,
        'referenceMobile': referenceMobile,
        'isNafiAsbat': isNafiAsbat,
        'isSahibEMehfil': isSahibEMehfil,
        'nafiZikrId': nafiZikrId,
        'profilePicture': profilePicture,
        'createdDate': createdDate,
        'modifiedDate': modifiedDate,
        'isActive': isActive,
        'notes': notes,
        'addedByUid': addedByUid,
        'addedByName': addedByName,
        'approvalStatus': approvalStatus.toFirestore(),
        'approvedByUid': approvedByUid,
        'approvedByName': approvedByName,
        'approvedAt': approvedAt,
      };
}

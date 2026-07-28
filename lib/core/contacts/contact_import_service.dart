import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/phone_number_utils.dart';

class ImportedContact {
  const ImportedContact({
    required this.name,
    required this.mobile,
  });

  final String name;
  final String mobile;
}

enum ContactImportPermissionResult { granted, denied, permanentlyDenied }

final contactImportServiceProvider = Provider<ContactImportService>((ref) {
  return ContactImportService();
});

class ContactImportService {
  /// Requests contacts permission. Native picker can work without it on some
  /// platforms, but Android needs READ_CONTACTS when requesting phone fields.
  Future<ContactImportPermissionResult> requestPermission() async {
    final status = await Permission.contacts.request();
    if (status.isGranted || status.isLimited) {
      return ContactImportPermissionResult.granted;
    }
    if (status.isPermanentlyDenied) {
      return ContactImportPermissionResult.permanentlyDenied;
    }
    return ContactImportPermissionResult.denied;
  }

  /// Opens the native single-contact picker with phone numbers.
  Future<ImportedContact?> pickOne() async {
    final permission = await requestPermission();
    if (permission != ContactImportPermissionResult.granted) {
      // Still try native picker (permissionless for display name only).
      try {
        final contact = await FlutterContacts.native.showPicker(
          properties: {ContactProperty.phone},
        );
        return _mapContact(contact);
      } catch (_) {
        return null;
      }
    }

    final contact = await FlutterContacts.native.showPicker(
      properties: {ContactProperty.phone, ContactProperty.name},
    );
    return _mapContact(contact);
  }

  /// Loads device contacts (name + phones) for multi-select import.
  Future<List<ImportedContact>> loadAll() async {
    final permission = await requestPermission();
    if (permission != ContactImportPermissionResult.granted) {
      return const [];
    }

    final contacts = await FlutterContacts.getAll(
      properties: {ContactProperty.name, ContactProperty.phone},
    );
    final mapped = <ImportedContact>[];
    for (final contact in contacts) {
      final item = _mapContact(contact);
      if (item != null) mapped.add(item);
    }
    mapped.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return mapped;
  }

  ImportedContact? _mapContact(Contact? contact) {
    if (contact == null) return null;

    final name = (contact.displayName ??
            [
              contact.name?.first ?? '',
              contact.name?.last ?? '',
            ].where((p) => p.trim().isNotEmpty).join(' '))
        .trim();
    if (name.isEmpty) return null;

    final rawPhone = contact.phones.isNotEmpty
        ? contact.phones.first.number.trim()
        : '';
    if (rawPhone.isEmpty) return null;

    final parsed = PhoneNumberUtils.parseStored(rawPhone);
    final stored = PhoneNumberUtils.toStored(
      parsed.country,
      parsed.nationalDigits,
    );
    if (stored.trim().isEmpty) return null;

    return ImportedContact(name: name, mobile: stored);
  }
}

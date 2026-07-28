import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../features/auth/domain/user_session.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/saliks/data/salik_repository.dart';
import '../../features/saliks/domain/entities/duplicate_salik_reason.dart';
import '../../features/saliks/domain/entities/salik.dart';
import '../localization/app_localizations.dart';
import '../router/form_navigation.dart';
import '../theme/app_spacing.dart';
import '../utils/access_control.dart';
import 'contact_import_service.dart';

Future<void> importContactIntoForm(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final service = ref.read(contactImportServiceProvider);

  final permission = await service.requestPermission();
  if (permission == ContactImportPermissionResult.permanentlyDenied) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.t('import_contacts_permission_denied'))),
    );
    await openAppSettings();
    return;
  }

  final contact = await service.pickOne();
  if (!context.mounted || contact == null) return;

  context.go(
    addSalikRoute(
      from: FormReturnRoute.saliks,
      name: contact.name,
      mobile: contact.mobile,
    ),
  );
}

Future<void> importContactsBatch(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final session = ref.read(currentSessionProvider);
  if (session == null || !AccessControl.canCreate(session.role)) return;

  final service = ref.read(contactImportServiceProvider);
  final permission = await service.requestPermission();
  if (permission != ContactImportPermissionResult.granted) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.t('import_contacts_permission_denied'))),
    );
    if (permission == ContactImportPermissionResult.permanentlyDenied) {
      await openAppSettings();
    }
    return;
  }

  final contacts = await service.loadAll();
  if (!context.mounted) return;
  if (contacts.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.t('empty_saliks'))),
    );
    return;
  }

  final selected = await showModalBottomSheet<List<ImportedContact>>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ContactMultiSelectSheet(contacts: contacts),
  );
  if (!context.mounted || selected == null || selected.isEmpty) return;

  final repo = ref.read(salikRepositoryProvider);
  var imported = 0;
  var skipped = 0;
  var failed = 0;
  final gender = UserSession.normalizeGender(session.gender);

  for (final contact in selected) {
    try {
      final salik = Salik(
        salikId: const Uuid().v4(),
        name: contact.name,
        fatherName: '',
        mobileNumber: contact.mobile,
        whatsappNumber: contact.mobile,
        areaId: '',
        genderId: gender,
        bazamId: '',
        khanqahId: '',
        salikCategoryId: '',
        dateOfBaith: DateTime.now().toIso8601String().split('T').first,
        referenceName: '',
        referenceMobile: '',
        isNafiAsbat: false,
        isSahibEMehfil: false,
        profilePicture: '',
        createdDate: DateTime.now().toIso8601String().split('T').first,
        modifiedDate: DateTime.now().toIso8601String().split('T').first,
        isActive: true,
      );
      await repo.createSalik(salik, session: session);
      imported++;
    } on DuplicateSalikException {
      skipped++;
    } catch (e) {
      failed++;
      debugPrint('Contact import failed for ${contact.name}: $e');
    }
  }

  if (!context.mounted) return;
  final message = l10n
      .t('import_contacts_summary')
      .replaceAll('{imported}', '$imported')
      .replaceAll('{skipped}', '$skipped')
      .replaceAll('{failed}', '$failed');
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _ContactMultiSelectSheet extends StatefulWidget {
  const _ContactMultiSelectSheet({required this.contacts});

  final List<ImportedContact> contacts;

  @override
  State<_ContactMultiSelectSheet> createState() =>
      _ContactMultiSelectSheetState();
}

class _ContactMultiSelectSheetState extends State<_ContactMultiSelectSheet> {
  late final Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {};
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final height = MediaQuery.sizeOf(context).height * 0.75;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.t('import_contacts'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final picked = _selected
                          .map((i) => widget.contacts[i])
                          .toList();
                      Navigator.of(context).pop(picked);
                    },
                    child: Text(l10n.t('submit')),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.contacts.length,
                itemBuilder: (context, index) {
                  final contact = widget.contacts[index];
                  final checked = _selected.contains(index);
                  return CheckboxListTile(
                    value: checked,
                    title: Text(contact.name),
                    subtitle: Text(contact.mobile),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selected.add(index);
                        } else {
                          _selected.remove(index);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows import menu: single → form, multi → batch create.
Future<void> showContactImportActions(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person_add_alt_1),
            title: Text(l10n.t('import_contact')),
            onTap: () => Navigator.pop(context, 'one'),
          ),
          ListTile(
            leading: const Icon(Icons.import_contacts),
            title: Text(l10n.t('import_contacts')),
            onTap: () => Navigator.pop(context, 'many'),
          ),
        ],
      ),
    ),
  );

  if (!context.mounted || choice == null) return;
  if (choice == 'one') {
    await importContactIntoForm(context, ref);
  } else {
    await importContactsBatch(context, ref);
  }
}

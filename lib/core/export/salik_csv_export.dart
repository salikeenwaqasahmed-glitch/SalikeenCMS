import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/saliks/domain/entities/area.dart';
import '../../features/saliks/domain/entities/salik.dart';
import '../../features/saliks/presentation/providers/area_provider.dart';

String _csvEscape(String value) {
  final escaped = value.replaceAll('"', '""');
  if (escaped.contains(',') ||
      escaped.contains('"') ||
      escaped.contains('\n') ||
      escaped.contains('\r')) {
    return '"$escaped"';
  }
  return escaped;
}

String buildSalikCsv(
  List<Salik> saliks, {
  Map<String, Area>? areaLookup,
}) {
  final lookup = areaLookup ?? const <String, Area>{};
  final buffer = StringBuffer();
  buffer.writeln(
    [
      'name',
      'fatherName',
      'mobileNumber',
      'whatsappNumber',
      'genderId',
      'area',
      'address',
      'referenceName',
      'dateOfBaith',
      'approvalStatus',
      'isActive',
      'isNafiAsbat',
      'isSahibEMehfil',
    ].join(','),
  );

  for (final s in saliks) {
    final areaLabel = salikLocationLabel(s, lookup);
    buffer.writeln(
      [
        _csvEscape(s.name),
        _csvEscape(s.fatherName),
        _csvEscape(s.mobileNumber),
        _csvEscape(s.whatsappNumber),
        _csvEscape(s.genderId),
        _csvEscape(areaLabel),
        _csvEscape(s.address),
        _csvEscape(s.referenceName),
        _csvEscape(s.dateOfBaith),
        _csvEscape(s.approvalStatus.toFirestore()),
        s.isActive ? 'true' : 'false',
        s.isNafiAsbat ? 'true' : 'false',
        s.isSahibEMehfil ? 'true' : 'false',
      ].join(','),
    );
  }
  return buffer.toString();
}

Future<void> shareSalikCsv(
  List<Salik> saliks, {
  Map<String, Area>? areaLookup,
}) async {
  final csv = buildSalikCsv(saliks, areaLookup: areaLookup);
  final dir = await getTemporaryDirectory();
  final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  final file = File('${dir.path}/saliks_export_$stamp.csv');
  await file.writeAsString(csv, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Saliks export',
    ),
  );
}

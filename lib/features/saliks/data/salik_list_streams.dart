import '../../../core/database/app_database.dart';
import '../domain/entities/salik.dart';

/// Merges Firestore saliks with local Drift cache + outbox (outbox wins; deletes hide remote).
List<Salik> mergeSalikOutbox({
  required List<Salik> remote,
  required List<LocalSalik> localRows,
  bool Function(Salik salik)? includeRemote,
  bool Function(Salik salik)? includeLocal,
  bool includeSyncedLocal = false,
}) {
  final localById = {for (final row in localRows) row.salikId: row};
  final byId = <String, Salik>{};

  for (final salik in remote) {
    if (includeRemote != null && !includeRemote(salik)) continue;
    final local = localById[salik.salikId];
    if (local?.syncStatus == pendingDelete) continue;
    if (local != null && local.syncStatus != synced) continue;
    byId[salik.salikId] = salik;
  }

  for (final row in localRows) {
    if (row.syncStatus == synced) {
      if (!includeSyncedLocal) continue;
      final salik = row.toSalik();
      if (includeLocal != null && !includeLocal(salik)) continue;
      byId.putIfAbsent(salik.salikId, () => salik);
      continue;
    }
    final salik = row.toSalik();
    if (includeLocal != null && !includeLocal(salik)) continue;
    if (row.syncStatus == pendingDelete) {
      byId.remove(row.salikId);
      continue;
    }
    byId[salik.salikId] = salik;
  }

  return byId.values.toList();
}

/// Drift-only salik list for UI — no live Firestore listener.
Stream<List<Salik>> watchLocalSaliks({
  required Stream<List<LocalSalik>> localStream,
  required List<Salik> Function(List<LocalSalik> localRows) project,
}) {
  return localStream.map(project);
}

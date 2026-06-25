import 'dart:async';

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

Stream<List<Salik>> watchMergedSaliks({
  required Stream<bool> onlineStream,
  required Stream<List<LocalSalik>> localStream,
  required Stream<List<Salik>> Function() remoteStreamFactory,
  required List<Salik> Function(
    List<Salik> remote,
    List<LocalSalik> local,
    bool online,
  ) merge,
}) {
  late final StreamController<List<Salik>> controller;
  StreamSubscription<List<LocalSalik>>? localSub;
  StreamSubscription<List<Salik>>? remoteSub;
  StreamSubscription<bool>? onlineSub;
  var latestLocal = <LocalSalik>[];
  var latestRemote = <Salik>[];
  var online = true;

  void emit() {
    if (controller.isClosed) return;
    controller.add(merge(latestRemote, latestLocal, online));
  }

  void attachRemote() {
    remoteSub?.cancel();
    remoteSub = null;
    if (!online) {
      latestRemote = [];
      emit();
      return;
    }
    remoteSub = remoteStreamFactory().listen(
      (remote) {
        latestRemote = remote;
        emit();
      },
      onError: controller.addError,
    );
  }

  controller = StreamController<List<Salik>>.broadcast(
    onListen: () {
      localSub = localStream.listen(
        (local) {
          latestLocal = local;
          emit();
        },
        onError: controller.addError,
      );
      onlineSub = onlineStream.listen(
        (value) {
          online = value;
          attachRemote();
          emit();
        },
        onError: controller.addError,
      );
    },
    onCancel: () async {
      await localSub?.cancel();
      await remoteSub?.cancel();
      await onlineSub?.cancel();
    },
  );

  return controller.stream;
}

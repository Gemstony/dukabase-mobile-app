import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/record_write_result.dart';
import 'connectivity_helper.dart';

/// Commits Firestore batches with offline-friendly behavior.
///
/// When offline, [WriteBatch.commit] may never resolve while waiting for the
/// server even though writes are persisted locally. This helper returns as soon
/// as the local queue accepts the batch.
class FirestoreWriteHelper {
  FirestoreWriteHelper._();

  static const Duration _offlineCommitTimeout = Duration(seconds: 3);
  static const Duration _onlineCommitTimeout = Duration(seconds: 30);

  static Future<RecordWriteResult> commitBatch(WriteBatch batch) async {
    final online = await ConnectivityHelper.isOnline();

    if (!online) {
      return _commitWhileOffline(batch);
    }

    try {
      await batch.commit().timeout(_onlineCommitTimeout);
      return const RecordWriteResult(success: true);
    } on TimeoutException {
      if (!await ConnectivityHelper.isOnline()) {
        return const RecordWriteResult(success: true, pendingSync: true);
      }
      debugPrint('Firestore batch commit timed out while online');
      return const RecordWriteResult(success: false);
    } catch (e, st) {
      debugPrint('Firestore batch commit error: $e\n$st');
      return const RecordWriteResult(success: false);
    }
  }

  static Future<RecordWriteResult> _commitWhileOffline(WriteBatch batch) async {
    try {
      await batch.commit().timeout(_offlineCommitTimeout);
      return const RecordWriteResult(success: true, pendingSync: true);
    } on TimeoutException {
      // Writes are usually queued locally even when the Future does not resolve.
      return const RecordWriteResult(success: true, pendingSync: true);
    } catch (e, st) {
      debugPrint('Firestore offline batch commit error: $e\n$st');
      return const RecordWriteResult(success: false);
    }
  }
}

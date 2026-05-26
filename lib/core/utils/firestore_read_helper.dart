import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'connectivity_helper.dart';

/// Firestore reads that work when the device has no network connection.
class FirestoreReadHelper {
  FirestoreReadHelper._();

  /// Fetches a query, preferring the server when online and local cache when offline.
  static Future<QuerySnapshot<Map<String, dynamic>>> getQuery(
    Query<Map<String, dynamic>> query,
  ) async {
    if (await ConnectivityHelper.isOnline()) {
      try {
        return await query.get();
      } catch (e) {
        debugPrint('Firestore query failed, using cache: $e');
      }
    }
    return query.get(const GetOptions(source: Source.cache));
  }

  /// Fetches a document, preferring server when online and cache when offline.
  static Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    if (await ConnectivityHelper.isOnline()) {
      try {
        return await reference.get();
      } catch (e) {
        debugPrint('Firestore document fetch failed, using cache: $e');
      }
    }
    return reference.get(const GetOptions(source: Source.cache));
  }
}

import 'package:connectivity_plus/connectivity_plus.dart';

/// Lightweight connectivity check for offline-first Firestore writes.
class ConnectivityHelper {
  ConnectivityHelper._();

  static final Connectivity _connectivity = Connectivity();

  static Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }
}

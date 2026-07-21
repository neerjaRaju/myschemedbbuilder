import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper over `connectivity_plus` exposing a simple online/offline
/// boolean and a change stream.
///
/// Note: connectivity only reports whether a network *interface* exists, not
/// whether the internet is actually reachable. The app treats any non-`none`
/// interface as "online" and relies on the download itself to surface real
/// failures.
class ConnectivityService {
  const ConnectivityService._();

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  /// Current connectivity status.
  static Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return _isOnline(results);
  }

  /// Emits `true` when a network interface becomes available and `false`
  /// when the device goes offline.
  static Stream<bool> onStatusChange() =>
      Connectivity().onConnectivityChanged.map(_isOnline);
}

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true; // optimistic default until first check
  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    // Perform an immediate check
    final results = await _connectivity.checkConnectivity();
    _update(results);

    // Then stream changes
    _subscription = _connectivity.onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online != _isOnline) {
      _isOnline = online;
      notifyListeners();
    }
  }

  /// Call this from the retry button — re-checks connectivity immediately.
  Future<void> recheck() async {
    final results = await _connectivity.checkConnectivity();
    _update(results);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

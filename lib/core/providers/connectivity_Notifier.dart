import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isOnline = true;
  bool _showRestored = false;
  bool get isOnline => _isOnline;
  bool get showRestored => _showRestored;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _timer;

  ConnectivityProvider() {
    _checkStatus();
    try {
      _subscription = Connectivity().onConnectivityChanged.listen((_) => _checkStatus());
    } catch (e) {
      debugPrint('Connectivity stream error $e');
    }
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    bool previous = _isOnline;
    bool current = false;

    try {
      final socket = await Socket.connect('8.8.8.8', 53, timeout: const Duration(seconds: 2));
      socket.destroy();
      current = true;
    } catch (_) {
      current = false;
    }

    if (previous != current) {
      _isOnline = current;
      if (current && !previous) {
        _showRestored = true;
        notifyListeners();
        Future.delayed(const Duration(seconds: 3), () {
          _showRestored = false;
          notifyListeners();
        });
      } else {
        _showRestored = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    try {
      _subscription?.cancel();
    } catch (e) {
      debugPrint('Error canceling connectivity subscription $e');
    }
    _timer?.cancel();
    super.dispose();
  }
}

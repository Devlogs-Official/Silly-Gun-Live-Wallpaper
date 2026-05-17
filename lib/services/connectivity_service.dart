import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../core/app_logger.dart';

enum InternetTransport { none, wifi, mobile, other }

class ConnectivityService extends ChangeNotifier {
  ConnectivityService({
    Connectivity? connectivity,
    InternetConnectionChecker? internetChecker,
  })  : _connectivity = connectivity ?? Connectivity(),
        _internetChecker = internetChecker ?? InternetConnectionChecker.instance;

  final Connectivity _connectivity;
  final InternetConnectionChecker _internetChecker;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<InternetConnectionStatus>? _internetSubscription;

  bool _hasInternet = false;
  InternetTransport _transport = InternetTransport.none;
  bool _isInitialized = false;

  bool get hasInternet => _hasInternet;
  bool get isInitialized => _isInitialized;
  bool get isOffline => !_hasInternet;
  InternetTransport get transport => _transport;
  bool get isWifi => _transport == InternetTransport.wifi;
  bool get isMobile => _transport == InternetTransport.mobile;

  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    final hasConnection = await _internetChecker.hasConnection;
    _applyState(results, hasConnection, notify: false);

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) async {
      final hasConnection = await _internetChecker.hasConnection;
      _applyState(results, hasConnection);
    });

    _internetSubscription = _internetChecker.onStatusChange.listen((status) async {
      final results = await _connectivity.checkConnectivity();
      _applyState(results, status == InternetConnectionStatus.connected);
    });

    _isInitialized = true;
    _notifySafely();
  }

  Future<bool> refresh() async {
    final results = await _connectivity.checkConnectivity();
    final hasConnection = await _internetChecker.hasConnection;
    _applyState(results, hasConnection);
    return _hasInternet;
  }

  void _applyState(
    List<ConnectivityResult> results,
    bool hasConnection, {
    bool notify = true,
  }) {
    final nextTransport = _transportFrom(results);
    final nextHasInternet =
        hasConnection && nextTransport != InternetTransport.none;

    if (_transport == nextTransport &&
        _hasInternet == nextHasInternet &&
        _isInitialized) {
      return;
    }

    _transport = nextTransport;
    _hasInternet = nextHasInternet;
    AppLogger.connectivity(
      'Connectivity changed',
      data: {'transport': _transport.name, 'internet': _hasInternet},
    );

    if (notify) _notifySafely();
  }

  InternetTransport _transportFrom(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) return InternetTransport.none;
    if (results.contains(ConnectivityResult.wifi)) return InternetTransport.wifi;
    if (results.contains(ConnectivityResult.mobile)) {
      return InternetTransport.mobile;
    }
    if (results.isEmpty) return InternetTransport.none;
    return InternetTransport.other;
  }

  void _notifySafely() {
    if (hasListeners) notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _internetSubscription?.cancel();
    super.dispose();
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/device_pairing_repository.dart';
import '../../../data/services/permission_service.dart';

enum DevicePairingState { searching, found, pairing, paired, failed }

final class PairingController extends ChangeNotifier {
  PairingController({
    DevicePairingRepository? repository,
    PermissionService? permissionService,
    this.debugForceArmbandFailure = false,
    this.autoSearch = true,
    DevicePairingState initialArmbandState = DevicePairingState.found,
    this.initialArmState = DevicePairingState.paired,
    bool localNetworkPermissionGranted = false,
  }) : _repository =
           repository ??
           FakeDevicePairingRepository(
             debugForceArmbandFailure: debugForceArmbandFailure,
           ),
       _permissionService = permissionService ?? const FakePermissionService(),
       armbandState = autoSearch
           ? DevicePairingState.searching
           : initialArmbandState,
       armState = initialArmState,
       _permissionGranted = localNetworkPermissionGranted {
    if (autoSearch) {
      unawaited(search());
    }
  }

  final DevicePairingRepository _repository;
  final PermissionService _permissionService;
  final bool debugForceArmbandFailure;
  final bool autoSearch;
  DevicePairingState armbandState;
  DevicePairingState armState;
  final DevicePairingState initialArmState;
  bool _permissionGranted;
  bool _busy = false;
  bool _disposed = false;

  bool get isSearching => armbandState == DevicePairingState.searching;
  bool get permissionGranted => _permissionGranted;

  Future<void> pairArm() async {
    if (_busy || armState == DevicePairingState.paired) return;
    _busy = true;
    armState = DevicePairingState.pairing;
    notifyListeners();
    try {
      await _repository.pair('arm');
      armState = DevicePairingState.paired;
    } on Object catch (error, stackTrace) {
      _logFailure('Pairing the arm failed', error, stackTrace);
      armState = DevicePairingState.failed;
    } finally {
      _busy = false;
      _notifyListenersIfAlive();
    }
  }

  Future<void> search() async {
    if (_busy) return;
    _busy = true;
    armbandState = DevicePairingState.searching;
    notifyListeners();
    try {
      final found = await _repository.searchDevices();
      armbandState = found.contains('armband')
          ? DevicePairingState.found
          : DevicePairingState.failed;
    } on Object catch (error, stackTrace) {
      _logFailure('Searching for devices failed', error, stackTrace);
      armbandState = DevicePairingState.failed;
    } finally {
      _busy = false;
      _notifyListenersIfAlive();
    }
  }

  Future<bool> requestPermissionAndPair() async {
    if (_busy || armbandState == DevicePairingState.paired) return false;
    _busy = true;
    try {
      _permissionGranted = await _permissionService
          .requestLocalNetworkPermission();
      if (!_permissionGranted) return false;
    } on Object catch (error, stackTrace) {
      _logFailure(
        'Requesting local network permission failed',
        error,
        stackTrace,
      );
      armbandState = DevicePairingState.failed;
      return false;
    } finally {
      _busy = false;
      _notifyListenersIfAlive();
    }
    await pairArmband();
    return true;
  }

  Future<void> pairArmband() async {
    if (!_permissionGranted ||
        _busy ||
        armbandState == DevicePairingState.paired) {
      return;
    }
    _busy = true;
    armbandState = DevicePairingState.pairing;
    notifyListeners();
    try {
      await _repository.pair('armband');
      armbandState = DevicePairingState.paired;
    } on Object catch (error, stackTrace) {
      _logFailure('Pairing the armband failed', error, stackTrace);
      armbandState = DevicePairingState.failed;
    } finally {
      _busy = false;
      _notifyListenersIfAlive();
    }
  }

  Future<void> tryAgain() async {
    if (!_permissionGranted) return;
    await pairArmband();
  }

  void _notifyListenersIfAlive() {
    if (!_disposed) notifyListeners();
  }

  void _logFailure(String message, Object error, StackTrace stackTrace) {
    debugPrint('$message: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';

abstract interface class DevicePairingRepository {
  Future<Set<String>> searchDevices();

  Future<void> pair(String deviceId);
}

final class FakeDevicePairingRepository implements DevicePairingRepository {
  FakeDevicePairingRepository({this.debugForceArmbandFailure = false});

  final bool debugForceArmbandFailure;

  @override
  Future<Set<String>> searchDevices() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const {'arm', 'armband'};
  }

  @override
  Future<void> pair(String deviceId) async {
    if (deviceId == 'arm') return;
    if (deviceId != 'armband') {
      throw ArgumentError.value(deviceId, 'deviceId', 'Unknown device');
    }

    await Future<void>.delayed(const Duration(seconds: 2));
    if (debugForceArmbandFailure && kDebugMode) {
      throw StateError('Debug flag forced armband pairing failure');
    }
  }
}

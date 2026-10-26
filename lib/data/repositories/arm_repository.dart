import 'dart:async';

import '../models/arm_status.dart';

abstract interface class ArmRepository {
  Stream<ArmStatus> watchStatus();

  bool get hasLinkedDevice;
}

abstract interface class ReconnectableArmRepository {
  Future<void> reconnect({required bool armband});
}

abstract interface class LinkableArmRepository {
  void setHasLinkedDevice(bool value);
}

final class FakeArmRepository
    implements ArmRepository, ReconnectableArmRepository, LinkableArmRepository {
  FakeArmRepository({
    this.forceDisconnect = false,
    this.hasDevice = true,
    this.armbandLinked = true,
    this.updateInterval = const Duration(seconds: 4),
  });

  bool forceDisconnect;
  bool hasDevice;
  bool armbandLinked;
  final Duration updateInterval;

  @override
  bool get hasLinkedDevice => hasDevice;

  @override
  void setHasLinkedDevice(bool value) {
    hasDevice = value;
    if (!value) armbandLinked = false;
  }

  @override
  Future<void> reconnect({required bool armband}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    forceDisconnect = false;
    hasDevice = true;
    if (armband) armbandLinked = true;
  }

  @override
  Stream<ArmStatus> watchStatus() async* {
    var cycle = 0;
    while (true) {
      final now = DateTime.now();
      final connected = !forceDisconnect && hasDevice;
      final gesture = cycle == 0 ? 3 : switch ((cycle - 1) % 8) {
        0 => 0,
        1 => 1,
        2 => 2,
        3 => 3,
        4 => 4,
        5 => 5,
        _ => null,
      };
      yield ArmStatus(
        connection: connected
            ? ArmConnection.connected
            : ArmConnection.disconnected,
        armbandLinked: connected && armbandLinked,
        activeGesture: connected ? gesture : null,
        signalConfidence: connected ? .96 : 0,
        armBattery: 82,
        armbandBattery: 64,
        lastSignalAt: connected ? now : null,
        lastSeenAt: now.subtract(const Duration(minutes: 1)),
      );
      cycle++;
      await Future<void>.delayed(updateInterval);
    }
  }
}

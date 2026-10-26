enum ArmConnection { connected, connecting, disconnected }

class ArmStatus {
  const ArmStatus({
    required this.connection,
    required this.armbandLinked,
    required this.activeGesture,
    required this.signalConfidence,
    required this.armBattery,
    required this.armbandBattery,
    required this.lastSignalAt,
    required this.lastSeenAt,
  }) : assert(signalConfidence >= 0 && signalConfidence <= 1),
       assert(armBattery == null || (armBattery >= 0 && armBattery <= 100)),
       assert(
         armbandBattery == null ||
             (armbandBattery >= 0 && armbandBattery <= 100),
       );

  final ArmConnection connection;
  final bool armbandLinked;
  final int? activeGesture;
  final double signalConfidence;
  final int? armBattery;
  final int? armbandBattery;
  final DateTime? lastSignalAt;
  final DateTime? lastSeenAt;
}

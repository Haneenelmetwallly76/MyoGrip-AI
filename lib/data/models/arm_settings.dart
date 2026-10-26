enum SensitivityLevel { low, medium, high }

class ArmSettings {
  const ArmSettings({
    required this.sensitivity,
    required this.hapticEnabled,
    required this.enabledGrips,
    this.pendingKeys = const {},
  });

  final SensitivityLevel sensitivity;
  final bool hapticEnabled;
  final Set<int> enabledGrips;
  final Set<String> pendingKeys;

  ArmSettings copyWith({
    SensitivityLevel? sensitivity,
    bool? hapticEnabled,
    Set<int>? enabledGrips,
    Set<String>? pendingKeys,
  }) => ArmSettings(
    sensitivity: sensitivity ?? this.sensitivity,
    hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    enabledGrips: enabledGrips ?? this.enabledGrips,
    pendingKeys: pendingKeys ?? this.pendingKeys,
  );
}

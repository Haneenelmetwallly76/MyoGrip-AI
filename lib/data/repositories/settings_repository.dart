import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/arm_settings.dart';

abstract interface class SettingsRepository {
  Future<ArmSettings> getSettings();

  Stream<ArmSettings> watch();

  Future<void> setSensitivity(SensitivityLevel level);

  Future<void> setHaptics(bool enabled);

  Future<void> setGripEnabled(int index, bool enabled);
}

final class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({
    this.latency = const Duration(milliseconds: 400),
    this.forceFailure = false,
  }) : _settings = const ArmSettings(
         sensitivity: SensitivityLevel.medium,
         hapticEnabled: true,
         enabledGrips: {0, 1, 3, 4, 5, 6, 7, 8},
       );

  final Duration latency;
  bool forceFailure;
  ArmSettings _settings;
  final StreamController<ArmSettings> _updates =
      StreamController<ArmSettings>.broadcast();

  static const initialEnabledGrips = {0, 1, 3, 4, 5, 6, 7, 8};

  @override
  Future<ArmSettings> getSettings() async {
    await Future<void>.delayed(latency);
    return _settings;
  }

  @override
  Stream<ArmSettings> watch() async* {
    yield _settings;
    yield* _updates.stream;
  }

  @override
  Future<void> setSensitivity(SensitivityLevel level) async {
    await _save(
      (settings) => settings.copyWith(sensitivity: level),
      'Could not save sensitivity',
    );
  }

  @override
  Future<void> setHaptics(bool enabled) async {
    await _save(
      (settings) => settings.copyWith(hapticEnabled: enabled),
      'Could not save haptic feedback',
    );
  }

  @override
  Future<void> setGripEnabled(int index, bool enabled) async {
    if (index < 0 || index > 9) {
      throw RangeError.range(index, 0, 9, 'index');
    }
    await _save((settings) {
      final grips = {...settings.enabledGrips};
      enabled ? grips.add(index) : grips.remove(index);
      return settings.copyWith(enabledGrips: grips);
    }, 'Could not save grip $index');
  }

  Future<void> _save(
    ArmSettings Function(ArmSettings) update,
    String message,
  ) async {
    await Future<void>.delayed(latency);
    if (forceFailure) throw StateError(message);
    _settings = update(_settings);
    _updates.add(_settings);
  }

  @visibleForTesting
  void dispose() => _updates.close();
}

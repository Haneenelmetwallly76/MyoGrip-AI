import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../data/models/arm_settings.dart';
import '../../../data/repositories/arm_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/models/arm_status.dart';
import '../../home/application/home_providers.dart';
import 'settings_providers.dart';

// TODO: Confirm the hardware/API sensitivity threshold mapping.
const sensitivityValues = {
  SensitivityLevel.low: 25,
  SensitivityLevel.medium: 50,
  SensitivityLevel.high: 75,
};

enum SettingsChangeResult { saved, pending, failed }

final class SettingsController extends ChangeNotifier {
  SettingsController({
    required this.settingsRepository,
    required this.armRepository,
  });

  static const sensitivityKey = 'sensitivity';
  static const hapticsKey = 'haptics';

  final SettingsRepository settingsRepository;
  final ArmRepository armRepository;
  final Map<String, int> _versions = {};
  final Set<String> _savingKeys = {};
  StreamSubscription<ArmStatus>? _connectionSubscription;
  StreamSubscription<ArmSettings>? _settingsSubscription;
  ArmSettings _settings = const ArmSettings(
    sensitivity: SensitivityLevel.medium,
    hapticEnabled: true,
    enabledGrips: FakeSettingsRepository.initialEnabledGrips,
  );
  bool _connected = false;
  bool _initialized = false;
  bool _syncing = false;
  bool _disposed = false;

  ArmSettings get settings => _settings;
  bool get isConnected => _connected;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    _settingsSubscription = settingsRepository.watch().listen(
      _onRepositorySettings,
      onError: _logError,
    );
    _connectionSubscription = armRepository.watchStatus().listen((status) {
      final wasConnected = _connected;
      _connected = status.connection == ArmConnection.connected;
      _notifyIfAlive();
      if (!wasConnected && _connected) unawaited(_syncPending());
    }, onError: _logError);
    try {
      final savedSettings = await settingsRepository.getSettings();
      final enabledGrips = {...savedSettings.enabledGrips};
      for (final key in _versions.keys.where((key) => key.startsWith('grip:'))) {
        final index = int.parse(key.substring('grip:'.length));
        _settings.enabledGrips.contains(index)
            ? enabledGrips.add(index)
            : enabledGrips.remove(index);
      }
      _settings = savedSettings.copyWith(
        sensitivity: (_versions[sensitivityKey] ?? 0) > 0
            ? _settings.sensitivity
            : savedSettings.sensitivity,
        hapticEnabled: (_versions[hapticsKey] ?? 0) > 0
            ? _settings.hapticEnabled
            : savedSettings.hapticEnabled,
        enabledGrips: enabledGrips,
        pendingKeys: _settings.pendingKeys,
      );
      _initialized = true;
      _notifyIfAlive();
    } on Object catch (error, stackTrace) {
      _logError(error, stackTrace);
      _initialized = true;
      _notifyIfAlive();
    }
  }

  void _onRepositorySettings(ArmSettings settings) {
    var next = settings.copyWith(pendingKeys: _settings.pendingKeys);
    for (final key in _savingKeys) {
      next = _restoreKey(next, _settings, key);
    }
    for (final key in _settings.pendingKeys) {
      next = _restoreKey(next, _settings, key);
    }
    _settings = next;
    _notifyIfAlive();
  }

  Future<SettingsChangeResult> setSensitivity(SensitivityLevel sensitivity) =>
      _change(
        key: sensitivityKey,
        apply: (settings) => settings.copyWith(sensitivity: sensitivity),
        save: () => settingsRepository.setSensitivity(sensitivity),
      );

  Future<SettingsChangeResult> setHaptics(bool enabled) => _change(
    key: hapticsKey,
    apply: (settings) => settings.copyWith(hapticEnabled: enabled),
    save: () => settingsRepository.setHaptics(enabled),
  );

  Future<SettingsChangeResult> setGripEnabled(int index, bool enabled) {
    if (index < 0 || index > 9) {
      throw RangeError.range(index, 0, 9, 'index');
    }
    if (_settings.enabledGrips.contains(index) &&
        !enabled &&
        _settings.enabledGrips.length == 1) {
      return Future.value(SettingsChangeResult.failed);
    }
    return _change(
      key: 'grip:$index',
      apply: (settings) {
        final grips = {...settings.enabledGrips};
        enabled ? grips.add(index) : grips.remove(index);
        return settings.copyWith(enabledGrips: grips);
      },
      save: () => settingsRepository.setGripEnabled(index, enabled),
    );
  }

  Future<SettingsChangeResult> _change({
    required String key,
    required ArmSettings Function(ArmSettings) apply,
    required Future<void> Function() save,
  }) async {
    final previous = _settings;
    final version = (_versions[key] ?? 0) + 1;
    _versions[key] = version;
    final pending = {..._settings.pendingKeys};
    if (!_connected) {
      pending.add(key);
    } else {
      pending.remove(key);
    }
    _settings = apply(_settings).copyWith(pendingKeys: pending);
    if (!_connected) {
      _notifyIfAlive();
      return SettingsChangeResult.pending;
    }
    _savingKeys.add(key);
    _notifyIfAlive();
    try {
      await save();
      if (_versions[key] != version) return SettingsChangeResult.saved;
      final pendingKeys = {..._settings.pendingKeys};
      if (_connected) {
        pendingKeys.remove(key);
      } else {
        pendingKeys.add(key);
      }
      _settings = _settings.copyWith(pendingKeys: pendingKeys);
      _notifyIfAlive();
      return SettingsChangeResult.saved;
    } on Object catch (error, stackTrace) {
      _logError(error, stackTrace);
      if (_versions[key] == version) {
        final restoredPending = {..._settings.pendingKeys}
          ..remove(key)
          ..addAll(
            previous.pendingKeys.where((pendingKey) => pendingKey == key),
          );
        _settings = _restoreKey(
          _settings,
          previous,
          key,
        ).copyWith(pendingKeys: restoredPending);
        _notifyIfAlive();
      }
      return SettingsChangeResult.failed;
    } finally {
      if (_versions[key] == version) _savingKeys.remove(key);
    }
  }

  ArmSettings _restoreKey(
    ArmSettings current,
    ArmSettings previous,
    String key,
  ) {
    if (key == sensitivityKey) {
      return current.copyWith(sensitivity: previous.sensitivity);
    }
    if (key == hapticsKey) {
      return current.copyWith(hapticEnabled: previous.hapticEnabled);
    }
    final index = int.parse(key.substring('grip:'.length));
    final grips = {...current.enabledGrips};
    previous.enabledGrips.contains(index)
        ? grips.add(index)
        : grips.remove(index);
    return current.copyWith(enabledGrips: grips);
  }

  Future<void> _syncPending() async {
    if (_syncing || !_connected) return;
    _syncing = true;
    try {
      for (final key in _settings.pendingKeys.toList()) {
        final version = _versions[key] ?? 0;
        try {
          if (key == sensitivityKey) {
            await settingsRepository.setSensitivity(_settings.sensitivity);
          } else if (key == hapticsKey) {
            await settingsRepository.setHaptics(_settings.hapticEnabled);
          } else if (key.startsWith('grip:')) {
            final index = int.parse(key.substring('grip:'.length));
            await settingsRepository.setGripEnabled(
              index,
              _settings.enabledGrips.contains(index),
            );
          }
          if (_connected && (_versions[key] ?? 0) == version) {
            _settings = _settings.copyWith(
              pendingKeys: {..._settings.pendingKeys}..remove(key),
            );
            _notifyIfAlive();
          }
        } on Object catch (error, stackTrace) {
          _logError(error, stackTrace);
        }
      }
    } finally {
      _syncing = false;
    }
  }

  void _logError(Object error, StackTrace stackTrace) {
    debugPrint('Settings operation failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  void _notifyIfAlive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_connectionSubscription?.cancel());
    unawaited(_settingsSubscription?.cancel());
    super.dispose();
  }
}

final settingsControllerProvider = ChangeNotifierProvider<SettingsController>((
  ref,
) {
  final controller = SettingsController(
    settingsRepository: ref.watch(settingsRepositoryProvider),
    armRepository: ref.watch(armRepositoryProvider),
  );
  unawaited(controller.initialize());
  return controller;
});

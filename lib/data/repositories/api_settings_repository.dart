import 'dart:async';

import '../api/api_client.dart';
import '../models/arm_settings.dart';
import 'auth_repository.dart';
import 'settings_repository.dart';

final class ApiSettingsRepository implements SettingsRepository {
  ApiSettingsRepository({
    required ApiClient client,
    required SessionTokenStore sessionTokenStore,
  }) : _apiClient = client,
       _tokenStore = sessionTokenStore;

  final ApiClient _apiClient;
  final SessionTokenStore _tokenStore;
  final StreamController<ArmSettings> _updates =
      StreamController<ArmSettings>.broadcast();
  ArmSettings _settings = const ArmSettings(
    sensitivity: SensitivityLevel.medium,
    hapticEnabled: true,
    enabledGrips: FakeSettingsRepository.initialEnabledGrips,
  );
  Future<void> _writeQueue = Future<void>.value();

  @override
  Future<ArmSettings> getSettings() async {
    try {
      final response = await _apiClient.get(
        '/api/prosthetic/settings',
        accessToken: await _accessToken(),
      );
      _settings = _settingsFromJson(response);
    } on ApiException catch (error) {
      if (error.code != 'SETTINGS_NOT_FOUND') rethrow;
    }
    _updates.add(_settings);
    return _settings;
  }

  @override
  Stream<ArmSettings> watch() async* {
    yield _settings;
    yield* _updates.stream;
  }

  @override
  Future<void> setSensitivity(SensitivityLevel level) =>
      _save((settings) => settings.copyWith(sensitivity: level));

  @override
  Future<void> setHaptics(bool enabled) =>
      _save((settings) => settings.copyWith(hapticEnabled: enabled));

  @override
  Future<void> setGripEnabled(int index, bool enabled) {
    if (index < 0 || index > 9) {
      throw RangeError.range(index, 0, 9, 'index');
    }
    return _save((settings) {
      final grips = {...settings.enabledGrips};
      enabled ? grips.add(index) : grips.remove(index);
      if (grips.isEmpty) {
        throw ArgumentError('At least one grip must remain enabled.');
      }
      return settings.copyWith(enabledGrips: grips);
    });
  }

  Future<void> _save(ArmSettings Function(ArmSettings) update) {
    final operation = _writeQueue.then((_) async {
      final next = update(_settings);
      final response = await _apiClient.put(
        '/api/prosthetic/settings',
        accessToken: await _accessToken(),
        body: {
          'sensitivity': sensitivityValues[next.sensitivity],
          'activeGrips': next.enabledGrips.toList()..sort(),
          'tensEnabled': next.hapticEnabled,
        },
      );
      _settings = _settingsFromJson(response);
      _updates.add(_settings);
    });
    _writeQueue = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<String> _accessToken() async {
    final token = await _tokenStore.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        code: 'UNAUTHORIZED',
        message: 'No saved session.',
      );
    }
    return token;
  }

  ArmSettings _settingsFromJson(Map<String, dynamic> json) {
    final value = (json['sensitivity'] as num).toInt();
    final sensitivity = switch (value) {
      <= 37 => SensitivityLevel.low,
      <= 62 => SensitivityLevel.medium,
      _ => SensitivityLevel.high,
    };
    final grips = (json['activeGrips'] as List<dynamic>)
        .map((value) => (value as num).toInt())
        .toSet();
    return ArmSettings(
      sensitivity: sensitivity,
      hapticEnabled: json['tensEnabled'] as bool,
      enabledGrips: grips,
    );
  }

  static const sensitivityValues = {
    SensitivityLevel.low: 25,
    SensitivityLevel.medium: 50,
    SensitivityLevel.high: 75,
  };
}

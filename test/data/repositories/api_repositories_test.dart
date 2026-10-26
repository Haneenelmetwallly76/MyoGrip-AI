import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myogrip_ai/data/api/api_client.dart';
import 'package:myogrip_ai/data/models/arm_settings.dart';
import 'package:myogrip_ai/data/repositories/api_auth_repository.dart';
import 'package:myogrip_ai/data/repositories/api_profile_repository.dart';
import 'package:myogrip_ai/data/repositories/api_settings_repository.dart';
import 'package:myogrip_ai/data/repositories/auth_repository.dart';

void main() {
  group('ApiAuthRepository', () {
    test('sign in stores the backend access token', () async {
      final tokenStore = _MemoryTokenStore();
      final repository = ApiAuthRepository(
        client: ApiClient(
          client: MockClient((request) async {
            expect(request.method, 'POST');
            expect(request.url.path, '/api/auth/login');
            expect(jsonDecode(request.body), {
              'email': 'person@example.com',
              'password': 'Password1',
            });
            return http.Response(jsonEncode({'accessToken': 'jwt-token'}), 200);
          }),
          baseUri: Uri.parse('http://localhost:5080'),
        ),
        sessionTokenStore: tokenStore,
      );

      await repository.signIn('person@example.com', 'Password1');

      expect(tokenStore.token, 'jwt-token');
    });

    test('expired saved session clears its token', () async {
      final tokenStore = _MemoryTokenStore()..token = 'expired';
      final repository = ApiAuthRepository(
        client: ApiClient(
          client: MockClient((request) async {
            expect(request.headers['authorization'], 'Bearer expired');
            return http.Response(
              jsonEncode({'code': 'UNAUTHORIZED', 'message': 'Expired'}),
              401,
            );
          }),
          baseUri: Uri.parse('http://localhost:5080'),
        ),
        sessionTokenStore: tokenStore,
      );

      expect(await repository.restoreSession(), isFalse);
      expect(tokenStore.token, isNull);
    });
  });

  test(
    'profile repository reads and updates authenticated profile data',
    () async {
      final requests = <http.Request>[];
      final repository = ApiProfileRepository(
        client: ApiClient(
          client: MockClient((request) async {
            requests.add(request);
            if (request.method == 'GET') {
              return http.Response(
                jsonEncode({
                  'fullName': 'Alex Patient',
                  'age': 34,
                  'email': 'alex@example.com',
                  'clinicCode': 'QA-1024',
                  'clinician': {'name': 'Dr. Clinic'},
                }),
                200,
              );
            }
            return http.Response('{}', 200);
          }),
          baseUri: Uri.parse('http://localhost:5080'),
        ),
        sessionTokenStore: _MemoryTokenStore()..token = 'jwt-token',
      );

      final profile = await repository.getProfile();
      await repository.updateProfile(
        profile.copyWith(name: 'Alex Updated', age: 35),
      );

      expect(profile.clinicCode, 'QA-1024');
      expect(profile.clinicianName, 'Dr. Clinic');
      expect(requests[0].headers['authorization'], 'Bearer jwt-token');
      expect(requests[1].method, 'PUT');
      expect(jsonDecode(requests[1].body), {
        'fullName': 'Alex Updated',
        'age': 35,
        'email': 'alex@example.com',
      });
    },
  );

  test('settings repository loads defaults and persists changes', () async {
    final requests = <http.Request>[];
    final repository = ApiSettingsRepository(
      client: ApiClient(
        client: MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'code': 'SETTINGS_NOT_FOUND',
                'message': 'No configuration yet.',
              }),
              404,
            );
          }
          return http.Response(
            jsonEncode({
              'sensitivity': 75,
              'activeGrips': [0, 1, 3, 4, 5, 6, 7, 8],
              'tensEnabled': false,
            }),
            200,
          );
        }),
        baseUri: Uri.parse('http://localhost:5080'),
      ),
      sessionTokenStore: _MemoryTokenStore()..token = 'jwt-token',
    );

    final defaults = await repository.getSettings();
    expect(defaults.sensitivity, SensitivityLevel.medium);
    expect(defaults.hapticEnabled, isTrue);

    await repository.setSensitivity(SensitivityLevel.high);

    expect(requests[1].method, 'PUT');
    expect(jsonDecode(requests[1].body), {
      'sensitivity': 75,
      'activeGrips': [0, 1, 3, 4, 5, 6, 7, 8],
      'tensEnabled': true,
    });
    expect((await repository.getSettings()).sensitivity, SensitivityLevel.high);
  });
}

final class _MemoryTokenStore implements ClearableSessionTokenStore {
  String? token;

  @override
  Future<void> clearToken() async {
    token = null;
  }

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async {
    token = value;
  }
}

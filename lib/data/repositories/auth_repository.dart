import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class AuthRepository {
  Future<bool> restoreSession();

  Future<void> signIn(String email, String password);

  Future<void> sendPasswordResetLink(String email);

  Future<void> register({
    required String fullName,
    required int age,
    required String email,
    required String password,
    required String clinicCode,
  });

  Future<bool> isEmailAvailable(String email);

  Future<bool> isClinicCodeValid(String clinicCode);

  bool get hasLinkedDevice;
}

abstract interface class SessionTokenStore {
  Future<String?> readToken();

  Future<void> writeToken(String token);
}

abstract interface class ClearableSessionTokenStore
    implements SessionTokenStore {
  Future<void> clearToken();
}

final class FlutterSecureSessionTokenStore
    implements ClearableSessionTokenStore {
  FlutterSecureSessionTokenStore() : _storage = const FlutterSecureStorage();

  static const _tokenKey = 'session_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}

final class AuthNetworkException implements Exception {
  const AuthNetworkException();
}

final class AuthCredentialsException implements Exception {
  const AuthCredentialsException();
}

final class AuthEmailTakenException implements Exception {
  const AuthEmailTakenException();
}

final class AuthClinicCodeException implements Exception {
  const AuthClinicCodeException();
}

final class AuthFeatureUnavailableException implements Exception {
  const AuthFeatureUnavailableException();
}

final class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    SessionTokenStore? tokenStore,
    this.forceNetworkFailure = false,
    this.responseDelay = const Duration(seconds: 1),
  }) : _tokenStore = tokenStore ?? FlutterSecureSessionTokenStore();

  final SessionTokenStore _tokenStore;
  bool forceNetworkFailure;
  final Duration responseDelay;

  @override
  bool get hasLinkedDevice => false;

  @override
  Future<bool> isEmailAvailable(String email) async {
    if (forceNetworkFailure) throw const AuthNetworkException();
    return email.trim().toLowerCase() != 'taken@example.com';
  }

  @override
  Future<bool> isClinicCodeValid(String clinicCode) async {
    if (forceNetworkFailure) throw const AuthNetworkException();
    return clinicCode.trim() == 'CLINIC1';
  }

  @override
  Future<bool> restoreSession() async {
    if (forceNetworkFailure) throw const AuthNetworkException();
    return (await _tokenStore.readToken()) != null;
  }

  @override
  Future<void> signIn(String email, String password) async {
    await Future<void>.delayed(responseDelay);
    if (forceNetworkFailure) throw const AuthNetworkException();
    if (email.trim() != 'test@example.com' || password != 'Passw0rd1') {
      throw const AuthCredentialsException();
    }
    await _tokenStore.writeToken('fake-session-token');
  }

  @override
  Future<void> sendPasswordResetLink(String email) async {
    await Future<void>.delayed(responseDelay);
    if (forceNetworkFailure) throw const AuthNetworkException();
  }

  @override
  Future<void> register({
    required String fullName,
    required int age,
    required String email,
    required String password,
    required String clinicCode,
  }) async {
    await Future<void>.delayed(responseDelay);
    if (forceNetworkFailure) throw const AuthNetworkException();
    if (email.trim().toLowerCase() == 'taken@example.com') {
      throw const AuthEmailTakenException();
    }
    if (clinicCode.trim() != 'CLINIC1') {
      throw const AuthClinicCodeException();
    }
    await _tokenStore.writeToken('fake-registration-session-token');
  }
}

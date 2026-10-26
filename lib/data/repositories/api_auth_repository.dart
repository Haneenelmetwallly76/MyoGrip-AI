import '../api/api_client.dart';
import 'auth_repository.dart';

final class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required ApiClient client,
    required SessionTokenStore sessionTokenStore,
  }) : _apiClient = client,
       _tokenStore = sessionTokenStore;

  final ApiClient _apiClient;
  final SessionTokenStore _tokenStore;

  @override
  bool get hasLinkedDevice => false;

  @override
  Future<bool> restoreSession() async {
    final token = await _tokenStore.readToken();
    if (token == null || token.isEmpty) return false;
    try {
      await _apiClient.get('/api/user/profile', accessToken: token);
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        if (_tokenStore case final ClearableSessionTokenStore clearable) {
          await clearable.clearToken();
        }
        return false;
      }
      throw const AuthNetworkException();
    } on ApiConnectionException {
      throw const AuthNetworkException();
    }
  }

  @override
  Future<void> signIn(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/api/auth/login',
        body: {'email': email, 'password': password},
      );
      final token = response['accessToken'];
      if (token is! String || token.isEmpty) {
        throw const FormatException('Login response did not include a token.');
      }
      await _tokenStore.writeToken(token);
    } on ApiException catch (error) {
      if (error.code == 'INVALID_CREDENTIALS' || error.statusCode == 401) {
        throw const AuthCredentialsException();
      }
      throw const AuthNetworkException();
    } on ApiConnectionException {
      throw const AuthNetworkException();
    } on FormatException {
      throw const AuthNetworkException();
    }
  }

  @override
  Future<void> register({
    required String fullName,
    required int age,
    required String email,
    required String password,
    required String clinicCode,
  }) async {
    try {
      await _apiClient.post(
        '/api/auth/register',
        body: {
          'fullName': fullName,
          'age': age,
          'email': email,
          'password': password,
          'clinicCode': clinicCode,
        },
      );
      await signIn(email, password);
    } on ApiException catch (error) {
      if (error.code == 'EMAIL_EXISTS') {
        throw const AuthEmailTakenException();
      }
      if (error.code == 'INVALID_CLINIC_CODE') {
        throw const AuthClinicCodeException();
      }
      throw const AuthNetworkException();
    } on ApiConnectionException {
      throw const AuthNetworkException();
    } on AuthCredentialsException {
      throw const AuthNetworkException();
    } on FormatException {
      throw const AuthNetworkException();
    }
  }

  // The backend validates availability when registration is submitted.
  @override
  Future<bool> isEmailAvailable(String email) async => true;

  // Clinic-code preflight is not exposed by the current API.
  @override
  Future<bool> isClinicCodeValid(String clinicCode) async => true;

  @override
  Future<void> sendPasswordResetLink(String email) =>
      throw const AuthFeatureUnavailableException();
}

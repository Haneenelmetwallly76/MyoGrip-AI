import '../api/api_client.dart';
import '../models/profile.dart';
import 'auth_repository.dart';
import 'profile_repository.dart';

final class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository({
    required ApiClient client,
    required SessionTokenStore sessionTokenStore,
  }) : _apiClient = client,
       _tokenStore = sessionTokenStore;

  final ApiClient _apiClient;
  final SessionTokenStore _tokenStore;

  @override
  Future<Profile> getProfile() async {
    final response = await _apiClient.get(
      '/api/user/profile',
      accessToken: await _accessToken(),
    );
    return _profileFromJson(response);
  }

  @override
  Future<void> updateProfile(Profile profile) async {
    await _apiClient.put(
      '/api/user/profile',
      accessToken: await _accessToken(),
      body: {
        'fullName': profile.name,
        'age': profile.age,
        'email': profile.email,
      },
    );
  }

  // Email conflicts are returned by the profile update endpoint.
  @override
  Future<bool> isEmailAvailable(String email) async => true;

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

  Profile _profileFromJson(Map<String, dynamic> json) {
    final clinician = json['clinician'];
    return Profile(
      name: json['fullName'] as String,
      age: (json['age'] as num).toInt(),
      email: json['email'] as String,
      clinicCode: json['clinicCode'] as String?,
      clinicianName: clinician is Map<String, dynamic>
          ? clinician['name'] as String?
          : null,
    );
  }
}

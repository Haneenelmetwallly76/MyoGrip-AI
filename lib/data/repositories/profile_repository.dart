import '../models/profile.dart';

abstract interface class ProfileRepository {
  Future<Profile> getProfile();

  Future<bool> isEmailAvailable(String email);

  Future<void> updateProfile(Profile profile);
}

final class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({
    this.latency = const Duration(milliseconds: 300),
    this.forceFailure = false,
    Profile? initialProfile,
  }) : _profile =
           initialProfile ??
           const Profile(
             name: 'Patient name',
             age: 34,
             email: 'name@example.com',
             clinicName: 'your clinic',
             clinicCode: 'CLINIC1',
             clinicianName: 'Your clinician',
           );

  final Duration latency;
  bool forceFailure;
  Profile _profile;

  @override
  Future<Profile> getProfile() async {
    await Future<void>.delayed(latency);
    if (forceFailure) throw StateError('Could not load profile');
    return _profile;
  }

  @override
  Future<void> updateProfile(Profile profile) async {
    await Future<void>.delayed(latency);
    if (forceFailure) throw StateError('Could not save profile');
    _profile = profile;
  }

  @override
  Future<bool> isEmailAvailable(String email) async {
    await Future<void>.delayed(latency);
    if (forceFailure) throw StateError('Could not check email availability');
    return email.trim().toLowerCase() == _profile.email.toLowerCase() ||
        email.trim().toLowerCase() != 'taken@example.com';
  }
}

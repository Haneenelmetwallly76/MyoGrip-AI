import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../data/models/profile.dart';
import '../../../data/models/usage_data.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/usage_repository.dart';
import 'profile_providers.dart';

enum ProfileLoadState { loading, loaded, failed }

final class ProfileController extends ChangeNotifier {
  ProfileController({
    required this._profileRepository,
    required this._usageRepository,
  });

  final ProfileRepository _profileRepository;
  final UsageRepository _usageRepository;
  Profile? profile;
  UsageData? usage;
  ProfileLoadState state = ProfileLoadState.loading;
  bool _disposed = false;

  bool get hasClinician => profile?.clinicianName != null;

  Future<void> load() async {
    state = ProfileLoadState.loading;
    _notifyIfAlive();
    try {
      final results = await Future.wait<Object>([
        _profileRepository.getProfile(),
        _usageRepository.getUsage(),
      ]);
      profile = results[0] as Profile;
      usage = results[1] as UsageData;
      state = ProfileLoadState.loaded;
    } on Object catch (error, stackTrace) {
      debugPrint('Could not load profile and usage: $error');
      debugPrintStack(stackTrace: stackTrace);
      state = ProfileLoadState.failed;
    }
    _notifyIfAlive();
  }

  void _notifyIfAlive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final profileControllerProvider = ChangeNotifierProvider<ProfileController>((
  ref,
) {
  final controller = ProfileController(
    profileRepository: ref.watch(profileRepositoryProvider),
    usageRepository: ref.watch(usageRepositoryProvider),
  );
  unawaited(controller.load());
  return controller;
});

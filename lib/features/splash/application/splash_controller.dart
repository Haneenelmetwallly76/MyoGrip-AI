import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/strings.dart';
import '../../../data/repositories/auth_repository.dart';

enum SplashDestination {
  home('/home'),
  onboarding('/onboarding/1'),
  login('/login');

  const SplashDestination(this.location);

  final String location;
}

final class SplashController {
  SplashController({
    AuthRepository? authRepository,
    Future<bool> Function()? readOnboardingDone,
    this.minimumDisplayDuration = const Duration(seconds: 2),
  }) : _authRepository = authRepository ?? FakeAuthRepository(),
       _readOnboardingDone = readOnboardingDone ?? _readSavedOnboardingDone;

  final AuthRepository _authRepository;
  final Future<bool> Function() _readOnboardingDone;
  final Duration minimumDisplayDuration;

  Future<SplashDestination> destinationAfterStartup() async {
    final minimumDisplay = Future<void>.delayed(minimumDisplayDuration);
    final destination = await _resolveDestination();
    await minimumDisplay;
    return destination;
  }

  Future<SplashDestination> _resolveDestination() async {
    try {
      if (await _authRepository.restoreSession()) {
        return SplashDestination.home;
      }
      return await _readOnboardingDone()
          ? SplashDestination.login
          : SplashDestination.onboarding;
    } on Object catch (error, stackTrace) {
      debugPrint('Could not restore the saved session: $error');
      debugPrintStack(stackTrace: stackTrace);
      return SplashDestination.login;
    }
  }

  static Future<bool> _readSavedOnboardingDone() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(AppStrings.onboardingDonePreferenceKey) ?? false;
  }
}

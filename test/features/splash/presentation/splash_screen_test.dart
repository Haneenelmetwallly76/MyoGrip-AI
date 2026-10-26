import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myogrip_ai/core/strings.dart';
import 'package:myogrip_ai/data/repositories/auth_repository.dart';
import 'package:myogrip_ai/features/splash/application/splash_controller.dart';
import 'package:myogrip_ai/features/splash/presentation/splash_screen.dart';
import 'package:myogrip_ai/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders the splash golden at 60% progress', (tester) async {
    await _loadAppFonts();
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = Completer<bool>();
    final completedLocations = <String>[];
    final controller = SplashController(
      authRepository: _FakeAuthRepository(() => session.future),
      readOnboardingDone: () async => false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SplashScreen(
          controller: controller,
          onComplete: completedLocations.add,
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/logo_mark.png'),
        tester.element(find.byType(SplashScreen)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    await expectLater(
      find.byType(SplashScreen),
      matchesGoldenFile('goldens/splash_360.png'),
    );
    tester.view.physicalSize = const Size(412, 915);
    await tester.pump();
    await expectLater(
      find.byType(SplashScreen),
      matchesGoldenFile('goldens/splash_412.png'),
    );
    expect(completedLocations, isEmpty);

    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel(AppStrings.splashSemantics), findsOneWidget);
    semantics.dispose();

    session.complete(false);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    expect(completedLocations, ['/onboarding/1']);
  });

  testWidgets('waits for both session check and two-second minimum', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = Completer<bool>();
    final completedLocations = <String>[];
    final controller = SplashController(
      authRepository: _FakeAuthRepository(() => session.future),
      readOnboardingDone: () async => false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SplashScreen(
          controller: controller,
          onComplete: completedLocations.add,
        ),
      ),
    );
    session.complete(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1999));

    expect(completedLocations, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(completedLocations, ['/onboarding/1']);
  });

  test('routes based on restored session and onboarding flag', () async {
    final validSession = SplashController(
      authRepository: _FakeAuthRepository(() async => true),
      readOnboardingDone: () async => false,
      minimumDisplayDuration: Duration.zero,
    );
    final firstLaunch = SplashController(
      authRepository: _FakeAuthRepository(() async => false),
      readOnboardingDone: () async => false,
      minimumDisplayDuration: Duration.zero,
    );
    final onboardingComplete = SplashController(
      authRepository: _FakeAuthRepository(() async => false),
      readOnboardingDone: () async => true,
      minimumDisplayDuration: Duration.zero,
    );
    final failedSession = SplashController(
      authRepository: _FakeAuthRepository(
        () async => throw StateError('offline'),
      ),
      readOnboardingDone: () async => false,
      minimumDisplayDuration: Duration.zero,
    );

    expect(
      await validSession.destinationAfterStartup(),
      SplashDestination.home,
    );
    expect(
      await firstLaunch.destinationAfterStartup(),
      SplashDestination.onboarding,
    );
    expect(
      await onboardingComplete.destinationAfterStartup(),
      SplashDestination.login,
    );
    expect(
      await failedSession.destinationAfterStartup(),
      SplashDestination.login,
    );
  });
}

class _FakeAuthRepository implements AuthRepository {
  const _FakeAuthRepository(this.restore);

  final Future<bool> Function() restore;

  @override
  Future<bool> restoreSession() => restore();

  @override
  Future<void> signIn(String email, String password) async {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetLink(String email) async {
    throw UnimplementedError();
  }

  @override
  Future<void> register({
    required String fullName,
    required int age,
    required String email,
    required String password,
    required String clinicCode,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> isEmailAvailable(String email) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> isClinicCodeValid(String clinicCode) async {
    throw UnimplementedError();
  }

  @override
  bool get hasLinkedDevice => false;
}

Future<void> _loadAppFonts() async {
  final fontFiles = <String, String>{
    'SourceSans3': 'assets/fonts/SourceSans3-Variable.ttf',
    'SourceSerif4': 'assets/fonts/SourceSerif4-Variable.ttf',
  };
  for (final entry in fontFiles.entries) {
    await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value))).load();
  }
}

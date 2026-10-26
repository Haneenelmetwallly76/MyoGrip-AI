import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:myogrip_ai/core/strings.dart';
import 'package:myogrip_ai/data/repositories/device_pairing_repository.dart';
import 'package:myogrip_ai/features/onboarding/application/pairing_controller.dart';
import 'package:myogrip_ai/features/onboarding/presentation/device_row.dart';
import 'package:myogrip_ai/features/onboarding/presentation/onboarding_step3_screen.dart';
import 'package:myogrip_ai/theme.dart';
import 'package:myogrip_ai/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('matches the found and paired state golden at 360x800', (
    tester,
  ) async {
    await _loadAppFonts();
    await _setViewport(tester);
    final controller = PairingController(autoSearch: false);
    addTearDown(controller.dispose);

    await _pumpStep(tester, controller);
    await expectLater(
      find.byType(OnboardingStep3Screen),
      matchesGoldenFile('goldens/onboarding_step3_found_360.png'),
    );
    tester.view.physicalSize = const Size(412, 915);
    await tester.pump();
    await expectLater(
      find.byType(OnboardingStep3Screen),
      matchesGoldenFile('goldens/onboarding_step3_found_412.png'),
    );

    final semantics = tester.ensureSemantics();
    await tester.pump();
    expect(
      find.bySemanticsLabel(AppStrings.onboardingDevicePairedSemantics),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('matches the pairing state golden at 360x800', (tester) async {
    await _loadAppFonts();
    await _setViewport(tester);
    final controller = PairingController(
      autoSearch: false,
      localNetworkPermissionGranted: true,
    );
    addTearDown(controller.dispose);

    await _pumpStep(tester, controller);
    await tester.tap(find.text(AppStrings.onboardingDevicePair));
    await tester.pump();
    await expectLater(
      find.byType(OnboardingStep3Screen),
      matchesGoldenFile('goldens/onboarding_step3_pairing_360.png'),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
  });

  testWidgets('matches the failed state golden at 360x800', (tester) async {
    await _loadAppFonts();
    await _setViewport(tester);
    final controller = PairingController(
      autoSearch: false,
      localNetworkPermissionGranted: true,
      repository: FakeDevicePairingRepository(debugForceArmbandFailure: true),
    );
    addTearDown(controller.dispose);

    await _pumpStep(tester, controller);
    await tester.tap(find.text(AppStrings.onboardingDevicePair));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await expectLater(
      find.byType(OnboardingStep3Screen),
      matchesGoldenFile('goldens/onboarding_step3_failed_360.png'),
    );
  });

  testWidgets('searching state hides rows and shows the status line', (
    tester,
  ) async {
    await _setViewport(tester);
    final controller = PairingController(
      autoSearch: false,
      initialArmbandState: DevicePairingState.searching,
    );
    addTearDown(controller.dispose);

    await _pumpStep(tester, controller);
    expect(find.text(AppStrings.onboardingDeviceSearching), findsOneWidget);
    expect(find.byType(DeviceRow), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('step 3 controls fit at 130% text scale', (tester) async {
    await _setViewport(tester);
    final controller = PairingController(autoSearch: false);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: OnboardingStep3Screen(
            onBack: () {},
            onFinish: () {},
            onSkip: () {},
            pairingController: controller,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.onboardingFinish), findsOneWidget);
    expect(find.text(AppStrings.onboardingStep3Title), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text(AppStrings.onboardingDevicePair));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.onboardingPermissionContinue), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'permission explanation gates pairing, Finish and Skip complete',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _setViewport(tester);
      await tester.pumpWidget(const app.MyoGripApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.onboardingNext));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.onboardingNext));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      expect(find.text(AppStrings.onboardingStep3Title), findsOneWidget);

      await tester.tap(find.text(AppStrings.onboardingDevicePair));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.onboardingPermissionReason), findsOneWidget);

      await tester.tap(find.text(AppStrings.onboardingPermissionNotNow));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.onboardingDevicePair), findsOneWidget);

      await tester.tap(find.text(AppStrings.onboardingDevicePair));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.onboardingPermissionContinue));
      await tester.pump();
      expect(find.text(AppStrings.onboardingDevicePairing), findsOneWidget);
      await tester.tap(find.text(AppStrings.onboardingFinish));
      await tester.pumpAndSettle();
      expect(find.text('Sign in').first, findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(tester.takeException(), isNull);
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getBool(AppStrings.onboardingDonePreferenceKey),
        isTrue,
      );
    },
  );

  test('fake repository pairs the arm and delays armband pairing', () async {
    final repository = FakeDevicePairingRepository();
    final stopwatch = Stopwatch()..start();
    await repository.pair('arm');
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));

    await repository.pair('armband');
    expect(stopwatch.elapsed, greaterThanOrEqualTo(const Duration(seconds: 2)));
  });
}

Future<void> _setViewport(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(360, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpStep(
  WidgetTester tester,
  PairingController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: OnboardingStep3Screen(
        onBack: () {},
        onFinish: () {},
        onSkip: () {},
        pairingController: controller,
      ),
    ),
  );
  for (final asset in [
    'assets/images/device_arm.png',
    'assets/images/device_armband.png',
  ]) {
    await tester.runAsync(
      () => precacheImage(
        AssetImage(asset),
        tester.element(find.byType(OnboardingStep3Screen)),
      ),
    );
  }
  await tester.pump();
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

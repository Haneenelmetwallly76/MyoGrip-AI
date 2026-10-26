import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:myogrip_ai/core/strings.dart';
import 'package:myogrip_ai/features/onboarding/presentation/onboarding_step1_screen.dart';
import 'package:myogrip_ai/features/onboarding/presentation/onboarding_step_scaffold.dart';
import 'package:myogrip_ai/main.dart' as app;
import 'package:myogrip_ai/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('matches the onboarding step 1 golden at 360x800', (
    tester,
  ) async {
    await _loadAppFonts();
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OnboardingStep1Screen(
          onBack: () {},
          onNext: () {},
          onSkip: () {},
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/onboarding_step1.png'),
        tester.element(find.byType(OnboardingStep1Screen)),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(OnboardingStepScaffold),
      matchesGoldenFile('goldens/onboarding_step1_360.png'),
    );
    tester.view.physicalSize = const Size(412, 915);
    await tester.pump();
    await expectLater(
      find.byType(OnboardingStepScaffold),
      matchesGoldenFile('goldens/onboarding_step1_412.png'),
    );

    final semantics = tester.ensureSemantics();
    await tester.pump();
    expect(
      find.bySemanticsLabel(AppStrings.onboardingStep1Illustration),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(AppStrings.onboardingSkipSemantics),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(AppStrings.onboardingNext), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('content remains scrollable at 130% text scale', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: OnboardingStep1Screen(
            onBack: () {},
            onNext: () {},
            onSkip: () {},
          ),
        ),
      ),
    );
    expect(find.text(AppStrings.onboardingStep1Title), findsOneWidget);
    expect(find.text(AppStrings.onboardingNext), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Next pushes step 2, Back returns, and Skip saves completion', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const app.MyoGripApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.onboardingStep1Title), findsOneWidget);

    await tester.tap(find.text(AppStrings.onboardingBack));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.onboardingStep1Title), findsOneWidget);

    await tester.tap(find.text(AppStrings.onboardingNext));
    await tester.pumpAndSettle();
    expect(find.text('Position the armband'), findsOneWidget);

    await tester.tap(find.text(AppStrings.onboardingBack));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.onboardingStep1Title), findsOneWidget);

    await tester.tap(find.text(AppStrings.onboardingSkip));
    await tester.pumpAndSettle();
    expect(find.text('Sign in').first, findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(AppStrings.onboardingDonePreferenceKey),
      isTrue,
    );
  });
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

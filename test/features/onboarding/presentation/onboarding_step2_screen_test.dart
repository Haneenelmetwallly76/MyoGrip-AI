import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:myogrip_ai/core/strings.dart';
import 'package:myogrip_ai/core/widgets/numbered_rule_list.dart';
import 'package:myogrip_ai/features/onboarding/presentation/onboarding_step2_screen.dart';
import 'package:myogrip_ai/features/onboarding/presentation/onboarding_step_scaffold.dart';
import 'package:myogrip_ai/main.dart' as app;
import 'package:myogrip_ai/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('matches the onboarding step 2 golden at 360x800', (
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
        home: OnboardingStep2Screen(
          onBack: () {},
          onNext: () {},
          onSkip: () {},
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/onboarding_step2.png'),
        tester.element(find.byType(OnboardingStep2Screen)),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(OnboardingStepScaffold),
      matchesGoldenFile('goldens/onboarding_step2_360.png'),
    );
    tester.view.physicalSize = const Size(412, 915);
    await tester.pump();
    await expectLater(
      find.byType(OnboardingStepScaffold),
      matchesGoldenFile('goldens/onboarding_step2_412.png'),
    );

    final semantics = tester.ensureSemantics();
    await tester.pump();
    expect(
      find.bySemanticsLabel(AppStrings.onboardingStep2Illustration),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        AppStrings.onboardingTipSemantics(1, 3, AppStrings.onboardingStep2Tip1),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        AppStrings.onboardingTipSemantics(2, 3, AppStrings.onboardingStep2Tip2),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        AppStrings.onboardingTipSemantics(3, 3, AppStrings.onboardingStep2Tip3),
      ),
      findsOneWidget,
    );
    expect(find.byType(NumberedRuleList), findsOneWidget);
    expect(find.byType(Divider), findsNWidgets(4));
    semantics.dispose();
  });

  testWidgets('checklist and controls fit at 130% text scale', (tester) async {
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
          child: OnboardingStep2Screen(
            onBack: () {},
            onNext: () {},
            onSkip: () {},
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.onboardingStep2Title), findsOneWidget);
    expect(find.text(AppStrings.onboardingStep2Tip3), findsOneWidget);
    expect(find.text(AppStrings.onboardingNext), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('step 2 routes forward, back, and saves Skip', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const app.MyoGripApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.onboardingNext));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.onboardingStep2Title), findsOneWidget);

    await tester.tap(find.text(AppStrings.onboardingNext));
    await tester.pumpAndSettle();
    expect(find.text('Pair your devices'), findsOneWidget);

    await tester.tap(find.text(AppStrings.onboardingBack));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.onboardingStep2Title), findsOneWidget);

    await tester.tap(find.text(AppStrings.onboardingSkip));
    await tester.pumpAndSettle();
    expect(find.text('Sign in').first, findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(AppStrings.onboardingDonePreferenceKey), isTrue);
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

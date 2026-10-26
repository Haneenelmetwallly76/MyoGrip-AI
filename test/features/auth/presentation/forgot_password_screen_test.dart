import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myogrip_ai/core/strings.dart';
import 'package:myogrip_ai/data/repositories/auth_repository.dart';
import 'package:myogrip_ai/features/auth/presentation/forgot_password_screen.dart';
import 'package:myogrip_ai/theme.dart';
import 'package:myogrip_ai/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('matches the forgot password form golden at 360x800', (
    tester,
  ) async {
    await _loadAppFonts();
    await _setViewport(tester);
    await tester.pumpWidget(_app());

    await expectLater(
      find.byType(ForgotPasswordScreen),
      matchesGoldenFile('goldens/forgot_password_default_360.png'),
    );
  });

  testWidgets('always shows the same confirmation after a valid email', (
    tester,
  ) async {
    await _setViewport(tester);
    await tester.pumpWidget(_app());
    await tester.enterText(find.byType(TextField), 'unknown@example.com');
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();

    expect(find.text(AppStrings.forgotPasswordConfirmation), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.text(AppStrings.forgotPasswordConfirmation), findsOneWidget);
    expect(find.text(AppStrings.forgotPasswordBackToSignIn), findsOneWidget);
    expect(find.byType(PrimaryButton), findsNothing);
    await expectLater(
      find.byType(ForgotPasswordScreen),
      matchesGoldenFile('goldens/forgot_password_confirmation_360.png'),
    );
  });

  testWidgets('form remains accessible at 130% text scale', (tester) async {
    await _setViewport(tester);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: _app(),
      ),
    );

    final semantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(AppStrings.forgotPasswordEmail),
      findsOneWidget,
    );
    expect(find.text(AppStrings.forgotPasswordSend), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

Widget _app() => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  home: ForgotPasswordScreen(
    authRepository: FakeAuthRepository(responseDelay: Duration.zero),
  ),
);

Future<void> _setViewport(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(360, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _loadAppFonts() async {
  for (final entry in const {
    'SourceSans3': 'assets/fonts/SourceSans3-Variable.ttf',
    'SourceSerif4': 'assets/fonts/SourceSerif4-Variable.ttf',
  }.entries) {
    await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value))).load();
  }
}

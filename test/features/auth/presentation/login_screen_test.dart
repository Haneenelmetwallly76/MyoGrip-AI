import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myogrip_ai/core/strings.dart';
import 'package:myogrip_ai/data/repositories/auth_repository.dart';
import 'package:myogrip_ai/features/auth/presentation/login_screen.dart';
import 'package:myogrip_ai/features/auth/presentation/forgot_password_screen.dart';
import 'package:myogrip_ai/theme.dart';
import 'package:myogrip_ai/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('matches the default sign-in golden at 360x800', (tester) async {
    await _loadAppFonts();
    await _setViewport(tester);
    final repository = _repository();
    await tester.pumpWidget(_app(repository));
    await _precacheLogo(tester);
    await tester.pump();

    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login_default_360.png'),
    );
    tester.view.physicalSize = const Size(412, 915);
    await tester.pump();
    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login_default_412.png'),
    );
  });

  testWidgets('matches the credentials error golden at 360x800', (
    tester,
  ) async {
    await _loadAppFonts();
    await _setViewport(tester);
    await tester.pumpWidget(_app(_repository()));
    await _precacheLogo(tester);
    await _enterCredentials(tester, 'wrong@example.com', 'incorrect');
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text(AppStrings.loginCredentialsIncorrect), findsOneWidget);
    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login_error_360.png'),
    );
  });

  testWidgets('matches the loading golden at 360x800', (tester) async {
    await _loadAppFonts();
    await _setViewport(tester);
    await tester.pumpWidget(_app(_repository()));
    await _precacheLogo(tester);
    await _enterCredentials(tester, 'test@example.com', 'Passw0rd1');
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login_loading_360.png'),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'network failure shows retry and successful retry replaces route',
    (tester) async {
      await _setViewport(tester);
      final repository = _repository(forceNetworkFailure: true);
      await tester.pumpWidget(_app(repository));
      await _enterCredentials(tester, 'test@example.com', 'Passw0rd1');
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text(AppStrings.loginNoConnection), findsOneWidget);
      expect(find.text(AppStrings.loginRetry), findsOneWidget);

      repository.forceNetworkFailure = false;
      tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Home route'), findsOneWidget);
      expect(await repository.restoreSession(), isTrue);
    },
  );

  testWidgets('validates fields on blur and remains usable at 130% scale', (
    tester,
  ) async {
    await _setViewport(tester);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: _app(_repository()),
      ),
    );

    final fields = find.byType(TextField);
    await tester.tap(fields.first);
    await tester.pump();
    await tester.tap(fields.last);
    await tester.pump();
    expect(find.text(AppStrings.loginEmailInvalid), findsOneWidget);
    expect(find.text(AppStrings.loginSubmit).first, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('links use the app routes', (tester) async {
    await _setViewport(tester);
    await tester.pumpWidget(_app(_repository()));
    await tester.tap(find.text(AppStrings.loginForgotPassword));
    await tester.pumpAndSettle();
    expect(find.text('Reset password'), findsOneWidget);

    await tester.tap(find.text('← Back'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.tap(find.text(AppStrings.loginCreateAccount));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsOneWidget);
  });
}

FakeAuthRepository _repository({bool forceNetworkFailure = false}) =>
    FakeAuthRepository(
      tokenStore: _MemorySessionTokenStore(),
      forceNetworkFailure: forceNetworkFailure,
    );

GoRouter _router(AuthRepository repository) => GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(authRepository: repository),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('Home route'))),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) =>
          ForgotPasswordScreen(authRepository: repository),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('Create account'))),
    ),
  ],
);

Widget _app(AuthRepository repository) => MaterialApp.router(
  theme: AppTheme.light,
  routerConfig: _router(repository),
);

Future<void> _enterCredentials(
  WidgetTester tester,
  String email,
  String password,
) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.first, email);
  await tester.enterText(fields.last, password);
}

Future<void> _precacheLogo(WidgetTester tester) async {
  await tester.runAsync(
    () => precacheImage(
      const AssetImage('assets/images/logo_mark.png'),
      tester.element(find.byType(LoginScreen)),
    ),
  );
}

Future<void> _setViewport(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(360, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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

final class _MemorySessionTokenStore implements SessionTokenStore {
  String? _token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> writeToken(String token) async {
    _token = token;
  }
}

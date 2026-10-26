import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myogrip_ai/core/strings.dart';
import 'package:myogrip_ai/data/repositories/auth_repository.dart';
import 'package:myogrip_ai/features/auth/presentation/register_screen.dart';
import 'package:myogrip_ai/theme.dart';
import 'package:myogrip_ai/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('matches the default registration golden at 360x800', (
    tester,
  ) async {
    await _loadAppFonts();
    await _setViewport(tester);
    await tester.pumpWidget(_app(_repository()));
    await tester.pump();
    await expectLater(
      find.byType(RegisterScreen),
      matchesGoldenFile('goldens/register_default_360.png'),
    );
    tester.view.physicalSize = const Size(412, 915);
    await tester.pump();
    await expectLater(
      find.byType(RegisterScreen),
      matchesGoldenFile('goldens/register_default_412.png'),
    );
  });

  testWidgets('matches the registration errors golden at 360x800', (
    tester,
  ) async {
    await _loadAppFonts();
    await _setViewport(tester);
    await tester.pumpWidget(_app(_repository()));
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();
    expect(find.text(AppStrings.registerNameRequired), findsOneWidget);
    expect(find.text(AppStrings.registerAgeRequired), findsOneWidget);
    expect(find.text(AppStrings.registerEmailRequired), findsOneWidget);
    expect(find.text(AppStrings.registerPasswordRequired), findsOneWidget);
    expect(find.text(AppStrings.registerClinicCodeRequired), findsOneWidget);
    await expectLater(
      find.byType(RegisterScreen),
      matchesGoldenFile('goldens/register_errors_360.png'),
    );
  });

  testWidgets('checks clinic and email on blur and applies server errors', (
    tester,
  ) async {
    await _setViewport(tester);
    await tester.pumpWidget(_app(_repository()));
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(2), 'taken@example.com');
    await tester.tap(fields.at(3));
    await tester.pump();
    expect(find.text(AppStrings.registerEmailTaken), findsOneWidget);

    await tester.enterText(fields.at(4), 'BADCLINIC');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text(AppStrings.registerClinicCodeInvalid), findsOneWidget);
  });

  testWidgets('validates age and password policy and registers successfully', (
    tester,
  ) async {
    await _setViewport(tester);
    final repository = _repository();
    await tester.pumpWidget(_app(repository));
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Sam Patient');
    await tester.enterText(fields.at(1), '121');
    await tester.enterText(fields.at(2), 'new@example.com');
    await tester.enterText(fields.at(3), 'short');
    await tester.enterText(fields.at(4), 'CLINIC1');
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();
    expect(find.text(AppStrings.registerAgeInvalid), findsOneWidget);
    expect(find.text(AppStrings.registerPasswordInvalid), findsOneWidget);

    await tester.enterText(fields.at(1), '34');
    await tester.enterText(fields.at(3), 'Password1');
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Home route'), findsOneWidget);
    expect(await repository.restoreSession(), isTrue);
    expect(repository.hasLinkedDevice, isFalse);
  });

  testWidgets('network failure shows a retry action for registration', (
    tester,
  ) async {
    await _setViewport(tester);
    final repository = _repository()..forceNetworkFailure = true;
    await tester.pumpWidget(_app(repository));
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Sam Patient');
    await tester.enterText(fields.at(1), '34');
    await tester.enterText(fields.at(2), 'new@example.com');
    await tester.enterText(fields.at(3), 'Password1');
    await tester.enterText(fields.at(4), 'CLINIC1');
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.registerServerError), findsOneWidget);
    expect(find.text(AppStrings.loginRetry), findsOneWidget);

    repository.forceNetworkFailure = false;
    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    await tester.pumpAndSettle();
    expect(find.text('Home route'), findsOneWidget);
  });

  testWidgets('remains scrollable at 130% text scale and links back to login', (
    tester,
  ) async {
    await _setViewport(tester);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: _app(_repository()),
      ),
    );
    expect(find.text(AppStrings.registerTitle).first, findsOneWidget);
    expect(find.text(AppStrings.registerSubmit).first, findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(AppStrings.registerSignIn));
    await tester.pumpAndSettle();
    expect(find.text('Login route'), findsOneWidget);
  });
}

FakeAuthRepository _repository() => FakeAuthRepository(
  tokenStore: _MemorySessionTokenStore(),
  responseDelay: Duration.zero,
);

GoRouter _router(AuthRepository repository) => GoRouter(
  initialLocation: '/register',
  routes: [
    GoRoute(
      path: '/register',
      builder: (context, state) => RegisterScreen(authRepository: repository),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('Home route'))),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('Login route'))),
    ),
  ],
);

Widget _app(AuthRepository repository) => MaterialApp.router(
  theme: AppTheme.light,
  routerConfig: _router(repository),
);

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

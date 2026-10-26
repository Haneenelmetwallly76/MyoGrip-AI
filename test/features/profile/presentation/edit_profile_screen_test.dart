import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myogrip_ai/core/strings.dart';
import 'package:myogrip_ai/data/repositories/profile_repository.dart';
import 'package:myogrip_ai/data/repositories/usage_repository.dart';
import 'package:myogrip_ai/features/profile/application/profile_providers.dart';
import 'package:myogrip_ai/features/profile/presentation/edit_profile_screen.dart';
import 'package:myogrip_ai/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('matches the profile edit view golden at 360x800', (
    tester,
  ) async {
    await _loadAppFonts();
    await _setViewport(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.editProfileClinicCodeCaption), findsOneWidget);
    await expectLater(
      find.byType(EditProfileScreen),
      matchesGoldenFile('goldens/edit_profile_view_360.png'),
    );
  });

  testWidgets('editable fields validate and save errors provide retry', (
    tester,
  ) async {
    await _loadAppFonts();
    await _setViewport(tester);
    final repository = FakeProfileRepository(latency: Duration.zero);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.editProfileEdit));
    await tester.pump();
    repository.forceFailure = true;
    await tester.enterText(find.byType(TextField).first, '');
    await tester.tap(find.text(AppStrings.editProfileSave));
    await tester.pump();
    expect(find.text(AppStrings.registerNameRequired), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'New Name');
    await tester.tap(find.text(AppStrings.editProfileSave));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();
    expect(find.text(AppStrings.editProfileSaveError), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(EditProfileScreen),
      matchesGoldenFile('goldens/edit_profile_error_360.png'),
    );
  });

  testWidgets('edit form remains usable at 130% text scale', (tester) async {
    await _setViewport(tester);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: _app(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.text(AppStrings.editProfileEdit), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app([ProfileRepository? repository]) => ProviderScope(
  overrides: [
    profileRepositoryProvider.overrideWith(
      (ref) => repository ?? FakeProfileRepository(latency: Duration.zero),
    ),
    usageRepositoryProvider.overrideWith(
      (ref) => FakeUsageRepository(latency: Duration.zero),
    ),
  ],
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const EditProfileScreen(),
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

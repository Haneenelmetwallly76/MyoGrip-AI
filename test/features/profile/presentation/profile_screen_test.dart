import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myogrip_ai/data/repositories/profile_repository.dart';
import 'package:myogrip_ai/data/models/profile.dart';
import 'package:myogrip_ai/data/repositories/usage_repository.dart';
import 'package:myogrip_ai/features/home/presentation/home_screen.dart';
import 'package:myogrip_ai/features/profile/application/profile_providers.dart';
import 'package:myogrip_ai/features/profile/presentation/profile_screen.dart';
import 'package:myogrip_ai/core/widgets/hours_bar_chart.dart';
import 'package:myogrip_ai/features/profile/presentation/send_report_sheet.dart';
import 'package:myogrip_ai/data/repositories/report_repository.dart';
import 'package:myogrip_ai/theme.dart';
import 'package:myogrip_ai/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('matches Profile default at 360x800', (tester) async {
    await _loadAppFonts();
    await _setViewport(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Hours worn per day'), findsOneWidget);
    expect(find.text('Grip strength'), findsOneWidget);
    expect(find.byType(BottomTabBar), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(ProfileScreen),
      matchesGoldenFile('goldens/profile_default_7_days_360.png'),
    );
  });

  testWidgets('bar selection announces its exact weekday and value', (
    tester,
  ) async {
    await _setViewport(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(HoursBarChart));
    await tester.pumpAndSettle();

    expect(find.text('Thu: 4.6 h'), findsOneWidget);
  });

  testWidgets('matches Profile 30-day range at 360x800', (tester) async {
    await _loadAppFonts();
    await _setViewport(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 days'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ProfileScreen),
      matchesGoldenFile('goldens/profile_30_days_360.png'),
    );
  });

  testWidgets('matches empty usage at 360x800', (tester) async {
    await _loadAppFonts();
    await _setViewport(tester);
    await tester.pumpWidget(
      _app(usage: FakeUsageRepository(empty: true, latency: Duration.zero)),
    );
    await tester.pumpAndSettle();

    expect(find.text('No usage recorded yet'), findsOneWidget);
    expect(find.text('Hours worn per day'), findsNothing);
    await expectLater(
      find.byType(ProfileScreen),
      matchesGoldenFile('goldens/profile_empty_360.png'),
    );
  });

  testWidgets('load errors offer retry', (tester) async {
    await _setViewport(tester);
    await tester.pumpWidget(
      _app(
        usage: FakeUsageRepository(forceFailure: true, latency: Duration.zero),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load your data.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('opens report sheet and confirms successful send', (
    tester,
  ) async {
    await _loadAppFonts();
    await _setViewport(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send report to my doctor'));
    await tester.pumpAndSettle();
    expect(find.byType(SendReportSheet), findsOneWidget);
    expect(find.text('Your clinician'), findsOneWidget);
    expect(find.text('Last 30 days'), findsOneWidget);
    expect(find.text('Error reports'), findsOneWidget);
    await expectLater(
      find.byType(Overlay).first,
      matchesGoldenFile('goldens/profile_send_report_sheet_360.png'),
    );
    await tester.tap(find.text('Send'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('Report sent'), findsOneWidget);
    expect(find.byType(SendReportSheet), findsNothing);
  });

  testWidgets('report failure stays in sheet with clay retry', (tester) async {
    await _setViewport(tester);
    await tester.pumpWidget(
      _app(
        report: FakeReportRepository(
          forceFailure: true,
          latency: Duration.zero,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send report to my doctor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.text('Could not send report.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('report action is disabled when no clinician is linked', (
    tester,
  ) async {
    await _setViewport(tester);
    await tester.pumpWidget(
      _app(
        profile: FakeProfileRepository(
          latency: Duration.zero,
          initialProfile: const Profile(
            name: 'Patient name',
            age: 34,
            email: 'name@example.com',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Link a clinic to send reports.'), findsOneWidget);
    final button = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, 'Send report to my doctor'),
    );
    expect(button.onPressed, isNull);
    await tester.tap(find.text('Send report to my doctor'));
    await tester.pump();
    expect(find.byType(SendReportSheet), findsNothing);
  });

  testWidgets('matches Profile at 130% text scale without overflow', (
    tester,
  ) async {
    await _loadAppFonts();
    await _setViewport(tester);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: _app(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BottomTabBar), findsOneWidget);
    expect(find.text('Send report to my doctor'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(ProfileScreen),
      matchesGoldenFile('goldens/profile_text_scale_130_360.png'),
    );
  });
}

Widget _app({
  UsageRepository? usage,
  ReportRepository? report,
  ProfileRepository? profile,
}) => ProviderScope(
  overrides: [
    profileRepositoryProvider.overrideWith(
      (ref) => profile ?? FakeProfileRepository(latency: Duration.zero),
    ),
    usageRepositoryProvider.overrideWith(
      (ref) => usage ?? FakeUsageRepository(latency: Duration.zero),
    ),
    reportRepositoryProvider.overrideWith(
      (ref) => report ?? FakeReportRepository(latency: Duration.zero),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.light,
    home: const HomeSecondaryTabScreen(selected: 2, child: ProfileScreen()),
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
  final fontFiles = <String, String>{
    'SourceSans3': 'assets/fonts/SourceSans3-Variable.ttf',
    'SourceSerif4': 'assets/fonts/SourceSerif4-Variable.ttf',
  };
  for (final entry in fontFiles.entries) {
    await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value))).load();
  }
}

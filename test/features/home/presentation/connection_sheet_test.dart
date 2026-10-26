import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myogrip_ai/core/strings.dart';
import 'package:myogrip_ai/data/models/arm_status.dart';
import 'package:myogrip_ai/data/repositories/arm_repository.dart';
import 'package:myogrip_ai/features/home/presentation/connection_sheet.dart';
import 'package:myogrip_ai/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('matches the connections sheet golden at 360x800', (
    tester,
  ) async {
    await _loadAppFonts();
    await _setViewport(tester);
    await tester.pumpWidget(_app());

    expect(find.text(AppStrings.homeArmController), findsOneWidget);
    expect(find.text(AppStrings.homeArmbandConnection), findsOneWidget);
    expect(find.text(AppStrings.homeConnected), findsNWidgets(2));
    await expectLater(
      find.byType(ConnectionSheet),
      matchesGoldenFile('goldens/connections_sheet_360.png'),
    );
  });

  testWidgets('Reconnect updates the visible status', (tester) async {
    await _setViewport(tester);
    await tester.pumpWidget(_app());
    await tester.tap(find.text(AppStrings.homeReconnect).first);
    await tester.pump();
    expect(find.text(AppStrings.homeConnecting), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text(AppStrings.homeConnected), findsNWidgets(2));
  });

  testWidgets('connection actions fit at 130% text scale', (tester) async {
    await _setViewport(tester);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: _app(),
      ),
    );

    expect(find.text(AppStrings.homeReconnect), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}

Widget _app() => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  home: Scaffold(
    bottomSheet: ConnectionSheet(
      repository: FakeArmRepository(updateInterval: const Duration(hours: 1)),
      status: ArmStatus(
        connection: ArmConnection.connected,
        armbandLinked: true,
        activeGesture: null,
        signalConfidence: 0,
        armBattery: 82,
        armbandBattery: 64,
        lastSignalAt: DateTime(2026, 10, 26, 10, 31),
        lastSeenAt: DateTime(2026, 10, 26, 10, 31),
      ),
    ),
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

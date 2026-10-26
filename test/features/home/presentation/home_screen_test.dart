import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myogrip_ai/core/strings.dart';
import 'package:myogrip_ai/data/models/arm_status.dart';
import 'package:myogrip_ai/data/repositories/arm_repository.dart';
import 'package:myogrip_ai/features/home/application/home_providers.dart';
import 'package:myogrip_ai/features/home/presentation/home_screen.dart';
import 'package:myogrip_ai/theme.dart';
import 'package:myogrip_ai/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('matches the connected Gesture 3 home golden', (tester) async {
    await _loadAppFonts();
    await _setViewport(tester);
    await tester.pumpWidget(_app(_status()));
    await tester.pump();
    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_connected_360.png'),
    );
    final semantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(
        'Live gesture: Gesture 3, fingers thumb, index and middle active',
      ),
      findsOneWidget,
    );
    semantics.dispose();

    test(
      'fake arm stream cycles gestures and exposes the disconnect toggle',
      () async {
        final repository = FakeArmRepository(
          updateInterval: const Duration(milliseconds: 1),
        );
        final statuses = StreamIterator(repository.watchStatus());
        addTearDown(statuses.cancel);
        expect(await statuses.moveNext(), isTrue);
        expect(statuses.current.activeGesture, 3);
        repository.forceDisconnect = true;
        expect(await statuses.moveNext(), isTrue);
        expect(statuses.current.connection, ArmConnection.disconnected);
        expect(statuses.current.activeGesture, isNull);
      },
    );
  });

  testWidgets('matches resting and disconnected home goldens', (tester) async {
    await _loadAppFonts();
    await _setViewport(tester);
    await tester.pumpWidget(_app(_status(gesture: null)));
    await tester.pump();
    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_resting_360.png'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      _app(_status(connection: ArmConnection.disconnected)),
    );
    await tester.pump();
    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_disconnected_360.png'),
    );
  });

  testWidgets('shows one low-battery notice and matches low battery golden', (
    tester,
  ) async {
    await _loadAppFonts();
    await _setViewport(tester);
    await tester.pumpWidget(_app(_status(armBattery: 19, armbandBattery: 15)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(AppStrings.homeLowBatterySnackbar), findsOneWidget);
    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_low_battery_360.png'),
    );
  });

  testWidgets(
    'text scale 1.3 remains usable and pinned controls stay visible',
    (tester) async {
      await _loadAppFonts();
      await _setViewport(tester);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: _app(_status()),
        ),
      );
      expect(find.text(AppStrings.homeEmergencyStop), findsOneWidget);
      expect(find.byType(BottomTabBar), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('goldens/home_text_scale_130_360.png'),
      );
    },
  );

  testWidgets(
    'stop stays sending until acknowledgment and resume restores ready',
    (tester) async {
      await _setViewport(tester);
      await tester.pumpWidget(_app(_status()));
      await tester.pump();
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.text(AppStrings.homeResume), findsOneWidget);
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();
      expect(find.text(AppStrings.homeEmergencyStop), findsOneWidget);
    },
  );

  testWidgets('no linked device displays pairing link and tabs navigate', (
    tester,
  ) async {
    await _setViewport(tester);
    await tester.pumpWidget(
      _app(
        const ArmStatus(
          connection: ArmConnection.disconnected,
          armbandLinked: false,
          activeGesture: null,
          signalConfidence: 0,
          armBattery: null,
          armbandBattery: null,
          lastSignalAt: null,
          lastSeenAt: null,
        ),
        hasDevice: false,
      ),
    );
    await tester.pump();
    expect(find.text(AppStrings.homeNoDeviceLinked), findsOneWidget);
    expect(find.text(AppStrings.homePairDevices), findsOneWidget);
    await tester.tap(find.text(AppStrings.homeTabSettings));
    await tester.pumpAndSettle();
    expect(find.text('Settings').first, findsOneWidget);
    await tester.tap(find.text(AppStrings.homeTabProfile));
    await tester.pumpAndSettle();
    expect(find.text('Profile').first, findsOneWidget);
  });
}

ArmStatus _status({
  ArmConnection connection = ArmConnection.connected,
  int? gesture = 3,
  int? armBattery = 82,
  int? armbandBattery = 64,
}) => ArmStatus(
  connection: connection,
  armbandLinked: connection == ArmConnection.connected,
  activeGesture: connection == ArmConnection.connected ? gesture : null,
  signalConfidence: connection == ArmConnection.connected ? .96 : 0,
  armBattery: armBattery,
  armbandBattery: armbandBattery,
  lastSignalAt: DateTime(2026, 10, 20, 10, 31),
  lastSeenAt: DateTime(2026, 10, 20, 10, 31),
);

Widget _app(ArmStatus status, {bool hasDevice = true}) {
  final repository = _SingleStatusArmRepository(status, linked: hasDevice);
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const HomeSecondaryTabScreen(
          selected: 1,
          child: Scaffold(body: Text('Settings')),
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const HomeSecondaryTabScreen(
          selected: 2,
          child: Scaffold(body: Text('Profile')),
        ),
      ),
      GoRoute(
        path: '/onboarding/3',
        builder: (context, state) =>
            const Scaffold(body: Text('Pairing route')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      armRepositoryProvider.overrideWith((ref) => repository),
      currentDateProvider.overrideWith((ref) => DateTime(2026, 10, 20)),
    ],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
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

final class _SingleStatusArmRepository implements ArmRepository {
  const _SingleStatusArmRepository(this.status, {required this.linked});

  final ArmStatus status;

  final bool linked;

  @override
  bool get hasLinkedDevice => linked;

  @override
  Stream<ArmStatus> watchStatus() => Stream<ArmStatus>.value(status);
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myogrip_ai/core/strings.dart';
import 'package:myogrip_ai/data/models/arm_settings.dart';
import 'package:myogrip_ai/data/models/arm_status.dart';
import 'package:myogrip_ai/data/repositories/arm_repository.dart';
import 'package:myogrip_ai/data/repositories/settings_repository.dart';
import 'package:myogrip_ai/features/home/application/home_providers.dart';
import 'package:myogrip_ai/features/home/presentation/home_screen.dart';
import 'package:myogrip_ai/features/settings/application/settings_controller.dart';
import 'package:myogrip_ai/features/settings/application/settings_providers.dart';
import 'package:myogrip_ai/features/settings/presentation/settings_screen.dart';
import 'package:myogrip_ai/theme.dart';
import 'package:myogrip_ai/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('matches default Settings at 360x800', (tester) async {
    await _loadAppFonts();
    await _setViewport(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.settingsTitle).first, findsOneWidget);
    expect(find.text('8 ${AppStrings.settingsOnCount}'), findsOneWidget);
    expect(find.text(AppStrings.settingsGestureNames[5]), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Gesture 2, off'), findsOneWidget);
    semantics.dispose();
    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_default_360.png'),
    );
    tester.view.physicalSize = const Size(412, 915);
    await tester.pump();
    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_default_412.png'),
    );
  });

  testWidgets('offline changes display Pending and update the count', (
    tester,
  ) async {
    await _loadAppFonts();
    await _setViewport(tester);
    await tester.pumpWidget(_app(connection: ArmConnection.disconnected));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.settingsLow));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Haptic feedback, on'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Gesture 0, on'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.settingsPending), findsNWidgets(3));
    expect(find.text('7 ${AppStrings.settingsOnCount}'), findsOneWidget);
    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_offline_pending_360.png'),
    );
  });

  testWidgets('text scale 1.3 scrolls without hiding the pinned tab bar', (
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
    expect(find.text(AppStrings.settingsTitle).first, findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_text_scale_130_360.png'),
    );
  });

  testWidgets('sensitivity failure rolls back and offers retry', (
    tester,
  ) async {
    await _setViewport(tester);
    final repository = FakeSettingsRepository(
      latency: const Duration(milliseconds: 50),
      forceFailure: true,
    );
    addTearDown(repository.dispose);
    await tester.pumpWidget(_app(settingsRepository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.settingsLow));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(AppStrings.settingsSaveFailed), findsOneWidget);
    expect(find.text(AppStrings.settingsMedium), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );
    expect(
      container.read(settingsControllerProvider).settings.sensitivity,
      SensitivityLevel.medium,
    );
  });

  testWidgets('first TENS enable requires confirmation and remembers notice', (
    tester,
  ) async {
    await _setViewport(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Haptic feedback, on'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Haptic feedback, off'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.settingsTensTurnOn));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(AppStrings.tensNoticeSeenPreferenceKey), isTrue);
    expect(find.bySemanticsLabel('Haptic feedback, on'), findsOneWidget);
  });

  test('offline pending settings sync after reconnection', () async {
    final armRepository = _MutableArmRepository();
    final settingsRepository = FakeSettingsRepository(
      latency: Duration.zero,
      forceFailure: true,
    );
    final controller = SettingsController(
      settingsRepository: settingsRepository,
      armRepository: armRepository,
    );
    addTearDown(controller.dispose);
    addTearDown(armRepository.dispose);
    addTearDown(settingsRepository.dispose);
    await controller.initialize();
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(controller.isConnected, isFalse);

    expect(
      await controller.setSensitivity(SensitivityLevel.low),
      SettingsChangeResult.pending,
    );
    expect(
      controller.settings.pendingKeys,
      contains(SettingsController.sensitivityKey),
    );

    settingsRepository.forceFailure = false;
    armRepository.setConnection(ArmConnection.connected);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(controller.settings.pendingKeys, isEmpty);
    expect(
      (await settingsRepository.getSettings()).sensitivity,
      SensitivityLevel.low,
    );
  });
}

Widget _app({
  ArmConnection connection = ArmConnection.connected,
  SettingsRepository? settingsRepository,
}) => ProviderScope(
  overrides: [
    armRepositoryProvider.overrideWith(
      (ref) => _SingleStatusArmRepository(connection),
    ),
    settingsRepositoryProvider.overrideWith(
      (ref) =>
          settingsRepository ?? FakeSettingsRepository(latency: Duration.zero),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.light,
    home: const HomeSecondaryTabScreen(selected: 1, child: SettingsScreen()),
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

final class _SingleStatusArmRepository implements ArmRepository {
  const _SingleStatusArmRepository(this.connection);

  final ArmConnection connection;

  @override
  bool get hasLinkedDevice => true;

  @override
  Stream<ArmStatus> watchStatus() => Stream<ArmStatus>.value(
    ArmStatus(
      connection: connection,
      armbandLinked: connection == ArmConnection.connected,
      activeGesture: null,
      signalConfidence: 0,
      armBattery: 82,
      armbandBattery: 64,
      lastSignalAt: DateTime(2026, 10, 20, 10, 31),
      lastSeenAt: DateTime(2026, 10, 20, 10, 31),
    ),
  );
}

final class _MutableArmRepository implements ArmRepository {
  final StreamController<ArmStatus> _updates =
      StreamController<ArmStatus>.broadcast();
  ArmConnection _connection = ArmConnection.disconnected;

  void setConnection(ArmConnection connection) {
    _connection = connection;
    _updates.add(_status(connection));
  }

  @override
  bool get hasLinkedDevice => true;

  @override
  Stream<ArmStatus> watchStatus() async* {
    yield _status(_connection);
    yield* _updates.stream;
  }

  ArmStatus _status(ArmConnection connection) => ArmStatus(
    connection: connection,
    armbandLinked: connection == ArmConnection.connected,
    activeGesture: null,
    signalConfidence: 0,
    armBattery: 82,
    armbandBattery: 64,
    lastSignalAt: DateTime(2026, 10, 20, 10, 31),
    lastSeenAt: DateTime(2026, 10, 20, 10, 31),
  );

  void dispose() => _updates.close();
}

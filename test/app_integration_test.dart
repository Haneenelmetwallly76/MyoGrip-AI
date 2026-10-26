import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myogrip_ai/core/strings.dart';
import 'package:myogrip_ai/core/widgets/hours_bar_chart.dart';
import 'package:myogrip_ai/data/models/arm_settings.dart';
import 'package:myogrip_ai/data/models/arm_status.dart';
import 'package:myogrip_ai/data/repositories/arm_repository.dart';
import 'package:myogrip_ai/data/repositories/auth_repository.dart';
import 'package:myogrip_ai/data/repositories/profile_repository.dart';
import 'package:myogrip_ai/data/repositories/report_repository.dart';
import 'package:myogrip_ai/data/repositories/settings_repository.dart';
import 'package:myogrip_ai/data/repositories/usage_repository.dart';
import 'package:myogrip_ai/features/profile/presentation/profile_screen.dart';
import 'package:myogrip_ai/features/settings/application/settings_controller.dart';
import 'package:myogrip_ai/features/settings/presentation/settings_screen.dart';
import 'package:myogrip_ai/main.dart';
import 'package:myogrip_ai/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'tab state and global stop survive navigation; profile actions work',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        AppStrings.onboardingDonePreferenceKey: true,
      });
      tester.view
        ..physicalSize = const Size(360, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final settings = FakeSettingsRepository(latency: Duration.zero);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MyoGripApp(
          authRepository: FakeAuthRepository(
            tokenStore: _MemorySessionTokenStore('existing-session'),
            responseDelay: Duration.zero,
          ),
          armRepository: _StaticArmRepository(),
          settingsRepository: settings,
          profileRepository: FakeProfileRepository(latency: Duration.zero),
          usageRepository: FakeUsageRepository(latency: Duration.zero),
          reportRepository: FakeReportRepository(latency: Duration.zero),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.homeTitle), findsOneWidget);

      final semantics = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel(AppStrings.homeEmergencyStopSemantics),
        findsOneWidget,
      );
      semantics.dispose();

      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.homeResume), findsOneWidget);

      await tester.tap(find.text(AppStrings.homeTabSettings));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.settingsLow));
      await tester.pumpAndSettle();
      expect(
        ProviderScope.containerOf(
          tester.element(find.byType(SettingsScreen)),
        ).read(settingsControllerProvider).settings.sensitivity,
        SensitivityLevel.low,
      );

      await tester.tap(find.text(AppStrings.homeTabProfile));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.profileThirtyDays));
      await tester.pumpAndSettle();
      expect(
        tester.widget<HoursBarChart>(find.byType(HoursBarChart)).showThirtyDays,
        isTrue,
      );

      await tester.tap(find.text(AppStrings.homeTabHome));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.homeResume), findsOneWidget);

      await tester.tap(find.text(AppStrings.homeTabSettings));
      await tester.pumpAndSettle();
      expect(
        ProviderScope.containerOf(
          tester.element(find.byType(SettingsScreen)),
        ).read(settingsControllerProvider).settings.sensitivity,
        SensitivityLevel.low,
      );
      await tester.tap(find.text(AppStrings.homeTabProfile));
      await tester.pumpAndSettle();
      expect(
        tester.widget<HoursBarChart>(find.byType(HoursBarChart)).showThirtyDays,
        isTrue,
      );

      ScaffoldMessenger.of(
        tester.element(find.byType(ProfileScreen)),
      ).hideCurrentSnackBar();
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.profileEdit));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.editProfileEdit));
      await tester.pump();
      await tester.tap(find.text(AppStrings.editProfileSave));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text(AppStrings.editProfileSaved), findsOneWidget);

      ScaffoldMessenger.of(
        tester.element(find.byType(ProfileScreen)),
      ).hideCurrentSnackBar();
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.profileSendReport));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.profileReportConfirm));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.profileReportSent), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

final class _MemorySessionTokenStore implements SessionTokenStore {
  _MemorySessionTokenStore(this.token);

  final String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String token) async {}
}

final class _StaticArmRepository implements ArmRepository {
  @override
  bool get hasLinkedDevice => true;

  @override
  Stream<ArmStatus> watchStatus() => Stream.value(
    ArmStatus(
      connection: ArmConnection.connected,
      armbandLinked: true,
      activeGesture: 3,
      signalConfidence: .96,
      armBattery: 82,
      armbandBattery: 64,
      lastSignalAt: DateTime(2026, 10, 26, 9, 40),
      lastSeenAt: DateTime(2026, 10, 26, 9, 39),
    ),
  );
}

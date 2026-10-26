import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../features/onboarding/application/pairing_controller.dart';
import '../../../theme.dart';
import '../../../data/repositories/device_pairing_repository.dart';
import '../../../widgets.dart';
import 'device_row.dart';
import 'onboarding_step_scaffold.dart';

class OnboardingStep3Screen extends StatefulWidget {
  const OnboardingStep3Screen({
    required this.onBack,
    required this.onFinish,
    required this.onSkip,
    super.key,
    this.pairingController,
    this.debugForceArmbandFailure = false,
    this.rePair = false,
    this.onDeviceLinked,
  });

  final VoidCallback onBack;
  final VoidCallback onFinish;
  final VoidCallback onSkip;
  final PairingController? pairingController;
  final bool debugForceArmbandFailure;
  final bool rePair;
  final VoidCallback? onDeviceLinked;

  @override
  State<OnboardingStep3Screen> createState() => _OnboardingStep3ScreenState();
}

class _OnboardingStep3ScreenState extends State<OnboardingStep3Screen> {
  late final PairingController _pairingController;
  late final bool _ownsController;
  bool _notifiedLinked = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.pairingController == null;
    _pairingController =
        widget.pairingController ??
        PairingController(
          repository: FakeDevicePairingRepository(
            debugForceArmbandFailure: widget.debugForceArmbandFailure,
          ),
          autoSearch: !widget.rePair,
          initialArmState: widget.rePair
              ? DevicePairingState.found
              : DevicePairingState.paired,
          initialArmbandState: DevicePairingState.found,
        );
    _pairingController.addListener(_onPairingChanged);
  }

  void _onPairingChanged() {
    if (!_notifiedLinked &&
        _pairingController.armState == DevicePairingState.paired) {
      _notifiedLinked = true;
      widget.onDeviceLinked?.call();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pairingController.removeListener(_onPairingChanged);
    if (_ownsController) _pairingController.dispose();
    super.dispose();
  }

  Future<void> _pairArmband() async {
    if (_pairingController.permissionGranted) {
      await _pairingController.pairArmband();
      return;
    }
    final continueToPair = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => AppSheet(
        label: AppStrings.onboardingPermissionSheetLabel,
        message: AppStrings.onboardingPermissionReason,
        primaryLabel: AppStrings.onboardingPermissionContinue,
        onPrimary: () => Navigator.of(sheetContext).pop(true),
        secondaryLabel: AppStrings.onboardingPermissionNotNow,
        onSecondary: () => Navigator.of(sheetContext).pop(false),
      ),
    );
    if (continueToPair == true && mounted) {
      await _pairingController.requestPermissionAndPair();
    }
  }

  @override
  Widget build(BuildContext context) => OnboardingStepScaffold(
    step: 3,
    nextLabel: AppStrings.onboardingFinish,
    onBack: widget.onBack,
    onNext: widget.onFinish,
    onSkip: widget.onSkip,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpace.s4),
        Text(AppStrings.onboardingStep3Title, style: AppTheme.onboardingTitleM),
        const SizedBox(height: AppSpace.s12),
        Text(AppStrings.onboardingStep3Body, style: AppTheme.onboardingBody),
        const SizedBox(height: AppSpace.onboardingDeviceListTopGap),
        if (_pairingController.isSearching)
          const _SearchingDevices()
        else ...[
          DeviceRow(
            asset: 'assets/images/device_arm.png',
            name: AppStrings.onboardingStep3ArmName,
            state: _pairingController.armState,
            onPair: () => unawaited(_pairingController.pairArm()),
            onTryAgain: () => unawaited(_pairingController.pairArm()),
          ),
          DeviceRow(
            asset: 'assets/images/device_armband.png',
            name: AppStrings.onboardingStep3ArmbandName,
            semanticsLabel: AppStrings.onboardingStep3ArmbandSemantics,
            state: _pairingController.armbandState,
            onPair: () => unawaited(_pairArmband()),
            onTryAgain: () => unawaited(_pairArmband()),
          ),
          const SizedBox(height: AppSpace.onboardingDeviceListHelperGap),
          Text(AppStrings.onboardingDeviceHelp, style: AppTheme.caption),
          if (_pairingController.armbandState == DevicePairingState.failed) ...[
            const SizedBox(height: AppSpace.s8),
            AppLink(
              AppStrings.onboardingDeviceSkipForNow,
              onTap: widget.onSkip,
              semanticsLabel: AppStrings.onboardingDeviceSkipForNow,
            ),
          ],
        ],
      ],
    ),
  );
}

class _SearchingDevices extends StatelessWidget {
  const _SearchingDevices();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(AppStrings.onboardingDeviceSearching, style: AppTheme.caption),
      const SizedBox(height: AppSpace.s8),
      const LinearProgressIndicator(
        minHeight: AppSpace.onboardingPairingLineHeight,
        color: AppColors.forest,
        backgroundColor: AppColors.rule,
      ),
    ],
  );
}

import 'package:flutter/material.dart';

import '../../../core/strings.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../theme.dart';
import '../../../widgets.dart';
import '../application/pairing_controller.dart';

class DeviceRow extends StatelessWidget {
  const DeviceRow({
    required this.asset,
    required this.name,
    this.semanticsLabel,
    required this.state,
    required this.onPair,
    required this.onTryAgain,
    super.key,
  });

  final String asset;
  final String name;
  final String? semanticsLabel;
  final DevicePairingState state;
  final VoidCallback onPair;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Rule(margin: EdgeInsets.zero),
      ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpace.onboardingDeviceRowMinHeight,
        ),
        child: Row(
          children: [
            Container(
              width: AppSpace.onboardingDevicePhotoSize,
              height: AppSpace.onboardingDevicePhotoSize,
              decoration: const BoxDecoration(
                color: AppColors.rule,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: ImageOrPlaceholder(
                asset: asset,
                width: AppSpace.onboardingDevicePhotoSize,
                height: AppSpace.onboardingDevicePhotoSize,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: AppSpace.onboardingDevicePhotoGap),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    semanticsLabel: semanticsLabel,
                    style: AppTheme.onboardingDeviceName,
                  ),
                  const SizedBox(height: AppSpace.onboardingDeviceStatusGap),
                  Text(
                    AppStrings.onboardingDeviceFoundNearby,
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.s8),
            _buildAction(),
          ],
        ),
      ),
    ],
  );

  Widget _buildAction() => switch (state) {
    DevicePairingState.searching => const SizedBox.shrink(),
    DevicePairingState.found => _PairButton(
      label: AppStrings.onboardingDevicePair,
      onPressed: onPair,
    ),
    DevicePairingState.pairing => const _PairButton(
      label: AppStrings.onboardingDevicePairing,
      onPressed: null,
      busy: true,
    ),
    DevicePairingState.paired => Semantics(
      label: AppStrings.onboardingDevicePairedSemantics,
      excludeSemantics: true,
      child: const Text(
        AppStrings.onboardingDevicePaired,
        style: AppTheme.onboardingPairedStatus,
      ),
    ),
    DevicePairingState.failed => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          AppStrings.onboardingDevicePairFailed,
          textAlign: TextAlign.end,
          style: AppTheme.onboardingFailedStatus,
        ),
        AppLink(
          AppStrings.onboardingDeviceTryAgain,
          onTap: onTryAgain,
          semanticsLabel: AppStrings.onboardingDeviceTryAgain,
        ),
      ],
    ),
  };
}

class _PairButton extends StatelessWidget {
  const _PairButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(
      minWidth: AppSpace.onboardingDeviceActionMinWidth,
      minHeight: AppSpace.minTouchTarget,
    ),
    child: Semantics(
      button: true,
      label: label,
      enabled: onPressed != null,
      onTap: onPressed,
      excludeSemantics: true,
      child: SizedBox(
        height: AppSpace.minTouchTarget,
        child: Center(
          child: SizedBox(
            width: AppSpace.onboardingDeviceActionMinWidth,
            height: AppSpace.onboardingDeviceActionHeight,
            child: OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.forest,
                side: const BorderSide(color: AppColors.forest, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.compactButton),
                ),
                minimumSize: Size.zero,
                fixedSize: const Size(
                  AppSpace.onboardingDeviceActionMinWidth,
                  AppSpace.onboardingDeviceActionHeight,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.s8),
              ),
              child: busy
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox.square(
                          dimension: AppSpace.s16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.forest,
                          ),
                        ),
                        const SizedBox(width: AppSpace.s4),
                        Text(
                          label,
                          style: AppTheme.body(color: AppColors.forest),
                        ),
                      ],
                    )
                  : Text(label, style: AppTheme.body(color: AppColors.forest)),
            ),
          ),
        ),
      ),
    ),
  );
}

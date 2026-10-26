import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_config.dart';
import '../../core/strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/home/application/emergency_stop_controller.dart';
import '../../features/home/application/home_providers.dart';
import '../../theme.dart';

class CompactStopButton extends ConsumerWidget {
  const CompactStopButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AppConfig.showCompactStopOnSecondaryTabs) {
      return const SizedBox.shrink();
    }
    final stopState = ref.watch(emergencyStopControllerProvider);
    return Semantics(
      button: true,
      label: AppStrings.homeEmergencyStop,
      child: IconButton(
        tooltip: AppStrings.homeEmergencyStop,
        constraints: const BoxConstraints.tightFor(
          width: AppSpace.homeCompactStopSize,
          height: AppSpace.homeCompactStopSize,
        ),
        onPressed: () {
          if (stopState == EmergencyStopState.stopped) {
            ref.read(emergencyStopControllerProvider.notifier).resume();
          } else {
            ref.read(emergencyStopControllerProvider.notifier).stop();
          }
        },
        icon: const Icon(Icons.stop, color: AppColors.stop),
      ),
    );
  }
}

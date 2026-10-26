import 'package:flutter/material.dart';

import '../../../core/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/step_progress.dart';
import '../../../theme.dart';
import '../../../widgets.dart';

class OnboardingStepScaffold extends StatelessWidget {
  const OnboardingStepScaffold({
    required this.step,
    required this.content,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    super.key,
    this.nextLabel = AppStrings.onboardingNext,
  }) : assert(step >= 1 && step <= 3);

  final int step;
  final Widget content;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final String nextLabel;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.onboardingSideInset,
                AppSpace.onboardingTopInset,
                AppSpace.onboardingSideInset,
                AppSpace.s24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.onboardingStepLabel(step),
                          style: AppTheme.caption,
                        ),
                      ),
                      AppLink(
                        AppStrings.onboardingSkip,
                        onTap: onSkip,
                        semanticsLabel: AppStrings.onboardingSkipSemantics,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s12),
                  StepProgress(total: 3, current: step),
                  const SizedBox(height: AppSpace.s20),
                  content,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.onboardingSideInset,
              AppSpace.s8,
              AppSpace.onboardingSideInset,
              AppSpace.onboardingButtonBottomInset,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: AppStrings.onboardingBack,
                    onPressed: onBack,
                  ),
                ),
                const SizedBox(width: AppSpace.onboardingButtonGap),
                Expanded(
                  child: PrimaryButton(
                    label: nextLabel,
                    onPressed: onNext,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

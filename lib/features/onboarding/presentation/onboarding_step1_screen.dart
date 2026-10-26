import 'package:flutter/material.dart';

import '../../../core/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../theme.dart';
import '../../../widgets.dart';
import 'onboarding_step_scaffold.dart';

class OnboardingStep1Screen extends StatelessWidget {
  const OnboardingStep1Screen({
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => OnboardingStepScaffold(
    step: 1,
    onBack: onBack,
    onNext: onNext,
    onSkip: onSkip,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: AppStrings.onboardingStep1Illustration,
          image: true,
          child: const ExcludeSemantics(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                AppColors.paper,
                BlendMode.multiply,
              ),
              child: ImageOrPlaceholder(
                asset: 'assets/images/onboarding_step1.png',
                width: double.infinity,
                height: AppSpace.onboardingIllustrationHeight,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s24),
        Text(AppStrings.onboardingStep1Title, style: AppTheme.onboardingTitleM),
        const SizedBox(height: AppSpace.s12),
        Text(AppStrings.onboardingStep1Body, style: AppTheme.onboardingBody),
      ],
    ),
  );
}

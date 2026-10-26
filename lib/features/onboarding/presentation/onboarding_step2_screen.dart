import 'package:flutter/material.dart';

import '../../../core/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/numbered_rule_list.dart';
import '../../../theme.dart';
import '../../../widgets.dart';
import 'onboarding_step_scaffold.dart';

class OnboardingStep2Screen extends StatelessWidget {
  const OnboardingStep2Screen({
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
    step: 2,
    onBack: onBack,
    onNext: onNext,
    onSkip: onSkip,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: AppStrings.onboardingStep2Illustration,
          image: true,
          child: const ExcludeSemantics(
            child: ImageOrPlaceholder(
              asset: 'assets/images/onboarding_step2.png',
              width: double.infinity,
              height: AppSpace.onboardingIllustrationHeight,
              fit: BoxFit.cover,
              blendWithPaper: true,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s24),
        Text(AppStrings.onboardingStep2Title, style: AppTheme.onboardingTitleM),
        const SizedBox(height: AppSpace.s12),
        Text(AppStrings.onboardingStep2Body, style: AppTheme.onboardingBody),
        const SizedBox(height: AppSpace.s16),
        const NumberedRuleList(
          items: [
            NumberedRuleListItem(
              number: AppStrings.onboardingStep2TipNumber1,
              text: AppStrings.onboardingStep2Tip1,
            ),
            NumberedRuleListItem(
              number: AppStrings.onboardingStep2TipNumber2,
              text: AppStrings.onboardingStep2Tip2,
            ),
            NumberedRuleListItem(
              number: AppStrings.onboardingStep2TipNumber3,
              text: AppStrings.onboardingStep2Tip3,
            ),
          ],
        ),
      ],
    ),
  );
}

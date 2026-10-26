import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../../theme.dart';
import '../../widgets.dart';

class AppSheet extends StatelessWidget {
  const AppSheet({
    required this.label,
    this.message,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.title,
    this.content,
    this.primaryBusy = false,
    this.primaryEnabled = true,
    this.secondaryAsLink = false,
    super.key,
  });

  final String label;
  final String? message;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String? title;
  final Widget? content;
  final bool primaryBusy;
  final bool primaryEnabled;
  final bool secondaryAsLink;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.onboardingSideInset,
          AppSpace.onboardingPermissionSheetTopInset,
          AppSpace.onboardingSideInset,
          AppSpace.onboardingPermissionSheetBottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Rule(margin: EdgeInsets.zero),
            const SizedBox(height: AppSpace.s20),
            if (title != null) ...[
              Text(title!, style: AppTheme.serif(AppSpace.appSheetTitleSize)),
              const SizedBox(height: AppSpace.appSheetContentGap),
            ],
            if (message != null) Text(message!, style: AppTheme.onboardingBody),
            ?content,
            if (primaryLabel != null && onPrimary != null) ...[
              const SizedBox(height: AppSpace.s24),
              PrimaryButton(
                label: primaryLabel!,
                onPressed: primaryEnabled ? onPrimary : null,
                busy: primaryBusy,
              ),
            ],
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: AppSpace.s8),
              if (secondaryAsLink)
                Center(child: AppLink(secondaryLabel!, onTap: onSecondary!))
              else
                SecondaryButton(label: secondaryLabel!, onPressed: onSecondary),
            ],
          ],
        ),
      ),
    ),
  );
}

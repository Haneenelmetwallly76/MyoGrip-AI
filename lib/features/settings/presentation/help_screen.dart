import 'package:flutter/material.dart';

import '../../../core/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../theme.dart';
import '../../../widgets.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screenH,
        AppSpace.homeTopInset,
        AppSpace.screenH,
        AppSpace.s64,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.helpTitle, style: AppTheme.serif(34)),
          const SizedBox(height: AppSpace.s20),
          for (var index = 0; index < AppStrings.helpQuestions.length; index++)
            _HelpRow(
              title: AppStrings.helpQuestions[index],
              answer: AppStrings.helpAnswers[index],
              expanded: _expandedIndex == index,
              onTap: () => setState(
                () => _expandedIndex = _expandedIndex == index ? null : index,
              ),
            ),
          const SizedBox(height: AppSpace.s24),
          Text(
            AppStrings.helpContactClinic,
            style: AppTheme.body(weight: FontWeight.w700),
          ),
          const Rule(margin: EdgeInsets.symmetric(vertical: AppSpace.s8)),
          _ContactRow(
            label: AppStrings.helpCallClinic,
            onTap: () => _showUnavailable(context),
          ),
          const Rule(margin: EdgeInsets.zero),
          _ContactRow(
            label: AppStrings.helpSendMessage,
            onTap: () => _showUnavailable(context),
          ),
          const Rule(margin: EdgeInsets.zero),
          const SizedBox(height: AppSpace.s24),
          Text(AppStrings.helpVersion, style: AppTheme.caption),
        ],
      ),
    ),
  );
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({
    required this.title,
    required this.answer,
    required this.expanded,
    required this.onTap,
  });

  final String title;
  final String answer;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Rule(margin: EdgeInsets.zero),
      Semantics(
        button: true,
        expanded: expanded,
        label: title,
        onTap: onTap,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpace.minTouchTarget),
            child: Row(
              children: [
                Expanded(child: Text(title, style: AppTheme.body(size: 16))),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.inkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.topCenter,
        child: expanded
            ? Padding(
                padding: const EdgeInsets.only(
                  bottom: AppSpace.s16,
                  right: AppSpace.s32,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(answer, style: AppTheme.body(color: AppColors.inkMuted)),
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
    ],
  );
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    onTap: onTap,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: AppSpace.minTouchTarget,
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTheme.body())),
            const Icon(Icons.chevron_right, color: AppColors.inkMuted),
          ],
        ),
      ),
    ),
  );
}

void _showUnavailable(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text(AppStrings.helpNotAvailable)));
}

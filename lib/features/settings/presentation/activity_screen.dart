import 'package:flutter/material.dart';

import '../../../core/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../theme.dart';
import '../../../widgets.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  bool _alertsOnly = false;

  @override
  Widget build(BuildContext context) {
    final entries = AppStrings.activityEntries
        .where((entry) => !_alertsOnly || entry.alert)
        .toList();
    return SafeArea(
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
            Text(AppStrings.activityTitle, style: AppTheme.serif(34)),
            const SizedBox(height: AppSpace.s16),
            Row(
              children: [
                _ActivityTab(
                  label: AppStrings.activityAll,
                  selected: !_alertsOnly,
                  onTap: () => setState(() => _alertsOnly = false),
                ),
                _ActivityTab(
                  label: AppStrings.activityAlerts,
                  selected: _alertsOnly,
                  onTap: () => setState(() => _alertsOnly = true),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.s16),
            if (entries.isEmpty)
              Text(AppStrings.activityEmpty, style: AppTheme.body())
            else
              for (final day in [
                AppStrings.activityToday,
                AppStrings.activityYesterday,
              ]) ...[
                if (entries.any((entry) => entry.day == day)) ...[
                  Text(day, style: AppTheme.body(weight: FontWeight.w700)),
                  const Rule(
                    margin: EdgeInsets.symmetric(vertical: AppSpace.s8),
                  ),
                  for (final entry in entries.where((item) => item.day == day))
                    _ActivityEntry(
                      time: entry.time,
                      title: entry.title,
                      detail: entry.detail,
                      alert: entry.alert,
                    ),
                ],
              ],
          ],
        ),
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '$label${selected ? ', selected' : ''}',
    onTap: onTap,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: AppSpace.minTouchTarget,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: AppTheme.body(
                    color: selected ? AppColors.forest : AppColors.inkMuted,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 30,
                  height: 2,
                  color: selected ? AppColors.forest : Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ActivityEntry extends StatelessWidget {
  const _ActivityEntry({
    required this.time,
    required this.title,
    required this.detail,
    required this.alert,
  });

  final String time;
  final String title;
  final String detail;
  final bool alert;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Rule(margin: EdgeInsets.zero),
      ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              child: Text(time, style: AppTheme.caption),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: alert ? AppColors.clay : AppColors.forest,
                shape: alert ? BoxShape.rectangle : BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: AppTheme.body(size: 16)),
                  if (detail.isNotEmpty)
                    Text(detail, style: AppTheme.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

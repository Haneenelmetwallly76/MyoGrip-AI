import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/hours_bar_chart.dart';
import '../../../core/widgets/profile_empty_usage.dart';
import '../../../core/widgets/trend_line_chart.dart';
import '../../../theme.dart';
import '../../../widgets.dart';
import '../application/profile_controller.dart';
import '../application/profile_providers.dart';
import 'send_report_sheet.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _showThirtyDays = false;

  Future<void> _showReportSheet(String clinicianName) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SendReportSheet(
        clinicianName: clinicianName,
        repository: ref.read(reportRepositoryProvider),
        onSent: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text(AppStrings.profileReportSent)),
            );
        },
      ),
    );
  }

  Future<void> _editProfile(ProfileController controller) async {
    final saved = await context.push<bool>('/profile/edit');
    if (!mounted || saved != true) return;
    await controller.load();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.editProfileSaved)));
  }

  String _profileMeta(int age, String email) =>
      '${AppStrings.profileAge} $age · $email';

  String _syncLabel(DateTime lastSyncedAt) {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final syncDate = DateUtils.dateOnly(lastSyncedAt);
    final time = DateFormat('HH:mm').format(lastSyncedAt);
    if (syncDate == today) return '${AppStrings.profileSyncedToday} $time';
    if (syncDate == today.subtract(const Duration(days: 1))) {
      return '${AppStrings.profileSyncedYesterday} $time';
    }
    return '${AppStrings.profileSyncedDate} ${DateFormat('d MMMM').format(lastSyncedAt)} at $time';
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(profileControllerProvider);
    final profile = controller.profile;
    final usage = controller.usage;
    final noClinician = profile != null && !controller.hasClinician;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screenH,
                AppSpace.homeTopInset,
                AppSpace.screenH,
                AppSpace.settingsScrollBottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.profileTitle,
                    style: AppTheme.serif(AppSpace.loginTitleSize),
                  ),
                  const SizedBox(height: AppSpace.profileHeaderGap),
                  if (controller.state == ProfileLoadState.loading)
                    const _ProfileSkeleton()
                  else if (controller.state == ProfileLoadState.failed)
                    _LoadError(onRetry: () => unawaited(controller.load()))
                  else if (profile != null && usage != null) ...[
                    _ProfileIdentity(
                      name: profile.name.isEmpty
                          ? AppStrings.profilePatientFallbackName
                          : profile.name,
                      meta: _profileMeta(profile.age, profile.email),
                      clinic: profile.clinicName == null
                          ? AppStrings.profileLinkedToClinic
                          : 'Linked to ${profile.clinicName}',
                      onEdit: () => _editProfile(controller),
                    ),
                    const Rule(
                      margin: EdgeInsets.symmetric(vertical: AppSpace.s16),
                    ),
                    if (!usage.hasUsage)
                      const ProfileEmptyUsage()
                    else ...[
                      _HoursSectionHeader(
                        showThirtyDays: _showThirtyDays,
                        onChange: (showThirtyDays) =>
                            setState(() => _showThirtyDays = showThirtyDays),
                      ),
                      const SizedBox(height: AppSpace.profileChartHeaderGap),
                      AnimatedSwitcher(
                        duration: const Duration(
                          milliseconds: AppSpace.profileBarSwitchDurationMs,
                        ),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: HoursBarChart(
                          key: ValueKey(_showThirtyDays),
                          values: _showThirtyDays
                              ? usage.monthlyHours
                              : usage.weeklyHours,
                          showThirtyDays: _showThirtyDays,
                        ),
                      ),
                      const Rule(
                        margin: EdgeInsets.symmetric(vertical: AppSpace.s16),
                      ),
                      _GripStrengthHeader(trend: usage.gripTrend30d),
                      const SizedBox(height: AppSpace.profileTrendHeaderGap),
                      TrendLineChart(values: usage.gripTrend30d),
                      const Rule(margin: EdgeInsets.only(top: AppSpace.s8)),
                    ],
                    const SizedBox(height: AppSpace.profileSyncTopGap),
                    Text(
                      _syncLabel(usage.lastSyncedAt),
                      style: AppTheme.body(
                        size: AppSpace.profileCaptionSize,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screenH,
              AppSpace.profileReportButtonTopInset,
              AppSpace.screenH,
              AppSpace.profileReportButtonBottomInset,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (noClinician)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.s8),
                    child: Text(
                      AppStrings.profileNoClinician,
                      style: AppTheme.body(
                        size: AppSpace.profileCaptionSize,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                Opacity(
                  opacity: noClinician ? .4 : 1,
                  child: PrimaryButton(
                    label: AppStrings.profileSendReport,
                    onPressed:
                        noClinician ||
                            controller.state != ProfileLoadState.loaded
                        ? null
                        : () =>
                              _showReportSheet(profile?.clinicianName ?? ''),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({
    required this.name,
    required this.meta,
    required this.clinic,
    required this.onEdit,
  });

  final String name;
  final String meta;
  final String clinic;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              name,
              style: AppTheme.serif(AppSpace.profileHeadingSize),
            ),
          ),
          AppLink(AppStrings.profileEdit, onTap: onEdit),
        ],
      ),
      Text(
        meta,
        style: AppTheme.body(
          size: AppSpace.profileCaptionSize,
          color: AppColors.inkMuted,
        ),
      ),
      Text(
        clinic,
        style: AppTheme.body(
          size: AppSpace.profileCaptionSize,
          color: AppColors.inkMuted,
        ),
      ),
    ],
  );
}

class _HoursSectionHeader extends StatelessWidget {
  const _HoursSectionHeader({
    required this.showThirtyDays,
    required this.onChange,
  });

  final bool showThirtyDays;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          AppStrings.profileHoursWorn,
          style: AppTheme.body(
            size: AppSpace.settingsSectionTitleSize,
            weight: FontWeight.w700,
          ),
        ),
      ),
      _RangeTab(
        label: AppStrings.profileSevenDays,
        selected: !showThirtyDays,
        onTap: () => onChange(false),
      ),
      const SizedBox(width: AppSpace.profileChartTabGap),
      _RangeTab(
        label: AppStrings.profileThirtyDays,
        selected: showThirtyDays,
        onTap: () => onChange(true),
      ),
    ],
  );
}

class _RangeTab extends StatelessWidget {
  const _RangeTab({
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
    label: label,
    onTap: onTap,
    child: ExcludeSemantics(
      child: InkWell(
        excludeFromSemantics: true,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpace.minTouchTarget),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s4,
                vertical: AppSpace.profileRangeTabVerticalPadding,
              ),
              child: Text(
                label,
                style:
                    AppTheme.body(
                      size: AppSpace.profileCaptionSize,
                      color: selected ? AppColors.forest : AppColors.inkMuted,
                      weight: selected ? FontWeight.w600 : FontWeight.w400,
                    ).copyWith(
                      decoration: selected
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _GripStrengthHeader extends StatelessWidget {
  const _GripStrengthHeader({required this.trend});

  final List<double> trend;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          AppStrings.profileGripStrength,
          style: AppTheme.body(
            size: AppSpace.settingsSectionTitleSize,
            weight: FontWeight.w700,
          ),
        ),
      ),
      Text(
        _trendLabel(),
        style: AppTheme.body(
          size: AppSpace.profileCaptionSize,
          color: AppColors.forest,
        ),
      ),
    ],
  );

  String _trendLabel() {
    final firstWeek = _average(trend.take(7));
    final lastWeek = _average(trend.skip(math.max(0, trend.length - 7)));
    if (firstWeek == 0) return AppStrings.profileSteady;
    final change = (lastWeek - firstWeek) / firstWeek;
    if (change > .05) return AppStrings.profileRising;
    if (change < -.05) return AppStrings.profileFalling;
    return AppStrings.profileSteady;
  }

  double _average(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return list.reduce((first, second) => first + second) / list.length;
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        AppStrings.profileLoadError,
        style: AppTheme.body(
          size: AppSpace.profileCaptionSize,
          color: AppColors.clay,
        ),
      ),
      AppLink(AppStrings.profileRetry, onTap: onRetry),
    ],
  );
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SkeletonLine(width: AppSpace.profileSkeletonMediumWidth),
      SizedBox(height: AppSpace.s8),
      _SkeletonLine(width: AppSpace.profileSkeletonLongWidth),
      SizedBox(height: AppSpace.s8),
      _SkeletonLine(width: AppSpace.profileSkeletonShortWidth),
      SizedBox(height: AppSpace.s24),
      Rule(margin: EdgeInsets.zero),
      SizedBox(height: AppSpace.s24),
      _SkeletonLine(width: AppSpace.profileSkeletonLongWidth),
      SizedBox(height: AppSpace.s16),
      _SkeletonLine(width: AppSpace.profileSkeletonMediumWidth),
      SizedBox(height: AppSpace.s24),
      Rule(margin: EdgeInsets.zero),
      SizedBox(height: AppSpace.s24),
      _SkeletonLine(width: AppSpace.profileSkeletonLongWidth),
    ],
  );
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(
      minHeight: AppSpace.profileSkeletonLineHeight,
      maxWidth: width,
    ),
    width: double.infinity,
    color: AppColors.rule,
  );
}

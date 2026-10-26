import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../data/models/arm_settings.dart';
import '../../../theme.dart';
import '../../../widgets.dart';
import '../application/settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({this.onSignOut, super.key});

  final Future<void> Function()? onSignOut;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _showingTensNotice = false;

  SettingsController get _controller => ref.read(settingsControllerProvider);

  Future<void> _changeSensitivity(int value) async {
    final level = SensitivityLevel.values[value];
    await _save(
      () => _controller.setSensitivity(level),
      () => _changeSensitivity(value),
    );
  }

  Future<void> _changeHaptics(bool enabled) async {
    if (!enabled) {
      await _save(
        () => _controller.setHaptics(false),
        () => _changeHaptics(false),
      );
      return;
    }
    if (_showingTensNotice) return;
    _showingTensNotice = true;
    try {
      final preferences = await SharedPreferences.getInstance();
      if (preferences.getBool(AppStrings.tensNoticeSeenPreferenceKey) == true) {
        await _save(
          () => _controller.setHaptics(true),
          () => _changeHaptics(true),
        );
        return;
      }
      if (!mounted) return;
      final shouldEnable = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => AppSheet(
          label: AppStrings.settingsTensSheetLabel,
          message: AppStrings.settingsTensNotice,
          primaryLabel: AppStrings.settingsTensTurnOn,
          onPrimary: () => Navigator.of(sheetContext).pop(true),
          secondaryLabel: AppStrings.settingsTensCancel,
          onSecondary: () => Navigator.of(sheetContext).pop(false),
        ),
      );
      await preferences.setBool(AppStrings.tensNoticeSeenPreferenceKey, true);
      if (shouldEnable == true && mounted) {
        await _save(
          () => _controller.setHaptics(true),
          () => _changeHaptics(true),
        );
      }
    } on Object catch (error, stackTrace) {
      debugPrint('Could not read or store TENS notice preference: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        _showRetrySnack(() => unawaited(_changeHaptics(true)));
      }
    } finally {
      _showingTensNotice = false;
    }
  }

  Future<void> _changeGrip(int index, bool enabled) async {
    if (!enabled &&
        _controller.settings.enabledGrips.length == 1 &&
        _controller.settings.enabledGrips.contains(index)) {
      _showSnack(AppStrings.settingsLastGripRequired);
      return;
    }
    await _save(
      () => _controller.setGripEnabled(index, enabled),
      () => _changeGrip(index, enabled),
    );
  }

  Future<void> _save(
    Future<SettingsChangeResult> Function() save,
    VoidCallback retry,
  ) async {
    final result = await save();
    if (!mounted) return;
    switch (result) {
      case SettingsChangeResult.saved:
        if (_controller.isConnected) _showSnack(AppStrings.settingsSaved);
      case SettingsChangeResult.pending:
        break;
      case SettingsChangeResult.failed:
        _showRetrySnack(retry);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: AppTheme.body(color: AppColors.paper)),
        ),
      );
  }

  void _showRetrySnack(VoidCallback retry) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.settingsSaveFailed,
            style: AppTheme.body(color: AppColors.paper),
          ),
          action: SnackBarAction(
            label: AppStrings.settingsRetry,
            onPressed: retry,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(settingsControllerProvider);
    final settings = controller.settings;
    final enabledCount = settings.enabledGrips.length;
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          SingleChildScrollView(
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
                  AppStrings.settingsTitle,
                  style: AppTheme.serif(AppSpace.loginTitleSize),
                ),
                const SizedBox(height: AppSpace.s20),
                _SectionHeading(
                  label: AppStrings.settingsSensitivity,
                  pending: settings.pendingKeys.contains(
                    SettingsController.sensitivityKey,
                  ),
                ),
                const SizedBox(height: AppSpace.settingsSectionCaptionGap),
                Text(
                  AppStrings.settingsSensitivityDescription,
                  style: AppTheme.body(
                    size: AppSpace.settingsSectionCaptionSize,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: AppSpace.settingsSegmentTopGap),
                SegmentedThree(
                  value: settings.sensitivity.index,
                  options: const [
                    AppStrings.settingsLow,
                    AppStrings.settingsMedium,
                    AppStrings.settingsHigh,
                  ],
                  onChanged: (value) => unawaited(_changeSensitivity(value)),
                ),
                const Rule(
                  margin: EdgeInsets.only(
                    top: AppSpace.settingsSensitivityRuleGap,
                    bottom: AppSpace.settingsSensitivityRuleBottomGap,
                  ),
                ),
                _HapticsSection(
                  enabled: settings.hapticEnabled,
                  pending: settings.pendingKeys.contains(
                    SettingsController.hapticsKey,
                  ),
                  onChanged: (value) => unawaited(_changeHaptics(value)),
                ),
                const Rule(
                  margin: EdgeInsets.symmetric(
                    vertical: AppSpace.settingsHapticsRuleGap,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.settingsGrips,
                        style: AppTheme.body(
                          size: AppSpace.settingsSectionTitleSize,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '$enabledCount ${AppStrings.settingsOnCount}',
                      style: AppTheme.body(
                        size: AppSpace.settingsCountSize,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s4),
                for (
                  var index = 0;
                  index < AppStrings.settingsGestureNames.length;
                  index++
                )
                  _GripRow(
                    index: index,
                    name: AppStrings.settingsGestureNames[index],
                    enabled: settings.enabledGrips.contains(index),
                    pending: settings.pendingKeys.contains('grip:$index'),
                    onChanged: (value) => unawaited(_changeGrip(index, value)),
                  ),
                const SizedBox(height: AppSpace.s20),
                Text(
                  AppStrings.settingsMore,
                  style: AppTheme.body(
                    size: AppSpace.settingsSectionTitleSize,
                    weight: FontWeight.w700,
                  ),
                ),
                const Rule(
                  margin: EdgeInsets.symmetric(vertical: AppSpace.s8),
                ),
                _SettingsLink(
                  label: AppStrings.settingsCalibration,
                  onTap: () => context.go('/calibration'),
                ),
                const Rule(margin: EdgeInsets.zero),
                _SettingsLink(
                  label: AppStrings.settingsActivityLog,
                  onTap: () => context.go('/activity'),
                ),
                const Rule(margin: EdgeInsets.zero),
                _SettingsLink(
                  label: AppStrings.settingsHelpSafety,
                  onTap: () => context.go('/help'),
                ),
                const Rule(margin: EdgeInsets.zero),
                const SizedBox(height: AppSpace.s8),
                AppLink(
                  AppStrings.settingsSignOut,
                  onTap: () async {
                    if (widget.onSignOut != null) {
                      await widget.onSignOut!();
                    } else if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
          ),
          const Positioned(left: 0, right: 0, bottom: 0, child: FadeAbove()),
        ],
      ),
    );
  }
}

class _SettingsLink extends StatelessWidget {
  const _SettingsLink({required this.label, required this.onTap});

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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.label, this.pending = false});

  final String label;
  final bool pending;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        label,
        style: AppTheme.body(
          size: AppSpace.settingsSectionTitleSize,
          weight: FontWeight.w700,
        ),
      ),
      if (pending) ...[
        const SizedBox(width: AppSpace.s8),
        const _PendingLabel(),
      ],
    ],
  );
}

class _HapticsSection extends StatelessWidget {
  const _HapticsSection({
    required this.enabled,
    required this.pending,
    required this.onChanged,
  });

  final bool enabled;
  final bool pending;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeading(
              label: AppStrings.settingsHapticFeedback,
              pending: pending,
            ),
            Text(
              AppStrings.settingsTensDescription,
              style: AppTheme.body(
                size: AppSpace.settingsSectionCaptionSize,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
      SquareSwitch(
        value: enabled,
        label: AppStrings.settingsSwitchSemantics(
          AppStrings.settingsHapticFeedback,
          enabled,
        ),
        onChanged: onChanged,
      ),
    ],
  );
}

class _GripRow extends StatelessWidget {
  const _GripRow({
    required this.index,
    required this.name,
    required this.enabled,
    required this.pending,
    required this.onChanged,
  });

  final int index;
  final String name;
  final bool enabled;
  final bool pending;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Rule(margin: EdgeInsets.zero),
      ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpace.settingsGripRowHeight,
        ),
        child: Row(
          children: [
            SizedBox(
              width: AppSpace.settingsGripNumberColumnWidth,
              child: Text(
                '$index',
                style: AppTheme.serif(
                  AppSpace.settingsGripNumberSize,
                  weight: FontWeight.w600,
                ).copyWith(color: AppColors.inkMuted),
              ),
            ),
            Expanded(
              child: Text(
                name,
                style: AppTheme.body(size: AppSpace.settingsGripLabelSize),
              ),
            ),
            if (pending) ...[
              const _PendingLabel(),
              const SizedBox(width: AppSpace.s8),
            ],
            SquareSwitch(
              value: enabled,
              label: AppStrings.settingsSwitchSemantics(name, enabled),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    ],
  );
}

class _PendingLabel extends StatelessWidget {
  const _PendingLabel();

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppStrings.settingsPending,
    child: Text(
      AppStrings.settingsPending,
      style: AppTheme.body(
        size: AppSpace.settingsPendingSize,
        color: AppColors.clay,
        weight: FontWeight.w600,
      ),
    ),
  );
}

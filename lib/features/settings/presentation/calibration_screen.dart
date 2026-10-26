import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/muscle_waveform.dart';
import '../../../core/widgets/step_progress.dart';
import '../../../core/widgets/hand_diagram.dart';
import '../../../data/gesture_map.dart';
import '../../../theme.dart';
import '../../../widgets.dart' hide HandDiagram;

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  int _step = 1;
  int _countdown = 3;
  int _repetitions = 0;
  Timer? _timer;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRelaxation() {
    if (_running) return;
    setState(() {
      _running = true;
      _countdown = 3;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown == 1) {
        timer.cancel();
        setState(() {
          _countdown = 0;
          _running = false;
        });
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _record() {
    if (_running || _repetitions >= 3) return;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        _repetitions++;
        if (_repetitions >= 3) {
          timer.cancel();
          _running = false;
        }
      });
    });
  }

  void _next() {
    if (_step >= 4 || !_canAdvance) return;
    setState(() {
      _step++;
      _repetitions = 0;
      _countdown = 3;
      _running = false;
    });
  }

  void _back() {
    if (_step <= 1) {
      context.go('/settings');
      return;
    }
    _timer?.cancel();
    setState(() {
      _step--;
      _repetitions = 0;
      _running = false;
      _countdown = 3;
    });
  }

  bool get _canAdvance => switch (_step) {
    1 => _countdown == 0 && !_running,
    2 || 3 => _repetitions == 3 && !_running,
    _ => false,
  };

  void _finish() {
    final messenger = ScaffoldMessenger.of(context);
    context.go('/settings');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.calibrationSaved)),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_step) {
      1 => AppStrings.calibrationRelaxTitle,
      2 => AppStrings.calibrationGesture1Title,
      3 => AppStrings.calibrationGesture2Title,
      _ => AppStrings.calibrationCompleteTitle,
    };
    final body = switch (_step) {
      1 => AppStrings.calibrationRelaxBody,
      2 => AppStrings.calibrationGesture1Body,
      3 => AppStrings.calibrationGesture2Body,
      _ => '',
    };
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screenH,
                  AppSpace.onboardingTopInset,
                  AppSpace.screenH,
                  AppSpace.s20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Step $_step of 4',
                            style: AppTheme.caption,
                          ),
                        ),
                        AppLink(
                          AppStrings.calibrationCancel,
                          onTap: () => context.go('/settings'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.s12),
                    StepProgress(total: 4, current: _step),
                    const SizedBox(height: AppSpace.s20),
                    SizedBox(
                      height: AppSpace.onboardingIllustrationHeight,
                      width: double.infinity,
                      child: Center(
                        child: _step == 4
                            ? const SizedBox(
                                width: AppSpace.homeHandWidth,
                                height: AppSpace.homeHandHeight,
                                child: Center(child: Text('✓')),
                              )
                            : const HandDiagram(
                                activeFingers: <Finger>{},
                                dimmed: false,
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.s20),
                    Text(title, style: AppTheme.onboardingTitleM),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.s12),
                      Text(body, style: AppTheme.onboardingBody),
                    ],
                    const SizedBox(height: AppSpace.s20),
                    if (_step == 1) _buildRelaxation(),
                    if (_step == 2 || _step == 3) _buildGesture(),
                    if (_step == 4) _buildComplete(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screenH,
                AppSpace.s12,
                AppSpace.screenH,
                AppSpace.s16,
              ),
              child: _step == 4
                  ? PrimaryButton(
                      label: AppStrings.calibrationDone,
                      onPressed: _finish,
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: AppStrings.onboardingBack,
                            onPressed: _back,
                          ),
                        ),
                        const SizedBox(width: AppSpace.onboardingButtonGap),
                        Expanded(
                          child: PrimaryButton(
                            label: AppStrings.onboardingNext,
                            onPressed: _canAdvance ? _next : null,
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

  Widget _buildRelaxation() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (!_running && _countdown == 3)
        PrimaryButton(
          label: AppStrings.calibrationStart,
          onPressed: _startRelaxation,
        )
      else ...[
        Center(
          child: Text(
            _running ? '$_countdown' : '0',
            style: AppTheme.serif(48),
          ),
        ),
        const SizedBox(height: AppSpace.s12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: (3 - _countdown) / 3,
            minHeight: 2,
            backgroundColor: AppColors.rule,
            color: AppColors.forest,
          ),
        ),
      ],
    ],
  );

  Widget _buildGesture() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      MuscleWaveform(active: _running, seed: _step),
      const SizedBox(height: AppSpace.s12),
      Row(
        children: List.generate(
          3,
          (index) => Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(right: AppSpace.s8),
            decoration: BoxDecoration(
              color: index < _repetitions ? AppColors.forest : AppColors.rule,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpace.s16),
      PrimaryButton(
        label: _running ? 'Recording…' : AppStrings.calibrationRecord,
        onPressed: _running || _repetitions == 3 ? null : _record,
      ),
    ],
  );

  Widget _buildComplete() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(AppStrings.calibrationGood, style: AppTheme.serif(44)),
      const SizedBox(height: AppSpace.s8),
      Text(AppStrings.calibrationQuality, style: AppTheme.caption),
      const Rule(margin: EdgeInsets.symmetric(vertical: AppSpace.s16)),
      const _CalibrationResult(text: 'Gesture 1 · 3 of 3 recorded'),
      const Rule(margin: EdgeInsets.zero),
      const _CalibrationResult(text: 'Gesture 2 · 3 of 3 recorded'),
      const Rule(margin: EdgeInsets.zero),
    ],
  );
}

class _CalibrationResult extends StatelessWidget {
  const _CalibrationResult({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppSpace.minTouchTarget,
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: AppTheme.body()),
    ),
  );
}

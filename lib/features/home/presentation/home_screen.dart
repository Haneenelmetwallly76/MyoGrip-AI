import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/compact_stop_button.dart';
import '../../../core/widgets/hand_diagram.dart';
import '../../../core/widgets/muscle_waveform.dart';
import '../../../core/widgets/stopped_notice.dart';
import '../../../data/gesture_map.dart';
import '../../../data/models/arm_status.dart';
import '../../../theme.dart';
import '../../../widgets.dart' hide HandDiagram;
import '../application/emergency_stop_controller.dart';
import '../application/home_providers.dart';
import 'connection_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    this.showBottomTabBar = true,
    this.onTabSelected,
    super.key,
  });

  final bool showBottomTabBar;
  final ValueChanged<int>? onTabSelected;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  StreamSubscription<ArmStatus>? _statusSubscription;
  ArmStatus? _status;
  bool _armLowShown = false;
  bool _armbandLowShown = false;
  int _signalChannel = 1;

  @override
  void initState() {
    super.initState();
    _statusSubscription = ref
        .read(armRepositoryProvider)
        .watchStatus()
        .listen(_onStatus, onError: _onStatusError);
  }

  void _onStatus(ArmStatus status) {
    if (!mounted) return;
    setState(() => _status = status);
    _showLowBatteryIfCrossed(status);
  }

  void _onStatusError(Object error, StackTrace stackTrace) {
    debugPrint('Could not read arm status: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  void _showLowBatteryIfCrossed(ArmStatus status) {
    final armLow = status.armBattery != null && status.armBattery! < 20;
    final armbandLow =
        status.armbandBattery != null && status.armbandBattery! < 20;
    if ((armLow && !_armLowShown) || (armbandLow && !_armbandLowShown)) {
      _armLowShown = _armLowShown || armLow;
      _armbandLowShown = _armbandLowShown || armbandLow;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showSnack(context, AppStrings.homeLowBatterySnackbar);
      });
    }
  }

  @override
  void dispose() {
    unawaited(_statusSubscription?.cancel());
    super.dispose();
  }

  String _connectionText(ArmStatus status) => switch (status.connection) {
    ArmConnection.connected =>
      status.armbandLinked
          ? AppStrings.homeConnectionLinked
          : AppStrings.homeConnectionNotLinked,
    ArmConnection.connecting => AppStrings.homeConnecting,
    ArmConnection.disconnected =>
      '${AppStrings.homeDisconnected} ${_lastSeen(status.lastSeenAt)}',
  };

  String _lastSeen(DateTime? time) =>
      time == null ? '—' : DateFormat('HH:mm').format(time);

  Future<void> _showConnections(ArmStatus? status) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => ConnectionSheet(
          repository: ref.read(armRepositoryProvider),
          status: status,
        ),
      );

  @override
  Widget build(BuildContext context) {
    ref.listen<EmergencyStopState>(emergencyStopControllerProvider, (
      previous,
      next,
    ) {
      if (next == EmergencyStopState.stopped &&
          previous != EmergencyStopState.stopped) {
        unawaited(HapticFeedback.heavyImpact());
      }
    });

    final repository = ref.watch(armRepositoryProvider);
    final stopState = ref.watch(emergencyStopControllerProvider);
    final status = _status;
    final date = DateFormat(
      AppStrings.homeDateFormat,
    ).format(ref.watch(currentDateProvider));
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screenH,
                  AppSpace.homeTopInset,
                  AppSpace.screenH,
                  AppSpace.homeBottomInset,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(date, style: AppTheme.caption),
                    const SizedBox(height: AppSpace.homeDateTitleGap),
                    Text(
                      AppStrings.homeTitle,
                      style: AppTheme.serif(AppSpace.loginTitleSize),
                    ),
                    const SizedBox(height: AppSpace.homeTitleConnectionGap),
                    _ConnectionLine(
                      text: status == null
                          ? AppStrings.homeConnecting
                          : _connectionText(status),
                      connection:
                          status?.connection ?? ArmConnection.connecting,
                      onTap: () => unawaited(_showConnections(status)),
                    ),
                    if (!repository.hasLinkedDevice) ...[
                      const Rule(
                        margin: EdgeInsets.symmetric(
                          vertical: AppSpace.homeRuleMargin,
                        ),
                      ),
                      Text(
                        AppStrings.homeNoDeviceLinked,
                        style: AppTheme.body(
                          size: AppSpace.homeStatusCaptionSize,
                        ),
                      ),
                      const SizedBox(height: AppSpace.s4),
                      Text(
                        AppStrings.homePairPrompt,
                        style: AppTheme.body(color: AppColors.inkMuted),
                      ),
                      AppLink(
                        AppStrings.homePairDevices,
                        onTap: () => context.go(
                          '/onboarding/3?mode=${AppStrings.homeRePairMode}',
                        ),
                      ),
                    ] else if (status != null) ...[
                      const Rule(
                        margin: EdgeInsets.symmetric(
                          vertical: AppSpace.homeRuleMargin,
                        ),
                      ),
                      if (stopState == EmergencyStopState.stopped) ...[
                        const StoppedNotice(),
                        const Rule(
                          margin: EdgeInsets.symmetric(
                            vertical: AppSpace.homeRuleMargin,
                          ),
                        ),
                      ],
                      _LiveStatus(
                        status: status,
                        stopped: stopState == EmergencyStopState.stopped,
                      ),
                      const Rule(
                        margin: EdgeInsets.symmetric(
                          vertical: AppSpace.homeRuleMargin,
                        ),
                      ),
                      _BatteryMeterRow(
                        label: AppStrings.homeArmBattery,
                        value: status.armBattery,
                      ),
                      const Rule(
                        margin: EdgeInsets.symmetric(vertical: AppSpace.s8),
                      ),
                      _BatteryMeterRow(
                        label: AppStrings.homeArmbandBattery,
                        value: status.armbandBattery,
                      ),
                      const Rule(
                        margin: EdgeInsets.symmetric(vertical: AppSpace.s8),
                      ),
                      _MuscleSignalSection(
                        active: status.activeGesture != null,
                        paused: stopState == EmergencyStopState.stopped,
                        channel: _signalChannel,
                        onChannelTap: () => setState(
                          () => _signalChannel = _signalChannel % 8 + 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.screenH,
                vertical: AppSpace.homeStopVerticalInset,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (stopState == EmergencyStopState.failed) ...[
                    Semantics(
                      liveRegion: true,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppStrings.homeStopNotDelivered,
                          style: AppTheme.body(
                            size: AppSpace.homeStopFailureSize,
                            color: AppColors.clay,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.s8),
                  ],
                  SizedBox(
                    height: AppSpace.homeStopHeight,
                    child: AnimatedSwitcher(
                      duration: const Duration(
                        milliseconds: AppSpace.homeButtonSwapDurationMs,
                      ),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: PrimaryButton(
                        key: ValueKey(stopState == EmergencyStopState.stopped),
                        label: stopState == EmergencyStopState.stopped
                            ? AppStrings.homeResume
                            : AppStrings.homeEmergencyStop,
                        semanticsLabel: stopState == EmergencyStopState.stopped
                            ? AppStrings.homeResume
                            : AppStrings.homeEmergencyStopSemantics,
                        height: AppSpace.homeStopHeight,
                        background: stopState == EmergencyStopState.stopped
                            ? AppColors.forest
                            : AppColors.stop,
                        icon: stopState == EmergencyStopState.stopped
                            ? const _PlayGlyph()
                            : const _StopGlyph(),
                        busy: stopState == EmergencyStopState.sending,
                        onPressed: () {
                          final controller = ref.read(
                            emergencyStopControllerProvider.notifier,
                          );
                          if (stopState == EmergencyStopState.stopped) {
                            unawaited(controller.resume());
                          } else {
                            unawaited(controller.stop());
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.showBottomTabBar) ...[
              const Divider(height: 1, thickness: 1, color: AppColors.rule),
              BottomTabBar(
                selected: 0,
                onSelected:
                    widget.onTabSelected ??
                    (index) => switch (index) {
                      1 => context.go('/settings'),
                      2 => context.go('/profile'),
                      _ => context.go('/home'),
                    },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MuscleSignalSection extends StatelessWidget {
  const _MuscleSignalSection({
    required this.active,
    required this.paused,
    required this.channel,
    required this.onChannelTap,
  });

  final bool active;
  final bool paused;
  final int channel;
  final VoidCallback onChannelTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Muscle signal',
              style: AppTheme.body(
                size: AppSpace.settingsSectionTitleSize,
                weight: FontWeight.w700,
              ),
            ),
          ),
          Text(paused ? 'Paused' : 'Live', style: AppTheme.caption),
        ],
      ),
      const SizedBox(height: AppSpace.s8),
      MuscleWaveform(active: active, paused: paused, seed: channel),
      Semantics(
        button: true,
        label: 'Channel $channel of 8. Tap to change',
        onTap: onChannelTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onChannelTap,
          child: SizedBox(
            height: AppSpace.minTouchTarget,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Channel $channel of 8 · tap to change',
                style: AppTheme.caption,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class HomeSecondaryTabScreen extends StatelessWidget {
  const HomeSecondaryTabScreen({
    required this.selected,
    required this.child,
    super.key,
  });

  final int selected;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        child,
        const Positioned(
          top: AppSpace.homeTopInset,
          right: AppSpace.screenH,
          child: CompactStopButton(),
        ),
      ],
    ),
    bottomNavigationBar: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1, thickness: 1, color: AppColors.rule),
        BottomTabBar(
          selected: selected,
          onSelected: (index) => switch (index) {
            0 => context.go('/home'),
            1 => context.go('/settings'),
            _ => context.go('/profile'),
          },
        ),
      ],
    ),
  );
}

class _ConnectionLine extends StatelessWidget {
  const _ConnectionLine({
    required this.text,
    required this.connection,
    required this.onTap,
  });

  final String text;
  final ArmConnection connection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = connection == ArmConnection.connected
        ? AppColors.forest
        : AppColors.inkMuted;
    return Semantics(
      button: true,
      label: text,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpace.minTouchTarget),
          child: Row(
            children: [
              Container(
                width: AppSpace.homeConnectionDotSize,
                height: AppSpace.homeConnectionDotSize,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpace.homeConnectionDotGap),
              Expanded(
                child: Text(
                  text,
                  style: AppTheme.body(
                    size: AppSpace.loginSubtitleSize,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveStatus extends StatelessWidget {
  const _LiveStatus({required this.status, this.stopped = false});

  final ArmStatus status;
  final bool stopped;

  @override
  Widget build(BuildContext context) {
    final hasData = status.connection == ArmConnection.connected;
    final gesture = stopped ? null : status.activeGesture;
    final activeFingers = hasData
        ? GestureMap.fingersFor(gesture)
        : const <Finger>{};
    final hand = HandDiagram(
      activeFingers: activeFingers,
      dimmed: !hasData,
      gestureIndex: hasData ? gesture : null,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Opacity(
            opacity: hasData ? 1 : .4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  gesture == null || !hasData
                      ? AppStrings.homeStatus
                      : AppStrings.homeHolding,
                  style: AppTheme.body(
                    size: AppSpace.homeStatusCaptionSize,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: AppSpace.s4),
                Text(
                  !hasData
                      ? AppStrings.homeNoData
                      : gesture == null
                      ? AppStrings.homeResting
                      : '${AppStrings.homeGesture} $gesture',
                  style: AppTheme.serif(AppSpace.homeStatusTitleSize),
                ),
                const SizedBox(height: AppSpace.s4),
                Text(
                  gesture == null || !hasData
                      ? '${AppStrings.homeLastSignalAt} ${_formatSignalTime(status.lastSignalAt)}'
                      : '${AppStrings.homeSignalConfidence} ${(status.signalConfidence * 100).round()}%',
                  style: AppTheme.body(
                    size: AppSpace.homeStatusCaptionSize,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpace.homeStatusColumnGap),
        hand,
      ],
    );
  }

  String _formatSignalTime(DateTime? time) =>
      time == null ? '—' : DateFormat('HH:mm').format(time);
}

class _BatteryMeterRow extends StatelessWidget {
  const _BatteryMeterRow({required this.label, required this.value});

  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) {
    final low = value != null && value! < 20;
    final color = low ? AppColors.clay : AppColors.forest;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text(label, style: AppTheme.body(size: 15))),
              if (low)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpace.s8),
                  child: Text(
                    AppStrings.homeLowBattery,
                    style: AppTheme.body(size: 13, color: AppColors.clay),
                  ),
                ),
              Text(
                value == null ? '—' : '$value%',
                style: AppTheme.serif(AppSpace.homeMeterValueSize),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s4),
          LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Container(
                  height: AppSpace.progressHeight,
                  color: AppColors.rule,
                ),
                if (value != null)
                  Container(
                    height: AppSpace.progressHeight,
                    width: constraints.maxWidth * (value! / 100).clamp(0, 1),
                    color: color,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StopGlyph extends StatelessWidget {
  const _StopGlyph();

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSpace.buttonRadius - 1),
    ),
    child: const Icon(Icons.stop, color: AppColors.stop, size: 18),
  );
}

class _PlayGlyph extends StatelessWidget {
  const _PlayGlyph();

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size(22, 22), painter: _PlayGlyphPainter());
}

class _PlayGlyphPainter extends CustomPainter {
  const _PlayGlyphPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .28, size.height * .12)
      ..lineTo(size.width * .84, size.height * .5)
      ..lineTo(size.width * .28, size.height * .88)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(covariant _PlayGlyphPainter oldDelegate) => false;
}

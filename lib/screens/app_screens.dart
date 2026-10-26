import 'dart:async';

import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme/app_spacing.dart';
import '../features/onboarding/presentation/onboarding_step_scaffold.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../theme.dart';
import '../widgets.dart';

void showAppSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: AppTheme.body(color: AppColors.paper)),
      ),
    );
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    required this.step,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    super.key,
  });
  final int step;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _armPaired = true;
  bool _bandPaired = false;
  bool _pairing = false;

  Future<void> _pairBand() async {
    if (_pairing || _bandPaired) return;
    setState(() => _pairing = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _pairing = false;
      _bandPaired = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final title = switch (step) {
      1 => 'Put on the prosthetic arm',
      2 => 'Position the armband',
      _ => 'Pair your devices',
    };
    final titleBody = <Widget>[
      if (step == 2)
        Semantics(
          image: true,
          label: 'Illustration: positioning the armband on the forearm',
          child: ExcludeSemantics(
            child: Image.asset(
              'assets/images/onboarding_step2.png',
              width: double.infinity,
              height: AppSpace.onboardingIllustrationHeight,
              fit: BoxFit.cover,
            ),
          ),
        ),
      if (step == 2) const SizedBox(height: AppSpace.s24),
      Text(title, style: AppTheme.onboardingTitleM),
      const SizedBox(height: AppSpace.s12),
      Text(
        step == 1
            ? AppStrings.onboardingStep1Body
            : step == 2
            ? 'Slide the MindRove armband onto the forearm, just below the elbow. Tighten until it feels snug and comfortable.'
            : 'Turn on your prosthetic arm and MindRove armband, then tap Pair next to each device.',
        style: AppTheme.onboardingBody,
      ),
      if (step == 2) ...[
        const SizedBox(height: 14),
        const _NumberedInstruction(
          number: '1',
          text: 'Sensors against clean, dry skin',
        ),
        const _NumberedInstruction(number: '2', text: 'Just below the elbow'),
        const _NumberedInstruction(
          number: '3',
          text: 'Snug but comfortable',
          last: true,
        ),
      ],
      if (step == 3) ...[
        const SizedBox(height: 14),
        DevicePairRow(
          asset: 'assets/images/device_arm.png',
          name: 'MyoGrip Arm',
          paired: _armPaired,
          busy: false,
          onPair: () => setState(() => _armPaired = true),
        ),
        DevicePairRow(
          asset: 'assets/images/device_armband.png',
          name: 'MindRove Armband',
          paired: _bandPaired,
          busy: _pairing,
          onPair: _pairBand,
        ),
        const SizedBox(height: AppSpace.s12),
        Text(
          'Cannot see a device? Check that it is switched on and close to your phone.',
          style: AppTheme.body(
            size: AppSpace.onboardingCaptionSize,
            color: AppColors.inkMuted,
          ),
        ),
      ],
    ];
    return OnboardingStepScaffold(
      step: step,
      onBack: widget.onBack,
      onNext: widget.onNext,
      onSkip: widget.onSkip,
      nextLabel: step == 3 ? 'Finish' : AppStrings.onboardingNext,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: titleBody,
      ),
    );
  }
}

class _NumberedInstruction extends StatelessWidget {
  const _NumberedInstruction({
    required this.number,
    required this.text,
    this.last = false,
  });
  final String number;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Rule(margin: EdgeInsets.zero),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(number, style: AppTheme.serif(20, weight: FontWeight.w600)),
            const SizedBox(width: 14),
            Expanded(child: Text(text, style: AppTheme.body())),
          ],
        ),
      ),
      if (last) const Rule(margin: EdgeInsets.zero),
    ],
  );
}

class DevicePairRow extends StatelessWidget {
  const DevicePairRow({
    required this.asset,
    required this.name,
    required this.paired,
    required this.busy,
    required this.onPair,
    super.key,
  });
  final String asset;
  final String name;
  final bool paired;
  final bool busy;
  final VoidCallback onPair;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Rule(margin: EdgeInsets.zero),
      ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 78),
        child: Row(
          children: [
            ImageOrPlaceholder(
              asset: asset,
              width: 52,
              height: 52,
              circular: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTheme.body(size: 16, weight: FontWeight.w700),
                  ),
                  Text(
                    'Found nearby',
                    style: AppTheme.body(size: 13, color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
            if (paired)
              Text(
                '✓ Paired',
                style: AppTheme.body(
                  color: AppColors.forest,
                  weight: FontWeight.w700,
                ),
              )
            else
              SizedBox(
                width: 88,
                height: 48,
                child: Semantics(
                  button: true,
                  label: 'Pair $name',
                  child: OutlinedButton(
                    onPressed: onPair,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.forest,
                      side: const BorderSide(
                        color: AppColors.forest,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.forest,
                            ),
                          )
                        : Text(
                            'Pair',
                            style: AppTheme.body(
                              color: AppColors.forest,
                              weight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selected = 0;
  bool _stopped = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _selected,
      children: [
        HomeTab(stopped: _stopped),
        const SettingsTab(),
        const ProfileTab(),
      ],
    ),
    bottomNavigationBar: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_selected == 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 8),
            child: PrimaryButton(
              label: _stopped ? 'Resume' : 'Emergency stop',
              height: 76,
              background: _stopped ? AppColors.forest : AppColors.stop,
              icon: _stopped
                  ? const Icon(
                      Icons.play_arrow,
                      color: AppColors.white,
                      size: 24,
                    )
                  : Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Icon(
                        Icons.stop,
                        color: AppColors.stop,
                        size: 23,
                      ),
                    ),
              onPressed: () => setState(() => _stopped = !_stopped),
            ),
          ),
        const Divider(height: 1, thickness: 1, color: AppColors.rule),
        BottomTabBar(
          selected: _selected,
          onSelected: (index) => setState(() => _selected = index),
        ),
      ],
    ),
  );
}

class HomeTab extends StatefulWidget {
  const HomeTab({required this.stopped, super.key});
  final bool stopped;
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Timer? _timer;
  int _gesture = 0;
  int _cycle = 0;

  @override
  void didUpdateWidget(covariant HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stopped != widget.stopped && !widget.stopped) {
      _cycle = 0;
      _gesture = 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || widget.stopped) return;
      setState(() {
        _cycle = (_cycle + 1) % 7;
        _gesture = _cycle == 6 ? -1 : _cycle;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<bool> get _active => switch (_gesture) {
    1 => [false, true, false, false, false],
    2 => [false, true, true, false, false],
    3 => [true, true, true, false, false],
    4 => [false, true, true, true, true],
    5 => [true, true, true, true, true],
    _ => [false, false, false, false, false],
  };

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${weekdays[now.weekday - 1]} ${now.day} ${months[now.month - 1]}',
              style: AppTheme.body(size: 13, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 5),
            Text('Your arm', style: AppTheme.serif(34)),
            const SizedBox(height: 5),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.forest,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Connected over Wi-Fi, armband linked',
                    style: AppTheme.body(size: 15, color: AppColors.forest),
                  ),
                ),
              ],
            ),
            if (widget.stopped) ...[
              const Rule(margin: EdgeInsets.symmetric(vertical: 14)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 3, height: 49, color: AppColors.stop),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Arm stopped',
                          style: AppTheme.body(
                            color: AppColors.stop,
                            weight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Motors and haptic feedback are off.',
                          style: AppTheme.muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const Rule(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.stopped ? 'Status' : 'Holding',
                        style: AppTheme.body(
                          size: 13,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.stopped || _gesture < 0
                            ? 'Resting'
                            : 'Gesture $_gesture',
                        style: AppTheme.serif(30),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.stopped
                            ? 'Last signal at 10:31'
                            : 'Signal confidence 96%',
                        style: AppTheme.body(
                          size: 13,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                HandDiagram(
                  activeFingers: widget.stopped
                      ? List.filled(5, false)
                      : _active,
                ),
              ],
            ),
            const Rule(),
            const MeterRow(label: 'Arm battery', value: 82),
            const MeterRow(label: 'MindRove armband', value: 64),
          ],
        ),
      ),
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) => const SettingsScreen();
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  Widget build(BuildContext context) => const ProfileScreen();
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _name = TextEditingController(text: 'Patient name');
  final _age = TextEditingController(text: '34');
  final _email = TextEditingController(text: 'name@example.com');

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit profile', style: AppTheme.serif(34)),
                  const SizedBox(height: 26),
                  UnderlineField(label: 'Name', controller: _name),
                  UnderlineField(
                    label: 'Age',
                    controller: _age,
                    keyboardType: TextInputType.number,
                  ),
                  UnderlineField(
                    label: 'Email',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  UnderlineField(
                    label: 'Clinic code',
                    controller: _readOnlyController,
                    readOnly: true,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Save',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  static final _readOnlyController = TextEditingController(text: 'CLINIC1');
}

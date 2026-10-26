import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/strings.dart';
import 'core/theme/app_spacing.dart';
import 'core/widgets/compact_stop_button.dart';
import 'data/api/api_client.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/api_auth_repository.dart';
import 'data/repositories/api_profile_repository.dart';
import 'data/repositories/api_settings_repository.dart';
import 'features/onboarding/presentation/onboarding_step1_screen.dart';
import 'features/onboarding/presentation/onboarding_step2_screen.dart';
import 'features/onboarding/presentation/onboarding_step3_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/auth/presentation/forgot_password_screen.dart';
import 'data/repositories/arm_repository.dart';
import 'features/home/application/home_providers.dart';
import 'features/home/presentation/home_screen.dart';
import 'data/repositories/settings_repository.dart';
import 'features/settings/application/settings_providers.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/settings/presentation/calibration_screen.dart';
import 'features/settings/presentation/activity_screen.dart';
import 'features/settings/presentation/help_screen.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/usage_repository.dart';
import 'data/repositories/report_repository.dart';
import 'features/profile/application/profile_providers.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/profile/presentation/edit_profile_screen.dart';
import 'features/splash/application/splash_controller.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'widgets.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  final apiClient = ApiClient();
  final tokenStore = FlutterSecureSessionTokenStore();
  runApp(
    MyoGripApp(
      authRepository: ApiAuthRepository(
        client: apiClient,
        sessionTokenStore: tokenStore,
      ),
      profileRepository: ApiProfileRepository(
        client: apiClient,
        sessionTokenStore: tokenStore,
      ),
      settingsRepository: ApiSettingsRepository(
        client: apiClient,
        sessionTokenStore: tokenStore,
      ),
      sessionTokenStore: tokenStore,
    ),
  );
}

class MyoGripApp extends StatefulWidget {
  const MyoGripApp({
    this.authRepository,
    this.armRepository,
    this.settingsRepository,
    this.profileRepository,
    this.usageRepository,
    this.reportRepository,
    this.sessionTokenStore,
    super.key,
  });

  final AuthRepository? authRepository;
  final ArmRepository? armRepository;
  final SettingsRepository? settingsRepository;
  final ProfileRepository? profileRepository;
  final UsageRepository? usageRepository;
  final ReportRepository? reportRepository;
  final ClearableSessionTokenStore? sessionTokenStore;

  @override
  State<MyoGripApp> createState() => _MyoGripAppState();
}

class _MyoGripAppState extends State<MyoGripApp> {
  late final GoRouter _router;
  late final SplashController _splashController;
  late final AuthRepository _authRepository;
  late final ArmRepository _armRepository;
  late final SettingsRepository _settingsRepository;
  late final ProfileRepository _profileRepository;
  late final UsageRepository _usageRepository;
  late final ReportRepository _reportRepository;
  late final ClearableSessionTokenStore? _sessionTokenStore;
  bool _startupComplete = false;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? FakeAuthRepository();
    _armRepository = widget.armRepository ?? FakeArmRepository();
    _settingsRepository = widget.settingsRepository ?? FakeSettingsRepository();
    _profileRepository = widget.profileRepository ?? FakeProfileRepository();
    _usageRepository = widget.usageRepository ?? FakeUsageRepository();
    _reportRepository = widget.reportRepository ?? FakeReportRepository();
    _sessionTokenStore = widget.sessionTokenStore;
    _splashController = SplashController(authRepository: _authRepository);
    _router = GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        if (!_startupComplete && state.matchedLocation != '/splash') {
          return '/splash';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => SplashScreen(
            controller: _splashController,
            onComplete: _completeStartup,
          ),
        ),
        GoRoute(
          path: '/onboarding/:step',
          pageBuilder: (context, state) {
            final step = int.tryParse(state.pathParameters['step'] ?? '') ?? 1;
            final rePair =
                state.uri.queryParameters['mode'] == AppStrings.homeRePairMode;
            void back() {
              if (context.canPop()) {
                context.pop();
              } else if (step > 1) {
                context.go('/onboarding/${step - 1}');
              }
            }

            void next() {
              if (step < 3) {
                unawaited(context.push('/onboarding/${step + 1}'));
              } else if (rePair) {
                context.go('/home');
              } else {
                unawaited(_completeOnboarding());
              }
            }

            void skip() {
              if (rePair) {
                context.go('/home');
              } else {
                unawaited(_completeOnboarding());
              }
            }

            final screen = step == 1
                ? OnboardingStep1Screen(
                    onBack: back,
                    onNext: next,
                    onSkip: skip,
                  )
                : step == 2
                ? OnboardingStep2Screen(
                    onBack: back,
                    onNext: next,
                    onSkip: skip,
                  )
                : OnboardingStep3Screen(
                    onBack: back,
                    onFinish: skip,
                    onSkip: skip,
                    rePair: rePair,
                    onDeviceLinked: () {
                      final repository = _armRepository;
                      if (repository
                          case final LinkableArmRepository linkable) {
                        linkable.setHasLinkedDevice(true);
                      }
                    },
                  );
            return CustomTransitionPage<void>(
              key: state.pageKey,
              transitionDuration: const Duration(
                milliseconds: AppSpace.onboardingNextDurationMs,
              ),
              reverseTransitionDuration: const Duration(
                milliseconds: AppSpace.onboardingNextDurationMs,
              ),
              child: screen,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) =>
                      SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        child: child,
                      ),
            );
          },
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              LoginScreen(authRepository: _authRepository),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) =>
              ForgotPasswordScreen(authRepository: _authRepository),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) =>
              RegisterScreen(authRepository: _authRepository),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              _HomeTabShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => HomeScreen(
                    showBottomTabBar: false,
                    onTabSelected: (index) => context.go(switch (index) {
                      1 => '/settings',
                      2 => '/profile',
                      _ => '/home',
                    }),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/settings',
                  builder: (context, state) {
                    final tokenStore = _sessionTokenStore;
                    return SettingsScreen(
                      onSignOut: tokenStore == null
                          ? null
                          : () => _signOut(context, tokenStore),
                    );
                  },
                ),
                GoRoute(
                  path: '/calibration',
                  builder: (context, state) => const CalibrationScreen(),
                ),
                GoRoute(
                  path: '/activity',
                  builder: (context, state) => const ActivityScreen(),
                ),
                GoRoute(
                  path: '/help',
                  builder: (context, state) => const HelpScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (context, state) => const EditProfileScreen(),
        ),
      ],
    );
  }

  void _completeStartup(String location) {
    _startupComplete = true;
    _router.go(location);
  }

  Future<void> _signOut(
    BuildContext context,
    ClearableSessionTokenStore tokenStore,
  ) async {
    await tokenStore.clearToken();
    if (context.mounted) context.go('/login');
  }

  Future<void> _completeOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(AppStrings.onboardingDonePreferenceKey, true);
    if (mounted) {
      _router.go('/login');
    }
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      armRepositoryProvider.overrideWith((ref) => _armRepository),
      settingsRepositoryProvider.overrideWith((ref) => _settingsRepository),
      profileRepositoryProvider.overrideWith((ref) => _profileRepository),
      usageRepositoryProvider.overrideWith((ref) => _usageRepository),
      reportRepositoryProvider.overrideWith((ref) => _reportRepository),
    ],
    child: MaterialApp.router(
      title: 'MyoGrip AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 1,
        maxScaleFactor: 1.3,
        child: child ?? const SizedBox.shrink(),
      ),
      routerConfig: _router,
    ),
  );
}

class _HomeTabShell extends StatelessWidget {
  const _HomeTabShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final contentBottomInset =
        AppSpace.tabBarHeight + 38 + bottomInset + AppSpace.s12;
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: contentBottomInset),
            child: navigationShell,
          ),
          if (navigationShell.currentIndex > 0)
            const Positioned(
              top: AppSpace.homeTopInset,
              right: AppSpace.screenH,
              child: CompactStopButton(),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12),
          child: BottomTabBar(
            selected: navigationShell.currentIndex,
            onSelected: (index) => navigationShell.goBranch(index),
          ),
        ),
      ),
    );
  }
}

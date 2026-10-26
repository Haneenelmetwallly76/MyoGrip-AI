import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme.dart';
import '../../../widgets.dart';
import '../application/splash_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    required this.onComplete,
    this.controller,
    super.key,
  });

  final ValueChanged<String> onComplete;
  final SplashController? controller;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _progress;
  late final AnimationController _fadeController;
  late final Animation<double> _fade;
  late final SplashController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        SplashController(authRepository: FakeAuthRepository());
    _progress = AnimationController(
      vsync: this,
      duration: _controller.minimumDisplayDuration,
    )..forward();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppSpace.splashFadeDurationMs),
    )..forward();
    _fade = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    unawaited(_finishStartup());
  }

  Future<void> _finishStartup() async {
    final destination = await _controller.destinationAfterStartup();
    if (mounted) {
      widget.onComplete(destination.location);
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: AppStrings.splashSemantics,
    child: ExcludeSemantics(
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Transform.translate(
                  offset: const Offset(0, -AppSpace.splashContentOffset),
                  child: AnimatedBuilder(
                    animation: _fade,
                    child: const _SplashBrand(),
                    builder: (context, child) => MediaQuery.of(context)
                            .disableAnimations
                        ? child!
                        : FadeTransition(opacity: _fade, child: child),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: AppSpace.s64,
                child: Center(
                  child: SizedBox(
                    width: AppSpace.splashProgressWidth,
                    height: AppSpace.progressHeight,
                    child: AnimatedBuilder(
                      animation: _progress,
                      builder: (context, _) => Stack(
                        children: [
                          const Positioned.fill(
                            child: ColoredBox(color: AppColors.rule),
                          ),
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width:
                                AppSpace.splashProgressWidth * _progress.value,
                            child: const ColoredBox(color: AppColors.forest),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SplashBrand extends StatelessWidget {
  const _SplashBrand();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const ImageOrPlaceholder(
        asset: 'assets/images/logo_mark.png',
        width: AppSpace.splashLogoWidth,
        height: AppSpace.splashLogoWidth,
        fit: BoxFit.contain,
        blendWithPaper: true,
      ),
      const SizedBox(height: AppSpace.splashTitleGap),
      Text(AppStrings.splashName, style: AppTheme.splashTitle),
      const SizedBox(height: AppSpace.splashTaglineGap),
      Text(AppStrings.splashTagline, style: AppTheme.splashTagline),
    ],
  );
}

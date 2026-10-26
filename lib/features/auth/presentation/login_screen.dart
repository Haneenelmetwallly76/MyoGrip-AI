import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme.dart';
import '../../../widgets.dart';
import '../application/login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.authRepository, super.key});

  final AuthRepository authRepository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginController _controller;
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = LoginController(widget.authRepository);
    _controller.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final result = await _controller.submit(_email.text, _password.text);
    if (!mounted) return;
    switch (result) {
      case LoginResult.success:
        context.go('/home');
      case LoginResult.noConnection:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text(AppStrings.loginNoConnection),
              action: SnackBarAction(
                label: AppStrings.loginRetry,
                onPressed: () => _submit(),
              ),
            ),
          );
      case LoginResult.invalid:
      case LoginResult.credentialsIncorrect:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screenH,
                  AppSpace.s16,
                  AppSpace.screenH,
                  AppSpace.s16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ImageOrPlaceholder(
                      asset: 'assets/images/logo_mark.png',
                      width: AppSpace.loginLogoSize,
                      height: AppSpace.loginLogoSize,
                      blendWithPaper: true,
                    ),
                    const SizedBox(height: AppSpace.loginTitleGap),
                    Text(
                      AppStrings.loginTitle,
                      style: AppTheme.serif(AppSpace.loginTitleSize),
                    ),
                    Text(
                      AppStrings.loginSubtitle,
                      style: AppTheme.body(
                        size: AppSpace.loginSubtitleSize,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpace.loginFormGap),
                    UnderlineField(
                      label: AppStrings.loginEmailLabel,
                      controller: _email,
                      error: _controller.emailError,
                      hint: AppStrings.loginEmailHint,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onBlur: () => _controller.validateEmail(_email.text),
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      enabled: !_controller.isLoading,
                    ),
                    UnderlineField(
                      label: AppStrings.loginPasswordLabel,
                      controller: _password,
                      error: _controller.passwordError,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      onBlur: () =>
                          _controller.validatePassword(_password.text),
                      onSubmitted: (_) => _submit(),
                      enabled: !_controller.isLoading,
                    ),
                    AppLink(
                      AppStrings.loginForgotPassword,
                      onTap: () => context.go('/forgot-password'),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screenH,
                AppSpace.s8,
                AppSpace.screenH,
                AppSpace.loginBottomInset,
              ),
              child: Column(
                children: [
                  PrimaryButton(
                    label: AppStrings.loginSubmit,
                    onPressed: _controller.isLoading ? null : _submit,
                    busy: _controller.isLoading,
                  ),
                  const SizedBox(height: AppSpace.loginFooterGap),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        AppStrings.loginNewHere,
                        style: AppTheme.body(color: AppColors.inkMuted),
                      ),
                      AppLink(
                        AppStrings.loginCreateAccount,
                        onTap: () => context.go('/register'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

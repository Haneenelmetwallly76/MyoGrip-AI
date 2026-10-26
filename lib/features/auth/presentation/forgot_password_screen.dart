import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme.dart';
import '../../../widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({required this.authRepository, super.key});

  final AuthRepository authRepository;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  String? _error;
  bool _sent = false;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final value = _email.text.trim();
    setState(() {
      _error = _emailPattern.hasMatch(value)
          ? null
          : AppStrings.loginEmailInvalid;
    });
  }

  Future<void> _submit() async {
    _validateEmail();
    if (_error != null || _loading) return;
    setState(() => _loading = true);
    try {
      await widget.authRepository.sendPasswordResetLink(_email.text.trim());
      if (mounted) setState(() => _sent = true);
    } on AuthNetworkException {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text(AppStrings.loginNoConnection),
              action: SnackBarAction(
                label: AppStrings.loginRetry,
                onPressed: () => unawaited(_submit()),
              ),
            ),
          );
      }
    } on AuthFeatureUnavailableException {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(AppStrings.authPasswordResetUnavailable),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screenH,
                AppSpace.plainFormTopInset,
                AppSpace.screenH,
                AppSpace.s24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLink(
                    AppStrings.forgotPasswordBack,
                    onTap: () => context.go('/login'),
                  ),
                  const SizedBox(height: AppSpace.plainFormTitleGap),
                  Text(
                    AppStrings.forgotPasswordTitle,
                    style: AppTheme.serif(AppSpace.loginTitleSize),
                  ),
                  const SizedBox(height: AppSpace.plainFormBodyGap),
                  Text(
                    AppStrings.forgotPasswordBody,
                    style: AppTheme.body(color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: AppSpace.s24),
                  if (_sent) ...[
                    Text(
                      AppStrings.forgotPasswordConfirmation,
                      style: AppTheme.body(),
                    ),
                    const SizedBox(height: AppSpace.s8),
                    AppLink(
                      AppStrings.forgotPasswordBackToSignIn,
                      onTap: () => context.go('/login'),
                    ),
                  ] else
                    UnderlineField(
                      label: AppStrings.forgotPasswordEmail,
                      controller: _email,
                      error: _error,
                      enabled: !_loading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      onBlur: _validateEmail,
                    ),
                ],
              ),
            ),
          ),
          if (!_sent)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screenH,
                AppSpace.plainFormButtonInset,
                AppSpace.screenH,
                AppSpace.plainFormBottomInset,
              ),
              child: PrimaryButton(
                label: AppStrings.forgotPasswordSend,
                onPressed: _loading ? null : _submit,
                busy: _loading,
              ),
            ),
        ],
      ),
    ),
  );

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme.dart';
import '../../../widgets.dart';
import '../application/register_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({required this.authRepository, super.key});

  final AuthRepository authRepository;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final RegisterController _controller;
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _clinicCode = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = RegisterController(widget.authRepository)
      ..addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    _name.dispose();
    _age.dispose();
    _email.dispose();
    _password.dispose();
    _clinicCode.dispose();
    super.dispose();
  }

  Future<void> _checkEmailAvailability() async {
    if (!await _controller.checkEmailAvailability(_email.text) && mounted) {
      _showServerError(retry: _checkEmailAvailability);
    }
  }

  Future<void> _checkClinicCode() async {
    if (!await _controller.checkClinicCode(_clinicCode.text) && mounted) {
      _showServerError(retry: _checkClinicCode);
    }
  }

  Future<void> _submit() async {
    final result = await _controller.submit(
      fullName: _name.text,
      age: _age.text,
      email: _email.text,
      password: _password.text,
      clinicCode: _clinicCode.text,
    );
    if (!mounted) return;
    switch (result) {
      case RegisterResult.success:
        context.go('/home');
      case RegisterResult.serverError:
        _showServerError(retry: _submit);
      case RegisterResult.invalid:
      case RegisterResult.emailTaken:
      case RegisterResult.clinicCodeInvalid:
        break;
    }
  }

  void _showServerError({required VoidCallback retry}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(AppStrings.registerServerError),
          action: SnackBarAction(
            label: AppStrings.loginRetry,
            onPressed: retry,
          ),
        ),
      );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: true,
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screenH,
                AppSpace.registerTopInset,
                AppSpace.screenH,
                AppSpace.s16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLink(AppStrings.registerBack, onTap: _goBack),
                  const SizedBox(height: AppSpace.registerHeaderTitleGap),
                  Text(
                    AppStrings.registerTitle,
                    style: AppTheme.serif(AppSpace.loginTitleSize),
                  ),
                  const SizedBox(height: AppSpace.registerSubtitleGap),
                  Text(
                    AppStrings.registerSubtitle,
                    style: AppTheme.body(
                      size: AppSpace.loginSubtitleSize,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpace.registerFormGap),
                  UnderlineField(
                    label: AppStrings.registerFullName,
                    controller: _name,
                    error: _controller.nameError,
                    hint: AppStrings.registerFullNameHint,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onBlur: () => _controller.validateName(_name.text),
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    enabled: !_controller.isLoading,
                    bottomSpacing: AppSpace.registerFieldGap,
                  ),
                  UnderlineField(
                    label: AppStrings.registerAge,
                    controller: _age,
                    error: _controller.ageError,
                    hint: AppStrings.registerAgeHint,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onBlur: () => _controller.validateAge(_age.text),
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    enabled: !_controller.isLoading,
                    bottomSpacing: AppSpace.registerFieldGap,
                  ),
                  UnderlineField(
                    label: AppStrings.registerEmail,
                    controller: _email,
                    error: _controller.emailError,
                    hint: AppStrings.loginEmailHint,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onBlur: _checkEmailAvailability,
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    enabled: !_controller.isLoading,
                    bottomSpacing: AppSpace.registerFieldGap,
                  ),
                  UnderlineField(
                    label: AppStrings.registerPassword,
                    controller: _password,
                    error: _controller.passwordError,
                    obscure: true,
                    textInputAction: TextInputAction.next,
                    onBlur: () =>
                        _controller.validatePassword(_password.text),
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    enabled: !_controller.isLoading,
                    helperText: _controller.passwordRuleHint,
                    bottomSpacing: AppSpace.registerFieldGap,
                  ),
                  UnderlineField(
                    label: AppStrings.registerClinicCode,
                    controller: _clinicCode,
                    error: _controller.clinicCodeError,
                    hint: AppStrings.registerClinicCodeHint,
                    textInputAction: TextInputAction.done,
                    onBlur: _checkClinicCode,
                    onSubmitted: (_) => _submit(),
                    enabled: !_controller.isLoading,
                    bottomSpacing: AppSpace.registerFieldGap,
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
              AppSpace.registerBottomInset,
            ),
            child: Column(
              children: [
                PrimaryButton(
                  label: AppStrings.registerSubmit,
                  onPressed: _controller.isLoading ? null : _submit,
                  busy: _controller.isLoading,
                ),
                const SizedBox(height: AppSpace.loginFooterGap),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      AppStrings.registerExistingAccount,
                      style: AppTheme.body(color: AppColors.inkMuted),
                    ),
                    AppLink(
                      AppStrings.registerSignIn,
                      onTap: () => context.go('/login'),
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

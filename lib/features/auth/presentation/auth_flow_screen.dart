import 'dart:async';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../../../core/l10n/business_localizations.dart';
import 'auth_controller.dart';

/// Multi-step authentication view (Login, Register, Email OTP, Reset Password).
final class AuthFlowScreen extends StatefulWidget {
  const AuthFlowScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<AuthFlowScreen> createState() => _AuthFlowScreenState();
}

final class _AuthFlowScreenState extends State<AuthFlowScreen> {
  final _loginIdentifierController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _registerEmailController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  final _otpEmailController = TextEditingController();
  final _otpCodeController = TextEditingController();

  final _resetEmailController = TextEditingController();
  final _resetCodeController = TextEditingController();
  final _resetPasswordController = TextEditingController();

  AuthStep? _lastSyncedStep;

  @override
  void initState() {
    super.initState();
    _lastSyncedStep = widget.controller.step;
    widget.controller.addListener(_syncStepDefaults);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncStepDefaults);
    _loginIdentifierController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPhoneController.dispose();
    _registerPasswordController.dispose();
    _otpEmailController.dispose();
    _otpCodeController.dispose();
    _resetEmailController.dispose();
    _resetCodeController.dispose();
    _resetPasswordController.dispose();
    super.dispose();
  }

  void _syncStepDefaults() {
    final step = widget.controller.step;
    final pendingEmail = widget.controller.pendingEmail;
    if (step == _lastSyncedStep) {
      return;
    }
    _lastSyncedStep = step;

    if (pendingEmail == null || pendingEmail.isEmpty) {
      return;
    }

    switch (step) {
      case AuthStep.login:
        if (_loginIdentifierController.text.isEmpty) {
          _loginIdentifierController.text = pendingEmail;
        }
      case AuthStep.verifyOtp:
        _otpEmailController.text = pendingEmail;
      case AuthStep.resetPassword:
        if (_resetEmailController.text.isEmpty) {
          _resetEmailController.text = pendingEmail;
        }
      case AuthStep.register:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = BusinessStringsScope.of(context);
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final colors = context.ucraftColors;
        final controller = widget.controller;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(
                  UcraftSpacing.screenHorizontalPadding,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        strings.appTitle,
                        style: UcraftTypography.display.copyWith(
                          color: colors.foreground,
                        ),
                      ),
                      const SizedBox(height: UcraftSpacing.space2),
                      Text(
                        _subtitleFor(controller.step, strings),
                        style: UcraftTypography.bodyLarge.copyWith(
                          color: colors.foregroundSecondary,
                        ),
                      ),
                      const SizedBox(height: UcraftSpacing.space6),
                      if (controller.infoMessage != null) ...[
                        _FeedbackBanner(
                          message: controller.infoMessage!,
                          icon: LucideIcons.circleCheck,
                          backgroundColor: colors.successBackground,
                          borderColor: colors.success,
                          foregroundColor: colors.successForeground,
                        ),
                        const SizedBox(height: UcraftSpacing.space4),
                      ],
                      if (controller.errorMessage != null) ...[
                        _FeedbackBanner(
                          message: controller.errorMessage!,
                          icon: LucideIcons.circleAlert,
                          backgroundColor: colors.destructiveBackground,
                          borderColor: colors.destructive,
                          foregroundColor: colors.destructiveForeground,
                        ),
                        const SizedBox(height: UcraftSpacing.space4),
                      ],
                      UcraftCard(
                        child: switch (controller.step) {
                          AuthStep.login => _buildLoginForm(
                            controller,
                            strings,
                          ),
                          AuthStep.register => _buildRegisterForm(
                            controller,
                            strings,
                          ),
                          AuthStep.verifyOtp => _buildOtpForm(
                            controller,
                            strings,
                          ),
                          AuthStep.resetPassword => _buildResetPasswordForm(
                            controller,
                            strings,
                          ),
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginForm(AuthController controller, BusinessStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UcraftTextField(
          key: const ValueKey<String>('login_identifier'),
          label: strings.authEmailOrPhoneLabel,
          hintText: 'owner@gym.tj',
          keyboardType: TextInputType.emailAddress,
          controller: _loginIdentifierController,
          enabled: !controller.isSubmitting,
          errorText: controller.firstFieldError(const ['email', 'phone']),
        ),
        const SizedBox(height: UcraftSpacing.formFieldGap),
        UcraftTextField(
          key: const ValueKey<String>('login_password'),
          label: strings.authPasswordLabel,
          obscureText: true,
          controller: _loginPasswordController,
          enabled: !controller.isSubmitting,
          errorText: controller.firstFieldError(const ['password']),
        ),
        const SizedBox(height: UcraftSpacing.space6),
        UcraftButton(
          label: strings.authSignInButton,
          fullWidth: true,
          isLoading: controller.isSubmitting,
          onPressed: () {
            unawaited(
              controller.login(
                identifier: _loginIdentifierController.text,
                password: _loginPasswordController.text,
              ),
            );
          },
        ),
        const SizedBox(height: UcraftSpacing.space3),
        UcraftButton(
          label: strings.authCreateAccountButton,
          variant: UcraftButtonVariant.tertiary,
          fullWidth: true,
          onPressed: controller.isSubmitting
              ? null
              : () => controller.showStep(AuthStep.register),
        ),
        UcraftButton(
          label: strings.authResetPasswordButton,
          variant: UcraftButtonVariant.tertiary,
          fullWidth: true,
          onPressed: controller.isSubmitting
              ? null
              : () => controller.showStep(
                  AuthStep.resetPassword,
                  email: _loginIdentifierController.text.contains('@')
                      ? _loginIdentifierController.text
                      : null,
                ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm(
    AuthController controller,
    BusinessStrings strings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UcraftTextField(
          key: const ValueKey<String>('register_email'),
          label: 'Email',
          hintText: 'staff@gym.tj',
          keyboardType: TextInputType.emailAddress,
          controller: _registerEmailController,
          enabled: !controller.isSubmitting,
          errorText: controller.firstFieldError(const ['email']),
        ),
        const SizedBox(height: UcraftSpacing.formFieldGap),
        UcraftTextField(
          key: const ValueKey<String>('register_phone'),
          label: strings.authPhoneOptionalLabel,
          hintText: '+992900001122',
          keyboardType: TextInputType.phone,
          controller: _registerPhoneController,
          enabled: !controller.isSubmitting,
          errorText: controller.firstFieldError(const ['phone']),
        ),
        const SizedBox(height: UcraftSpacing.formFieldGap),
        UcraftTextField(
          key: const ValueKey<String>('register_password'),
          label: strings.authPasswordMinLabel,
          obscureText: true,
          controller: _registerPasswordController,
          enabled: !controller.isSubmitting,
          errorText: controller.firstFieldError(const ['password']),
        ),
        const SizedBox(height: UcraftSpacing.space6),
        UcraftButton(
          label: strings.authRegisterButton,
          fullWidth: true,
          isLoading: controller.isSubmitting,
          onPressed: () {
            unawaited(
              controller.registerAndSendOtp(
                email: _registerEmailController.text,
                phone: _registerPhoneController.text,
                password: _registerPasswordController.text,
              ),
            );
          },
        ),
        const SizedBox(height: UcraftSpacing.space3),
        UcraftButton(
          label: strings.authBackToLoginButton,
          variant: UcraftButtonVariant.tertiary,
          fullWidth: true,
          onPressed: controller.isSubmitting
              ? null
              : () => controller.showStep(AuthStep.login),
        ),
      ],
    );
  }

  Widget _buildOtpForm(AuthController controller, BusinessStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UcraftTextField(
          key: const ValueKey<String>('otp_email'),
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          controller: _otpEmailController,
          enabled: !controller.isSubmitting,
          errorText: controller.firstFieldError(const ['email']),
        ),
        const SizedBox(height: UcraftSpacing.formFieldGap),
        UcraftTextField(
          key: const ValueKey<String>('otp_code'),
          label: strings.authOtpCodeLabel,
          hintText: '123456',
          keyboardType: TextInputType.number,
          controller: _otpCodeController,
          enabled: !controller.isSubmitting,
          errorText: controller.firstFieldError(const ['code']),
        ),
        const SizedBox(height: UcraftSpacing.space6),
        UcraftButton(
          label: strings.authVerifyEmailButton,
          fullWidth: true,
          isLoading: controller.isSubmitting,
          onPressed: () {
            unawaited(
              controller.verifyOtp(
                email: _otpEmailController.text,
                code: _otpCodeController.text,
              ),
            );
          },
        ),
        const SizedBox(height: UcraftSpacing.space3),
        UcraftButton(
          label: strings.authResendOtpButton,
          variant: UcraftButtonVariant.secondary,
          fullWidth: true,
          onPressed: controller.isSubmitting
              ? null
              : () {
                  unawaited(
                    controller.resendOtp(email: _otpEmailController.text),
                  );
                },
        ),
        const SizedBox(height: UcraftSpacing.space2),
        UcraftButton(
          label: strings.authBackToLoginButton,
          variant: UcraftButtonVariant.tertiary,
          fullWidth: true,
          onPressed: controller.isSubmitting
              ? null
              : () => controller.showStep(AuthStep.login),
        ),
      ],
    );
  }

  Widget _buildResetPasswordForm(
    AuthController controller,
    BusinessStrings strings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UcraftTextField(
          key: const ValueKey<String>('reset_email'),
          label: 'Email',
          hintText: 'owner@gym.tj',
          keyboardType: TextInputType.emailAddress,
          controller: _resetEmailController,
          enabled: !controller.isSubmitting,
          errorText: controller.firstFieldError(const ['email']),
        ),
        const SizedBox(height: UcraftSpacing.space3),
        UcraftButton(
          label: strings.authSendCodeButton,
          variant: UcraftButtonVariant.secondary,
          fullWidth: true,
          onPressed: controller.isSubmitting
              ? null
              : () {
                  unawaited(
                    controller.resendOtp(email: _resetEmailController.text),
                  );
                },
        ),
        const SizedBox(height: UcraftSpacing.formFieldGap),
        UcraftTextField(
          key: const ValueKey<String>('reset_code'),
          label: strings.authOtpCodeLabel,
          hintText: '123456',
          keyboardType: TextInputType.number,
          controller: _resetCodeController,
          enabled: !controller.isSubmitting,
          errorText: controller.firstFieldError(const ['code']),
        ),
        const SizedBox(height: UcraftSpacing.formFieldGap),
        UcraftTextField(
          key: const ValueKey<String>('reset_password'),
          label: strings.authNewPasswordLabel,
          obscureText: true,
          controller: _resetPasswordController,
          enabled: !controller.isSubmitting,
          errorText: controller.firstFieldError(const ['password']),
        ),
        const SizedBox(height: UcraftSpacing.space6),
        UcraftButton(
          label: strings.authSaveNewPasswordButton,
          fullWidth: true,
          isLoading: controller.isSubmitting,
          onPressed: () {
            unawaited(
              controller.confirmResetPassword(
                email: _resetEmailController.text,
                code: _resetCodeController.text,
                newPassword: _resetPasswordController.text,
              ),
            );
          },
        ),
        const SizedBox(height: UcraftSpacing.space3),
        UcraftButton(
          label: strings.authBackToLoginButton,
          variant: UcraftButtonVariant.tertiary,
          fullWidth: true,
          onPressed: controller.isSubmitting
              ? null
              : () => controller.showStep(AuthStep.login),
        ),
      ],
    );
  }

  String _subtitleFor(AuthStep step, BusinessStrings strings) {
    return switch (step) {
      AuthStep.login => strings.authSubtitleLogin,
      AuthStep.register => strings.authSubtitleRegister,
      AuthStep.verifyOtp => strings.authSubtitleOtp,
      AuthStep.resetPassword => strings.authSubtitleReset,
    };
  }
}

final class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
  });

  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(UcraftSpacing.space3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: UcraftRadius.borderSm,
        border: Border.all(
          color: borderColor,
          width: UcraftElevation.borderDefault,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: foregroundColor),
          const SizedBox(width: UcraftSpacing.iconLabelGap),
          Expanded(
            child: Text(
              message,
              style: UcraftTypography.bodyMedium.copyWith(
                color: foregroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../../../core/l10n/business_localizations.dart';
import '../../../core/theme/business_page_surface.dart';
import 'qr_scanner_view.dart';
import 'reception_scan_controller.dart';

/// Reception screen scanning a client's personal 60-second QR code.
final class ScanClientQrScreen extends StatelessWidget {
  const ScanClientQrScreen({
    super.key,
    required this.controller,
    this.scannerBuilder = buildMobileQrScanner,
    this.onOpenClient,
    this.onOpenClients,
    this.onOpenPayments,
  });

  final ReceptionScanController controller;
  final QrScannerBuilder scannerBuilder;
  final void Function(int clientId)? onOpenClient;
  final VoidCallback? onOpenClients;
  final VoidCallback? onOpenPayments;

  @override
  Widget build(BuildContext context) {
    final strings = BusinessStringsScope.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return BusinessPageScaffold(
          appBar: AppBar(title: Text(strings.scanClientQrButton)),
          body: SafeArea(
            child: switch (controller.phase) {
              ScanPhase.idle => _buildScanner(context, strings),
              ScanPhase.processing => UcraftLoadingState(
                message: strings.scannerCheckingMembership,
              ),
              ScanPhase.success => _buildSuccess(context, strings),
              ScanPhase.refused => _buildRefusal(context, strings),
              ScanPhase.networkError => _buildNetworkError(context, strings),
            },
          ),
        );
      },
    );
  }

  Widget _buildScanner(BuildContext context, BusinessStrings strings) {
    final colors = context.ucraftColors;
    return Column(
      children: [
        Expanded(
          child: scannerBuilder(
            context,
            (value) => unawaited(controller.onCodeScanned(value)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(UcraftSpacing.space4),
          child: Text(
            strings.scannerCameraHint,
            textAlign: TextAlign.center,
            style: UcraftTypography.body.copyWith(
              color: colors.foregroundSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context, BusinessStrings strings) {
    final colors = context.ucraftColors;
    final result = controller.result!;
    final remaining = result.remainingVisits;
    return _ResultPanel(
      icon: LucideIcons.circleCheck,
      iconColor: colors.success,
      background: colors.successBackground,
      title: strings.scannerVisitRecorded,
      lines: [
        '${strings.scannerMembershipPrefix}${result.membershipId}',
        if (remaining != null)
          '${strings.scannerRemainingVisitsPrefix}$remaining',
      ],
      actions: [
        UcraftButton(
          label: strings.scannerScanNextButton,
          fullWidth: true,
          onPressed: controller.scanNext,
        ),
      ],
    );
  }

  Widget _buildRefusal(BuildContext context, BusinessStrings strings) {
    final colors = context.ucraftColors;
    final error = controller.error!;
    final bool needsPayment = error.code == 'NO_ACTIVE_MEMBERSHIP';
    final bool isMembershipRefusal =
        error.code == 'NO_ACTIVE_MEMBERSHIP' ||
        error.code == 'MEMBERSHIP_FROZEN' ||
        error.code == 'DAILY_LIMIT_EXCEEDED' ||
        error.code == 'OUTSIDE_ALLOWED_TIME';
    return _ResultPanel(
      icon: LucideIcons.ban,
      iconColor: colors.destructive,
      background: colors.destructiveBackground,
      title: _refusalTitle(error.code, strings),
      lines: [error.message],
      actions: [
        if (needsPayment && onOpenPayments != null)
          UcraftButton(
            label: strings.scannerAcceptPaymentButton,
            fullWidth: true,
            onPressed: onOpenPayments,
          ),
        if (isMembershipRefusal && onOpenClients != null)
          UcraftButton(
            label: strings.scannerOpenClientsButton,
            variant: UcraftButtonVariant.secondary,
            fullWidth: true,
            onPressed: onOpenClients,
          ),
        UcraftButton(
          label: strings.scannerScanNextButton,
          variant: UcraftButtonVariant.secondary,
          fullWidth: true,
          onPressed: controller.scanNext,
        ),
      ],
    );
  }

  Widget _buildNetworkError(BuildContext context, BusinessStrings strings) {
    final colors = context.ucraftColors;
    final error = controller.error;
    final lines = <String>[
      if (error?.retryAfterSeconds != null) error!.message,
      strings.scannerNetworkRetryHint,
    ];
    return _ResultPanel(
      icon: LucideIcons.wifiOff,
      iconColor: colors.warning,
      background: colors.warningBackground,
      title: strings.scannerNetworkErrorTitle,
      lines: lines,
      actions: [
        UcraftButton(
          label: strings.retryLabel,
          fullWidth: true,
          onPressed: () => unawaited(controller.retry()),
        ),
        UcraftButton(
          label: strings.cancelLabel,
          variant: UcraftButtonVariant.tertiary,
          fullWidth: true,
          onPressed: controller.scanNext,
        ),
      ],
    );
  }

  String _refusalTitle(String code, BusinessStrings strings) {
    return switch (code) {
      'NO_ACTIVE_MEMBERSHIP' => strings.scannerRefusalNoActive,
      'MEMBERSHIP_FROZEN' => strings.scannerRefusalFrozen,
      'DAILY_LIMIT_EXCEEDED' => strings.scannerRefusalDailyLimit,
      'OUTSIDE_ALLOWED_TIME' => strings.scannerRefusalOutsideTime,
      'INVALID_QR_TOKEN' => strings.scannerRefusalInvalidQr,
      _ => strings.scannerRefusalGeneric,
    };
  }
}

final class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.title,
    required this.lines,
    required this.actions,
  });

  final IconData icon;
  final Color iconColor;
  final Color background;
  final String title;
  final List<String> lines;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(UcraftSpacing.screenHorizontalPadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(UcraftSpacing.space6),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: UcraftRadius.borderLg,
                ),
                child: Column(
                  children: [
                    Icon(icon, size: 64, color: iconColor),
                    const SizedBox(height: UcraftSpacing.space4),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: UcraftTypography.headline.copyWith(
                        color: colors.foreground,
                      ),
                    ),
                    for (final line in lines) ...[
                      const SizedBox(height: UcraftSpacing.space2),
                      Text(
                        line,
                        textAlign: TextAlign.center,
                        style: UcraftTypography.bodyLarge.copyWith(
                          color: colors.foregroundSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: UcraftSpacing.space6),
              for (final action in actions) ...[
                action,
                const SizedBox(height: UcraftSpacing.space3),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

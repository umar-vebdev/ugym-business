import 'dart:async';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

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
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Сканер QR клиента')),
          body: SafeArea(
            child: switch (controller.phase) {
              ScanPhase.idle => _buildScanner(context),
              ScanPhase.processing => const UcraftLoadingState(
                message: 'Проверяем абонемент...',
              ),
              ScanPhase.success => _buildSuccess(context),
              ScanPhase.refused => _buildRefusal(context),
              ScanPhase.networkError => _buildNetworkError(context),
            },
          ),
        );
      },
    );
  }

  Widget _buildScanner(BuildContext context) {
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
            'Наведите камеру на личный QR-код клиента из приложения uGym',
            textAlign: TextAlign.center,
            style: UcraftTypography.body.copyWith(
              color: colors.foregroundSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final colors = context.ucraftColors;
    final result = controller.result!;
    final remaining = result.remainingVisits;
    return _ResultPanel(
      icon: LucideIcons.circleCheck,
      iconColor: colors.success,
      background: colors.successBackground,
      title: 'Посещение отмечено',
      lines: [
        'Абонемент №${result.membershipId}',
        if (remaining != null) 'Осталось занятий: $remaining',
      ],
      actions: [
        UcraftButton(
          label: 'Сканировать следующего',
          fullWidth: true,
          onPressed: controller.scanNext,
        ),
      ],
    );
  }

  Widget _buildRefusal(BuildContext context) {
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
      title: _refusalTitle(error.code),
      lines: [error.message],
      actions: [
        if (needsPayment && onOpenPayments != null)
          UcraftButton(
            label: 'Принять оплату',
            fullWidth: true,
            onPressed: onOpenPayments,
          ),
        if (isMembershipRefusal && onOpenClients != null)
          UcraftButton(
            label: 'Открыть клиентов',
            variant: UcraftButtonVariant.secondary,
            fullWidth: true,
            onPressed: onOpenClients,
          ),
        UcraftButton(
          label: 'Сканировать следующего',
          variant: UcraftButtonVariant.secondary,
          fullWidth: true,
          onPressed: controller.scanNext,
        ),
      ],
    );
  }

  Widget _buildNetworkError(BuildContext context) {
    final colors = context.ucraftColors;
    final error = controller.error;
    final lines = <String>[
      if (error?.retryAfterSeconds != null) error!.message,
      'Нажмите «Повторить» — дубль посещения не будет создан.',
    ];
    return _ResultPanel(
      icon: LucideIcons.wifiOff,
      iconColor: colors.warning,
      background: colors.warningBackground,
      title: 'Нет связи с сервером',
      lines: lines,
      actions: [
        UcraftButton(
          label: 'Повторить',
          fullWidth: true,
          onPressed: () => unawaited(controller.retry()),
        ),
        UcraftButton(
          label: 'Отмена',
          variant: UcraftButtonVariant.tertiary,
          fullWidth: true,
          onPressed: controller.scanNext,
        ),
      ],
    );
  }

  String _refusalTitle(String code) {
    return switch (code) {
      'NO_ACTIVE_MEMBERSHIP' => 'Нет активного абонемента',
      'MEMBERSHIP_FROZEN' => 'Абонемент заморожен',
      'DAILY_LIMIT_EXCEEDED' => 'Лимит входов на сегодня исчерпан',
      'OUTSIDE_ALLOWED_TIME' => 'Вне разрешённого времени абонемента',
      'INVALID_QR_TOKEN' => 'QR-код недействителен или устарел',
      _ => 'Посещение не отмечено',
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

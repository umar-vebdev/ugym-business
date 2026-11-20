import 'dart:async';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../../../core/l10n/business_localizations.dart';
import '../../../core/session/business_role.dart';
import '../../../core/session/business_session_controller.dart';
import '../../../core/theme/business_typography.dart';
import '../domain/analytics_and_billing_models.dart';
import 'analytics_charts.dart';

/// Owner-only analytics dashboard showing revenue, clients, visits, and top items.
final class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    super.key,
    required this.repository,
    required this.sessionController,
    this.initialFrom,
    this.initialTo,
  });

  final AnalyticsAndBillingRepository repository;
  final BusinessSessionController sessionController;
  final String? initialFrom;
  final String? initialTo;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

final class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  final _inactiveDaysController = TextEditingController(text: '14');

  bool _loading = true;
  int? _selectedPresetDays = 6;
  String? _errorMessage;
  OverviewAnalytics? _overview;
  RevenueReport? _revenueReport;

  @override
  void initState() {
    super.initState();
    if (widget.initialFrom != null || widget.initialTo != null) {
      _selectedPresetDays = null;
    }
    final now = DateTime.now().toUtc();
    _fromController = TextEditingController(
      text:
          widget.initialFrom ??
          _formatDate(now.subtract(const Duration(days: 6))),
    );
    _toController = TextEditingController(
      text: widget.initialTo ?? _formatDate(now),
    );
    if (widget.sessionController.canView(BusinessPermission.viewAnalytics)) {
      unawaited(_load());
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _inactiveDaysController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _applyPreset(int days) {
    final now = DateTime.now().toUtc();
    setState(() {
      _selectedPresetDays = days;
    });
    _fromController.text = _formatDate(now.subtract(Duration(days: days)));
    _toController.text = _formatDate(now);
    unawaited(_load());
  }

  Future<void> _load() async {
    final inactiveDays = int.tryParse(_inactiveDaysController.text.trim());
    if (inactiveDays == null || inactiveDays < 1 || inactiveDays > 365) {
      setState(() {
        _errorMessage = 'Порог неактивности должен быть от 1 до 365 дней.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final from = _fromController.text.trim();
      final to = _toController.text.trim();
      final overviewFuture = widget.repository.fetchOverview(
        from: from,
        to: to,
        inactiveDays: inactiveDays,
      );
      final revenueFuture = widget.repository.fetchRevenueReport(
        from: from,
        to: to,
      );
      final overview = await overviewFuture;
      final revenue = await revenueFuture;
      if (!mounted) {
        return;
      }
      setState(() {
        _overview = overview;
        _revenueReport = revenue;
        _loading = false;
      });
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = error.message;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = 'Не удалось загрузить аналитику.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = BusinessStringsScope.of(context);
    return ListenableBuilder(
      listenable: widget.sessionController,
      builder: (context, _) {
        final colors = context.ucraftColors;
        if (!widget.sessionController.canView(
          BusinessPermission.viewAnalytics,
        )) {
          return UcraftEmptyState(
            icon: LucideIcons.shieldAlert,
            title: strings.analyticsNoAccessTitle,
            description: strings.analyticsOwnerOnlyDesc,
          );
        }

        final overview = _overview;
        final report = _revenueReport;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UcraftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.analyticsPeriodFilterTitle,
                    style: BusinessTypography.title.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: UcraftSpacing.space2),
                  UcraftSegmentedTabs<int>(
                    items: [
                      UcraftSegmentedTabItem(
                        value: 0,
                        label: strings.analyticsTodayLabel,
                      ),
                      UcraftSegmentedTabItem(
                        value: 6,
                        label: strings.analyticsWeekLabel,
                      ),
                      UcraftSegmentedTabItem(
                        value: 29,
                        label: strings.analyticsMonthLabel,
                      ),
                    ],
                    selected: _selectedPresetDays,
                    onSelected: _applyPreset,
                  ),
                  const SizedBox(height: UcraftSpacing.space3),
                  Row(
                    children: [
                      Expanded(
                        child: UcraftTextField(
                          controller: _fromController,
                          label: strings.analyticsFromDateLabel,
                        ),
                      ),
                      const SizedBox(width: UcraftSpacing.space2),
                      Expanded(
                        child: UcraftTextField(
                          controller: _toController,
                          label: strings.analyticsToDateLabel,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: UcraftSpacing.space2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: UcraftTextField(
                          controller: _inactiveDaysController,
                          label: strings.analyticsInactiveDaysLabel,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: UcraftSpacing.space2),
                      UcraftButton(
                        label: strings.analyticsApplyButton,
                        onPressed: _loading
                            ? null
                            : () {
                                setState(() => _selectedPresetDays = null);
                                unawaited(_load());
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: UcraftSpacing.space3),
            if (_loading)
              const UcraftLoadingState(
                isSkeleton: true,
                skeletonCount: 3,
                skeletonHeight: 96,
              )
            else if (_errorMessage != null)
              UcraftErrorState(
                title: strings.analyticsErrorTitle,
                message: _errorMessage!,
                retryLabel: strings.retryLabel,
                onRetry: () => unawaited(_load()),
              )
            else if (overview == null || report == null)
              UcraftEmptyState(
                icon: LucideIcons.trendingUp,
                title: strings.analyticsEmptyTitle,
                description: strings.analyticsEmptyDesc,
              )
            else ...[
              _buildRevenueCard(context, report.summary, strings),
              const SizedBox(height: UcraftSpacing.space3),
              _buildClientsAndVisitsCard(context, overview, strings),
              const SizedBox(height: UcraftSpacing.space3),
              _buildPopularitySection(
                context,
                title: strings.analyticsTopPlansTitle,
                items: overview.popularMemberships,
                strings: strings,
              ),
              const SizedBox(height: UcraftSpacing.space3),
              _buildPopularitySection(
                context,
                title: strings.analyticsTopProductsTitle,
                items: overview.popularProducts,
                strings: strings,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRevenueCard(
    BuildContext context,
    RevenueSummary summary,
    BusinessStrings strings,
  ) {
    final colors = context.ucraftColors;
    final c = summary.currency;
    return UcraftCard(
      variant: UcraftCardVariant.highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: strings.analyticsRevenuePrefix,
                  style: BusinessTypography.label.copyWith(
                    color: colors.foregroundSecondary,
                  ),
                ),
                TextSpan(
                  text: strings.formatMoney(summary.totalMinor, currency: c),
                ),
              ],
            ),
            style: BusinessTypography.amountLarge.copyWith(
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: UcraftSpacing.space3),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: UcraftRadius.borderSm,
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(UcraftSpacing.space3),
              child: Column(
                children: [
                  _buildFieldValueRow(
                    colors: colors,
                    label: strings.membershipsLabel,
                    value: strings.formatMoney(
                      summary.membershipsMinor,
                      currency: c,
                    ),
                  ),
                  Divider(height: UcraftSpacing.space4, color: colors.border),
                  _buildFieldValueRow(
                    colors: colors,
                    label: strings.subTabProducts,
                    value: strings.formatMoney(
                      summary.productsMinor,
                      currency: c,
                    ),
                  ),
                  Divider(height: UcraftSpacing.space4, color: colors.border),
                  _buildFieldValueRow(
                    colors: colors,
                    label: strings.receiptsCountLabel,
                    value: '${summary.salesCount}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: UcraftSpacing.space3),
          RevenuePaymentMixBar(
            byPaymentMethod: summary.byPaymentMethod,
            currency: c,
          ),
        ],
      ),
    );
  }

  Widget _buildClientsAndVisitsCard(
    BuildContext context,
    OverviewAnalytics overview,
    BusinessStrings strings,
  ) {
    final colors = context.ucraftColors;
    return UcraftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.analyticsClientsAndVisitsTitle,
            style: BusinessTypography.titleLarge.copyWith(
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: UcraftSpacing.space3),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: UcraftRadius.borderSm,
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(UcraftSpacing.space3),
              child: Column(
                children: [
                  _buildFieldValueRow(
                    colors: colors,
                    label: 'Всего клиентов',
                    value: '${overview.clients.totalClients}',
                    subtitle:
                        'Новых: ${overview.clients.newClients} • Постоянных: ${overview.clients.existingClients}',
                  ),
                  Divider(height: UcraftSpacing.space4, color: colors.border),
                  _buildFieldValueRow(
                    colors: colors,
                    label: 'Всего визитов',
                    value: '${overview.visits.totalVisits}',
                    subtitle:
                        'По QR: ${overview.visits.qrVisits} • Вручную: ${overview.visits.manualVisits}',
                  ),
                  Divider(height: UcraftSpacing.space4, color: colors.border),
                  _buildFieldValueRow(
                    colors: colors,
                    label:
                        'Неактивных за ${overview.visits.inactiveDaysThreshold} дн.',
                    value: '${overview.visits.inactiveClientsCount}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: UcraftSpacing.space4),
          VisitsByDayBarChart(byDay: overview.visits.byDay),
        ],
      ),
    );
  }

  Widget _buildFieldValueRow({
    required UcraftColors colors,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: UcraftTypography.bodyMedium.copyWith(
                  color: colors.foregroundSecondary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: UcraftTypography.caption.copyWith(
                    color: colors.foregroundMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: UcraftSpacing.space3),
        Text(
          value,
          style: BusinessTypography.amount.copyWith(color: colors.foreground),
        ),
      ],
    );
  }

  Widget _buildPopularitySection(
    BuildContext context, {
    required String title,
    required List<ItemPopularity> items,
    required BusinessStrings strings,
  }) {
    final colors = context.ucraftColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UcraftSectionHeader(title: title),
        const SizedBox(height: UcraftSpacing.space2),
        if (items.isEmpty)
          UcraftCard(
            child: Text(
              strings.analyticsNoSalesInPeriod,
              style: UcraftTypography.caption.copyWith(
                color: colors.foregroundSecondary,
              ),
            ),
          )
        else
          UcraftListSection(
            children: [
              for (final item in items)
                UcraftListRow(
                  title: '${item.name} — ${item.soldCount} шт.',
                  trailing: Text(
                    strings.formatMoney(
                      item.revenueMinor,
                      currency: item.currency,
                    ),
                    style: BusinessTypography.amount.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Bulk push/SMS announcement screen for `owner` and `admin`.
final class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({
    super.key,
    required this.repository,
    required this.sessionController,
  });

  final AnalyticsAndBillingRepository repository;
  final BusinessSessionController sessionController;

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

final class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  AnnouncementChannel _channel = AnnouncementChannel.push;
  bool _submitting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_submitting) {
      return;
    }

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || title.length > 120) {
      setState(() {
        _errorMessage = 'Укажите заголовок (1–120 символов).';
        _successMessage = null;
      });
      return;
    }
    if (body.isEmpty || body.length > 1000) {
      setState(() {
        _errorMessage = 'Укажите текст объявления (1–1000 символов).';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await widget.repository.sendAnnouncement(
        channel: _channel,
        title: title,
        body: body,
      );
      if (!mounted) {
        return;
      }
      _titleController.clear();
      _bodyController.clear();
      setState(() {
        _submitting = false;
        _successMessage =
            'Рассылка (${result.channel.apiValue}) поставлена в очередь: ${result.queuedCount}.';
      });
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _errorMessage = error.message;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _errorMessage = 'Не удалось отправить рассылку.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = BusinessStringsScope.of(context);
    return ListenableBuilder(
      listenable: widget.sessionController,
      builder: (context, _) {
        final colors = context.ucraftColors;
        if (!widget.sessionController.canView(
          BusinessPermission.sendAnnouncements,
        )) {
          return UcraftEmptyState(
            icon: LucideIcons.shieldAlert,
            title: strings.analyticsNoAccessTitle,
            description: strings.announcementsNoAccessDesc,
          );
        }

        final canSend = widget.sessionController.canMutate(
          BusinessPermission.sendAnnouncements,
        );

        return UcraftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.announcementsTitle,
                style: BusinessTypography.title.copyWith(
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: UcraftSpacing.space3),
              UcraftSegmentedTabs<AnnouncementChannel>(
                items: const [
                  UcraftSegmentedTabItem(
                    value: AnnouncementChannel.push,
                    label: 'Push',
                  ),
                  UcraftSegmentedTabItem(
                    value: AnnouncementChannel.sms,
                    label: 'SMS',
                  ),
                ],
                selected: _channel,
                enabled: canSend && !_submitting,
                onSelected: (channel) => setState(() => _channel = channel),
              ),
              const SizedBox(height: UcraftSpacing.space3),
              UcraftTextField(
                controller: _titleController,
                label: strings.announcementsTitleField,
                enabled: canSend && !_submitting,
              ),
              const SizedBox(height: UcraftSpacing.space3),
              UcraftTextField(
                controller: _bodyController,
                label: strings.announcementsBodyField,
                maxLines: 3,
                enabled: canSend && !_submitting,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: UcraftSpacing.space3),
                Text(
                  _errorMessage!,
                  style: BusinessTypography.bodyMedium.copyWith(
                    color: colors.destructive,
                  ),
                ),
              ],
              if (_successMessage != null) ...[
                const SizedBox(height: UcraftSpacing.space3),
                Text(
                  _successMessage!,
                  style: BusinessTypography.bodyMedium.copyWith(
                    color: colors.success,
                  ),
                ),
              ],
              const SizedBox(height: UcraftSpacing.space4),
              UcraftButton(
                label: strings.announcementsSendButton,
                fullWidth: true,
                isLoading: _submitting,
                onPressed: canSend && !_submitting
                    ? () => unawaited(_send())
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Platform billing subscription status and plan limits (no online payments).
final class BillingStatusScreen extends StatefulWidget {
  const BillingStatusScreen({
    super.key,
    required this.repository,
    required this.sessionController,
  });

  final AnalyticsAndBillingRepository repository;
  final BusinessSessionController sessionController;

  @override
  State<BillingStatusScreen> createState() => _BillingStatusScreenState();
}

final class _BillingStatusScreenState extends State<BillingStatusScreen> {
  bool _loading = true;
  String? _errorMessage;
  CompanySubscription? _subscription;
  List<PlatformPlan> _plans = const <PlatformPlan>[];

  @override
  void initState() {
    super.initState();
    if (widget.sessionController.canView(BusinessPermission.viewBilling)) {
      unawaited(_load());
    } else {
      _loading = false;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final subFuture = widget.repository.fetchBillingSubscription();
      final plansFuture = widget.repository.listBillingPlans();
      final sub = await subFuture;
      final plans = await plansFuture;
      if (!mounted) {
        return;
      }
      setState(() {
        _subscription = sub;
        _plans = plans;
        _loading = false;
      });
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = error.message;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = 'Не удалось загрузить статус подписки.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final strings = BusinessStringsScope.of(context);
    if (!widget.sessionController.canView(BusinessPermission.viewBilling)) {
      return UcraftEmptyState(
        icon: LucideIcons.shieldAlert,
        title: strings.analyticsNoAccessTitle,
        description: strings.billingNoAccessDesc,
      );
    }

    if (_loading) {
      return const UcraftLoadingState(isSkeleton: true, skeletonCount: 3);
    }

    if (_errorMessage != null) {
      return UcraftErrorState(
        title: strings.posLoadErrorTitle,
        message: _errorMessage!,
        retryLabel: strings.retryLabel,
        onRetry: () => unawaited(_load()),
      );
    }

    final sub = _subscription;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sub != null) ...[
          Builder(
            builder: (context) {
              final (statusIcon, statusTone) = switch (sub.status) {
                CompanySubscriptionStatus.active => (
                  LucideIcons.circleCheck,
                  UcraftStatusTone.success,
                ),
                CompanySubscriptionStatus.trial => (
                  LucideIcons.clock,
                  UcraftStatusTone.info,
                ),
                CompanySubscriptionStatus.expired => (
                  LucideIcons.triangleAlert,
                  UcraftStatusTone.destructive,
                ),
              };
              final totalSeconds = sub.endsAt
                  .difference(sub.startsAt)
                  .inSeconds;
              final remainingSeconds = totalSeconds > 0
                  ? sub.endsAt
                        .difference(DateTime.now().toUtc())
                        .inSeconds
                        .clamp(0, totalSeconds)
                  : 0;
              final progress = totalSeconds > 0
                  ? remainingSeconds / totalSeconds
                  : 0.0;
              final remainingDays = (remainingSeconds / 86400).ceil();

              return UcraftCard(
                variant: UcraftCardVariant.highlight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: UcraftSpacing.space2,
                      runSpacing: UcraftSpacing.space1,
                      children: [
                        Text(
                          strings.billingStatusTitle,
                          style: BusinessTypography.title.copyWith(
                            color: colors.foreground,
                          ),
                        ),
                        UcraftStatusPill(
                          icon: statusIcon,
                          label: _statusLabel(sub.status, strings),
                          tone: statusTone,
                        ),
                      ],
                    ),
                    const SizedBox(height: UcraftSpacing.space1),
                    Text(
                      '${strings.billingValidUntilPrefix}${DateFormatter.formatDateTime(sub.endsAt, offset: DateFormatter.dushanbeOffset)}',
                      style: UcraftTypography.body.copyWith(
                        color: colors.foregroundSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (totalSeconds > 0) ...[
                      const SizedBox(height: UcraftSpacing.space3),
                      UcraftProgressBar(
                        value: progress,
                        leadingLabel: sub.isReadOnly
                            ? '0 дн.'
                            : '$remainingDays дн.',
                        trailingLabel: DateFormatter.formatDate(
                          sub.endsAt,
                          offset: DateFormatter.dushanbeOffset,
                        ),
                      ),
                    ],
                    if (sub.isReadOnly) ...[
                      const SizedBox(height: UcraftSpacing.space2),
                      Text(
                        strings.billingReadOnlyHint,
                        style: UcraftTypography.caption.copyWith(
                          color: colors.destructive,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: UcraftSpacing.space3),
        ],
        UcraftSectionHeader(title: strings.billingPlansTitle),
        const SizedBox(height: UcraftSpacing.space2),
        if (_plans.isEmpty)
          UcraftCard(
            child: Text(
              strings.billingPlansEmpty,
              style: UcraftTypography.caption.copyWith(
                color: colors.foregroundSecondary,
              ),
            ),
          )
        else
          UcraftListSection(
            children: [
              for (final plan in _plans)
                UcraftListRow(
                  title:
                      '${plan.name} · ${strings.formatMoney(plan.priceMinor, currency: plan.currency)} / ${plan.period == BillingPlanPeriod.month ? strings.billingPlanMonth : strings.billingPlanYear}',
                  subtitle:
                      'Лимиты: до ${plan.maxGyms} залов, до ${plan.maxStaff} сотрудников',
                  trailing: UcraftStatusPill(
                    icon: plan.isActive
                        ? LucideIcons.circleCheck
                        : LucideIcons.pause,
                    label: plan.isActive
                        ? strings.planStatusActive
                        : strings.planStatusArchived,
                    tone: plan.isActive
                        ? UcraftStatusTone.success
                        : UcraftStatusTone.neutral,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  String _statusLabel(
    CompanySubscriptionStatus status,
    BusinessStrings strings,
  ) {
    return switch (status) {
      CompanySubscriptionStatus.trial => strings.billingStatusTrial,
      CompanySubscriptionStatus.active => strings.billingStatusActive,
      CompanySubscriptionStatus.expired => strings.billingStatusExpired,
    };
  }
}

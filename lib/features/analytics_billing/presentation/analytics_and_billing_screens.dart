import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../../../core/session/business_role.dart';
import '../../../core/session/business_session_controller.dart';
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
  String? _errorMessage;
  OverviewAnalytics? _overview;
  RevenueReport? _revenueReport;

  @override
  void initState() {
    super.initState();
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
    return ListenableBuilder(
      listenable: widget.sessionController,
      builder: (context, _) {
        final colors = context.ucraftColors;
        if (!widget.sessionController.canView(
          BusinessPermission.viewAnalytics,
        )) {
          return const UcraftEmptyState(
            title: 'Недостаточно прав',
            description: 'Аналитика и выручка доступны только владельцу.',
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
                    'Фильтр периода',
                    style: UcraftTypography.title.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: UcraftSpacing.space2),
                  Wrap(
                    spacing: UcraftSpacing.space2,
                    runSpacing: UcraftSpacing.space2,
                    children: [
                      UcraftButton(
                        label: 'Сегодня',
                        variant: UcraftButtonVariant.secondary,
                        onPressed: () => _applyPreset(0),
                      ),
                      UcraftButton(
                        label: 'Неделя',
                        variant: UcraftButtonVariant.secondary,
                        onPressed: () => _applyPreset(6),
                      ),
                      UcraftButton(
                        label: 'Месяц',
                        variant: UcraftButtonVariant.secondary,
                        onPressed: () => _applyPreset(29),
                      ),
                    ],
                  ),
                  const SizedBox(height: UcraftSpacing.space3),
                  Row(
                    children: [
                      Expanded(
                        child: UcraftTextField(
                          controller: _fromController,
                          label: 'С (ГГГГ-ММ-ДД)',
                        ),
                      ),
                      const SizedBox(width: UcraftSpacing.space2),
                      Expanded(
                        child: UcraftTextField(
                          controller: _toController,
                          label: 'По (ГГГГ-ММ-ДД)',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: UcraftSpacing.space2),
                  Row(
                    children: [
                      Expanded(
                        child: UcraftTextField(
                          controller: _inactiveDaysController,
                          label: 'Неактивные (1–365 дн.)',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: UcraftSpacing.space2),
                      UcraftButton(
                        label: 'Применить',
                        onPressed: _loading ? null : () => unawaited(_load()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: UcraftSpacing.space3),
            if (_loading)
              const UcraftLoadingState(message: 'Загружаем аналитику...')
            else if (_errorMessage != null)
              UcraftErrorState(
                title: 'Ошибка аналитики',
                message: _errorMessage!,
                onRetry: () => unawaited(_load()),
              )
            else if (overview == null || report == null)
              const UcraftEmptyState(
                title: 'Данных нет',
                description: 'Выберите период и обновите отчёт.',
              )
            else ...[
              _buildRevenueCard(context, report.summary),
              const SizedBox(height: UcraftSpacing.space3),
              _buildClientsAndVisitsCard(context, overview),
              const SizedBox(height: UcraftSpacing.space3),
              _buildPopularityCard(
                context,
                title: 'Топ тарифов',
                items: overview.popularMemberships,
              ),
              const SizedBox(height: UcraftSpacing.space3),
              _buildPopularityCard(
                context,
                title: 'Топ товаров',
                items: overview.popularProducts,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRevenueCard(BuildContext context, RevenueSummary summary) {
    final colors = context.ucraftColors;
    final c = summary.currency;
    return UcraftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Выручка: ${_money(summary.totalMinor)} $c',
            style: UcraftTypography.title.copyWith(color: colors.foreground),
          ),
          const SizedBox(height: UcraftSpacing.space1),
          Text(
            'Абонементы: ${_money(summary.membershipsMinor)} $c • Товары: ${_money(summary.productsMinor)} $c • Чеков: ${summary.salesCount}',
            style: UcraftTypography.caption.copyWith(
              color: colors.foregroundSecondary,
            ),
          ),
          const SizedBox(height: UcraftSpacing.space1),
          Text(
            'Наличные: ${_money(summary.byPaymentMethod.cash)} $c • Терминал: ${_money(summary.byPaymentMethod.cardTerminal)} $c • Перевод: ${_money(summary.byPaymentMethod.transfer)} $c',
            style: UcraftTypography.caption.copyWith(
              color: colors.foregroundSecondary,
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
  ) {
    final colors = context.ucraftColors;
    return UcraftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Клиенты и посещаемость',
            style: UcraftTypography.title.copyWith(color: colors.foreground),
          ),
          const SizedBox(height: UcraftSpacing.space1),
          Text(
            'Клиентов: ${overview.clients.totalClients} (новых: ${overview.clients.newClients}, постоянных: ${overview.clients.existingClients})',
            style: UcraftTypography.body.copyWith(
              color: colors.foregroundSecondary,
            ),
          ),
          const SizedBox(height: UcraftSpacing.space1),
          Text(
            'Визиты: ${overview.visits.totalVisits} (QR: ${overview.visits.qrVisits}, ручные: ${overview.visits.manualVisits})',
            style: UcraftTypography.body.copyWith(
              color: colors.foregroundSecondary,
            ),
          ),
          const SizedBox(height: UcraftSpacing.space1),
          Text(
            'Неактивных за ${overview.visits.inactiveDaysThreshold} дн.: ${overview.visits.inactiveClientsCount}',
            style: UcraftTypography.caption.copyWith(
              color: colors.foregroundSecondary,
            ),
          ),
          const SizedBox(height: UcraftSpacing.space3),
          VisitsByDayBarChart(byDay: overview.visits.byDay),
        ],
      ),
    );
  }

  Widget _buildPopularityCard(
    BuildContext context, {
    required String title,
    required List<ItemPopularity> items,
  }) {
    final colors = context.ucraftColors;
    return UcraftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: UcraftTypography.title.copyWith(color: colors.foreground),
          ),
          const SizedBox(height: UcraftSpacing.space2),
          if (items.isEmpty)
            Text(
              'За период продаж не было.',
              style: UcraftTypography.caption.copyWith(
                color: colors.foregroundSecondary,
              ),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: UcraftSpacing.space1),
                child: Text(
                  '${item.name} — ${item.soldCount} шт. (${_money(item.revenueMinor)} ${item.currency})',
                  style: UcraftTypography.body.copyWith(
                    color: colors.foreground,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  String _money(int minor) => (minor / 100).toStringAsFixed(2);
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
    return ListenableBuilder(
      listenable: widget.sessionController,
      builder: (context, _) {
        final colors = context.ucraftColors;
        if (!widget.sessionController.canView(
          BusinessPermission.sendAnnouncements,
        )) {
          return const UcraftEmptyState(
            title: 'Недостаточно прав',
            description: 'Рассылки доступны владельцу и администратору.',
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
                'Массовая рассылка',
                style: UcraftTypography.title.copyWith(
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: UcraftSpacing.space3),
              Wrap(
                spacing: UcraftSpacing.space2,
                children: [
                  UcraftButton(
                    label: 'Push',
                    variant: _channel == AnnouncementChannel.push
                        ? UcraftButtonVariant.primary
                        : UcraftButtonVariant.secondary,
                    onPressed: canSend && !_submitting
                        ? () => setState(
                            () => _channel = AnnouncementChannel.push,
                          )
                        : null,
                  ),
                  UcraftButton(
                    label: 'SMS',
                    variant: _channel == AnnouncementChannel.sms
                        ? UcraftButtonVariant.primary
                        : UcraftButtonVariant.secondary,
                    onPressed: canSend && !_submitting
                        ? () =>
                              setState(() => _channel = AnnouncementChannel.sms)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: UcraftSpacing.space3),
              UcraftTextField(
                controller: _titleController,
                label: 'Заголовок (до 120)',
                enabled: canSend && !_submitting,
              ),
              const SizedBox(height: UcraftSpacing.space3),
              UcraftTextField(
                controller: _bodyController,
                label: 'Текст сообщения (до 1000)',
                maxLines: 3,
                enabled: canSend && !_submitting,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: UcraftSpacing.space3),
                Text(
                  _errorMessage!,
                  style: UcraftTypography.bodyMedium.copyWith(
                    color: colors.destructive,
                  ),
                ),
              ],
              if (_successMessage != null) ...[
                const SizedBox(height: UcraftSpacing.space3),
                Text(
                  _successMessage!,
                  style: UcraftTypography.bodyMedium.copyWith(
                    color: colors.success,
                  ),
                ),
              ],
              const SizedBox(height: UcraftSpacing.space4),
              UcraftButton(
                label: 'Отправить рассылку',
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
    if (!widget.sessionController.canView(BusinessPermission.viewBilling)) {
      return const UcraftEmptyState(
        title: 'Недостаточно прав',
        description: 'Подписка платформы доступна владельцу и администратору.',
      );
    }

    if (_loading) {
      return const UcraftLoadingState(message: 'Загружаем подписку...');
    }

    if (_errorMessage != null) {
      return UcraftErrorState(
        title: 'Ошибка загрузки',
        message: _errorMessage!,
        onRetry: () => unawaited(_load()),
      );
    }

    final sub = _subscription;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sub != null)
          UcraftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Подписка платформы: ${_statusLabel(sub.status)}',
                  style: UcraftTypography.title.copyWith(
                    color: sub.isReadOnly
                        ? colors.destructive
                        : colors.foreground,
                  ),
                ),
                const SizedBox(height: UcraftSpacing.space1),
                Text(
                  'Действует до: ${DateFormatter.formatDateTime(sub.endsAt, offset: DateFormatter.dushanbeOffset)}',
                  style: UcraftTypography.body.copyWith(
                    color: colors.foregroundSecondary,
                  ),
                ),
                if (sub.isReadOnly) ...[
                  const SizedBox(height: UcraftSpacing.space2),
                  Text(
                    'Режим только для чтения: для продления свяжитесь с поддержкой платформы.',
                    style: UcraftTypography.caption.copyWith(
                      color: colors.destructive,
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: UcraftSpacing.space3),
        UcraftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Тарифы платформы',
                style: UcraftTypography.title.copyWith(
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: UcraftSpacing.space2),
              if (_plans.isEmpty)
                Text(
                  'Список тарифов пуст.',
                  style: UcraftTypography.caption.copyWith(
                    color: colors.foregroundSecondary,
                  ),
                )
              else
                for (final plan in _plans) ...[
                  Text(
                    '${plan.name} (${plan.period.apiValue}) — ${(plan.priceMinor / 100).toStringAsFixed(2)} ${plan.currency}',
                    style: UcraftTypography.bodyMedium.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                  Text(
                    'Лимиты: до ${plan.maxGyms} залов, до ${plan.maxStaff} сотрудников',
                    style: UcraftTypography.caption.copyWith(
                      color: colors.foregroundSecondary,
                    ),
                  ),
                  const SizedBox(height: UcraftSpacing.space2),
                ],
            ],
          ),
        ),
      ],
    );
  }

  String _statusLabel(CompanySubscriptionStatus status) {
    return switch (status) {
      CompanySubscriptionStatus.trial => 'Пробный период (trial)',
      CompanySubscriptionStatus.active => 'Активна (active)',
      CompanySubscriptionStatus.expired => 'Истекла (expired)',
    };
  }
}

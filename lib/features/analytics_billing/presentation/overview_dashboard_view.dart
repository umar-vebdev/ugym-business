import 'dart:async';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../../../core/session/business_role.dart';
import '../../../core/session/business_session_controller.dart';
import '../../memberships/domain/memberships_models.dart';
import '../../sales/domain/sales_and_requests_models.dart';
import '../domain/analytics_and_billing_models.dart';

/// Live operational overview dashboard for `owner` and `admin`.
final class OverviewDashboardView extends StatefulWidget {
  const OverviewDashboardView({
    super.key,
    required this.appTitle,
    required this.sessionController,
    this.analyticsRepository,
    this.salesRepository,
    this.membershipsRepository,
    this.onOpenScanner,
    this.onOpenKiosk,
    this.onOpenPos,
    this.onOpenPendingRequests,
    this.onOpenExpiringMemberships,
    this.onOpenAnalytics,
    this.clock,
  });

  final String appTitle;
  final BusinessSessionController sessionController;
  final AnalyticsAndBillingRepository? analyticsRepository;
  final SalesAndRequestsRepository? salesRepository;
  final MembershipsRepository? membershipsRepository;
  final VoidCallback? onOpenScanner;
  final VoidCallback? onOpenKiosk;
  final VoidCallback? onOpenPos;
  final VoidCallback? onOpenPendingRequests;
  final VoidCallback? onOpenExpiringMemberships;
  final VoidCallback? onOpenAnalytics;
  final DateTime Function()? clock;

  @override
  State<OverviewDashboardView> createState() => _OverviewDashboardViewState();
}

final class _OverviewDashboardViewState extends State<OverviewDashboardView> {
  bool _loading = false;
  String? _errorMessage;
  OverviewAnalytics? _overview;
  int? _pendingRequestsCount;
  int? _expiringMembershipsCount;
  BusinessRole? _lastLoadedRole;
  int? _lastLoadedGymId;

  bool get _canLoadOverview =>
      widget.analyticsRepository != null &&
      widget.sessionController.canView(BusinessPermission.viewAnalytics);

  bool get _canLoadPendingRequests =>
      widget.salesRepository != null &&
      widget.sessionController.canView(
        BusinessPermission.manageMembershipRequestsAndSales,
      );

  bool get _canLoadExpiring =>
      widget.membershipsRepository != null &&
      widget.sessionController.canView(
        BusinessPermission.viewExpiringAndFreezeMemberships,
      );

  bool get _hasAnyDataSource =>
      _canLoadOverview || _canLoadPendingRequests || _canLoadExpiring;

  @override
  void initState() {
    super.initState();
    widget.sessionController.addListener(_handleSessionChanged);
    _lastLoadedRole = widget.sessionController.role;
    _lastLoadedGymId = widget.sessionController.selectedGym?.id;
    if (_hasAnyDataSource) {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    widget.sessionController.removeListener(_handleSessionChanged);
    super.dispose();
  }

  void _handleSessionChanged() {
    final nextRole = widget.sessionController.role;
    final nextGymId = widget.sessionController.selectedGym?.id;
    if (nextRole != _lastLoadedRole || nextGymId != _lastLoadedGymId) {
      _lastLoadedRole = nextRole;
      _lastLoadedGymId = nextGymId;
      if (_hasAnyDataSource) {
        unawaited(_load());
      } else if (mounted) {
        setState(() {
          _overview = null;
          _pendingRequestsCount = null;
          _expiringMembershipsCount = null;
          _errorMessage = null;
          _loading = false;
        });
      }
    }
  }

  String _todayIsoDate() {
    final now = (widget.clock ?? DateTime.now)();
    final local = DateFormatter.toTargetZone(
      now,
      offset: DateFormatter.dushanbeOffset,
    );
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _load() async {
    if (!_hasAnyDataSource) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final today = _todayIsoDate();
    OverviewAnalytics? overview;
    int? pendingCount;
    int? expiringCount;
    String? firstError;
    var loadedAny = false;

    final tasks = <Future<void>>[];

    if (_canLoadOverview) {
      tasks.add(() async {
        try {
          overview = await widget.analyticsRepository!.fetchOverview(
            from: today,
            to: today,
          );
          loadedAny = true;
        } on UgymApiException catch (error) {
          firstError ??= error.message;
        } on Object {
          firstError ??= 'Не удалось загрузить показатели дня.';
        }
      }());
    }

    if (_canLoadPendingRequests) {
      tasks.add(() async {
        try {
          final requests = await widget.salesRepository!.listMembershipRequests(
            status: MembershipRequestStatus.pending,
          );
          pendingCount = requests.length;
          loadedAny = true;
        } on UgymApiException catch (error) {
          firstError ??= error.message;
        } on Object {
          firstError ??= 'Не удалось загрузить очередь заявок.';
        }
      }());
    }

    if (_canLoadExpiring) {
      tasks.add(() async {
        try {
          final expiring = await widget.membershipsRepository!
              .listExpiringMemberships();
          expiringCount = expiring.length;
          loadedAny = true;
        } on UgymApiException catch (error) {
          firstError ??= error.message;
        } on Object {
          firstError ??= 'Не удалось загрузить истекающие абонементы.';
        }
      }());
    }

    await Future.wait<void>(tasks);
    if (!mounted) {
      return;
    }

    setState(() {
      _overview = overview;
      _pendingRequestsCount = pendingCount;
      _expiringMembershipsCount = expiringCount;
      _errorMessage = loadedAny ? null : firstError;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sessionController,
      builder: (context, _) {
        final colors = context.ucraftColors;
        final role = widget.sessionController.role;
        final gymName =
            widget.sessionController.selectedGym?.name ?? 'Филиал не выбран';

        final hasQuickActions =
            widget.onOpenScanner != null ||
            widget.onOpenKiosk != null ||
            widget.onOpenPos != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UcraftCard(
              child: Wrap(
                spacing: UcraftSpacing.space3,
                runSpacing: UcraftSpacing.space2,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.appTitle,
                        style: UcraftTypography.title.copyWith(
                          color: colors.foreground,
                        ),
                      ),
                      const SizedBox(height: UcraftSpacing.space1),
                      Text(
                        'Роль: ${role?.name ?? 'не определена'} • Филиал: $gymName',
                        style: UcraftTypography.body.copyWith(
                          color: colors.foregroundSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (_hasAnyDataSource)
                    UcraftButton(
                      label: 'Обновить',
                      variant: UcraftButtonVariant.secondary,
                      isLoading: _loading,
                      onPressed: _loading ? null : () => unawaited(_load()),
                    ),
                ],
              ),
            ),
            if (hasQuickActions) ...[
              const SizedBox(height: UcraftSpacing.space3),
              UcraftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Быстрые действия',
                      style: UcraftTypography.title.copyWith(
                        color: colors.foreground,
                      ),
                    ),
                    const SizedBox(height: UcraftSpacing.space3),
                    Wrap(
                      spacing: UcraftSpacing.space2,
                      runSpacing: UcraftSpacing.space2,
                      children: [
                        if (widget.onOpenScanner != null)
                          UcraftButton(
                            label: 'Сканер QR клиента',
                            onPressed:
                                widget.sessionController.canMutate(
                                  BusinessPermission.manageReceptionQrAndVisits,
                                )
                                ? widget.onOpenScanner
                                : null,
                          ),
                        if (widget.onOpenKiosk != null)
                          UcraftButton(
                            label: 'Киоск QR зала',
                            variant: UcraftButtonVariant.secondary,
                            onPressed: widget.onOpenKiosk,
                          ),
                        if (widget.onOpenPos != null &&
                            widget.sessionController.canMutate(
                              BusinessPermission
                                  .manageMembershipRequestsAndSales,
                            ))
                          UcraftButton(
                            label: 'Открыть кассу',
                            variant: UcraftButtonVariant.secondary,
                            onPressed: widget.onOpenPos,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (_hasAnyDataSource) ...[
              const SizedBox(height: UcraftSpacing.space3),
              if (_loading &&
                  _overview == null &&
                  _pendingRequestsCount == null &&
                  _expiringMembershipsCount == null)
                const UcraftLoadingState(isSkeleton: true, skeletonCount: 2)
              else if (_errorMessage != null)
                UcraftErrorState(
                  title: 'Ошибка загрузки сводки',
                  message: _errorMessage!,
                  retryLabel: 'Повторить',
                  onRetry: () => unawaited(_load()),
                )
              else
                _buildMetricsGrid(context),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    final cards = <Widget>[
      if (_overview != null) _buildRevenueKpiCard(context, _overview!),
      if (_overview != null) _buildVisitsKpiCard(context, _overview!),
      if (_pendingRequestsCount != null)
        _buildOperationalAlertCard(
          context,
          title: 'Заявки в ожидании',
          value: '$_pendingRequestsCount',
          subtitle: _pendingRequestsCount == 0
              ? 'Необработанных заявок из uGym нет'
              : 'Ожидают подтверждения оплаты на кассе',
          highlightWarning: _pendingRequestsCount! > 0,
          actionLabel: widget.onOpenPendingRequests != null
              ? 'К заявкам'
              : null,
          onAction: widget.onOpenPendingRequests,
        ),
      if (_expiringMembershipsCount != null)
        _buildOperationalAlertCard(
          context,
          title: 'Истекают за 7 дней',
          value: '$_expiringMembershipsCount',
          subtitle: _expiringMembershipsCount == 0
              ? 'Истекающих абонементов нет'
              : 'Абонементы для напоминания о продлении',
          highlightWarning: _expiringMembershipsCount! > 0,
          actionLabel: widget.onOpenExpiringMemberships != null
              ? 'К истекающим'
              : null,
          onAction: widget.onOpenExpiringMemberships,
        ),
    ];

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool twoColumns = constraints.maxWidth >= 600 && cards.length > 1;
        if (!twoColumns) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i + 1 < cards.length)
                  const SizedBox(height: UcraftSpacing.cardGap),
              ],
            ],
          );
        }

        final double cardWidth =
            (constraints.maxWidth - UcraftSpacing.cardGap) / 2;
        return Wrap(
          spacing: UcraftSpacing.cardGap,
          runSpacing: UcraftSpacing.cardGap,
          children: [
            for (final card in cards) SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }

  Widget _buildRevenueKpiCard(
    BuildContext context,
    OverviewAnalytics overview,
  ) {
    final colors = context.ucraftColors;
    final revenue = overview.revenue;
    final total = MoneyFormatter.format(
      revenue.totalMinor,
      currency: revenue.currency,
      alwaysShowDecimals: true,
    );
    final memberships = MoneyFormatter.format(
      revenue.membershipsMinor,
      currency: revenue.currency,
    );
    final products = MoneyFormatter.format(
      revenue.productsMinor,
      currency: revenue.currency,
    );

    return UcraftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Выручка сегодня',
            style: UcraftTypography.label.copyWith(
              color: colors.foregroundSecondary,
            ),
          ),
          const SizedBox(height: UcraftSpacing.space2),
          Text(
            total,
            style: UcraftTypography.headline.copyWith(
              fontFamily: UcraftTypography.monoFontFamily,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: UcraftSpacing.space2),
          Text(
            'Чеков: ${revenue.salesCount} • Абонементы: $memberships • Товары: $products',
            style: UcraftTypography.caption.copyWith(
              color: colors.foregroundSecondary,
            ),
          ),
          if (widget.onOpenAnalytics != null) ...[
            const SizedBox(height: UcraftSpacing.space3),
            UcraftButton(
              label: 'Открыть аналитику',
              variant: UcraftButtonVariant.secondary,
              onPressed: widget.onOpenAnalytics,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVisitsKpiCard(BuildContext context, OverviewAnalytics overview) {
    final colors = context.ucraftColors;
    final visits = overview.visits;
    final clients = overview.clients;

    return UcraftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Посещения сегодня',
            style: UcraftTypography.label.copyWith(
              color: colors.foregroundSecondary,
            ),
          ),
          const SizedBox(height: UcraftSpacing.space2),
          Text(
            '${visits.totalVisits}',
            style: UcraftTypography.headline.copyWith(
              fontFamily: UcraftTypography.monoFontFamily,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: UcraftSpacing.space2),
          Text(
            'QR: ${visits.qrVisits} • Ручные: ${visits.manualVisits} • Новых клиентов: ${clients.newClients}',
            style: UcraftTypography.caption.copyWith(
              color: colors.foregroundSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalAlertCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required bool highlightWarning,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colors = context.ucraftColors;
    return UcraftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                highlightWarning ? LucideIcons.bell : LucideIcons.circleCheck,
                size: 20,
                color: highlightWarning ? colors.warning : colors.success,
              ),
              const SizedBox(width: UcraftSpacing.iconLabelGap),
              Expanded(
                child: Text(
                  title,
                  style: UcraftTypography.label.copyWith(
                    color: colors.foregroundSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: UcraftSpacing.space2),
          Text(
            value,
            style: UcraftTypography.headline.copyWith(
              fontFamily: UcraftTypography.monoFontFamily,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: highlightWarning ? colors.warning : colors.foreground,
            ),
          ),
          const SizedBox(height: UcraftSpacing.space1),
          Text(
            subtitle,
            style: UcraftTypography.caption.copyWith(
              color: colors.foregroundSecondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: UcraftSpacing.space3),
            UcraftButton(
              label: actionLabel,
              variant: UcraftButtonVariant.secondary,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

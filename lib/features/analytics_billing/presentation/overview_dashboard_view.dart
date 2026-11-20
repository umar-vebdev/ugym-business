import 'dart:async';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../../../core/l10n/business_localizations.dart';
import '../../../core/session/business_role.dart';
import '../../../core/session/business_session_controller.dart';
import '../../../core/theme/business_typography.dart';
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
    final strings = BusinessStringsScope.of(context);
    return ListenableBuilder(
      listenable: widget.sessionController,
      builder: (context, _) {
        final colors = context.ucraftColors;
        final role = widget.sessionController.role;
        final gymName =
            widget.sessionController.selectedGym?.name ??
            strings.branchNotSelected;
        final canScan = widget.sessionController.canMutate(
          BusinessPermission.manageReceptionQrAndVisits,
        );
        final canPos =
            widget.onOpenPos != null &&
            widget.sessionController.canMutate(
              BusinessPermission.manageMembershipRequestsAndSales,
            );
        final hasSecondaryActions = widget.onOpenKiosk != null || canPos;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroSummaryCard(
              context,
              strings: strings,
              role: role,
              gymName: gymName,
            ),
            if (widget.onOpenScanner != null) ...[
              const SizedBox(height: UcraftSpacing.space4),
              UcraftButton(
                label: strings.scanClientQrButton,
                leadingIcon: LucideIcons.qrCode,
                fullWidth: true,
                onPressed: canScan ? widget.onOpenScanner : null,
              ),
            ],
            if (hasSecondaryActions || _hasAnyDataSource) ...[
              const SizedBox(height: UcraftSpacing.space2),
              Wrap(
                spacing: UcraftSpacing.space2,
                runSpacing: UcraftSpacing.space2,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  if (widget.onOpenKiosk != null)
                    UcraftButton(
                      label: strings.kioskQrButton,
                      leadingIcon: LucideIcons.monitorSmartphone,
                      variant: UcraftButtonVariant.secondary,
                      onPressed: widget.onOpenKiosk,
                    ),
                  if (canPos)
                    UcraftButton(
                      label: strings.openPosButton,
                      leadingIcon: LucideIcons.shoppingBag,
                      variant: UcraftButtonVariant.secondary,
                      onPressed: widget.onOpenPos,
                    ),
                  if (_hasAnyDataSource)
                    UcraftButton(
                      label: strings.refreshLabel,
                      variant: UcraftButtonVariant.tertiary,
                      isLoading: _loading,
                      onPressed: _loading ? null : () => unawaited(_load()),
                    ),
                ],
              ),
            ],
            if (_hasAnyDataSource) ...[
              const SizedBox(height: UcraftSpacing.sectionGap),
              if (_loading &&
                  _overview == null &&
                  _pendingRequestsCount == null &&
                  _expiringMembershipsCount == null)
                const UcraftLoadingState(isSkeleton: true, skeletonCount: 2)
              else if (_errorMessage != null)
                UcraftErrorState(
                  icon: LucideIcons.circleAlert,
                  title: strings.overviewErrorTitle,
                  message: _errorMessage!,
                  retryLabel: strings.retryLabel,
                  onRetry: () => unawaited(_load()),
                )
              else
                _buildOperationalSection(context, strings, colors),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHeroSummaryCard(
    BuildContext context, {
    required BusinessStrings strings,
    required BusinessRole? role,
    required String gymName,
  }) {
    final colors = context.ucraftColors;
    final overview = _overview;
    final roleLabel = role?.name ?? strings.roleUnset;

    return UcraftCard(
      variant: UcraftCardVariant.highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.appTitle.toUpperCase(),
                  style: UcraftTypography.overline.copyWith(
                    color: colors.foregroundMuted,
                  ),
                ),
              ),
              UcraftStatusPill(
                icon: LucideIcons.shieldCheck,
                label: '${strings.roleLabel}: $roleLabel',
                tone: UcraftStatusTone.info,
              ),
            ],
          ),
          const SizedBox(height: UcraftSpacing.space1),
          Text(
            gymName,
            style: UcraftTypography.titleLarge.copyWith(
              color: colors.foreground,
            ),
          ),
          if (overview != null) ...[
            const SizedBox(height: UcraftSpacing.space4),
            _buildOwnerKpiStrip(context, overview, strings),
            if (widget.onOpenAnalytics != null) ...[
              const SizedBox(height: UcraftSpacing.space2),
              Align(
                alignment: Alignment.centerLeft,
                child: UcraftButton(
                  label: strings.openAnalyticsButton,
                  variant: UcraftButtonVariant.tertiary,
                  onPressed: widget.onOpenAnalytics,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildOwnerKpiStrip(
    BuildContext context,
    OverviewAnalytics overview,
    BusinessStrings strings,
  ) {
    final colors = context.ucraftColors;
    final revenue = overview.revenue;
    final visits = overview.visits;
    final clients = overview.clients;
    final total = strings.formatMoney(
      revenue.totalMinor,
      currency: revenue.currency,
    );
    final memberships = strings.formatMoney(
      revenue.membershipsMinor,
      currency: revenue.currency,
      alwaysShowDecimals: false,
    );
    final products = strings.formatMoney(
      revenue.productsMinor,
      currency: revenue.currency,
      alwaysShowDecimals: false,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final metricRevenue = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.revenueTodayTitle,
              style: UcraftTypography.caption.copyWith(
                color: colors.foregroundSecondary,
              ),
            ),
            const SizedBox(height: UcraftSpacing.space1),
            Text(
              total,
              style: BusinessTypography.amountLarge.copyWith(
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: UcraftSpacing.space1),
            Text(
              '${strings.receiptsCountLabel}: ${revenue.salesCount} • ${strings.membershipsLabel}: $memberships • ${strings.subTabProducts}: $products',
              style: UcraftTypography.caption.copyWith(
                color: colors.foregroundSecondary,
              ),
            ),
          ],
        );

        final metricVisits = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.visitsTodayTitle,
              style: UcraftTypography.caption.copyWith(
                color: colors.foregroundSecondary,
              ),
            ),
            const SizedBox(height: UcraftSpacing.space1),
            Text(
              '${visits.totalVisits}',
              style: UcraftTypography.headline.copyWith(
                fontFamily: UcraftTypography.monoFontFamily,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: UcraftSpacing.space1),
            Text(
              'QR: ${visits.qrVisits} • ${strings.manualVisitsLabel}: ${visits.manualVisits} • ${strings.newClientsLabel}: ${clients.newClients}',
              style: UcraftTypography.caption.copyWith(
                color: colors.foregroundSecondary,
              ),
            ),
          ],
        );

        if (constraints.maxWidth >= 520) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: metricRevenue),
              const SizedBox(width: UcraftSpacing.space4),
              Expanded(child: metricVisits),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            metricRevenue,
            const SizedBox(height: UcraftSpacing.space3),
            metricVisits,
          ],
        );
      },
    );
  }

  Widget _buildOperationalSection(
    BuildContext context,
    BusinessStrings strings,
    UcraftColors colors,
  ) {
    final rows = <Widget>[
      if (_pendingRequestsCount != null)
        _buildOperationalRow(
          context,
          colors: colors,
          title: strings.pendingRequestsTitle,
          count: _pendingRequestsCount!,
          subtitle: _pendingRequestsCount == 0
              ? strings.pendingRequestsEmpty
              : strings.pendingRequestsHint,
          actionLabel: widget.onOpenPendingRequests != null
              ? strings.goToRequestsButton
              : null,
          onAction: widget.onOpenPendingRequests,
        ),
      if (_expiringMembershipsCount != null)
        _buildOperationalRow(
          context,
          colors: colors,
          title: strings.expiringSoonTitle,
          count: _expiringMembershipsCount!,
          subtitle: _expiringMembershipsCount == 0
              ? strings.expiringSoonEmpty
              : strings.expiringSoonHint,
          actionLabel: widget.onOpenExpiringMemberships != null
              ? strings.goToExpiringButton
              : null,
          onAction: widget.onOpenExpiringMemberships,
        ),
    ];

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UcraftSectionHeader(title: strings.quickActionsTitle),
        const SizedBox(height: UcraftSpacing.space2),
        UcraftListSection(children: rows),
      ],
    );
  }

  Widget _buildOperationalRow(
    BuildContext context, {
    required UcraftColors colors,
    required String title,
    required int count,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final bool warn = count > 0;
    return UcraftListRow(
      monoLeadingWidth: true,
      onTap: onAction,
      leading: Text(
        '$count',
        style: UcraftTypography.headline.copyWith(
          fontFamily: UcraftTypography.monoFontFamily,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: warn ? colors.warning : colors.foreground,
        ),
      ),
      title: title,
      subtitle: subtitle,
      trailing: actionLabel != null && onAction != null
          ? UcraftButton(
              label: actionLabel,
              leadingIcon: warn ? LucideIcons.bell : LucideIcons.circleCheck,
              variant: UcraftButtonVariant.tertiary,
              onPressed: onAction,
            )
          : Icon(
              warn ? LucideIcons.bell : LucideIcons.circleCheck,
              size: 16,
              color: warn ? colors.warning : colors.success,
            ),
    );
  }
}

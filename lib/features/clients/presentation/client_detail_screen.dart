import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../../../core/l10n/business_localizations.dart';
import '../../../core/router/role_guard_and_banners.dart';
import '../../../core/session/business_role.dart';
import '../../../core/session/business_session_controller.dart';
import '../../memberships/domain/memberships_models.dart';
import '../../reception_qr/domain/reception_visits_models.dart';
import '../../reception_qr/presentation/visits_log_screen.dart';
import '../../sales/domain/sales_and_requests_models.dart';
import '../../sales/presentation/membership_requests_and_sales_tabs.dart';
import '../../sales/presentation/pos_and_products_screens.dart';
import '../domain/clients_models.dart';

enum _ClientDetailTab { memberships, visits, sales }

/// Client 360° profile showing memberships, visits, purchases, and quick actions.
final class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({
    super.key,
    required this.client,
    required this.sessionController,
    required this.membershipsRepository,
    required this.visitsRepository,
    required this.salesRepository,
  });

  final ClientSummary client;
  final BusinessSessionController sessionController;
  final MembershipsRepository membershipsRepository;
  final ReceptionVisitsRepository visitsRepository;
  final SalesAndRequestsRepository salesRepository;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

final class _ClientDetailScreenState extends State<ClientDetailScreen> {
  _ClientDetailTab _tab = _ClientDetailTab.memberships;
  bool _loading = true;
  String? _errorMessage;
  int? _busyMembershipId;

  List<ClientMembership> _memberships = const <ClientMembership>[];
  List<VisitRecord> _visits = const <VisitRecord>[];
  List<SaleRecord> _sales = const <SaleRecord>[];

  @override
  void initState() {
    super.initState();
    unawaited(_loadAll());
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final membershipsFuture = widget.membershipsRepository
          .listClientMemberships(clientId: widget.client.id);
      final visitsFuture = widget.visitsRepository.listClientVisits(
        clientId: widget.client.id,
      );
      final salesFuture = widget.salesRepository.listClientSales(
        clientId: widget.client.id,
      );

      final memberships = await membershipsFuture;
      final visits = await visitsFuture;
      final sales = await salesFuture;

      if (!mounted) {
        return;
      }
      setState(() {
        _memberships = memberships;
        _visits = visits;
        _sales = sales;
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
        _errorMessage = 'Не удалось загрузить карточку клиента.';
      });
    }
  }

  Future<void> _openPosCheckout() async {
    final sold = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PosCheckoutScreen(
          salesRepository: widget.salesRepository,
          membershipsRepository: widget.membershipsRepository,
          sessionController: widget.sessionController,
          initialClientId: widget.client.id,
        ),
      ),
    );
    if (sold == true && mounted) {
      await _loadAll();
    }
  }

  Future<void> _openManualVisit() async {
    final gym = widget.sessionController.selectedGym;
    if (gym == null) {
      return;
    }

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: ManualCheckInSheet(
            repository: widget.visitsRepository,
            gymId: gym.id,
            gymName: gym.name,
          ),
        );
      },
    );

    if (created == true && mounted) {
      await _loadAll();
    }
  }

  Future<void> _toggleFreeze(ClientMembership membership) async {
    setState(() {
      _busyMembershipId = membership.id;
      _errorMessage = null;
    });

    try {
      if (membership.status == MembershipStatus.frozen) {
        await widget.membershipsRepository.unfreezeMembership(
          membershipId: membership.id,
        );
      } else {
        await widget.membershipsRepository.freezeMembership(
          membershipId: membership.id,
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _busyMembershipId = null;
      });
      await _loadAll();
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyMembershipId = null;
        _errorMessage = error.message;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyMembershipId = null;
        _errorMessage = 'Не удалось изменить заморозку.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sessionController,
      builder: (context, _) {
        final colors = context.ucraftColors;
        final strings = BusinessStringsScope.of(context);
        final canSell = widget.sessionController.canMutate(
          BusinessPermission.manageMembershipRequestsAndSales,
        );
        final canFreeze = widget.sessionController.canMutate(
          BusinessPermission.viewExpiringAndFreezeMemberships,
        );
        final canManualVisit =
            widget.sessionController.selectedGym != null &&
            widget.sessionController.canMutate(
              BusinessPermission.manageReceptionQrAndVisits,
            );

        return Scaffold(
          appBar: AppBar(title: Text(widget.client.name)),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(UcraftSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SubscriptionReadOnlyBanner(
                    controller: widget.sessionController,
                  ),
                  if (widget.sessionController.isReadOnly)
                    const SizedBox(height: UcraftSpacing.space3),
                  UcraftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${widget.client.name} (#${widget.client.id})',
                                style: UcraftTypography.title.copyWith(
                                  color: colors.foreground,
                                ),
                              ),
                            ),
                            Text(
                              widget.client.linked
                                  ? strings.clientLinkedBadge
                                  : strings.clientOfflineBadge,
                              style: UcraftTypography.caption.copyWith(
                                color: widget.client.linked
                                    ? colors.success
                                    : colors.foregroundSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: UcraftSpacing.space1),
                        Text(
                          widget.client.email != null
                              ? '${widget.client.phone} • ${widget.client.email}'
                              : widget.client.phone,
                          style: UcraftTypography.body.copyWith(
                            color: colors.foregroundSecondary,
                          ),
                        ),
                        if (canSell) ...[
                          const SizedBox(height: UcraftSpacing.space3),
                          UcraftButton(
                            label: strings.clientSellCta,
                            fullWidth: true,
                            onPressed: () => unawaited(_openPosCheckout()),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: UcraftSpacing.space3),
                  Wrap(
                    spacing: UcraftSpacing.space2,
                    runSpacing: UcraftSpacing.space2,
                    children: [
                      UcraftButton(
                        label: strings.membershipsLabel,
                        variant: _tab == _ClientDetailTab.memberships
                            ? UcraftButtonVariant.primary
                            : UcraftButtonVariant.secondary,
                        onPressed: () =>
                            setState(() => _tab = _ClientDetailTab.memberships),
                      ),
                      UcraftButton(
                        label: strings.clientTabVisits,
                        variant: _tab == _ClientDetailTab.visits
                            ? UcraftButtonVariant.primary
                            : UcraftButtonVariant.secondary,
                        onPressed: () =>
                            setState(() => _tab = _ClientDetailTab.visits),
                      ),
                      UcraftButton(
                        label: strings.clientTabSales,
                        variant: _tab == _ClientDetailTab.sales
                            ? UcraftButtonVariant.primary
                            : UcraftButtonVariant.secondary,
                        onPressed: () =>
                            setState(() => _tab = _ClientDetailTab.sales),
                      ),
                    ],
                  ),
                  const SizedBox(height: UcraftSpacing.space3),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: UcraftTypography.bodyMedium.copyWith(
                        color: colors.destructive,
                      ),
                    ),
                    const SizedBox(height: UcraftSpacing.space3),
                  ],
                  if (_loading)
                    UcraftLoadingState(message: strings.clientDetailLoading)
                  else
                    switch (_tab) {
                      _ClientDetailTab.memberships => _buildMembershipsTab(
                        context,
                        canFreeze,
                      ),
                      _ClientDetailTab.visits => _buildVisitsTab(
                        context,
                        canManualVisit,
                      ),
                      _ClientDetailTab.sales => _buildSalesTab(context),
                    },
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMembershipsTab(BuildContext context, bool canFreeze) {
    final colors = context.ucraftColors;
    final strings = BusinessStringsScope.of(context);
    if (_memberships.isEmpty) {
      return UcraftEmptyState(
        title: strings.clientNoMembershipsTitle,
        description: strings.clientNoMembershipsDesc,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in _memberships) ...[
          UcraftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${strings.scannerMembershipPrefix}${item.id} • ${item.status.apiValue}',
                  style: UcraftTypography.bodyMedium.copyWith(
                    color: colors.foreground,
                  ),
                ),
                if (item.remainingVisits != null)
                  Text(
                    '${strings.scannerRemainingVisitsPrefix}${item.remainingVisits}',
                    style: UcraftTypography.caption.copyWith(
                      color: colors.foregroundSecondary,
                    ),
                  ),
                if (canFreeze &&
                    (item.status == MembershipStatus.active ||
                        item.status == MembershipStatus.frozen)) ...[
                  const SizedBox(height: UcraftSpacing.space2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: UcraftButton(
                      label: item.status == MembershipStatus.frozen
                          ? strings.clientUnfreezeButton
                          : strings.clientFreezeButton,
                      variant: UcraftButtonVariant.secondary,
                      isLoading: _busyMembershipId == item.id,
                      onPressed: _busyMembershipId == item.id
                          ? null
                          : () => unawaited(_toggleFreeze(item)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: UcraftSpacing.space3),
        ],
      ],
    );
  }

  Widget _buildVisitsTab(BuildContext context, bool canManualVisit) {
    final colors = context.ucraftColors;
    final strings = BusinessStringsScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canManualVisit) ...[
          UcraftButton(
            label: strings.clientManualCheckInButton,
            variant: UcraftButtonVariant.secondary,
            onPressed: () => unawaited(_openManualVisit()),
          ),
          const SizedBox(height: UcraftSpacing.space3),
        ],
        if (_visits.isEmpty)
          UcraftEmptyState(
            title: strings.clientNoVisitsTitle,
            description: strings.clientNoVisitsDesc,
          )
        else
          for (final visit in _visits) ...[
            UcraftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Визит №${visit.id} • ${visit.status.name}',
                    style: UcraftTypography.bodyMedium.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                  Text(
                    DateFormatter.formatDateTime(
                      visit.visitedAt,
                      offset: DateFormatter.dushanbeOffset,
                    ),
                    style: UcraftTypography.caption.copyWith(
                      color: colors.foregroundSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: UcraftSpacing.space3),
          ],
      ],
    );
  }

  Widget _buildSalesTab(BuildContext context) {
    final colors = context.ucraftColors;
    final strings = BusinessStringsScope.of(context);
    if (_sales.isEmpty) {
      return UcraftEmptyState(
        title: strings.clientNoSalesTitle,
        description: strings.clientNoSalesDesc,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final sale in _sales) ...[
          UcraftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Чек №${sale.id} • ${(sale.totalMinor / 100).toStringAsFixed(2)} ${sale.currency}',
                  style: UcraftTypography.bodyMedium.copyWith(
                    color: colors.foreground,
                  ),
                ),
                Text(
                  '${paymentMethodLabel(sale.paymentMethod, strings: strings)} • ${sale.status.apiValue}',
                  style: UcraftTypography.caption.copyWith(
                    color: colors.foregroundSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: UcraftSpacing.space3),
        ],
      ],
    );
  }
}

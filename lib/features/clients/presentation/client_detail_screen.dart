import 'dart:async';

import 'package:lucide_icons_flutter/lucide_icons.dart';
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
              padding: const EdgeInsets.all(
                UcraftSpacing.screenHorizontalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SubscriptionReadOnlyBanner(
                    controller: widget.sessionController,
                  ),
                  if (widget.sessionController.isReadOnly)
                    const SizedBox(height: UcraftSpacing.space4),
                  UcraftCard(
                    variant: UcraftCardVariant.highlight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${widget.client.name} (#${widget.client.id})',
                                style: UcraftTypography.titleLarge.copyWith(
                                  color: colors.foreground,
                                ),
                              ),
                            ),
                            UcraftStatusPill(
                              icon: widget.client.linked
                                  ? LucideIcons.link2
                                  : LucideIcons.user,
                              label: widget.client.linked
                                  ? strings.clientLinkedBadge
                                  : strings.clientOfflineBadge,
                              tone: widget.client.linked
                                  ? UcraftStatusTone.success
                                  : UcraftStatusTone.neutral,
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
                      ],
                    ),
                  ),
                  if (canSell) ...[
                    const SizedBox(height: UcraftSpacing.space4),
                    UcraftButton(
                      label: strings.clientSellCta,
                      leadingIcon: LucideIcons.shoppingBag,
                      fullWidth: true,
                      onPressed: () => unawaited(_openPosCheckout()),
                    ),
                  ],
                  const SizedBox(height: UcraftSpacing.sectionGap),
                  UcraftSegmentedTabs<_ClientDetailTab>(
                    items: [
                      UcraftSegmentedTabItem(
                        value: _ClientDetailTab.memberships,
                        label: strings.membershipsLabel,
                      ),
                      UcraftSegmentedTabItem(
                        value: _ClientDetailTab.visits,
                        label: strings.clientTabVisits,
                      ),
                      UcraftSegmentedTabItem(
                        value: _ClientDetailTab.sales,
                        label: strings.clientTabSales,
                      ),
                    ],
                    selected: _tab,
                    onSelected: (next) => setState(() => _tab = next),
                  ),
                  const SizedBox(height: UcraftSpacing.space4),
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
                    const UcraftLoadingState(isSkeleton: true, skeletonCount: 3)
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
    final strings = BusinessStringsScope.of(context);
    if (_memberships.isEmpty) {
      return UcraftEmptyState(
        icon: LucideIcons.ticket,
        title: strings.clientNoMembershipsTitle,
        description: strings.clientNoMembershipsDesc,
      );
    }

    return UcraftListSection(
      children: [
        for (final item in _memberships)
          UcraftListRow(
            title:
                '${strings.scannerMembershipPrefix}${item.id} • ${item.status.apiValue}',
            subtitle: item.remainingVisits != null
                ? '${strings.scannerRemainingVisitsPrefix}${item.remainingVisits}'
                : null,
            trailing:
                canFreeze &&
                    (item.status == MembershipStatus.active ||
                        item.status == MembershipStatus.frozen)
                ? UcraftButton(
                    label: item.status == MembershipStatus.frozen
                        ? strings.clientUnfreezeButton
                        : strings.clientFreezeButton,
                    variant: UcraftButtonVariant.secondary,
                    isLoading: _busyMembershipId == item.id,
                    onPressed: _busyMembershipId == item.id
                        ? null
                        : () => unawaited(_toggleFreeze(item)),
                  )
                : UcraftStatusPill(
                    icon: item.status == MembershipStatus.active
                        ? LucideIcons.circleCheck
                        : item.status == MembershipStatus.frozen
                        ? LucideIcons.snowflake
                        : LucideIcons.circleX,
                    label: item.status.apiValue,
                    tone: item.status == MembershipStatus.active
                        ? UcraftStatusTone.success
                        : item.status == MembershipStatus.frozen
                        ? UcraftStatusTone.info
                        : UcraftStatusTone.neutral,
                  ),
          ),
      ],
    );
  }

  Widget _buildVisitsTab(BuildContext context, bool canManualVisit) {
    final strings = BusinessStringsScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canManualVisit) ...[
          UcraftButton(
            label: strings.clientManualCheckInButton,
            leadingIcon: LucideIcons.checkCheck,
            variant: UcraftButtonVariant.secondary,
            onPressed: () => unawaited(_openManualVisit()),
          ),
          const SizedBox(height: UcraftSpacing.space3),
        ],
        if (_visits.isEmpty)
          UcraftEmptyState(
            icon: LucideIcons.calendarCheck,
            title: strings.clientNoVisitsTitle,
            description: strings.clientNoVisitsDesc,
          )
        else
          UcraftListSection(
            children: [
              for (final visit in _visits)
                UcraftListRow(
                  title: 'Визит №${visit.id} • ${visit.status.name}',
                  subtitle: DateFormatter.formatDateTime(
                    visit.visitedAt,
                    offset: DateFormatter.dushanbeOffset,
                  ),
                  trailing: UcraftStatusPill(
                    icon: visit.status == VisitStatus.cancelled
                        ? LucideIcons.circleX
                        : LucideIcons.circleCheck,
                    label: visit.status == VisitStatus.cancelled
                        ? strings.visitStatusCancelled
                        : strings.visitStatusCompleted,
                    tone: visit.status == VisitStatus.cancelled
                        ? UcraftStatusTone.destructive
                        : UcraftStatusTone.success,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildSalesTab(BuildContext context) {
    final strings = BusinessStringsScope.of(context);
    if (_sales.isEmpty) {
      return UcraftEmptyState(
        icon: LucideIcons.receipt,
        title: strings.clientNoSalesTitle,
        description: strings.clientNoSalesDesc,
      );
    }

    return UcraftListSection(
      children: [
        for (final sale in _sales)
          UcraftListRow(
            title:
                'Чек №${sale.id} • ${(sale.totalMinor / 100).toStringAsFixed(2)} ${sale.currency}',
            subtitle:
                '${paymentMethodLabel(sale.paymentMethod, strings: strings)} • ${sale.status.apiValue}',
            trailing: UcraftStatusPill(
              icon: sale.status == SaleStatus.refunded
                  ? LucideIcons.rotateCcw
                  : LucideIcons.circleCheck,
              label: sale.status == SaleStatus.refunded
                  ? strings.saleRefundButton
                  : strings.saleStatusPaid,
              tone: sale.status == SaleStatus.refunded
                  ? UcraftStatusTone.destructive
                  : UcraftStatusTone.success,
            ),
          ),
      ],
    );
  }
}

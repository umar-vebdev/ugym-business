import 'dart:async';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../../features/analytics_billing/domain/analytics_and_billing_models.dart';
import '../../features/analytics_billing/presentation/analytics_and_billing_screens.dart';
import '../../features/analytics_billing/presentation/overview_dashboard_view.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/clients/domain/clients_models.dart';
import '../../features/clients/presentation/client_detail_screen.dart';
import '../../features/clients/presentation/clients_list_screen.dart';
import '../../features/company_onboarding/domain/company_onboarding_models.dart';
import '../../features/company_onboarding/presentation/company_onboarding_screen.dart';
import '../../features/memberships/domain/memberships_models.dart';
import '../../features/memberships/presentation/memberships_screens.dart';
import '../../features/reception_qr/domain/kiosk_security.dart';
import '../../features/reception_qr/domain/reception_visits_models.dart';
import '../../features/reception_qr/presentation/gym_qr_kiosk_screen.dart';
import '../../features/reception_qr/presentation/qr_scanner_view.dart';
import '../../features/reception_qr/presentation/reception_scan_controller.dart';
import '../../features/reception_qr/presentation/scan_client_qr_screen.dart';
import '../../features/reception_qr/presentation/visits_log_screen.dart';
import '../../features/sales/domain/sales_and_requests_models.dart';
import '../../features/sales/presentation/membership_requests_and_sales_tabs.dart';
import '../../features/sales/presentation/pos_and_products_screens.dart';
import '../../features/schedule/domain/trainers_schedule_models.dart';
import '../../features/schedule/presentation/schedule_tab.dart';
import '../../features/schedule/presentation/trainers_screen.dart';
import '../../features/storefront_staff/domain/storefront_and_staff_models.dart';
import '../../features/storefront_staff/presentation/gym_photo_picker.dart';
import '../../features/storefront_staff/presentation/staff_management_screen.dart';
import '../../features/storefront_staff/presentation/storefront_editor_screen.dart';
import '../config/app_config.dart';
import '../l10n/business_localizations.dart';
import '../session/business_role.dart';
import '../session/business_session_controller.dart';
import '../theme/theme_controller.dart';
import 'role_guard_and_banners.dart';

/// Primary navigation destinations of uGym Business.
enum BusinessDestination { overview, members, operations, analytics, more }

enum _MembersSubTab { clients, expiring, types }

enum _OperationsSubTab { visits, requests, sales, products, schedule, trainers }

enum _MoreSubTab { settings, storefront, staff, announcements, billing }

enum _ScanNavigationAction { openPayments, openClients }

/// Adaptive role-aware navigation shell (BottomBar on phones, Rail on tablets).
final class BusinessShell extends StatefulWidget {
  const BusinessShell({
    super.key,
    required this.config,
    required this.sessionController,
    required this.localeController,
    required this.themeController,
    this.authController,
    this.healthService,
    this.onboardingRepository,
    this.visitsRepository,
    this.clientsRepository,
    this.membershipsRepository,
    this.salesRepository,
    this.trainersScheduleRepository,
    this.storefrontAndStaffRepository,
    this.analyticsAndBillingRepository,
    this.kioskPinGuard,
    this.kioskWakeLock = const PlatformKioskWakeLock(),
    this.qrScannerBuilder = buildMobileQrScanner,
    this.gymPhotoPicker = pickGymPhotoFromGallery,
  });

  final AppConfig config;
  final BusinessSessionController sessionController;
  final LocaleController localeController;
  final ThemeController themeController;
  final AuthController? authController;
  final UgymHealthService? healthService;
  final CompanyOnboardingRepository? onboardingRepository;
  final ReceptionVisitsRepository? visitsRepository;
  final ClientsRepository? clientsRepository;
  final MembershipsRepository? membershipsRepository;
  final SalesAndRequestsRepository? salesRepository;
  final TrainersScheduleRepository? trainersScheduleRepository;
  final StorefrontAndStaffRepository? storefrontAndStaffRepository;
  final AnalyticsAndBillingRepository? analyticsAndBillingRepository;
  final KioskPinGuard? kioskPinGuard;
  final KioskWakeLock kioskWakeLock;
  final QrScannerBuilder qrScannerBuilder;
  final GymPhotoPicker gymPhotoPicker;

  static List<BusinessDestination> visibleDestinationsFor(BusinessRole? role) {
    return switch (role) {
      BusinessRole.owner => const [
        BusinessDestination.overview,
        BusinessDestination.members,
        BusinessDestination.operations,
        BusinessDestination.analytics,
        BusinessDestination.more,
      ],
      BusinessRole.admin => const [
        BusinessDestination.overview,
        BusinessDestination.members,
        BusinessDestination.operations,
        BusinessDestination.more,
      ],
      BusinessRole.trainer => const [
        BusinessDestination.operations,
        BusinessDestination.more,
      ],
      BusinessRole.noCompany ||
      null => const [BusinessDestination.overview, BusinessDestination.more],
    };
  }

  @override
  State<BusinessShell> createState() => _BusinessShellState();
}

final class _BusinessShellState extends State<BusinessShell> {
  BusinessDestination _selected = BusinessDestination.overview;
  _MembersSubTab _membersTab = _MembersSubTab.clients;
  _OperationsSubTab _operationsTab = _OperationsSubTab.visits;
  _MoreSubTab _moreTab = _MoreSubTab.settings;
  bool _checkingHealth = false;
  bool? _healthOk;

  Future<void> _runHealthCheck() async {
    final service = widget.healthService;
    if (service == null || _checkingHealth) {
      return;
    }

    setState(() {
      _checkingHealth = true;
    });

    bool ok = false;
    try {
      final status = await service.check();
      ok = status.isHealthy;
    } on Object {
      ok = false;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _checkingHealth = false;
      _healthOk = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final listened = Listenable.merge([
      widget.sessionController,
      widget.localeController,
      widget.themeController,
      if (widget.authController != null) widget.authController,
    ]);

    return ListenableBuilder(
      listenable: listened,
      builder: (context, _) {
        final strings = widget.localeController.strings;
        final destinations = BusinessShell.visibleDestinationsFor(
          widget.sessionController.role,
        );
        final activeDestination = destinations.contains(_selected)
            ? _selected
            : destinations.first;
        final selectedIndex = destinations.indexOf(activeDestination);
        final colors = context.ucraftColors;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool useRail = constraints.maxWidth >= 600;
            final bool isExpanded = constraints.maxWidth >= 840;

            final Widget content = SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(
                  UcraftSpacing.screenHorizontalPadding,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SubscriptionReadOnlyBanner(
                          controller: widget.sessionController,
                          message: strings.readOnlyBanner,
                          onOpenDetails:
                              widget.analyticsAndBillingRepository != null &&
                                  widget.sessionController.canView(
                                    BusinessPermission.viewBilling,
                                  )
                              ? () => setState(() {
                                  _selected = BusinessDestination.more;
                                  _moreTab = _MoreSubTab.billing;
                                })
                              : null,
                        ),
                        if (widget.sessionController.isReadOnly)
                          const SizedBox(height: UcraftSpacing.space4),
                        Wrap(
                          spacing: UcraftSpacing.space3,
                          runSpacing: UcraftSpacing.space2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Text(
                              _labelFor(activeDestination, strings),
                              style: UcraftTypography.headline.copyWith(
                                color: colors.foreground,
                              ),
                            ),
                            if (widget.sessionController.canView(
                              BusinessPermission.viewGyms,
                            ))
                              GymBranchSelector(
                                controller: widget.sessionController,
                              ),
                          ],
                        ),
                        const SizedBox(height: UcraftSpacing.space4),
                        _buildDestinationBody(
                          context,
                          activeDestination,
                          strings,
                          isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );

            if (useRail) {
              return Scaffold(
                body: Row(
                  children: [
                    NavigationRail(
                      backgroundColor: colors.surface,
                      selectedIndex: selectedIndex,
                      extended: isExpanded,
                      labelType: isExpanded
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.all,
                      onDestinationSelected: (index) {
                        setState(() {
                          _selected = destinations[index];
                        });
                      },
                      destinations: [
                        for (final dest in destinations)
                          NavigationRailDestination(
                            icon: Icon(_iconFor(dest, selected: false)),
                            selectedIcon: Icon(_iconFor(dest, selected: true)),
                            label: Text(_labelFor(dest, strings)),
                          ),
                      ],
                    ),
                    VerticalDivider(width: 1, color: colors.border),
                    Expanded(child: content),
                  ],
                ),
              );
            }

            return Scaffold(
              body: content,
              bottomNavigationBar: NavigationBar(
                backgroundColor: colors.surface,
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selected = destinations[index];
                  });
                },
                destinations: [
                  for (final dest in destinations)
                    NavigationDestination(
                      icon: Icon(_iconFor(dest, selected: false)),
                      selectedIcon: Icon(_iconFor(dest, selected: true)),
                      label: _labelFor(dest, strings),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDestinationBody(
    BuildContext context,
    BusinessDestination destination,
    BusinessStrings strings,
    bool isDark,
  ) {
    return switch (destination) {
      BusinessDestination.overview => _buildOverview(context, strings),
      BusinessDestination.operations => _buildOperations(context),
      BusinessDestination.members => _buildMembers(context, strings),
      BusinessDestination.analytics =>
        widget.analyticsAndBillingRepository != null
            ? AnalyticsScreen(
                repository: widget.analyticsAndBillingRepository!,
                sessionController: widget.sessionController,
              )
            : UcraftEmptyState(
                title: strings.navAnalytics,
                description: 'Аналитика и аудит появятся на этапе B4.',
              ),
      BusinessDestination.more => _buildMore(context, strings, isDark),
    };
  }

  Widget _buildOverview(BuildContext context, BusinessStrings strings) {
    final role = widget.sessionController.role;
    if (role == BusinessRole.noCompany && widget.onboardingRepository != null) {
      return CompanyOnboardingCard(
        repository: widget.onboardingRepository!,
        sessionController: widget.sessionController,
      );
    }

    final visitsRepo = widget.visitsRepository;
    final salesRepo = widget.salesRepository;
    final membershipsRepo = widget.membershipsRepository;
    final selectedGym = widget.sessionController.selectedGym;
    final bool canOpenKiosk =
        widget.config.enableKioskMode &&
        visitsRepo != null &&
        selectedGym != null &&
        (role == BusinessRole.owner || role == BusinessRole.admin);

    return OverviewDashboardView(
      appTitle: strings.appTitle,
      sessionController: widget.sessionController,
      analyticsRepository: widget.analyticsAndBillingRepository,
      salesRepository: salesRepo,
      membershipsRepository: membershipsRepo,
      onOpenScanner: visitsRepo != null && selectedGym != null
          ? () => unawaited(
              _openClientScanner(context, visitsRepo, selectedGym.id),
            )
          : null,
      onOpenKiosk: canOpenKiosk
          ? () => unawaited(_openKiosk(context, visitsRepo, selectedGym.id))
          : null,
      onOpenPos: salesRepo != null && membershipsRepo != null
          ? () =>
                unawaited(_openPosCheckout(context, salesRepo, membershipsRepo))
          : null,
      onOpenPendingRequests: salesRepo != null
          ? () => setState(() {
              _selected = BusinessDestination.operations;
              _operationsTab = _OperationsSubTab.requests;
            })
          : null,
      onOpenExpiringMemberships: membershipsRepo != null
          ? () => setState(() {
              _selected = BusinessDestination.members;
              _membersTab = _MembersSubTab.expiring;
            })
          : null,
      onOpenAnalytics:
          widget.analyticsAndBillingRepository != null &&
              widget.sessionController.canView(BusinessPermission.viewAnalytics)
          ? () => setState(() {
              _selected = BusinessDestination.analytics;
            })
          : null,
    );
  }

  Widget _buildMembers(BuildContext context, BusinessStrings strings) {
    final clientsRepo = widget.clientsRepository;
    final membershipsRepo = widget.membershipsRepository;
    if (clientsRepo == null && membershipsRepo == null) {
      return UcraftEmptyState(
        title: strings.navMembers,
        description: 'Раздел клиентов, абонементов и оплат появится после подключения API.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: UcraftSpacing.space2,
          runSpacing: UcraftSpacing.space2,
          children: [
            if (clientsRepo != null)
              UcraftButton(
                label: 'Клиенты',
                variant: _membersTab == _MembersSubTab.clients
                    ? UcraftButtonVariant.primary
                    : UcraftButtonVariant.secondary,
                onPressed: () =>
                    setState(() => _membersTab = _MembersSubTab.clients),
              ),
            if (membershipsRepo != null) ...[
              UcraftButton(
                label: 'Истекающие',
                variant: _membersTab == _MembersSubTab.expiring
                    ? UcraftButtonVariant.primary
                    : UcraftButtonVariant.secondary,
                onPressed: () =>
                    setState(() => _membersTab = _MembersSubTab.expiring),
              ),
              UcraftButton(
                label: 'Тарифы',
                variant: _membersTab == _MembersSubTab.types
                    ? UcraftButtonVariant.primary
                    : UcraftButtonVariant.secondary,
                onPressed: () =>
                    setState(() => _membersTab = _MembersSubTab.types),
              ),
            ],
          ],
        ),
        const SizedBox(height: UcraftSpacing.space4),
        switch (_membersTab) {
          _MembersSubTab.clients when clientsRepo != null => ClientsListScreen(
            repository: clientsRepo,
            sessionController: widget.sessionController,
            onOpenClient:
                membershipsRepo != null &&
                    widget.visitsRepository != null &&
                    widget.salesRepository != null
                ? (client) => unawaited(_openClientDetail(context, client))
                : null,
          ),
          _MembersSubTab.expiring when membershipsRepo != null =>
            ExpiringMembershipsTab(
              repository: membershipsRepo,
              sessionController: widget.sessionController,
            ),
          _MembersSubTab.types when membershipsRepo != null =>
            MembershipTypesScreen(
              repository: membershipsRepo,
              sessionController: widget.sessionController,
            ),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }

  Widget _buildOperations(BuildContext context) {
    final colors = context.ucraftColors;
    final visitsRepo = widget.visitsRepository;
    final salesRepo = widget.salesRepository;
    final membershipsRepo = widget.membershipsRepository;
    final scheduleRepo = widget.trainersScheduleRepository;

    if (visitsRepo == null && salesRepo == null && scheduleRepo == null) {
      return const UcraftEmptyState(
        title: 'Операции',
        description: 'Подключите сервис визитов и кассы.',
      );
    }

    final role = widget.sessionController.role;
    if (role == BusinessRole.trainer && scheduleRepo != null) {
      return ScheduleTab(
        repository: scheduleRepo,
        sessionController: widget.sessionController,
      );
    }

    final selectedGym = widget.sessionController.selectedGym;
    final canScan =
        visitsRepo != null &&
        selectedGym != null &&
        widget.sessionController.canMutate(
          BusinessPermission.manageReceptionQrAndVisits,
        );
    final canOpenKiosk =
        widget.config.enableKioskMode &&
        visitsRepo != null &&
        selectedGym != null &&
        (role == BusinessRole.owner || role == BusinessRole.admin);
    final canPos =
        salesRepo != null &&
        membershipsRepo != null &&
        widget.sessionController.canMutate(
          BusinessPermission.manageMembershipRequestsAndSales,
        );
    final showSalesTabs =
        salesRepo != null &&
        widget.sessionController.canView(
          BusinessPermission.manageMembershipRequestsAndSales,
        );
    final showScheduleTab =
        scheduleRepo != null &&
        widget.sessionController.canView(
          BusinessPermission.viewSessionBookings,
        );
    final showTrainersTab =
        scheduleRepo != null &&
        widget.sessionController.canView(BusinessPermission.viewTrainers);

    final availableTabs = <_OperationsSubTab>[
      if (visitsRepo != null) _OperationsSubTab.visits,
      if (showSalesTabs) ...[
        _OperationsSubTab.requests,
        _OperationsSubTab.sales,
        _OperationsSubTab.products,
      ],
      if (showScheduleTab) _OperationsSubTab.schedule,
      if (showTrainersTab) _OperationsSubTab.trainers,
    ];
    final _OperationsSubTab? effectiveTab =
        availableTabs.contains(_operationsTab)
        ? _operationsTab
        : (availableTabs.isNotEmpty ? availableTabs.first : null);
    final showTabBar = showSalesTabs || showScheduleTab || showTrainersTab;
    final showReceptionCard = visitsRepo != null || canPos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showReceptionCard)
          UcraftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ресепшен и касса',
                  style: UcraftTypography.title.copyWith(
                    color: colors.foreground,
                  ),
                ),
                const SizedBox(height: UcraftSpacing.space3),
                Wrap(
                  spacing: UcraftSpacing.space2,
                  runSpacing: UcraftSpacing.space2,
                  children: [
                    if (visitsRepo != null)
                      UcraftButton(
                        label: 'Сканер QR клиента',
                        onPressed: canScan
                            ? () => unawaited(
                                _openClientScanner(
                                  context,
                                  visitsRepo,
                                  selectedGym.id,
                                ),
                              )
                            : null,
                      ),
                    if (canOpenKiosk)
                      UcraftButton(
                        label: 'Киоск QR зала',
                        variant: UcraftButtonVariant.secondary,
                        onPressed: () => unawaited(
                          _openKiosk(context, visitsRepo, selectedGym.id),
                        ),
                      ),
                    if (canPos)
                      UcraftButton(
                        label: 'Открыть кассу',
                        variant: UcraftButtonVariant.secondary,
                        onPressed: () => unawaited(
                          _openPosCheckout(context, salesRepo, membershipsRepo),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        if (showTabBar && availableTabs.isNotEmpty) ...[
          if (showReceptionCard) const SizedBox(height: UcraftSpacing.space3),
          Wrap(
            spacing: UcraftSpacing.space2,
            runSpacing: UcraftSpacing.space2,
            children: [
              if (visitsRepo != null)
                UcraftButton(
                  label: 'Визиты',
                  variant: effectiveTab == _OperationsSubTab.visits
                      ? UcraftButtonVariant.primary
                      : UcraftButtonVariant.secondary,
                  onPressed: () =>
                      setState(() => _operationsTab = _OperationsSubTab.visits),
                ),
              if (showSalesTabs) ...[
                UcraftButton(
                  label: 'Заявки',
                  variant: effectiveTab == _OperationsSubTab.requests
                      ? UcraftButtonVariant.primary
                      : UcraftButtonVariant.secondary,
                  onPressed: () => setState(
                    () => _operationsTab = _OperationsSubTab.requests,
                  ),
                ),
                UcraftButton(
                  label: 'Продажи',
                  variant: effectiveTab == _OperationsSubTab.sales
                      ? UcraftButtonVariant.primary
                      : UcraftButtonVariant.secondary,
                  onPressed: () =>
                      setState(() => _operationsTab = _OperationsSubTab.sales),
                ),
                UcraftButton(
                  label: 'Товары',
                  variant: effectiveTab == _OperationsSubTab.products
                      ? UcraftButtonVariant.primary
                      : UcraftButtonVariant.secondary,
                  onPressed: () => setState(
                    () => _operationsTab = _OperationsSubTab.products,
                  ),
                ),
              ],
              if (showScheduleTab)
                UcraftButton(
                  label: 'Расписание',
                  variant: effectiveTab == _OperationsSubTab.schedule
                      ? UcraftButtonVariant.primary
                      : UcraftButtonVariant.secondary,
                  onPressed: () => setState(
                    () => _operationsTab = _OperationsSubTab.schedule,
                  ),
                ),
              if (showTrainersTab)
                UcraftButton(
                  label: 'Тренеры',
                  variant: effectiveTab == _OperationsSubTab.trainers
                      ? UcraftButtonVariant.primary
                      : UcraftButtonVariant.secondary,
                  onPressed: () => setState(
                    () => _operationsTab = _OperationsSubTab.trainers,
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: UcraftSpacing.space4),
        switch (effectiveTab) {
          _OperationsSubTab.visits when visitsRepo != null => VisitsLogScreen(
            repository: visitsRepo,
            sessionController: widget.sessionController,
          ),
          _OperationsSubTab.requests when salesRepo != null =>
            MembershipRequestsQueueTab(
              repository: salesRepo,
              sessionController: widget.sessionController,
            ),
          _OperationsSubTab.sales when salesRepo != null => SalesHistoryTab(
            repository: salesRepo,
            sessionController: widget.sessionController,
          ),
          _OperationsSubTab.products when salesRepo != null => ProductsScreen(
            repository: salesRepo,
            sessionController: widget.sessionController,
          ),
          _OperationsSubTab.schedule when scheduleRepo != null => ScheduleTab(
            repository: scheduleRepo,
            sessionController: widget.sessionController,
          ),
          _OperationsSubTab.trainers when scheduleRepo != null =>
            TrainersScreen(
              repository: scheduleRepo,
              sessionController: widget.sessionController,
            ),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }

  Future<void> _openClientDetail(
    BuildContext context,
    ClientSummary client,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ClientDetailScreen(
          client: client,
          sessionController: widget.sessionController,
          membershipsRepository: widget.membershipsRepository!,
          visitsRepository: widget.visitsRepository!,
          salesRepository: widget.salesRepository!,
        ),
      ),
    );
  }

  Future<void> _openPosCheckout(
    BuildContext context,
    SalesAndRequestsRepository salesRepo,
    MembershipsRepository membershipsRepo,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PosCheckoutScreen(
          salesRepository: salesRepo,
          membershipsRepository: membershipsRepo,
          sessionController: widget.sessionController,
        ),
      ),
    );
  }

  Widget _buildMore(
    BuildContext context,
    BusinessStrings strings,
    bool isDark,
  ) {
    final colors = context.ucraftColors;
    final onboardingRepo = widget.onboardingRepository;
    final storefrontRepo = widget.storefrontAndStaffRepository;
    final analyticsRepo = widget.analyticsAndBillingRepository;
    final showOwnerSettings =
        onboardingRepo != null &&
        widget.sessionController.role == BusinessRole.owner;

    final canStorefront =
        storefrontRepo != null &&
        widget.sessionController.canView(BusinessPermission.manageStorefront);
    final canStaff =
        storefrontRepo != null &&
        widget.sessionController.canView(BusinessPermission.manageStaff);
    final canAnnouncements =
        analyticsRepo != null &&
        widget.sessionController.canView(BusinessPermission.sendAnnouncements);
    final canBilling =
        analyticsRepo != null &&
        widget.sessionController.canView(BusinessPermission.viewBilling);

    final showSubTabs =
        canStorefront || canStaff || canAnnouncements || canBilling;

    final _MoreSubTab effectiveTab = switch (_moreTab) {
      _MoreSubTab.storefront when canStorefront => _MoreSubTab.storefront,
      _MoreSubTab.staff when canStaff => _MoreSubTab.staff,
      _MoreSubTab.announcements when canAnnouncements =>
        _MoreSubTab.announcements,
      _MoreSubTab.billing when canBilling => _MoreSubTab.billing,
      _ => _MoreSubTab.settings,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSubTabs) ...[
          Wrap(
            spacing: UcraftSpacing.space2,
            runSpacing: UcraftSpacing.space2,
            children: [
              UcraftButton(
                label: 'Настройки',
                variant: effectiveTab == _MoreSubTab.settings
                    ? UcraftButtonVariant.primary
                    : UcraftButtonVariant.secondary,
                onPressed: () =>
                    setState(() => _moreTab = _MoreSubTab.settings),
              ),
              if (canStorefront)
                UcraftButton(
                  label: 'Витрина',
                  variant: effectiveTab == _MoreSubTab.storefront
                      ? UcraftButtonVariant.primary
                      : UcraftButtonVariant.secondary,
                  onPressed: () =>
                      setState(() => _moreTab = _MoreSubTab.storefront),
                ),
              if (canStaff)
                UcraftButton(
                  label: 'Штат',
                  variant: effectiveTab == _MoreSubTab.staff
                      ? UcraftButtonVariant.primary
                      : UcraftButtonVariant.secondary,
                  onPressed: () => setState(() => _moreTab = _MoreSubTab.staff),
                ),
              if (canAnnouncements)
                UcraftButton(
                  label: 'Рассылки',
                  variant: effectiveTab == _MoreSubTab.announcements
                      ? UcraftButtonVariant.primary
                      : UcraftButtonVariant.secondary,
                  onPressed: () =>
                      setState(() => _moreTab = _MoreSubTab.announcements),
                ),
              if (canBilling)
                UcraftButton(
                  label: 'Подписка',
                  variant: effectiveTab == _MoreSubTab.billing
                      ? UcraftButtonVariant.primary
                      : UcraftButtonVariant.secondary,
                  onPressed: () =>
                      setState(() => _moreTab = _MoreSubTab.billing),
                ),
            ],
          ),
          const SizedBox(height: UcraftSpacing.space4),
        ],
        switch (effectiveTab) {
          _MoreSubTab.storefront when storefrontRepo != null =>
            StorefrontEditorScreen(
              repository: storefrontRepo,
              sessionController: widget.sessionController,
              photoPicker: widget.gymPhotoPicker,
            ),
          _MoreSubTab.staff when storefrontRepo != null =>
            StaffManagementScreen(
              repository: storefrontRepo,
              sessionController: widget.sessionController,
            ),
          _MoreSubTab.announcements when analyticsRepo != null =>
            AnnouncementsScreen(
              repository: analyticsRepo,
              sessionController: widget.sessionController,
            ),
          _MoreSubTab.billing when analyticsRepo != null => BillingStatusScreen(
            repository: analyticsRepo,
            sessionController: widget.sessionController,
          ),
          _ => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showOwnerSettings) ...[
                CompanyBranchesAndCurrencyCard(
                  repository: onboardingRepo,
                  sessionController: widget.sessionController,
                ),
                const SizedBox(height: UcraftSpacing.space4),
              ],
              UcraftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      strings.appTitle,
                      style: UcraftTypography.title.copyWith(
                        color: colors.foreground,
                      ),
                    ),
                    const SizedBox(height: UcraftSpacing.space1),
                    Text(
                      widget.config.flavor.name,
                      style: UcraftTypography.mono.copyWith(
                        color: colors.foregroundSecondary,
                      ),
                    ),
                    const SizedBox(height: UcraftSpacing.space4),
                    Wrap(
                      spacing: UcraftSpacing.space2,
                      runSpacing: UcraftSpacing.space2,
                      children: [
                        for (final locale in AppLocale.values)
                          UcraftButton(
                            label: locale.shortLabel,
                            variant: widget.localeController.locale == locale
                                ? UcraftButtonVariant.primary
                                : UcraftButtonVariant.secondary,
                            onPressed: () {
                              unawaited(
                                widget.localeController.setLocale(locale),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: UcraftSpacing.space4),
                    UcraftButton(
                      label: isDark
                          ? strings.themeLightLabel
                          : strings.themeDarkLabel,
                      variant: UcraftButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: () {
                        unawaited(
                          widget.themeController.setThemeMode(
                            isDark ? ThemeMode.light : ThemeMode.dark,
                          ),
                        );
                      },
                    ),
                    if (widget.healthService != null) ...[
                      const SizedBox(height: UcraftSpacing.space3),
                      UcraftButton(
                        label: strings.checkHealth,
                        isLoading: _checkingHealth,
                        fullWidth: true,
                        onPressed: _runHealthCheck,
                      ),
                      if (_healthOk != null) ...[
                        const SizedBox(height: UcraftSpacing.space3),
                        Row(
                          children: [
                            Icon(
                              _healthOk!
                                  ? LucideIcons.circleCheck
                                  : LucideIcons.circleAlert,
                              size: 20,
                              color: _healthOk!
                                  ? colors.success
                                  : colors.destructive,
                            ),
                            const SizedBox(width: UcraftSpacing.iconLabelGap),
                            Expanded(
                              child: Text(
                                _healthOk!
                                    ? strings.healthOk
                                    : strings.healthError,
                                style: UcraftTypography.bodyMedium.copyWith(
                                  color: _healthOk!
                                      ? colors.successForeground
                                      : colors.destructiveForeground,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                    if (widget.authController != null) ...[
                      const SizedBox(height: UcraftSpacing.space3),
                      UcraftButton(
                        label: strings.signOutLabel,
                        variant: UcraftButtonVariant.destructive,
                        fullWidth: true,
                        isLoading: widget.authController!.isSubmitting,
                        onPressed: () {
                          unawaited(widget.authController!.logout());
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        },
      ],
    );
  }

  Future<void> _openClientScanner(
    BuildContext context,
    ReceptionVisitsRepository visitsRepo,
    int gymId,
  ) async {
    final salesRepo = widget.salesRepository;
    final membershipsRepo = widget.membershipsRepository;
    final bool canOpenPayments =
        salesRepo != null &&
        membershipsRepo != null &&
        widget.sessionController.canMutate(
          BusinessPermission.manageMembershipRequestsAndSales,
        );
    final bool canOpenClients =
        widget.clientsRepository != null &&
        widget.sessionController.canView(BusinessPermission.manageClientsCrm);

    final scanController = ReceptionScanController(
      repository: visitsRepo,
      gymId: gymId,
    );
    _ScanNavigationAction? action;
    try {
      action = await Navigator.of(context).push<_ScanNavigationAction>(
        MaterialPageRoute<_ScanNavigationAction>(
          builder: (scannerContext) => ScanClientQrScreen(
            controller: scanController,
            scannerBuilder: widget.qrScannerBuilder,
            onOpenPayments: canOpenPayments
                ? () =>
                      Navigator.of(scannerContext)
                          .pop(_ScanNavigationAction.openPayments)
                : null,
            onOpenClients: canOpenClients
                ? () =>
                      Navigator.of(scannerContext)
                          .pop(_ScanNavigationAction.openClients)
                : null,
          ),
        ),
      );
    } finally {
      scanController.dispose();
    }

    if (!context.mounted || !mounted || action == null) {
      return;
    }

    switch (action) {
      case _ScanNavigationAction.openPayments:
        if (salesRepo != null && membershipsRepo != null) {
          await _openPosCheckout(context, salesRepo, membershipsRepo);
        }
      case _ScanNavigationAction.openClients:
        setState(() {
          _selected = BusinessDestination.members;
          _membersTab = _MembersSubTab.clients;
        });
    }
  }

  Future<void> _openKiosk(
    BuildContext context,
    ReceptionVisitsRepository visitsRepo,
    int gymId,
  ) async {
    final pinGuard =
        widget.kioskPinGuard ??
        const KioskPinGuard(storage: SecureTokenStorage());
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (kioskContext) => GymQrKioskScreen(
          gymId: gymId,
          repository: visitsRepo,
          pinGuard: pinGuard,
          wakeLock: widget.kioskWakeLock,
          onExitKiosk: () => Navigator.of(kioskContext).pop(),
        ),
      ),
    );
  }

  String _labelFor(BusinessDestination destination, BusinessStrings strings) {
    return switch (destination) {
      BusinessDestination.overview => strings.navOverview,
      BusinessDestination.members => strings.navMembers,
      BusinessDestination.operations => strings.navOperations,
      BusinessDestination.analytics => strings.navAnalytics,
      BusinessDestination.more => strings.navMore,
    };
  }

  IconData _iconFor(BusinessDestination destination, {required bool selected}) {
    return switch (destination) {
      BusinessDestination.overview => LucideIcons.layoutDashboard,
      BusinessDestination.members => LucideIcons.users,
      BusinessDestination.operations => LucideIcons.qrCode,
      BusinessDestination.analytics => LucideIcons.chartColumn,
      BusinessDestination.more => LucideIcons.menu,
    };
  }
}

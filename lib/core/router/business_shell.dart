import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

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
import '../config/app_config.dart';
import '../l10n/business_localizations.dart';
import '../session/business_role.dart';
import '../session/business_session_controller.dart';
import '../theme/theme_controller.dart';
import 'role_guard_and_banners.dart';

/// Primary navigation destinations of uGym Business.
enum BusinessDestination { overview, members, operations, analytics, more }

enum _MembersSubTab { clients, expiring, types }

enum _OperationsSubTab { visits, requests, sales, products }

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
    this.kioskPinGuard,
    this.kioskWakeLock = const PlatformKioskWakeLock(),
    this.qrScannerBuilder = buildMobileQrScanner,
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
  final KioskPinGuard? kioskPinGuard;
  final KioskWakeLock kioskWakeLock;
  final QrScannerBuilder qrScannerBuilder;

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

            final Widget content = SafeArea(
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
            );

            if (useRail) {
              return Scaffold(
                body: Row(
                  children: [
                    NavigationRail(
                      backgroundColor: colors.surface,
                      selectedIndex: selectedIndex,
                      labelType: NavigationRailLabelType.all,
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
      BusinessDestination.analytics => UcraftEmptyState(
        title: strings.navAnalytics,
        description: 'Аналитика и аудит появятся на этапе B4.',
      ),
      BusinessDestination.more => _buildMore(context, strings, isDark),
    };
  }

  Widget _buildOverview(BuildContext context, BusinessStrings strings) {
    final colors = context.ucraftColors;
    final role = widget.sessionController.role;
    if (role == BusinessRole.noCompany && widget.onboardingRepository != null) {
      return CompanyOnboardingCard(
        repository: widget.onboardingRepository!,
        sessionController: widget.sessionController,
      );
    }

    final gymName =
        widget.sessionController.selectedGym?.name ?? 'Филиал не выбран';
    return UcraftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.appTitle,
            style: UcraftTypography.title.copyWith(color: colors.foreground),
          ),
          const SizedBox(height: UcraftSpacing.space2),
          Text(
            'Роль: ${role?.name ?? 'не определена'} • Филиал: $gymName',
            style: UcraftTypography.body.copyWith(
              color: colors.foregroundSecondary,
            ),
          ),
        ],
      ),
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

    if (visitsRepo == null && salesRepo == null) {
      return const UcraftEmptyState(
        title: 'Операции',
        description: 'Подключите сервис визитов и кассы.',
      );
    }

    final role = widget.sessionController.role;
    final selectedGym = widget.sessionController.selectedGym;
    final canScan =
        visitsRepo != null &&
        selectedGym != null &&
        widget.sessionController.canMutate(
          BusinessPermission.manageReceptionQrAndVisits,
        );
    final canOpenKiosk =
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        if (showSalesTabs) ...[
          const SizedBox(height: UcraftSpacing.space3),
          Wrap(
            spacing: UcraftSpacing.space2,
            runSpacing: UcraftSpacing.space2,
            children: [
              if (visitsRepo != null)
                UcraftButton(
                  label: 'Визиты',
                  variant: _operationsTab == _OperationsSubTab.visits
                      ? UcraftButtonVariant.primary
                      : UcraftButtonVariant.secondary,
                  onPressed: () =>
                      setState(() => _operationsTab = _OperationsSubTab.visits),
                ),
              UcraftButton(
                label: 'Заявки',
                variant: _operationsTab == _OperationsSubTab.requests
                    ? UcraftButtonVariant.primary
                    : UcraftButtonVariant.secondary,
                onPressed: () =>
                    setState(() => _operationsTab = _OperationsSubTab.requests),
              ),
              UcraftButton(
                label: 'Продажи',
                variant: _operationsTab == _OperationsSubTab.sales
                    ? UcraftButtonVariant.primary
                    : UcraftButtonVariant.secondary,
                onPressed: () =>
                    setState(() => _operationsTab = _OperationsSubTab.sales),
              ),
              UcraftButton(
                label: 'Товары',
                variant: _operationsTab == _OperationsSubTab.products
                    ? UcraftButtonVariant.primary
                    : UcraftButtonVariant.secondary,
                onPressed: () =>
                    setState(() => _operationsTab = _OperationsSubTab.products),
              ),
            ],
          ),
        ],
        const SizedBox(height: UcraftSpacing.space4),
        if (!showSalesTabs && visitsRepo != null)
          VisitsLogScreen(
            repository: visitsRepo,
            sessionController: widget.sessionController,
          )
        else
          switch (_operationsTab) {
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
    final showOwnerSettings =
        onboardingRepo != null &&
        widget.sessionController.role == BusinessRole.owner;

    return Column(
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
                        unawaited(widget.localeController.setLocale(locale));
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
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        size: 18,
                        color: _healthOk! ? colors.success : colors.destructive,
                      ),
                      const SizedBox(width: UcraftSpacing.iconLabelGap),
                      Expanded(
                        child: Text(
                          _healthOk! ? strings.healthOk : strings.healthError,
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
                  label: 'Выйти',
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
    );
  }

  Future<void> _openClientScanner(
    BuildContext context,
    ReceptionVisitsRepository visitsRepo,
    int gymId,
  ) async {
    final scanController = ReceptionScanController(
      repository: visitsRepo,
      gymId: gymId,
    );
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ScanClientQrScreen(
            controller: scanController,
            scannerBuilder: widget.qrScannerBuilder,
          ),
        ),
      );
    } finally {
      scanController.dispose();
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
      BusinessDestination.overview =>
        selected ? Icons.dashboard : Icons.dashboard_outlined,
      BusinessDestination.members =>
        selected ? Icons.people : Icons.people_outline,
      BusinessDestination.operations =>
        selected ? Icons.qr_code_scanner : Icons.qr_code_scanner_outlined,
      BusinessDestination.analytics =>
        selected ? Icons.bar_chart : Icons.bar_chart_outlined,
      BusinessDestination.more => selected ? Icons.menu : Icons.menu_outlined,
    };
  }
}

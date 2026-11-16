import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../config/app_config.dart';
import '../l10n/business_localizations.dart';
import '../session/business_role.dart';
import '../session/business_session_controller.dart';
import '../theme/theme_controller.dart';
import 'role_guard_and_banners.dart';

/// Primary navigation destinations of uGym Business.
enum BusinessDestination { overview, members, operations, analytics, more }

/// Adaptive role-aware navigation shell (BottomBar on phones, Rail on tablets).
final class BusinessShell extends StatefulWidget {
  const BusinessShell({
    super.key,
    required this.config,
    required this.sessionController,
    required this.localeController,
    required this.themeController,
    this.healthService,
  });

  final AppConfig config;
  final BusinessSessionController sessionController;
  final LocaleController localeController;
  final ThemeController themeController;
  final UgymHealthService? healthService;

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
                                  variant:
                                      widget.localeController.locale == locale
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
                                        ? Icons.check_circle_outline
                                        : Icons.error_outline,
                                    size: 18,
                                    color: _healthOk!
                                        ? colors.success
                                        : colors.destructive,
                                  ),
                                  const SizedBox(
                                    width: UcraftSpacing.iconLabelGap,
                                  ),
                                  Expanded(
                                    child: Text(
                                      _healthOk!
                                          ? strings.healthOk
                                          : strings.healthError,
                                      style: UcraftTypography.bodyMedium
                                          .copyWith(
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
                        ],
                      ),
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

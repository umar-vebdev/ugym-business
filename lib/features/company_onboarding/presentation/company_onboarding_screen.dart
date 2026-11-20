import 'dart:async';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../../../core/l10n/business_localizations.dart';
import '../../../core/session/business_role.dart';
import '../../../core/session/business_session_controller.dart';
import '../../../core/theme/business_typography.dart';
import '../domain/company_onboarding_models.dart';

/// Onboarding form allowing a user without a company to start a 14-day trial.
final class CompanyOnboardingCard extends StatefulWidget {
  const CompanyOnboardingCard({
    super.key,
    required this.repository,
    required this.sessionController,
    this.onCompleted,
  });

  final CompanyOnboardingRepository repository;
  final BusinessSessionController sessionController;
  final VoidCallback? onCompleted;

  @override
  State<CompanyOnboardingCard> createState() => _CompanyOnboardingCardState();
}

final class _CompanyOnboardingCardState extends State<CompanyOnboardingCard> {
  final _companyNameController = TextEditingController();
  final _gymNameController = TextEditingController();
  final _gymAddressController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;
  Map<String, List<String>> _fieldErrors = const <String, List<String>>{};

  @override
  void dispose() {
    _companyNameController.dispose();
    _gymNameController.dispose();
    _gymAddressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _fieldErrors = const <String, List<String>>{};
    });

    try {
      final created = await widget.repository.createCompany(
        companyName: _companyNameController.text,
        gymName: _gymNameController.text,
        gymAddress: _gymAddressController.text,
      );

      List<GymSummary> summaries;
      try {
        final branches = await widget.repository.listGyms();
        summaries = branches
            .map(
              (b) => GymSummary(id: b.id, name: b.name, timezone: b.timezone),
            )
            .toList(growable: false);
      } on Object {
        summaries = <GymSummary>[
          GymSummary(id: created.gymId, name: _gymNameController.text.trim()),
        ];
      }

      if (summaries.isEmpty) {
        summaries = <GymSummary>[
          GymSummary(id: created.gymId, name: _gymNameController.text.trim()),
        ];
      }

      widget.sessionController.setRole(BusinessRole.owner);
      await widget.sessionController.setGyms(summaries);

      if (mounted) {
        widget.onCompleted?.call();
      }
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _fieldErrors = error.fieldErrors;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final strings = BusinessStringsScope.of(context);

    return UcraftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            strings.onboardingTitle,
            style: BusinessTypography.title.copyWith(color: colors.foreground),
          ),
          const SizedBox(height: UcraftSpacing.space2),
          Text(
            strings.onboardingSubtitle,
            style: UcraftTypography.body.copyWith(
              color: colors.foregroundSecondary,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: UcraftSpacing.space4),
            Container(
              padding: const EdgeInsets.all(UcraftSpacing.space3),
              decoration: BoxDecoration(
                color: colors.destructiveBackground,
                borderRadius: UcraftRadius.borderSm,
                border: Border.all(
                  color: colors.destructive,
                  width: UcraftElevation.borderDefault,
                ),
              ),
              child: Text(
                _errorMessage!,
                style: BusinessTypography.bodyMedium.copyWith(
                  color: colors.destructiveForeground,
                ),
              ),
            ),
          ],
          const SizedBox(height: UcraftSpacing.space4),
          UcraftTextField(
            key: const ValueKey<String>('onboarding_company_name'),
            label: strings.onboardingCompanyNameLabel,
            hintText: 'FitLine LLC',
            controller: _companyNameController,
            enabled: !_isSubmitting,
            errorText: _fieldErrors['company_name']?.first,
          ),
          const SizedBox(height: UcraftSpacing.space2),
          UcraftTextField(
            key: const ValueKey<String>('onboarding_gym_name'),
            label: strings.onboardingGymNameLabel,
            hintText: 'FitLine Центральный',
            controller: _gymNameController,
            enabled: !_isSubmitting,
            errorText: _fieldErrors['gym_name']?.first,
          ),
          const SizedBox(height: UcraftSpacing.space2),
          UcraftTextField(
            key: const ValueKey<String>('onboarding_gym_address'),
            label: strings.onboardingGymAddressLabel,
            hintText: 'ул. Рудаки 100',
            controller: _gymAddressController,
            enabled: !_isSubmitting,
            errorText: _fieldErrors['gym_address']?.first,
          ),
          const SizedBox(height: UcraftSpacing.space6),
          UcraftButton(
            label: strings.createCompanyCta,
            fullWidth: true,
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

/// Owner management panel for gym branches, geofence settings, and currency.
final class CompanyBranchesAndCurrencyCard extends StatefulWidget {
  const CompanyBranchesAndCurrencyCard({
    super.key,
    required this.repository,
    required this.sessionController,
  });

  final CompanyOnboardingRepository repository;
  final BusinessSessionController sessionController;

  @override
  State<CompanyBranchesAndCurrencyCard> createState() =>
      _CompanyBranchesAndCurrencyCardState();
}

final class _CompanyBranchesAndCurrencyCardState
    extends State<CompanyBranchesAndCurrencyCard> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _radiusController = TextEditingController(text: '200');

  bool _loading = true;
  bool _submitting = false;
  bool _geoCheckEnabled = false;
  String? _errorMessage;
  String? _statusMessage;
  String? _activeCurrencyCode;
  int? _editingGymId;
  List<GymBranch> _branches = const <GymBranch>[];
  List<CurrencyOption> _currencies = const <CurrencyOption>[];

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final branches = await widget.repository.listGyms();
      final currencies = await widget.repository.listCurrencies();
      await _syncSessionGyms(branches);
      if (!mounted) {
        return;
      }
      setState(() {
        _branches = branches;
        _currencies = currencies;
        _loading = false;
      });
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _syncSessionGyms(List<GymBranch> branches) {
    final summaries = branches
        .map((b) => GymSummary(id: b.id, name: b.name, timezone: b.timezone))
        .toList(growable: false);
    return widget.sessionController.setGyms(summaries);
  }

  void _startEdit(GymBranch branch) {
    setState(() {
      _editingGymId = branch.id;
      _nameController.text = branch.name;
      _addressController.text = branch.address ?? '';
      _geoCheckEnabled = branch.geoCheckEnabled;
      _radiusController.text = branch.geoCheckRadiusMeters.toString();
      _errorMessage = null;
      _statusMessage = null;
    });
  }

  void _resetForm() {
    setState(() {
      _editingGymId = null;
      _nameController.clear();
      _addressController.clear();
      _geoCheckEnabled = false;
      _radiusController.text = '200';
    });
  }

  Future<void> _saveGym() async {
    if (_submitting ||
        !widget.sessionController.canMutate(BusinessPermission.manageGyms)) {
      return;
    }

    final parsedRadius = int.tryParse(_radiusController.text.trim()) ?? 200;
    final clampedRadius = parsedRadius.clamp(50, 5000);

    setState(() {
      _submitting = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      if (_editingGymId == null) {
        await widget.repository.createGym(
          name: _nameController.text,
          address: _addressController.text,
          geoCheckEnabled: _geoCheckEnabled,
          geoCheckRadiusMeters: clampedRadius,
        );
        _statusMessage = 'Филиал создан';
      } else {
        await widget.repository.updateGym(
          gymId: _editingGymId!,
          name: _nameController.text,
          address: _addressController.text,
          geoCheckEnabled: _geoCheckEnabled,
          geoCheckRadiusMeters: clampedRadius,
        );
        _statusMessage = 'Филиал обновлён';
      }

      final updated = await widget.repository.listGyms();
      await _syncSessionGyms(updated);
      if (!mounted) {
        return;
      }
      setState(() {
        _branches = updated;
      });
      _resetForm();
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _selectCurrency(CurrencyOption option) async {
    if (_submitting ||
        !widget.sessionController.canMutate(
          BusinessPermission.changeCompanyCurrency,
        )) {
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final code = await widget.repository.updateCompanyCurrency(
        currencyId: option.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _activeCurrencyCode = code;
        _statusMessage = 'Валюта компании: $code';
      });
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = BusinessStringsScope.of(context);
    if (_loading) {
      return const UcraftLoadingState(isSkeleton: true, skeletonCount: 2);
    }

    if (_errorMessage != null && _branches.isEmpty && _currencies.isEmpty) {
      return UcraftErrorState(
        message: _errorMessage!,
        retryLabel: strings.retryLabel,
        onRetry: _loadData,
      );
    }

    final colors = context.ucraftColors;
    final canMutateGyms = widget.sessionController.canMutate(
      BusinessPermission.manageGyms,
    );
    final canMutateCurrency = widget.sessionController.canMutate(
      BusinessPermission.changeCompanyCurrency,
    );

    final activeCurrency = _currencies
        .where((currency) => currency.code == _activeCurrencyCode)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_statusMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(UcraftSpacing.space3),
            decoration: BoxDecoration(
              color: colors.successBackground,
              borderRadius: UcraftRadius.borderSm,
              border: Border.all(color: colors.success),
            ),
            child: Text(
              _statusMessage!,
              style: BusinessTypography.bodyMedium.copyWith(
                color: colors.successForeground,
              ),
            ),
          ),
          const SizedBox(height: UcraftSpacing.space2),
        ],
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(UcraftSpacing.space3),
            decoration: BoxDecoration(
              color: colors.destructiveBackground,
              borderRadius: UcraftRadius.borderSm,
              border: Border.all(color: colors.destructive),
            ),
            child: Text(
              _errorMessage!,
              style: BusinessTypography.bodyMedium.copyWith(
                color: colors.destructiveForeground,
              ),
            ),
          ),
          const SizedBox(height: UcraftSpacing.space2),
        ],
        UcraftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _editingGymId == null
                    ? strings.branchesAddTitle
                    : strings.branchesEditTitle,
                style: BusinessTypography.title.copyWith(
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: UcraftSpacing.space2),
              for (final branch in _branches) ...[
                UcraftCard(
                  onTap: canMutateGyms ? () => _startEdit(branch) : null,
                  padding: const EdgeInsets.all(UcraftSpacing.space3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              branch.name,
                              style: BusinessTypography.bodyMedium.copyWith(
                                color: colors.foreground,
                              ),
                            ),
                            if (branch.address != null)
                              Text(
                                branch.address!,
                                style: UcraftTypography.caption.copyWith(
                                  color: colors.foregroundSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        branch.geoCheckEnabled
                            ? '${branch.geoCheckRadiusMeters} м'
                            : strings.branchesNoGeofence,
                        style: UcraftTypography.mono.copyWith(
                          color: colors.foregroundSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: UcraftSpacing.space2),
              ],
              const SizedBox(height: UcraftSpacing.space2),
              UcraftTextField(
                key: const ValueKey<String>('gym_branch_name'),
                label: strings.branchesNameLabel,
                controller: _nameController,
                enabled: canMutateGyms && !_submitting,
              ),
              const SizedBox(height: UcraftSpacing.space2),
              UcraftTextField(
                key: const ValueKey<String>('gym_branch_address'),
                label: strings.branchesAddressLabel,
                controller: _addressController,
                enabled: canMutateGyms && !_submitting,
              ),
              const SizedBox(height: UcraftSpacing.space3),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  strings.branchesGeoCheckSwitch,
                  style: BusinessTypography.bodyMedium.copyWith(
                    color: colors.foreground,
                  ),
                ),
                value: _geoCheckEnabled,
                onChanged: canMutateGyms && !_submitting
                    ? (value) {
                        setState(() {
                          _geoCheckEnabled = value;
                        });
                      }
                    : null,
              ),
              if (_geoCheckEnabled) ...[
                const SizedBox(height: UcraftSpacing.space2),
                UcraftTextField(
                  key: const ValueKey<String>('gym_geofence_radius'),
                  label: strings.branchesGeoRadiusLabel,
                  keyboardType: TextInputType.number,
                  controller: _radiusController,
                  enabled: canMutateGyms && !_submitting,
                ),
              ],
              const SizedBox(height: UcraftSpacing.space2),
              UcraftButton(
                label: _editingGymId == null
                    ? strings.branchesAddTitle
                    : strings.branchesSaveChangesButton,
                fullWidth: true,
                isLoading: _submitting,
                onPressed: canMutateGyms ? _saveGym : null,
              ),
              if (_editingGymId != null) ...[
                const SizedBox(height: UcraftSpacing.space2),
                UcraftButton(
                  label: strings.cancelLabel,
                  variant: UcraftButtonVariant.tertiary,
                  fullWidth: true,
                  onPressed: _submitting ? null : _resetForm,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: UcraftSpacing.space2),
        UcraftCard(
          child: DropdownButtonHideUnderline(
            child: InputDecorator(
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: UcraftSpacing.space3,
                ),
                constraints: BoxConstraints(minHeight: UcraftSpacing.space12),
              ),
              child: DropdownButton<CurrencyOption>(
                key: const ValueKey('company_currency'),
                value: activeCurrency,
                hint: Text(strings.companyCurrencyTitle),
                icon: const Icon(LucideIcons.chevronDown, size: 16),
                style: BusinessTypography.bodyMedium.copyWith(
                  color: colors.foreground,
                ),
                isExpanded: true,
                items: [
                  for (final currency in _currencies)
                    DropdownMenuItem(
                      value: currency,
                      child: Text(
                        '${currency.code} (${currency.name})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: canMutateCurrency && !_submitting
                    ? (currency) {
                        if (currency != null) {
                          unawaited(_selectCurrency(currency));
                        }
                      }
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

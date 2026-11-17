import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../../../core/session/business_role.dart';
import '../../../core/session/business_session_controller.dart';
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

    return UcraftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Создание компании (14 дней бесплатно)',
            style: UcraftTypography.title.copyWith(color: colors.foreground),
          ),
          const SizedBox(height: UcraftSpacing.space2),
          Text(
            'Укажите название компании и первого филиала — пробный период активируется автоматически.',
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
                style: UcraftTypography.bodyMedium.copyWith(
                  color: colors.destructiveForeground,
                ),
              ),
            ),
          ],
          const SizedBox(height: UcraftSpacing.space4),
          UcraftTextField(
            key: const ValueKey<String>('onboarding_company_name'),
            label: 'Название компании',
            hintText: 'FitLine LLC',
            controller: _companyNameController,
            enabled: !_isSubmitting,
            errorText: _fieldErrors['company_name']?.first,
          ),
          const SizedBox(height: UcraftSpacing.formFieldGap),
          UcraftTextField(
            key: const ValueKey<String>('onboarding_gym_name'),
            label: 'Название первого зала',
            hintText: 'FitLine Центральный',
            controller: _gymNameController,
            enabled: !_isSubmitting,
            errorText: _fieldErrors['gym_name']?.first,
          ),
          const SizedBox(height: UcraftSpacing.formFieldGap),
          UcraftTextField(
            key: const ValueKey<String>('onboarding_gym_address'),
            label: 'Адрес зала (необязательно)',
            hintText: 'ул. Рудаки 100',
            controller: _gymAddressController,
            enabled: !_isSubmitting,
            errorText: _fieldErrors['gym_address']?.first,
          ),
          const SizedBox(height: UcraftSpacing.space6),
          UcraftButton(
            label: 'Создать компанию (14 дней бесплатно)',
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
    if (_loading) {
      return const UcraftLoadingState(isSkeleton: true, skeletonCount: 2);
    }

    if (_errorMessage != null && _branches.isEmpty && _currencies.isEmpty) {
      return UcraftErrorState(
        message: _errorMessage!,
        retryLabel: 'Повторить',
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
              style: UcraftTypography.bodyMedium.copyWith(
                color: colors.successForeground,
              ),
            ),
          ),
          const SizedBox(height: UcraftSpacing.space4),
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
              style: UcraftTypography.bodyMedium.copyWith(
                color: colors.destructiveForeground,
              ),
            ),
          ),
          const SizedBox(height: UcraftSpacing.space4),
        ],
        UcraftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _editingGymId == null ? 'Добавить филиал' : 'Редактировать зал',
                style: UcraftTypography.title.copyWith(
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: UcraftSpacing.space4),
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
                              style: UcraftTypography.bodyMedium.copyWith(
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
                            : 'Без геозоны',
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
                label: 'Название филиала',
                controller: _nameController,
                enabled: canMutateGyms && !_submitting,
              ),
              const SizedBox(height: UcraftSpacing.formFieldGap),
              UcraftTextField(
                key: const ValueKey<String>('gym_branch_address'),
                label: 'Адрес филиала',
                controller: _addressController,
                enabled: canMutateGyms && !_submitting,
              ),
              const SizedBox(height: UcraftSpacing.space3),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Проверять геозону при чекине',
                  style: UcraftTypography.bodyMedium.copyWith(
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
                  label: 'Радиус геозоны (50–5000 м)',
                  keyboardType: TextInputType.number,
                  controller: _radiusController,
                  enabled: canMutateGyms && !_submitting,
                ),
              ],
              const SizedBox(height: UcraftSpacing.space4),
              UcraftButton(
                label: _editingGymId == null
                    ? 'Добавить филиал'
                    : 'Сохранить изменения',
                fullWidth: true,
                isLoading: _submitting,
                onPressed: canMutateGyms ? _saveGym : null,
              ),
              if (_editingGymId != null) ...[
                const SizedBox(height: UcraftSpacing.space2),
                UcraftButton(
                  label: 'Отмена',
                  variant: UcraftButtonVariant.tertiary,
                  fullWidth: true,
                  onPressed: _submitting ? null : _resetForm,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: UcraftSpacing.space4),
        UcraftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Валюта компании',
                style: UcraftTypography.title.copyWith(
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: UcraftSpacing.space3),
              Wrap(
                spacing: UcraftSpacing.space2,
                runSpacing: UcraftSpacing.space2,
                children: [
                  for (final currency in _currencies)
                    UcraftButton(
                      label: '${currency.code} (${currency.name})',
                      variant: _activeCurrencyCode == currency.code
                          ? UcraftButtonVariant.primary
                          : UcraftButtonVariant.secondary,
                      onPressed: canMutateCurrency && !_submitting
                          ? () => _selectCurrency(currency)
                          : null,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

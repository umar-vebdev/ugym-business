import 'dart:async';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../../../core/l10n/business_localizations.dart';
import '../../../core/session/business_role.dart';
import '../../../core/session/business_session_controller.dart';
import '../domain/memberships_models.dart';

/// Screen listing company membership tariffs with owner management actions.
final class MembershipTypesScreen extends StatefulWidget {
  const MembershipTypesScreen({
    super.key,
    required this.repository,
    required this.sessionController,
  });

  final MembershipsRepository repository;
  final BusinessSessionController sessionController;

  @override
  State<MembershipTypesScreen> createState() => _MembershipTypesScreenState();
}

final class _MembershipTypesScreenState extends State<MembershipTypesScreen> {
  bool _onlyActive = true;
  bool _loading = true;
  String? _errorMessage;
  int? _togglingTypeId;
  List<MembershipType> _types = const <MembershipType>[];

  @override
  void initState() {
    super.initState();
    unawaited(_loadTypes());
  }

  Future<void> _loadTypes() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final items = await widget.repository.listMembershipTypes(
        onlyActive: _onlyActive ? true : null,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _types = items;
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
        _errorMessage = 'Не удалось загрузить тарифы.';
      });
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            CreateMembershipTypeScreen(repository: widget.repository),
      ),
    );
    if (created == true && mounted) {
      await _loadTypes();
    }
  }

  Future<void> _toggleActive(MembershipType type) async {
    setState(() {
      _togglingTypeId = type.id;
      _errorMessage = null;
    });

    try {
      await widget.repository.setMembershipTypeActive(
        typeId: type.id,
        isActive: !type.isActive,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _togglingTypeId = null;
      });
      await _loadTypes();
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _togglingTypeId = null;
        _errorMessage = error.message;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _togglingTypeId = null;
        _errorMessage = 'Не удалось изменить статус тарифа.';
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
        final canManage = widget.sessionController.canMutate(
          BusinessPermission.manageMembershipTypesAndCancel,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: UcraftSpacing.space2,
              runSpacing: UcraftSpacing.space2,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  strings.plansTitle,
                  style: UcraftTypography.title.copyWith(
                    color: colors.foreground,
                  ),
                ),
                Wrap(
                  spacing: UcraftSpacing.space2,
                  children: [
                    UcraftButton(
                      label: _onlyActive
                          ? strings.plansShowAllButton
                          : strings.plansOnlyActiveButton,
                      variant: UcraftButtonVariant.secondary,
                      onPressed: () {
                        setState(() {
                          _onlyActive = !_onlyActive;
                        });
                        unawaited(_loadTypes());
                      },
                    ),
                    if (canManage)
                      UcraftButton(
                        label: strings.plansCreateButton,
                        leadingIcon: LucideIcons.plus,
                        variant: UcraftButtonVariant.secondary,
                        onPressed: () => unawaited(_openCreate()),
                      ),
                  ],
                ),
              ],
            ),
            if (_errorMessage != null && _types.isNotEmpty) ...[
              const SizedBox(height: UcraftSpacing.space2),
              Text(
                _errorMessage!,
                style: UcraftTypography.bodyMedium.copyWith(
                  color: colors.destructive,
                ),
              ),
            ],
            const SizedBox(height: UcraftSpacing.space3),
            if (_loading)
              const UcraftLoadingState(isSkeleton: true, skeletonCount: 4)
            else if (_errorMessage != null && _types.isEmpty)
              UcraftErrorState(
                icon: LucideIcons.circleAlert,
                title: strings.posLoadErrorTitle,
                message: _errorMessage!,
                retryLabel: strings.retryLabel,
                onRetry: () => unawaited(_loadTypes()),
              )
            else if (_types.isEmpty)
              UcraftEmptyState(
                icon: LucideIcons.ticket,
                title: strings.plansEmptyTitle,
                description: strings.plansEmptyDesc,
              )
            else
              UcraftListSection(
                children: [
                  for (final type in _types)
                    _MembershipTypeRow(
                      type: type,
                      canManage: canManage,
                      isToggling: _togglingTypeId == type.id,
                      onToggleActive: () => unawaited(_toggleActive(type)),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

final class _MembershipTypeRow extends StatelessWidget {
  const _MembershipTypeRow({
    required this.type,
    required this.canManage,
    required this.isToggling,
    required this.onToggleActive,
  });

  final MembershipType type;
  final bool canManage;
  final bool isToggling;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final strings = BusinessStringsScope.of(context);
    final priceText = (type.priceMinor / 100).toStringAsFixed(2);
    final details = <String>[
      _kindLabel(type.kind, strings),
      if (type.durationDays != null) '${type.durationDays} дн.',
      if (type.visitsCount != null) '${type.visitsCount} визитов',
      if (type.validityDays != null) 'срок ${type.validityDays} дн.',
    ].join(' • ');

    return UcraftListRow(
      title: type.name,
      subtitle: details,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$priceText ${type.currency}',
            style: UcraftTypography.mono.copyWith(color: colors.foreground),
          ),
          const SizedBox(width: UcraftSpacing.space2),
          UcraftStatusPill(
            icon: type.isActive ? LucideIcons.circleCheck : LucideIcons.archive,
            label: type.isActive
                ? strings.planStatusActive
                : strings.planStatusArchived,
            tone: type.isActive
                ? UcraftStatusTone.success
                : UcraftStatusTone.neutral,
          ),
        ],
      ),
      bottom: canManage
          ? Align(
              alignment: Alignment.centerRight,
              child: UcraftButton(
                label: type.isActive
                    ? strings.planArchiveButton
                    : strings.planActivateButton,
                variant: UcraftButtonVariant.secondary,
                isLoading: isToggling,
                onPressed: isToggling ? null : onToggleActive,
              ),
            )
          : null,
    );
  }

  String _kindLabel(MembershipKind kind, BusinessStrings strings) {
    return switch (kind) {
      MembershipKind.unlimitedTime => strings.planKindUnlimited,
      MembershipKind.visitsPack => strings.planKindVisitsPack,
      MembershipKind.mixed => strings.planKindMixed,
    };
  }
}

/// Owner-only constructor screen for creating a membership tariff.
final class CreateMembershipTypeScreen extends StatefulWidget {
  const CreateMembershipTypeScreen({super.key, required this.repository});

  final MembershipsRepository repository;

  @override
  State<CreateMembershipTypeScreen> createState() =>
      _CreateMembershipTypeScreenState();
}

final class _CreateMembershipTypeScreenState
    extends State<CreateMembershipTypeScreen> {
  static final RegExp _timeRegex = RegExp(r'^\d{2}:\d{2}$');

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _visitsController = TextEditingController();
  final _validityController = TextEditingController();
  final _dailyLimitController = TextEditingController(text: '1');
  final _timeFromController = TextEditingController();
  final _timeToController = TextEditingController();
  final _freezeDaysController = TextEditingController(text: '0');
  final _freezeTimesController = TextEditingController(text: '0');

  MembershipKind _kind = MembershipKind.unlimitedTime;
  MembershipStartMode _startMode = MembershipStartMode.onPurchase;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _visitsController.dispose();
    _validityController.dispose();
    _dailyLimitController.dispose();
    _timeFromController.dispose();
    _timeToController.dispose();
    _freezeDaysController.dispose();
    _freezeTimesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }

    final name = _nameController.text.trim();
    final priceMajor = double.tryParse(
      _priceController.text.trim().replaceAll(',', '.'),
    );
    final durationDays = int.tryParse(_durationController.text.trim());
    final visitsCount = int.tryParse(_visitsController.text.trim());
    final validityDays = int.tryParse(_validityController.text.trim());
    final dailyLimit = int.tryParse(_dailyLimitController.text.trim());
    final timeFrom = _timeFromController.text.trim();
    final timeTo = _timeToController.text.trim();
    final freezeDays = int.tryParse(_freezeDaysController.text.trim());
    final freezeTimes = int.tryParse(_freezeTimesController.text.trim());

    String? validationError;
    if (name.isEmpty || name.length > 255) {
      validationError = 'Укажите название тарифа (до 255 символов).';
    } else if (priceMajor == null || priceMajor < 0) {
      validationError = 'Укажите корректную цену.';
    } else if (_kind == MembershipKind.unlimitedTime &&
        (durationDays == null || durationDays < 1)) {
      validationError = 'Для безлимита укажите длительность в днях.';
    } else if (_kind == MembershipKind.visitsPack &&
        (visitsCount == null || visitsCount < 1)) {
      validationError = 'Для пакета укажите количество визитов.';
    } else if (_kind == MembershipKind.mixed &&
        (durationDays == null ||
            durationDays < 1 ||
            visitsCount == null ||
            visitsCount < 1)) {
      validationError =
          'Для смешанного тарифа укажите и визиты, и длительность в днях.';
    } else if ((timeFrom.isEmpty) != (timeTo.isEmpty)) {
      validationError = 'Временное окно задаётся парой «с» и «до» (ЧЧ:ММ).';
    } else if (timeFrom.isNotEmpty &&
        (!_timeRegex.hasMatch(timeFrom) || !_timeRegex.hasMatch(timeTo))) {
      validationError = 'Время должно быть в формате ЧЧ:ММ.';
    }

    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await widget.repository.createMembershipType(
        CreateMembershipTypeInput(
          name: name,
          priceMinor: (priceMajor! * 100).round(),
          kind: _kind,
          startMode: _startMode,
          durationDays: _kind == MembershipKind.visitsPack
              ? null
              : durationDays,
          visitsCount: _kind == MembershipKind.unlimitedTime
              ? null
              : visitsCount,
          validityDays: _kind == MembershipKind.visitsPack
              ? validityDays
              : null,
          dailyLimit: dailyLimit,
          timeFrom: timeFrom.isEmpty ? null : timeFrom,
          timeTo: timeTo.isEmpty ? null : timeTo,
          freezeMaxDays: freezeDays,
          freezeMaxTimes: freezeTimes,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
      });
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
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
        _errorMessage = 'Не удалось создать тариф.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final strings = BusinessStringsScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.planNewTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(UcraftSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UcraftTextField(
                controller: _nameController,
                label: strings.planNameLabel,
              ),
              const SizedBox(height: UcraftSpacing.space3),
              UcraftTextField(
                controller: _priceController,
                label: strings.planPriceInCurrencyLabel,
                hintText: '250',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: UcraftSpacing.space3),
              Text(
                strings.planKindSectionLabel,
                style: UcraftTypography.bodyMedium.copyWith(
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: UcraftSpacing.space2),
              UcraftSegmentedTabs<MembershipKind>(
                items: [
                  for (final kind in MembershipKind.values)
                    UcraftSegmentedTabItem(
                      value: kind,
                      label: _kindLabel(kind, strings),
                    ),
                ],
                selected: _kind,
                onSelected: (kind) {
                  setState(() {
                    _kind = kind;
                    _errorMessage = null;
                  });
                },
              ),
              const SizedBox(height: UcraftSpacing.space3),
              Text(
                strings.planStartModeSectionLabel,
                style: UcraftTypography.bodyMedium.copyWith(
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: UcraftSpacing.space2),
              UcraftSegmentedTabs<MembershipStartMode>(
                items: [
                  UcraftSegmentedTabItem(
                    value: MembershipStartMode.onPurchase,
                    label: strings.planStartOnPurchase,
                  ),
                  UcraftSegmentedTabItem(
                    value: MembershipStartMode.onFirstVisit,
                    label: strings.planStartOnFirstVisit,
                  ),
                ],
                selected: _startMode,
                onSelected: (mode) {
                  setState(() {
                    _startMode = mode;
                  });
                },
              ),
              if (_kind != MembershipKind.visitsPack) ...[
                const SizedBox(height: UcraftSpacing.space3),
                UcraftTextField(
                  controller: _durationController,
                  label: strings.planDurationDaysLabel,
                  keyboardType: TextInputType.number,
                ),
              ],
              if (_kind != MembershipKind.unlimitedTime) ...[
                const SizedBox(height: UcraftSpacing.space3),
                UcraftTextField(
                  controller: _visitsController,
                  label: strings.planVisitsCountLabel,
                  keyboardType: TextInputType.number,
                ),
              ],
              if (_kind == MembershipKind.visitsPack) ...[
                const SizedBox(height: UcraftSpacing.space3),
                UcraftTextField(
                  controller: _validityController,
                  label: strings.planValidityDaysLabel,
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: UcraftSpacing.space3),
              UcraftTextField(
                controller: _dailyLimitController,
                label: strings.planDailyLimitLabel,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: UcraftSpacing.space3),
              Row(
                children: [
                  Expanded(
                    child: UcraftTextField(
                      controller: _timeFromController,
                      label: strings.planTimeFromLabel,
                      hintText: '08:00',
                    ),
                  ),
                  const SizedBox(width: UcraftSpacing.space2),
                  Expanded(
                    child: UcraftTextField(
                      controller: _timeToController,
                      label: strings.planTimeToLabel,
                      hintText: '16:00',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: UcraftSpacing.space3),
              Row(
                children: [
                  Expanded(
                    child: UcraftTextField(
                      controller: _freezeDaysController,
                      label: strings.planFreezeDaysLabel,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: UcraftSpacing.space2),
                  Expanded(
                    child: UcraftTextField(
                      controller: _freezeTimesController,
                      label: strings.planFreezeTimesLabel,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
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
              const SizedBox(height: UcraftSpacing.space4),
              UcraftButton(
                label: strings.planSaveButton,
                fullWidth: true,
                isLoading: _submitting,
                onPressed: _submitting ? null : () => unawaited(_submit()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _kindLabel(MembershipKind kind, BusinessStrings strings) {
    return switch (kind) {
      MembershipKind.unlimitedTime => strings.planKindUnlimited,
      MembershipKind.visitsPack => strings.planKindVisitsPack,
      MembershipKind.mixed => strings.planKindMixed,
    };
  }
}

/// List of memberships expiring within 7 days with freeze/unfreeze and cancel.
final class ExpiringMembershipsTab extends StatefulWidget {
  const ExpiringMembershipsTab({
    super.key,
    required this.repository,
    required this.sessionController,
  });

  final MembershipsRepository repository;
  final BusinessSessionController sessionController;

  @override
  State<ExpiringMembershipsTab> createState() => _ExpiringMembershipsTabState();
}

final class _ExpiringMembershipsTabState extends State<ExpiringMembershipsTab> {
  bool _loading = true;
  String? _errorMessage;
  int? _busyMembershipId;
  List<ClientMembership> _items = const <ClientMembership>[];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final list = await widget.repository.listExpiringMemberships();
      if (!mounted) {
        return;
      }
      setState(() {
        _items = list;
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
        _errorMessage = 'Не удалось загрузить истекающие абонементы.';
      });
    }
  }

  Future<void> _toggleFreeze(ClientMembership item) async {
    setState(() {
      _busyMembershipId = item.id;
      _errorMessage = null;
    });

    try {
      final state = item.status == MembershipStatus.frozen
          ? await widget.repository.unfreezeMembership(membershipId: item.id)
          : await widget.repository.freezeMembership(membershipId: item.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _busyMembershipId = null;
        _items = _items
            .map(
              (m) => m.id == item.id
                  ? ClientMembership(
                      id: m.id,
                      clientId: m.clientId,
                      typeId: m.typeId,
                      kind: m.kind,
                      status: state.status,
                      remainingVisits: m.remainingVisits,
                      startsAt: m.startsAt,
                      endsAt: state.endsAt ?? m.endsAt,
                      freezeDaysUsed: state.freezeDaysUsed,
                      freezeTimesUsed: state.freezeTimesUsed,
                      frozenAt: state.frozenAt,
                      cancellationReason: m.cancellationReason,
                    )
                  : m,
            )
            .toList(growable: false);
      });
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

  Future<void> _cancelMembership(ClientMembership item) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _CancelMembershipDialog(membershipId: item.id),
    );
    if (reason == null || !mounted) {
      return;
    }

    setState(() {
      _busyMembershipId = item.id;
      _errorMessage = null;
    });

    try {
      final updated = await widget.repository.cancelMembership(
        membershipId: item.id,
        reason: reason,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _busyMembershipId = null;
        _items = _items
            .map(
              (m) => m.id == item.id
                  ? ClientMembership(
                      id: m.id,
                      clientId: m.clientId,
                      typeId: m.typeId,
                      kind: m.kind,
                      status: updated.status,
                      remainingVisits: m.remainingVisits,
                      startsAt: m.startsAt,
                      endsAt: m.endsAt,
                      freezeDaysUsed: m.freezeDaysUsed,
                      freezeTimesUsed: m.freezeTimesUsed,
                      frozenAt: m.frozenAt,
                      cancellationReason: updated.cancellationReason ?? reason,
                    )
                  : m,
            )
            .toList(growable: false);
      });
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
        _errorMessage = 'Не удалось отменить абонемент.';
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
        final canFreeze = widget.sessionController.canMutate(
          BusinessPermission.viewExpiringAndFreezeMemberships,
        );
        final canCancel = widget.sessionController.canMutate(
          BusinessPermission.manageMembershipTypesAndCancel,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.expiringSoonTitle,
                    style: UcraftTypography.title.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                ),
                UcraftButton(
                  label: strings.refreshLabel,
                  variant: UcraftButtonVariant.secondary,
                  onPressed: _loading ? null : () => unawaited(_load()),
                ),
              ],
            ),
            if (_errorMessage != null && _items.isNotEmpty) ...[
              const SizedBox(height: UcraftSpacing.space2),
              Text(
                _errorMessage!,
                style: UcraftTypography.bodyMedium.copyWith(
                  color: colors.destructive,
                ),
              ),
            ],
            const SizedBox(height: UcraftSpacing.space3),
            if (_loading)
              const UcraftLoadingState(isSkeleton: true, skeletonCount: 4)
            else if (_errorMessage != null && _items.isEmpty)
              UcraftErrorState(
                icon: LucideIcons.circleAlert,
                title: strings.posLoadErrorTitle,
                message: _errorMessage!,
                retryLabel: strings.retryLabel,
                onRetry: () => unawaited(_load()),
              )
            else if (_items.isEmpty)
              UcraftEmptyState(
                icon: LucideIcons.calendarCheck,
                title: strings.expiringEmptyTitle,
                description: strings.expiringEmptyDesc,
              )
            else
              UcraftListSection(
                children: [
                  for (final item in _items)
                    _ExpiringMembershipRow(
                      item: item,
                      canFreeze: canFreeze,
                      canCancel: canCancel,
                      isBusy: _busyMembershipId == item.id,
                      onToggleFreeze: () => unawaited(_toggleFreeze(item)),
                      onCancel: () => unawaited(_cancelMembership(item)),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

final class _ExpiringMembershipRow extends StatelessWidget {
  const _ExpiringMembershipRow({
    required this.item,
    required this.canFreeze,
    required this.canCancel,
    required this.isBusy,
    required this.onToggleFreeze,
    required this.onCancel,
  });

  final ClientMembership item;
  final bool canFreeze;
  final bool canCancel;
  final bool isBusy;
  final VoidCallback onToggleFreeze;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final strings = BusinessStringsScope.of(context);
    final endsText = item.endsAt != null
        ? DateFormatter.formatDateTime(
            item.endsAt!,
            offset: DateFormatter.dushanbeOffset,
          )
        : '—';
    final isFrozen = item.status == MembershipStatus.frozen;
    final isCancelled = item.status == MembershipStatus.cancelled;

    return UcraftListRow(
      title:
          '${strings.scannerMembershipPrefix}${item.id} • Клиент №${item.clientId}',
      subtitle:
          'До: $endsText${item.remainingVisits != null ? ' • ${strings.scannerRemainingVisitsPrefix}${item.remainingVisits}' : ''}',
      trailing: UcraftStatusPill(
        icon: isCancelled
            ? LucideIcons.circleX
            : isFrozen
            ? LucideIcons.snowflake
            : LucideIcons.clock,
        label: item.status.apiValue,
        tone: isCancelled
            ? UcraftStatusTone.destructive
            : isFrozen
            ? UcraftStatusTone.info
            : UcraftStatusTone.warning,
      ),
      bottom: !isCancelled && (canFreeze || canCancel)
          ? Wrap(
              spacing: UcraftSpacing.space2,
              runSpacing: UcraftSpacing.space2,
              alignment: WrapAlignment.end,
              children: [
                if (canFreeze)
                  UcraftButton(
                    label: isFrozen
                        ? strings.clientUnfreezeButton
                        : strings.clientFreezeButton,
                    variant: UcraftButtonVariant.secondary,
                    isLoading: isBusy,
                    onPressed: isBusy ? null : onToggleFreeze,
                  ),
                if (canCancel)
                  UcraftButton(
                    label: strings.membershipCancelButton,
                    variant: UcraftButtonVariant.destructive,
                    isLoading: isBusy,
                    onPressed: isBusy ? null : onCancel,
                  ),
              ],
            )
          : null,
    );
  }
}

final class _CancelMembershipDialog extends StatefulWidget {
  const _CancelMembershipDialog({required this.membershipId});

  final int membershipId;

  @override
  State<_CancelMembershipDialog> createState() =>
      _CancelMembershipDialogState();
}

final class _CancelMembershipDialogState
    extends State<_CancelMembershipDialog> {
  final _reasonController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = BusinessStringsScope.of(context);
    return AlertDialog(
      title: Text(strings.membershipCancelDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${strings.scannerMembershipPrefix}${widget.membershipId}'),
          const SizedBox(height: UcraftSpacing.space3),
          UcraftTextField(
            controller: _reasonController,
            label: strings.visitCancelReasonLabel,
            errorText: _errorText,
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.backLabel),
        ),
        UcraftButton(
          label: strings.visitConfirmCancelButton,
          variant: UcraftButtonVariant.destructive,
          onPressed: () {
            final reason = _reasonController.text.trim();
            if (reason.isEmpty || reason.length > 500) {
              setState(() {
                _errorText = 'Укажите причину (1–500 символов).';
              });
              return;
            }
            Navigator.of(context).pop(reason);
          },
        ),
      ],
    );
  }
}

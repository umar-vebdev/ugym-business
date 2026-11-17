import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

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
                  'Тарифы абонементов',
                  style: UcraftTypography.title.copyWith(
                    color: colors.foreground,
                  ),
                ),
                Wrap(
                  spacing: UcraftSpacing.space2,
                  children: [
                    UcraftButton(
                      label: _onlyActive ? 'Показать все' : 'Только активные',
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
                        label: 'Создать тариф',
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
              const UcraftLoadingState(message: 'Загружаем тарифы...')
            else if (_errorMessage != null && _types.isEmpty)
              UcraftErrorState(
                title: 'Ошибка загрузки',
                message: _errorMessage!,
                onRetry: () => unawaited(_loadTypes()),
              )
            else if (_types.isEmpty)
              const UcraftEmptyState(
                title: 'Тарифов пока нет',
                description: 'Создайте первый тариф, чтобы продавать абонементы на кассе и в приложении.',
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final type in _types) ...[
                    _MembershipTypeCard(
                      type: type,
                      canManage: canManage,
                      isToggling: _togglingTypeId == type.id,
                      onToggleActive: () => unawaited(_toggleActive(type)),
                    ),
                    const SizedBox(height: UcraftSpacing.space3),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }
}

final class _MembershipTypeCard extends StatelessWidget {
  const _MembershipTypeCard({
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
    final priceText = (type.priceMinor / 100).toStringAsFixed(2);
    final details = <String>[
      _kindLabel(type.kind),
      if (type.durationDays != null) '${type.durationDays} дн.',
      if (type.visitsCount != null) '${type.visitsCount} визитов',
      if (type.validityDays != null) 'срок ${type.validityDays} дн.',
    ].join(' • ');

    return UcraftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  type.name,
                  style: UcraftTypography.bodyMedium.copyWith(
                    color: colors.foreground,
                  ),
                ),
              ),
              Text(
                '$priceText ${type.currency}',
                style: UcraftTypography.bodyMedium.copyWith(
                  color: colors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: UcraftSpacing.space1),
          Text(
            '$details • ${type.isActive ? 'Активен' : 'В архиве'}',
            style: UcraftTypography.caption.copyWith(
              color: colors.foregroundSecondary,
            ),
          ),
          if (canManage) ...[
            const SizedBox(height: UcraftSpacing.space3),
            Align(
              alignment: Alignment.centerRight,
              child: UcraftButton(
                label: type.isActive ? 'В архив' : 'Активировать',
                variant: UcraftButtonVariant.secondary,
                isLoading: isToggling,
                onPressed: isToggling ? null : onToggleActive,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _kindLabel(MembershipKind kind) {
    return switch (kind) {
      MembershipKind.unlimitedTime => 'Безлимит',
      MembershipKind.visitsPack => 'Пакет визитов',
      MembershipKind.mixed => 'Визиты + срок',
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

    return Scaffold(
      appBar: AppBar(title: const Text('Новый тариф')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(UcraftSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UcraftTextField(
                controller: _nameController,
                label: 'Название',
                hintText: 'Например, Безлимит 30 дней',
              ),
              const SizedBox(height: UcraftSpacing.space3),
              UcraftTextField(
                controller: _priceController,
                label: 'Цена в валюте зала',
                hintText: '250',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: UcraftSpacing.space3),
              Text(
                'Тип тарифа',
                style: UcraftTypography.bodyMedium.copyWith(
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: UcraftSpacing.space2),
              Wrap(
                spacing: UcraftSpacing.space2,
                runSpacing: UcraftSpacing.space2,
                children: [
                  for (final kind in MembershipKind.values)
                    UcraftButton(
                      label: _kindLabel(kind),
                      variant: _kind == kind
                          ? UcraftButtonVariant.primary
                          : UcraftButtonVariant.secondary,
                      onPressed: () {
                        setState(() {
                          _kind = kind;
                          _errorMessage = null;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: UcraftSpacing.space3),
              Text(
                'Начало действия',
                style: UcraftTypography.bodyMedium.copyWith(
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: UcraftSpacing.space2),
              Wrap(
                spacing: UcraftSpacing.space2,
                runSpacing: UcraftSpacing.space2,
                children: [
                  UcraftButton(
                    label: 'С момента покупки',
                    variant: _startMode == MembershipStartMode.onPurchase
                        ? UcraftButtonVariant.primary
                        : UcraftButtonVariant.secondary,
                    onPressed: () {
                      setState(() {
                        _startMode = MembershipStartMode.onPurchase;
                      });
                    },
                  ),
                  UcraftButton(
                    label: 'С первого визита',
                    variant: _startMode == MembershipStartMode.onFirstVisit
                        ? UcraftButtonVariant.primary
                        : UcraftButtonVariant.secondary,
                    onPressed: () {
                      setState(() {
                        _startMode = MembershipStartMode.onFirstVisit;
                      });
                    },
                  ),
                ],
              ),
              if (_kind != MembershipKind.visitsPack) ...[
                const SizedBox(height: UcraftSpacing.space3),
                UcraftTextField(
                  controller: _durationController,
                  label: 'Длительность (дней)',
                  keyboardType: TextInputType.number,
                ),
              ],
              if (_kind != MembershipKind.unlimitedTime) ...[
                const SizedBox(height: UcraftSpacing.space3),
                UcraftTextField(
                  controller: _visitsController,
                  label: 'Количество визитов',
                  keyboardType: TextInputType.number,
                ),
              ],
              if (_kind == MembershipKind.visitsPack) ...[
                const SizedBox(height: UcraftSpacing.space3),
                UcraftTextField(
                  controller: _validityController,
                  label: 'Срок годности пакета (дней, опционально)',
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: UcraftSpacing.space3),
              UcraftTextField(
                controller: _dailyLimitController,
                label: 'Лимит визитов в день (1–100)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: UcraftSpacing.space3),
              Row(
                children: [
                  Expanded(
                    child: UcraftTextField(
                      controller: _timeFromController,
                      label: 'Окно с (ЧЧ:ММ)',
                      hintText: '08:00',
                    ),
                  ),
                  const SizedBox(width: UcraftSpacing.space2),
                  Expanded(
                    child: UcraftTextField(
                      controller: _timeToController,
                      label: 'Окно до (ЧЧ:ММ)',
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
                      label: 'Заморозка (дней)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: UcraftSpacing.space2),
                  Expanded(
                    child: UcraftTextField(
                      controller: _freezeTimesController,
                      label: 'Заморозок (раз)',
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
                label: 'Сохранить тариф',
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

  String _kindLabel(MembershipKind kind) {
    return switch (kind) {
      MembershipKind.unlimitedTime => 'Безлимит',
      MembershipKind.visitsPack => 'Пакет визитов',
      MembershipKind.mixed => 'Визиты + срок',
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
                    'Истекают за 7 дней',
                    style: UcraftTypography.title.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                ),
                UcraftButton(
                  label: 'Обновить',
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
              const UcraftLoadingState(message: 'Загружаем абонементы...')
            else if (_errorMessage != null && _items.isEmpty)
              UcraftErrorState(
                title: 'Ошибка загрузки',
                message: _errorMessage!,
                onRetry: () => unawaited(_load()),
              )
            else if (_items.isEmpty)
              const UcraftEmptyState(
                title: 'Нет истекающих абонементов',
                description: 'В ближайшие 7 дней ни у одного клиента абонемент не заканчивается.',
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in _items) ...[
                    _ExpiringMembershipCard(
                      item: item,
                      canFreeze: canFreeze,
                      canCancel: canCancel,
                      isBusy: _busyMembershipId == item.id,
                      onToggleFreeze: () => unawaited(_toggleFreeze(item)),
                      onCancel: () => unawaited(_cancelMembership(item)),
                    ),
                    const SizedBox(height: UcraftSpacing.space3),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }
}

final class _ExpiringMembershipCard extends StatelessWidget {
  const _ExpiringMembershipCard({
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
    final colors = context.ucraftColors;
    final endsText = item.endsAt != null
        ? DateFormatter.formatDateTime(
            item.endsAt!,
            offset: DateFormatter.dushanbeOffset,
          )
        : 'без срока';
    final isFrozen = item.status == MembershipStatus.frozen;
    final isCancelled = item.status == MembershipStatus.cancelled;

    return UcraftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Абонемент №${item.id} • Клиент №${item.clientId}',
                  style: UcraftTypography.bodyMedium.copyWith(
                    color: colors.foreground,
                  ),
                ),
              ),
              Text(
                item.status.apiValue,
                style: UcraftTypography.caption.copyWith(
                  color: isCancelled
                      ? colors.destructive
                      : colors.foregroundSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: UcraftSpacing.space1),
          Text(
            'До: $endsText${item.remainingVisits != null ? ' • Осталось визитов: ${item.remainingVisits}' : ''}',
            style: UcraftTypography.caption.copyWith(
              color: colors.foregroundSecondary,
            ),
          ),
          if (!isCancelled && (canFreeze || canCancel)) ...[
            const SizedBox(height: UcraftSpacing.space3),
            Wrap(
              spacing: UcraftSpacing.space2,
              runSpacing: UcraftSpacing.space2,
              alignment: WrapAlignment.end,
              children: [
                if (canFreeze)
                  UcraftButton(
                    label: isFrozen ? 'Разморозить' : 'Заморозить',
                    variant: UcraftButtonVariant.secondary,
                    isLoading: isBusy,
                    onPressed: isBusy ? null : onToggleFreeze,
                  ),
                if (canCancel)
                  UcraftButton(
                    label: 'Отменить',
                    variant: UcraftButtonVariant.destructive,
                    isLoading: isBusy,
                    onPressed: isBusy ? null : onCancel,
                  ),
              ],
            ),
          ],
        ],
      ),
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
    return AlertDialog(
      title: const Text('Отменить абонемент'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Абонемент №${widget.membershipId}'),
          const SizedBox(height: UcraftSpacing.space3),
          UcraftTextField(
            controller: _reasonController,
            label: 'Причина отмены',
            hintText: 'До 500 символов',
            errorText: _errorText,
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Назад'),
        ),
        UcraftButton(
          label: 'Подтвердить отмену',
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

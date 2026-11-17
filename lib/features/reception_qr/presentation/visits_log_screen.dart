import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../../../core/session/business_role.dart';
import '../../../core/session/business_session_controller.dart';
import '../domain/reception_visits_models.dart';

/// Company visits log with manual check-in and 24-hour cancellation support.
final class VisitsLogScreen extends StatefulWidget {
  const VisitsLogScreen({
    super.key,
    required this.repository,
    required this.sessionController,
    this.clock,
    this.idempotencyKeyGenerator,
  });

  final ReceptionVisitsRepository repository;
  final BusinessSessionController sessionController;
  final DateTime Function()? clock;
  final String Function()? idempotencyKeyGenerator;

  @override
  State<VisitsLogScreen> createState() => _VisitsLogScreenState();
}

final class _VisitsLogScreenState extends State<VisitsLogScreen> {
  bool _loading = true;
  String? _errorMessage;
  List<VisitRecord> _visits = const <VisitRecord>[];
  int? _cancellingVisitId;

  DateTime _nowUtc() => (widget.clock?.call() ?? DateTime.now()).toUtc();

  @override
  void initState() {
    super.initState();
    unawaited(_loadVisits());
  }

  Future<void> _loadVisits() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final visits = await widget.repository.listCompanyVisits();
      if (!mounted) {
        return;
      }
      setState(() {
        _visits = visits;
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
        _errorMessage = 'Не удалось загрузить журнал визитов.';
      });
    }
  }

  Future<void> _openManualCheckIn() async {
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
            repository: widget.repository,
            gymId: gym.id,
            gymName: gym.name,
            idempotencyKeyGenerator: widget.idempotencyKeyGenerator,
          ),
        );
      },
    );

    if (created == true && mounted) {
      await _loadVisits();
    }
  }

  Future<void> _promptCancelVisit(VisitRecord visit) async {
    final confirmedReason = await showDialog<String>(
      context: context,
      builder: (_) => _CancelVisitDialog(visit: visit),
    );

    if (confirmedReason == null || !mounted) {
      return;
    }

    setState(() {
      _cancellingVisitId = visit.id;
      _errorMessage = null;
    });

    try {
      final updated = await widget.repository.cancelVisit(
        visitId: visit.id,
        reason: confirmedReason,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _cancellingVisitId = null;
        _visits = _visits
            .map((item) => item.id == updated.id ? updated : item)
            .toList(growable: false);
      });
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _cancellingVisitId = null;
        _errorMessage = error.message;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _cancellingVisitId = null;
        _errorMessage = 'Не удалось отменить визит.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sessionController,
      builder: (context, _) {
        final colors = context.ucraftColors;
        final canMutate = widget.sessionController.canMutate(
          BusinessPermission.manageReceptionQrAndVisits,
        );
        final selectedGym = widget.sessionController.selectedGym;
        final nowUtc = _nowUtc();

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
                  'Журнал визитов',
                  style: UcraftTypography.title.copyWith(
                    color: colors.foreground,
                  ),
                ),
                Wrap(
                  spacing: UcraftSpacing.space2,
                  children: [
                    UcraftButton(
                      label: 'Обновить',
                      variant: UcraftButtonVariant.secondary,
                      onPressed: _loading
                          ? null
                          : () => unawaited(_loadVisits()),
                    ),
                    UcraftButton(
                      label: 'Ручная отметка',
                      onPressed: canMutate && selectedGym != null
                          ? () => unawaited(_openManualCheckIn())
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            if (selectedGym == null && canMutate) ...[
              const SizedBox(height: UcraftSpacing.space2),
              Text(
                'Выберите филиал для ручной отметки посещения.',
                style: UcraftTypography.caption.copyWith(
                  color: colors.foregroundSecondary,
                ),
              ),
            ],
            if (_errorMessage != null && _visits.isNotEmpty) ...[
              const SizedBox(height: UcraftSpacing.space3),
              Text(
                _errorMessage!,
                style: UcraftTypography.bodyMedium.copyWith(
                  color: colors.destructive,
                ),
              ),
            ],
            const SizedBox(height: UcraftSpacing.space3),
            if (_loading)
              const UcraftLoadingState(message: 'Загружаем визиты...')
            else if (_errorMessage != null && _visits.isEmpty)
              UcraftErrorState(
                title: 'Ошибка загрузки',
                message: _errorMessage!,
                onRetry: () => unawaited(_loadVisits()),
              )
            else if (_visits.isEmpty)
              const UcraftEmptyState(
                title: 'Визитов пока нет',
                description: 'Отметки по QR-коду и ручные визиты появятся в этом списке.',
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final visit in _visits) ...[
                    _VisitCard(
                      visit: visit,
                      formattedTime: DateFormatter.formatDateTime(
                        visit.visitedAt,
                        offset: DateFormatter.dushanbeOffset,
                      ),
                      canCancel: canMutate && visit.canCancelAt(nowUtc),
                      isCancelling: _cancellingVisitId == visit.id,
                      onCancel: () => unawaited(_promptCancelVisit(visit)),
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

final class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.visit,
    required this.formattedTime,
    required this.canCancel,
    required this.isCancelling,
    required this.onCancel,
  });

  final VisitRecord visit;
  final String formattedTime;
  final bool canCancel;
  final bool isCancelling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final isCancelled = visit.status == VisitStatus.cancelled;

    return UcraftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Клиент №${visit.clientId} • Абонемент №${visit.membershipId}',
                  style: UcraftTypography.bodyMedium.copyWith(
                    color: colors.foreground,
                  ),
                ),
              ),
              Text(
                isCancelled ? 'Отменён' : 'Завершён',
                style: UcraftTypography.caption.copyWith(
                  color: isCancelled ? colors.destructive : colors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: UcraftSpacing.space1),
          Text(
            '${_methodLabel(visit.method)} • $formattedTime • Зал №${visit.gymId}',
            style: UcraftTypography.caption.copyWith(
              color: colors.foregroundSecondary,
            ),
          ),
          if (isCancelled && visit.cancelReason != null) ...[
            const SizedBox(height: UcraftSpacing.space2),
            Text(
              'Причина отмены: ${visit.cancelReason}',
              style: UcraftTypography.caption.copyWith(
                color: colors.destructiveForeground,
              ),
            ),
          ],
          if (canCancel) ...[
            const SizedBox(height: UcraftSpacing.space3),
            Align(
              alignment: Alignment.centerRight,
              child: UcraftButton(
                label: 'Отменить визит',
                variant: UcraftButtonVariant.destructive,
                isLoading: isCancelling,
                onPressed: isCancelling ? null : onCancel,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _methodLabel(VisitMethod method) {
    return switch (method) {
      VisitMethod.qr => 'QR зала',
      VisitMethod.clientQr => 'QR клиента',
      VisitMethod.manual => 'Ручная отметка',
    };
  }
}

/// Modal form to register a manual visit (optionally backdated) with idempotency.
final class ManualCheckInSheet extends StatefulWidget {
  const ManualCheckInSheet({
    super.key,
    required this.repository,
    required this.gymId,
    this.gymName,
    this.idempotencyKeyGenerator,
    this.onSuccess,
  });

  final ReceptionVisitsRepository repository;
  final int gymId;
  final String? gymName;
  final String Function()? idempotencyKeyGenerator;
  final void Function(CheckInResult result)? onSuccess;

  @override
  State<ManualCheckInSheet> createState() => _ManualCheckInSheetState();
}

final class _ManualCheckInSheetState extends State<ManualCheckInSheet> {
  final _clientIdController = TextEditingController();
  final _visitedAtController = TextEditingController();

  bool _backdated = false;
  bool _submitting = false;
  String? _clientIdError;
  String? _visitedAtError;
  String? _submitError;
  String? _pendingIdempotencyKey;

  @override
  void dispose() {
    _clientIdController.dispose();
    _visitedAtController.dispose();
    super.dispose();
  }

  void _invalidateIdempotencyKey() {
    _pendingIdempotencyKey = null;
  }

  DateTime? _parseVisitedAtUtc(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final normalized = trimmed.contains('T')
        ? trimmed
        : trimmed.replaceFirst(' ', 'T');
    final hasZone =
        normalized.endsWith('Z') ||
        RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(normalized);

    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) {
      return null;
    }

    if (hasZone) {
      return parsed.toUtc();
    }

    // Treat naive local input as Dushanbe (+05:00) and convert to UTC.
    final asUtc = DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
    );
    return asUtc.subtract(DateFormatter.dushanbeOffset);
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }

    final clientId = int.tryParse(_clientIdController.text.trim());
    String? clientError;
    if (clientId == null || clientId <= 0) {
      clientError = 'Введите корректный ID клиента.';
    }

    DateTime? visitedAtUtc;
    String? visitedAtError;
    if (_backdated) {
      visitedAtUtc = _parseVisitedAtUtc(_visitedAtController.text);
      if (visitedAtUtc == null) {
        visitedAtError = 'Укажите дату и время в формате ГГГГ-ММ-ДД ЧЧ:ММ.';
      }
    }

    if (clientError != null || visitedAtError != null) {
      setState(() {
        _clientIdError = clientError;
        _visitedAtError = visitedAtError;
        _submitError = null;
      });
      return;
    }

    _pendingIdempotencyKey ??=
        (widget.idempotencyKeyGenerator?.call() ?? UgymUuid.v4());

    setState(() {
      _submitting = true;
      _clientIdError = null;
      _visitedAtError = null;
      _submitError = null;
    });

    try {
      final result = await widget.repository.registerManualVisit(
        clientId: clientId!,
        gymId: widget.gymId,
        visitedAt: visitedAtUtc,
        idempotencyKey: _pendingIdempotencyKey,
      );
      if (!mounted) {
        return;
      }
      _pendingIdempotencyKey = null;
      setState(() {
        _submitting = false;
      });
      widget.onSuccess?.call(result);
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _submitError = error.message;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _submitError = 'Не удалось отметить посещение. Повторите попытку.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final gymLabel = widget.gymName ?? 'Филиал №${widget.gymId}';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(UcraftSpacing.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ручная отметка визита',
              style: UcraftTypography.title.copyWith(color: colors.foreground),
            ),
            const SizedBox(height: UcraftSpacing.space1),
            Text(
              gymLabel,
              style: UcraftTypography.caption.copyWith(
                color: colors.foregroundSecondary,
              ),
            ),
            const SizedBox(height: UcraftSpacing.space4),
            UcraftTextField(
              controller: _clientIdController,
              label: 'ID клиента',
              hintText: 'Например, 42',
              keyboardType: TextInputType.number,
              errorText: _clientIdError,
              onChanged: (_) => _invalidateIdempotencyKey(),
            ),
            const SizedBox(height: UcraftSpacing.space3),
            CheckboxListTile(
              value: _backdated,
              contentPadding: EdgeInsets.zero,
              title: const Text('Отметить задним числом'),
              onChanged: (value) {
                _invalidateIdempotencyKey();
                setState(() {
                  _backdated = value ?? false;
                  if (!_backdated) {
                    _visitedAtError = null;
                  }
                });
              },
            ),
            if (_backdated) ...[
              const SizedBox(height: UcraftSpacing.space2),
              UcraftTextField(
                controller: _visitedAtController,
                label: 'Дата и время визита (+05:00)',
                hintText: '2026-11-16 14:30',
                errorText: _visitedAtError,
                onChanged: (_) => _invalidateIdempotencyKey(),
              ),
            ],
            if (_submitError != null) ...[
              const SizedBox(height: UcraftSpacing.space3),
              Text(
                _submitError!,
                style: UcraftTypography.bodyMedium.copyWith(
                  color: colors.destructive,
                ),
              ),
            ],
            const SizedBox(height: UcraftSpacing.space4),
            UcraftButton(
              label: 'Отметить посещение',
              fullWidth: true,
              isLoading: _submitting,
              onPressed: _submitting ? null : () => unawaited(_submit()),
            ),
          ],
        ),
      ),
    );
  }
}

final class _CancelVisitDialog extends StatefulWidget {
  const _CancelVisitDialog({required this.visit});

  final VisitRecord visit;

  @override
  State<_CancelVisitDialog> createState() => _CancelVisitDialogState();
}

final class _CancelVisitDialogState extends State<_CancelVisitDialog> {
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
      title: const Text('Отменить визит'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Визит №${widget.visit.id} (клиент №${widget.visit.clientId})'),
          const SizedBox(height: UcraftSpacing.space3),
          UcraftTextField(
            controller: _reasonController,
            label: 'Причина отмены',
            hintText: 'Например, ошибочная отметка',
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
            if (reason.isEmpty) {
              setState(() {
                _errorText = 'Укажите причину отмены.';
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

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../../../core/session/business_role.dart';
import '../../../core/session/business_session_controller.dart';
import '../domain/sales_and_requests_models.dart';

/// Queue of incoming client membership requests awaiting PaymentMark.
final class MembershipRequestsQueueTab extends StatefulWidget {
  const MembershipRequestsQueueTab({
    super.key,
    required this.repository,
    required this.sessionController,
    this.clock,
    this.idempotencyKeyGenerator,
  });

  final SalesAndRequestsRepository repository;
  final BusinessSessionController sessionController;
  final DateTime Function()? clock;
  final String Function()? idempotencyKeyGenerator;

  @override
  State<MembershipRequestsQueueTab> createState() =>
      _MembershipRequestsQueueTabState();
}

final class _MembershipRequestsQueueTabState
    extends State<MembershipRequestsQueueTab> {
  MembershipRequestStatus? _filterStatus = MembershipRequestStatus.pending;
  bool _loading = true;
  String? _errorMessage;
  int? _busyRequestId;
  List<MembershipRequestRecord> _requests = const <MembershipRequestRecord>[];
  final Map<String, String> _pendingPayKeys = <String, String>{};

  DateTime _nowUtc() => (widget.clock?.call() ?? DateTime.now()).toUtc();

  String _payKeySlot(int requestId, PaymentMethod method) =>
      '$requestId:${method.apiValue}';

  String _resolvePayKey(int requestId, PaymentMethod method) {
    final slot = _payKeySlot(requestId, method);
    return _pendingPayKeys.putIfAbsent(
      slot,
      () => widget.idempotencyKeyGenerator?.call() ?? UgymUuid.v4(),
    );
  }

  void _clearPayKeysForRequest(int requestId) {
    _pendingPayKeys.removeWhere((key, _) => key.startsWith('$requestId:'));
  }

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
      final list = await widget.repository.listMembershipRequests(
        status: _filterStatus,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _requests = list;
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
        _errorMessage = 'Не удалось загрузить заявки.';
      });
    }
  }

  Future<void> _openPayDialog(MembershipRequestRecord request) async {
    final paid = await showDialog<bool>(
      context: context,
      builder: (_) => _PayRequestDialog(
        requestId: request.id,
        repository: widget.repository,
        resolveIdempotencyKey: (method) => _resolvePayKey(request.id, method),
        onPaidSuccess: () => _clearPayKeysForRequest(request.id),
      ),
    );
    if (paid == true && mounted) {
      await _load();
    }
  }

  Future<void> _cancelRequest(MembershipRequestRecord request) async {
    final reason = await showDialog<String?>(
      context: context,
      builder: (_) => _CancelRequestDialog(requestId: request.id),
    );
    if (reason == null || !mounted) {
      return;
    }

    setState(() {
      _busyRequestId = request.id;
      _errorMessage = null;
    });

    try {
      await widget.repository.cancelMembershipRequest(
        requestId: request.id,
        reason: reason.isEmpty ? null : reason,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _busyRequestId = null;
      });
      await _load();
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyRequestId = null;
        _errorMessage = error.message;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyRequestId = null;
        _errorMessage = 'Не удалось отменить заявку.';
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
          BusinessPermission.manageMembershipRequestsAndSales,
        );
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
                  'Заявки на абонементы',
                  style: UcraftTypography.title.copyWith(
                    color: colors.foreground,
                  ),
                ),
                UcraftButton(
                  label: 'Обновить',
                  variant: UcraftButtonVariant.secondary,
                  onPressed: _loading ? null : () => unawaited(_load()),
                ),
              ],
            ),
            const SizedBox(height: UcraftSpacing.space2),
            Wrap(
              spacing: UcraftSpacing.space2,
              runSpacing: UcraftSpacing.space2,
              children: [
                for (final status in MembershipRequestStatus.values)
                  UcraftButton(
                    label: _statusLabel(status),
                    variant: _filterStatus == status
                        ? UcraftButtonVariant.primary
                        : UcraftButtonVariant.secondary,
                    onPressed: () {
                      setState(() {
                        _filterStatus = status;
                      });
                      unawaited(_load());
                    },
                  ),
              ],
            ),
            if (_errorMessage != null && _requests.isNotEmpty) ...[
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
              const UcraftLoadingState(message: 'Загружаем заявки...')
            else if (_errorMessage != null && _requests.isEmpty)
              UcraftErrorState(
                title: 'Ошибка загрузки',
                message: _errorMessage!,
                onRetry: () => unawaited(_load()),
              )
            else if (_requests.isEmpty)
              const UcraftEmptyState(
                title: 'Заявок нет',
                description: 'Новые заявки из приложения uGym появятся здесь.',
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final req in _requests) ...[
                    _RequestCard(
                      request: req,
                      expiresLabel: _formatExpiry(req.expiresAt, nowUtc),
                      canAct:
                          canMutate &&
                          req.status == MembershipRequestStatus.pending,
                      isBusy: _busyRequestId == req.id,
                      onPay: () => unawaited(_openPayDialog(req)),
                      onCancel: () => unawaited(_cancelRequest(req)),
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

  String _statusLabel(MembershipRequestStatus status) {
    return switch (status) {
      MembershipRequestStatus.pending => 'Ожидают',
      MembershipRequestStatus.paid => 'Оплачены',
      MembershipRequestStatus.cancelled => 'Отменены',
      MembershipRequestStatus.expired => 'Истекли',
    };
  }

  String _formatExpiry(DateTime expiresAt, DateTime nowUtc) {
    final diff = expiresAt.toUtc().difference(nowUtc);
    if (diff.isNegative) {
      return 'срок истёк';
    }
    final hours = diff.inHours;
    final mins = diff.inMinutes.remainder(60);
    return 'осталось $hours ч $mins м';
  }
}

final class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.expiresLabel,
    required this.canAct,
    required this.isBusy,
    required this.onPay,
    required this.onCancel,
  });

  final MembershipRequestRecord request;
  final String expiresLabel;
  final bool canAct;
  final bool isBusy;
  final VoidCallback onPay;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    return UcraftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Заявка №${request.id} • Тариф №${request.membershipTypeId}',
                  style: UcraftTypography.bodyMedium.copyWith(
                    color: colors.foreground,
                  ),
                ),
              ),
              Text(
                expiresLabel,
                style: UcraftTypography.caption.copyWith(
                  color: colors.foregroundSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: UcraftSpacing.space1),
          Text(
            request.clientId != null
                ? 'Клиент №${request.clientId} • Зал №${request.gymId}'
                : 'Пользователь №${request.userId} • Зал №${request.gymId}',
            style: UcraftTypography.caption.copyWith(
              color: colors.foregroundSecondary,
            ),
          ),
          if (canAct) ...[
            const SizedBox(height: UcraftSpacing.space3),
            Wrap(
              spacing: UcraftSpacing.space2,
              runSpacing: UcraftSpacing.space2,
              alignment: WrapAlignment.end,
              children: [
                UcraftButton(
                  label: 'Отменить заявку',
                  variant: UcraftButtonVariant.secondary,
                  isLoading: isBusy,
                  onPressed: isBusy ? null : onCancel,
                ),
                UcraftButton(
                  label: 'Принять оплату',
                  isLoading: isBusy,
                  onPressed: isBusy ? null : onPay,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

final class _PayRequestDialog extends StatefulWidget {
  const _PayRequestDialog({
    required this.requestId,
    required this.repository,
    required this.resolveIdempotencyKey,
    required this.onPaidSuccess,
  });

  final int requestId;
  final SalesAndRequestsRepository repository;
  final String Function(PaymentMethod method) resolveIdempotencyKey;
  final VoidCallback onPaidSuccess;

  @override
  State<_PayRequestDialog> createState() => _PayRequestDialogState();
}

final class _PayRequestDialogState extends State<_PayRequestDialog> {
  PaymentMethod _method = PaymentMethod.cash;
  bool _submitting = false;
  String? _errorText;

  Future<void> _confirm() async {
    if (_submitting) {
      return;
    }
    final key = widget.resolveIdempotencyKey(_method);
    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      await widget.repository.payMembershipRequest(
        requestId: widget.requestId,
        paymentMethod: _method,
        idempotencyKey: key,
      );
      if (!mounted) {
        return;
      }
      widget.onPaidSuccess();
      Navigator.of(context).pop(true);
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _errorText = error.message;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _errorText = 'Ошибка подтверждения оплаты. Повторите попытку.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    return AlertDialog(
      title: Text('Оплата заявки №${widget.requestId}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: UcraftSpacing.space2,
            runSpacing: UcraftSpacing.space2,
            children: [
              for (final method in PaymentMethod.values)
                UcraftButton(
                  label: paymentMethodLabel(method),
                  variant: _method == method
                      ? UcraftButtonVariant.primary
                      : UcraftButtonVariant.secondary,
                  onPressed: _submitting
                      ? null
                      : () {
                          setState(() {
                            _method = method;
                          });
                        },
                ),
            ],
          ),
          if (_errorText != null) ...[
            const SizedBox(height: UcraftSpacing.space3),
            Text(
              _errorText!,
              style: UcraftTypography.caption.copyWith(
                color: colors.destructive,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Назад'),
        ),
        UcraftButton(
          label: 'Подтвердить оплату',
          isLoading: _submitting,
          onPressed: _submitting ? null : () => unawaited(_confirm()),
        ),
      ],
    );
  }
}

final class _CancelRequestDialog extends StatefulWidget {
  const _CancelRequestDialog({required this.requestId});

  final int requestId;

  @override
  State<_CancelRequestDialog> createState() => _CancelRequestDialogState();
}

final class _CancelRequestDialogState extends State<_CancelRequestDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Отменить заявку №${widget.requestId}'),
      content: UcraftTextField(
        controller: _reasonController,
        label: 'Причина (необязательно)',
        hintText: 'До 255 символов',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Назад'),
        ),
        UcraftButton(
          label: 'Подтвердить',
          variant: UcraftButtonVariant.destructive,
          onPressed: () =>
              Navigator.of(context).pop(_reasonController.text.trim()),
        ),
      ],
    );
  }
}

/// Company sales history with owner-only refund support.
final class SalesHistoryTab extends StatefulWidget {
  const SalesHistoryTab({
    super.key,
    required this.repository,
    required this.sessionController,
  });

  final SalesAndRequestsRepository repository;
  final BusinessSessionController sessionController;

  @override
  State<SalesHistoryTab> createState() => _SalesHistoryTabState();
}

final class _SalesHistoryTabState extends State<SalesHistoryTab> {
  bool _loading = true;
  String? _errorMessage;
  int? _refundingSaleId;
  List<SaleRecord> _sales = const <SaleRecord>[];

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
      final list = await widget.repository.listSales();
      if (!mounted) {
        return;
      }
      setState(() {
        _sales = list;
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
        _errorMessage = 'Не удалось загрузить историю продаж.';
      });
    }
  }

  Future<void> _refundSale(SaleRecord sale) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _RefundSaleDialog(saleId: sale.id),
    );
    if (reason == null || !mounted) {
      return;
    }

    setState(() {
      _refundingSaleId = sale.id;
      _errorMessage = null;
    });

    try {
      final updated = await widget.repository.refundSale(
        saleId: sale.id,
        reason: reason,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _refundingSaleId = null;
        _sales = _sales
            .map((item) => item.id == updated.id ? updated : item)
            .toList(growable: false);
      });
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _refundingSaleId = null;
        _errorMessage = error.message;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _refundingSaleId = null;
        _errorMessage = 'Не удалось оформить возврат.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sessionController,
      builder: (context, _) {
        final colors = context.ucraftColors;
        final canRefund = widget.sessionController.canMutate(
          BusinessPermission.refundSalesAndManageProducts,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'История продаж',
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
            if (_errorMessage != null && _sales.isNotEmpty) ...[
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
              const UcraftLoadingState(message: 'Загружаем продажи...')
            else if (_errorMessage != null && _sales.isEmpty)
              UcraftErrorState(
                title: 'Ошибка загрузки',
                message: _errorMessage!,
                onRetry: () => unawaited(_load()),
              )
            else if (_sales.isEmpty)
              const UcraftEmptyState(
                title: 'Продаж пока нет',
                description: 'Оформленные чеки кассы и оплаченные заявки появятся здесь.',
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final sale in _sales) ...[
                    _SaleCard(
                      sale: sale,
                      canRefund: canRefund && sale.status == SaleStatus.paid,
                      isRefunding: _refundingSaleId == sale.id,
                      onRefund: () => unawaited(_refundSale(sale)),
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

final class _SaleCard extends StatelessWidget {
  const _SaleCard({
    required this.sale,
    required this.canRefund,
    required this.isRefunding,
    required this.onRefund,
  });

  final SaleRecord sale;
  final bool canRefund;
  final bool isRefunding;
  final VoidCallback onRefund;

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final total = (sale.totalMinor / 100).toStringAsFixed(2);
    final isRefunded = sale.status == SaleStatus.refunded;
    final dateText = DateFormatter.formatDateTime(
      sale.paidAt,
      offset: DateFormatter.dushanbeOffset,
    );

    return UcraftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Чек №${sale.id} • $total ${sale.currency}',
                  style: UcraftTypography.bodyMedium.copyWith(
                    color: colors.foreground,
                  ),
                ),
              ),
              Text(
                isRefunded ? 'Возврат' : 'Оплачен',
                style: UcraftTypography.caption.copyWith(
                  color: isRefunded ? colors.destructive : colors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: UcraftSpacing.space1),
          Text(
            '${paymentMethodLabel(sale.paymentMethod)} • $dateText${sale.clientId != null ? ' • Клиент №${sale.clientId}' : ''}',
            style: UcraftTypography.caption.copyWith(
              color: colors.foregroundSecondary,
            ),
          ),
          if (isRefunded && sale.refundReason != null) ...[
            const SizedBox(height: UcraftSpacing.space2),
            Text(
              'Причина возврата: ${sale.refundReason}',
              style: UcraftTypography.caption.copyWith(
                color: colors.destructiveForeground,
              ),
            ),
          ],
          if (canRefund) ...[
            const SizedBox(height: UcraftSpacing.space3),
            Align(
              alignment: Alignment.centerRight,
              child: UcraftButton(
                label: 'Возврат',
                variant: UcraftButtonVariant.destructive,
                isLoading: isRefunding,
                onPressed: isRefunding ? null : onRefund,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

final class _RefundSaleDialog extends StatefulWidget {
  const _RefundSaleDialog({required this.saleId});

  final int saleId;

  @override
  State<_RefundSaleDialog> createState() => _RefundSaleDialogState();
}

final class _RefundSaleDialogState extends State<_RefundSaleDialog> {
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
      title: Text('Возврат чека №${widget.saleId}'),
      content: UcraftTextField(
        controller: _reasonController,
        label: 'Причина возврата',
        hintText: 'До 500 символов',
        errorText: _errorText,
        maxLines: 2,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Назад'),
        ),
        UcraftButton(
          label: 'Подтвердить возврат',
          variant: UcraftButtonVariant.destructive,
          onPressed: () {
            final reason = _reasonController.text.trim();
            if (reason.isEmpty || reason.length > 500) {
              setState(() {
                _errorText = 'Укажите причину возврата (1–500 символов).';
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

/// Localized display label for [PaymentMethod].
String paymentMethodLabel(PaymentMethod method) {
  return switch (method) {
    PaymentMethod.cash => 'Наличные',
    PaymentMethod.cardTerminal => 'Терминал',
    PaymentMethod.transfer => 'Перевод',
  };
}

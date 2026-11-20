import 'dart:async';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../../../core/l10n/business_localizations.dart';
import '../../../core/router/role_guard_and_banners.dart';
import '../../../core/session/business_role.dart';
import '../../../core/session/business_session_controller.dart';
import '../../../core/theme/business_typography.dart';
import '../../memberships/domain/memberships_models.dart';
import '../domain/sales_and_requests_models.dart';
import 'membership_requests_and_sales_tabs.dart';

/// POS checkout screen for selling memberships and products via PaymentMark.
final class PosCheckoutScreen extends StatefulWidget {
  const PosCheckoutScreen({
    super.key,
    required this.salesRepository,
    required this.membershipsRepository,
    this.sessionController,
    this.initialClientId,
    this.idempotencyKeyGenerator,
    this.onSaleCompleted,
  });

  final SalesAndRequestsRepository salesRepository;
  final MembershipsRepository membershipsRepository;
  final BusinessSessionController? sessionController;
  final int? initialClientId;
  final String Function()? idempotencyKeyGenerator;
  final void Function(SaleRecord sale)? onSaleCompleted;

  @override
  State<PosCheckoutScreen> createState() => _PosCheckoutScreenState();
}

final class _PosCheckoutScreenState extends State<PosCheckoutScreen> {
  late final TextEditingController _clientIdController;

  bool _loading = true;
  bool _submitting = false;
  String? _loadError;
  String? _submitError;
  String? _pendingKey;

  List<ProductItem> _products = const <ProductItem>[];
  List<MembershipType> _membershipTypes = const <MembershipType>[];
  final Map<int, int> _productQuantities = <int, int>{};
  final Set<int> _selectedTypeIds = <int>{};
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    _clientIdController = TextEditingController(
      text: widget.initialClientId?.toString() ?? '',
    );
    unawaited(_loadCatalog());
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final productsFuture = widget.salesRepository.listProducts(
        onlyActive: true,
      );
      final typesFuture = widget.membershipsRepository.listMembershipTypes(
        onlyActive: true,
      );
      final products = await productsFuture;
      final types = await typesFuture;
      if (!mounted) {
        return;
      }
      setState(() {
        _products = products;
        _membershipTypes = types;
        _loading = false;
      });
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadError = error.message;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadError = 'Не удалось загрузить каталог для кассы.';
      });
    }
  }

  int _totalMinor() {
    int sum = 0;
    for (final product in _products) {
      final qty = _productQuantities[product.id] ?? 0;
      sum += product.priceMinor * qty;
    }
    for (final type in _membershipTypes) {
      if (_selectedTypeIds.contains(type.id)) {
        sum += type.priceMinor;
      }
    }
    return sum;
  }

  String _currencyLabel() {
    if (_membershipTypes.isNotEmpty) {
      return _membershipTypes.first.currency;
    }
    if (_products.isNotEmpty) {
      return _products.first.currency;
    }
    return 'TJS';
  }

  bool get _isReadOnly => widget.sessionController?.isReadOnly ?? false;

  Future<void> _submit() async {
    if (_submitting || _isReadOnly) {
      return;
    }

    final productLines = _productQuantities.entries
        .where((e) => e.value > 0)
        .map((e) => SaleProductLineInput(productId: e.key, quantity: e.value))
        .toList(growable: false);
    final typeIds = _selectedTypeIds.toList(growable: false);

    if (productLines.isEmpty && typeIds.isEmpty) {
      setState(() {
        _submitError = 'Добавьте хотя бы один товар или абонемент.';
      });
      return;
    }

    final rawClientId = _clientIdController.text.trim();
    final int? clientId = rawClientId.isEmpty
        ? null
        : int.tryParse(rawClientId);
    if (rawClientId.isNotEmpty && (clientId == null || clientId <= 0)) {
      setState(() {
        _submitError = 'Укажите корректный ID клиента.';
      });
      return;
    }
    if (typeIds.isNotEmpty && clientId == null) {
      setState(() {
        _submitError = 'Для продажи абонемента укажите ID клиента.';
      });
      return;
    }

    _pendingKey ??= (widget.idempotencyKeyGenerator?.call() ?? UgymUuid.v4());

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final sale = await widget.salesRepository.registerSale(
        clientId: clientId,
        paymentMethod: _paymentMethod,
        products: productLines,
        membershipTypeIds: typeIds,
        idempotencyKey: _pendingKey,
      );
      if (!mounted) {
        return;
      }
      _pendingKey = null;
      setState(() {
        _submitting = false;
      });
      widget.onSaleCompleted?.call(sale);
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
        _submitError = 'Не удалось провести продажу. Повторите попытку.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.sessionController;
    if (session != null) {
      return ListenableBuilder(
        listenable: session,
        builder: (context, _) => _buildScaffold(context),
      );
    }
    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    final colors = context.ucraftColors;
    final strings = BusinessStringsScope.of(context);
    final total = strings.formatMoney(
      _totalMinor(),
      currency: _currencyLabel(),
    );
    final session = widget.sessionController;
    final isReadOnly = _isReadOnly;

    return Scaffold(
      appBar: AppBar(title: Text(strings.posTitle)),
      body: SafeArea(
        child: _loading
            ? UcraftLoadingState(message: strings.posLoadingCatalog)
            : _loadError != null
            ? UcraftErrorState(
                title: strings.posLoadErrorTitle,
                message: _loadError!,
                retryLabel: strings.retryLabel,
                onRetry: () => unawaited(_loadCatalog()),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(
                  UcraftSpacing.screenHorizontalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (session != null) ...[
                      SubscriptionReadOnlyBanner(controller: session),
                      if (isReadOnly)
                        const SizedBox(height: UcraftSpacing.space4),
                    ],
                    UcraftCard(
                      variant: UcraftCardVariant.highlight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            strings.posTitle.toUpperCase(),
                            style: UcraftTypography.overline.copyWith(
                              color: colors.foregroundMuted,
                            ),
                          ),
                          const SizedBox(height: UcraftSpacing.space1),
                          Text(
                            '${strings.posTotalPrefix}$total',
                            style: BusinessTypography.amountLarge.copyWith(
                              color: colors.foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: UcraftSpacing.space4),
                    UcraftTextField(
                      controller: _clientIdController,
                      label: strings.posClientIdLabel,
                      hintText: 'Например, 11',
                      keyboardType: TextInputType.number,
                      enabled: !isReadOnly && !_submitting,
                      onChanged: (_) => _pendingKey = null,
                    ),
                    const SizedBox(height: UcraftSpacing.sectionGap),
                    UcraftSectionHeader(title: strings.membershipsLabel),
                    const SizedBox(height: UcraftSpacing.space2),
                    if (_membershipTypes.isEmpty)
                      Text(
                        strings.posNoActivePlans,
                        style: UcraftTypography.caption.copyWith(
                          color: colors.foregroundSecondary,
                        ),
                      )
                    else
                      Wrap(
                        spacing: UcraftSpacing.space2,
                        runSpacing: UcraftSpacing.space2,
                        children: [
                          for (final type in _membershipTypes)
                            UcraftButton(
                              label:
                                  '${type.name} (${strings.formatMoney(type.priceMinor, currency: type.currency, alwaysShowDecimals: false)})',
                              variant: UcraftButtonVariant.secondary,
                              leadingIcon: _selectedTypeIds.contains(type.id)
                                  ? LucideIcons.circleCheck
                                  : null,
                              onPressed: () {
                                _pendingKey = null;
                                setState(() {
                                  if (_selectedTypeIds.contains(type.id)) {
                                    _selectedTypeIds.remove(type.id);
                                  } else {
                                    _selectedTypeIds.add(type.id);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    const SizedBox(height: UcraftSpacing.sectionGap),
                    UcraftSectionHeader(title: strings.subTabProducts),
                    const SizedBox(height: UcraftSpacing.space2),
                    if (_products.isEmpty)
                      Text(
                        strings.posNoActiveProducts,
                        style: UcraftTypography.caption.copyWith(
                          color: colors.foregroundSecondary,
                        ),
                      )
                    else
                      UcraftListSection(
                        children: [
                          for (final product in _products)
                            UcraftListRow(
                              title: product.name,
                              subtitle: strings.formatMoney(
                                product.priceMinor,
                                currency: product.currency,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: strings.posDecreaseQtyTooltip,
                                    onPressed:
                                        (_productQuantities[product.id] ?? 0) >
                                            0
                                        ? () {
                                            _pendingKey = null;
                                            setState(() {
                                              final current =
                                                  _productQuantities[product
                                                      .id] ??
                                                  0;
                                              _productQuantities[product.id] =
                                                  current - 1;
                                            });
                                          }
                                        : null,
                                    icon: const Icon(
                                      LucideIcons.minus,
                                      size: 20,
                                    ),
                                  ),
                                  Text(
                                    '${_productQuantities[product.id] ?? 0}',
                                    style: UcraftTypography.mono,
                                  ),
                                  IconButton(
                                    tooltip: strings.posIncreaseQtyTooltip,
                                    onPressed: () {
                                      _pendingKey = null;
                                      setState(() {
                                        final current =
                                            _productQuantities[product.id] ?? 0;
                                        _productQuantities[product.id] =
                                            current + 1;
                                      });
                                    },
                                    icon: const Icon(
                                      LucideIcons.plus,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: UcraftSpacing.sectionGap),
                    Text(
                      strings.posPaymentMethodLabel,
                      style: UcraftTypography.bodyMedium.copyWith(
                        color: colors.foreground,
                      ),
                    ),
                    const SizedBox(height: UcraftSpacing.space2),
                    UcraftSegmentedTabs<PaymentMethod>(
                      items: [
                        for (final method in PaymentMethod.values)
                          UcraftSegmentedTabItem(
                            value: method,
                            label: paymentMethodLabel(method, strings: strings),
                          ),
                      ],
                      selected: _paymentMethod,
                      enabled: !isReadOnly && !_submitting,
                      onSelected: (method) {
                        _pendingKey = null;
                        setState(() {
                          _paymentMethod = method;
                        });
                      },
                    ),
                    if (_submitError != null) ...[
                      const SizedBox(height: UcraftSpacing.space2),
                      Text(
                        _submitError!,
                        style: UcraftTypography.bodyMedium.copyWith(
                          color: colors.destructive,
                        ),
                      ),
                    ],
                    const SizedBox(height: UcraftSpacing.space4),
                    UcraftButton(
                      label: strings.posSubmitSaleButton,
                      fullWidth: true,
                      isLoading: _submitting,
                      onPressed: _submitting || isReadOnly
                          ? null
                          : () => unawaited(_submit()),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Warehouse products list with owner-only create and stock/active edits.
final class ProductsScreen extends StatefulWidget {
  const ProductsScreen({
    super.key,
    required this.repository,
    required this.sessionController,
  });

  final SalesAndRequestsRepository repository;
  final BusinessSessionController sessionController;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

final class _ProductsScreenState extends State<ProductsScreen> {
  bool _loading = true;
  String? _errorMessage;
  List<ProductItem> _products = const <ProductItem>[];

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
      final list = await widget.repository.listProducts();
      if (!mounted) {
        return;
      }
      setState(() {
        _products = list;
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
        _errorMessage = 'Не удалось загрузить товары.';
      });
    }
  }

  Future<void> _openCreateProduct() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _CreateProductDialog(repository: widget.repository),
    );
    if (created == true && mounted) {
      await _load();
    }
  }

  Future<void> _openEditProduct(ProductItem product) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _EditProductDialog(product: product, repository: widget.repository),
    );
    if (updated == true && mounted) {
      await _load();
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
          BusinessPermission.refundSalesAndManageProducts,
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
                  strings.productsTitle,
                  style: UcraftTypography.title.copyWith(
                    color: colors.foreground,
                  ),
                ),
                if (canManage)
                  UcraftButton(
                    label: strings.productsAddButton,
                    leadingIcon: LucideIcons.plus,
                    variant: UcraftButtonVariant.secondary,
                    onPressed: () => unawaited(_openCreateProduct()),
                  ),
              ],
            ),
            const SizedBox(height: UcraftSpacing.space3),
            if (_loading)
              const UcraftLoadingState(isSkeleton: true, skeletonCount: 4)
            else if (_errorMessage != null && _products.isEmpty)
              UcraftErrorState(
                icon: LucideIcons.circleAlert,
                title: strings.posLoadErrorTitle,
                message: _errorMessage!,
                retryLabel: strings.retryLabel,
                onRetry: () => unawaited(_load()),
              )
            else if (_products.isEmpty)
              UcraftEmptyState(
                icon: LucideIcons.package,
                title: strings.productsEmptyTitle,
                description: strings.productsEmptyDesc,
              )
            else
              UcraftListSection(
                children: [
                  for (final product in _products)
                    UcraftListRow(
                      title: product.name,
                      subtitle:
                          '${strings.formatMoney(product.priceMinor, currency: product.currency)} • ${strings.productStockLabel}: ${product.stockQuantity ?? 0}',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          UcraftStatusPill(
                            icon: product.isActive
                                ? LucideIcons.circleCheck
                                : LucideIcons.archive,
                            label: product.isActive
                                ? strings.planStatusActive
                                : strings.planStatusArchived,
                            tone: product.isActive
                                ? UcraftStatusTone.success
                                : UcraftStatusTone.neutral,
                          ),
                          if (canManage) ...[
                            const SizedBox(width: UcraftSpacing.space2),
                            UcraftButton(
                              label: strings.productEditButton,
                              variant: UcraftButtonVariant.secondary,
                              onPressed: () =>
                                  unawaited(_openEditProduct(product)),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

final class _CreateProductDialog extends StatefulWidget {
  const _CreateProductDialog({required this.repository});

  final SalesAndRequestsRepository repository;

  @override
  State<_CreateProductDialog> createState() => _CreateProductDialogState();
}

final class _CreateProductDialogState extends State<_CreateProductDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '0');

  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(
      _priceController.text.trim().replaceAll(',', '.'),
    );
    final stock = int.tryParse(_stockController.text.trim());
    if (name.isEmpty ||
        price == null ||
        price < 0 ||
        stock == null ||
        stock < 0) {
      setState(() {
        _errorText = 'Проверьте название, цену и остаток.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      await widget.repository.createProduct(
        name: name,
        priceMinor: (price * 100).round(),
        stockQuantity: stock,
      );
      if (!mounted) {
        return;
      }
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
        _errorText = 'Не удалось создать товар.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final strings = BusinessStringsScope.of(context);
    return AlertDialog(
      title: Text(strings.productNewTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UcraftTextField(
            controller: _nameController,
            label: strings.planNameLabel,
          ),
          const SizedBox(height: UcraftSpacing.space2),
          UcraftTextField(
            controller: _priceController,
            label: strings.productPriceLabel,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: UcraftSpacing.space2),
          UcraftTextField(
            controller: _stockController,
            label: strings.productStockLabel,
            keyboardType: TextInputType.number,
          ),
          if (_errorText != null) ...[
            const SizedBox(height: UcraftSpacing.space2),
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
          child: Text(strings.cancelLabel),
        ),
        UcraftButton(
          label: strings.productCreateButton,
          isLoading: _submitting,
          onPressed: _submitting ? null : () => unawaited(_submit()),
        ),
      ],
    );
  }
}

final class _EditProductDialog extends StatefulWidget {
  const _EditProductDialog({required this.product, required this.repository});

  final ProductItem product;
  final SalesAndRequestsRepository repository;

  @override
  State<_EditProductDialog> createState() => _EditProductDialogState();
}

final class _EditProductDialogState extends State<_EditProductDialog> {
  late final TextEditingController _stockController;
  late bool _isActive;
  bool _submitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _stockController = TextEditingController(
      text: (widget.product.stockQuantity ?? 0).toString(),
    );
    _isActive = widget.product.isActive;
  }

  @override
  void dispose() {
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final stock = int.tryParse(_stockController.text.trim());
    if (stock == null || stock < 0) {
      setState(() {
        _errorText = 'Остаток должен быть 0 или больше.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      await widget.repository.updateProduct(
        productId: widget.product.id,
        isActive: _isActive,
        stockQuantity: stock,
      );
      if (!mounted) {
        return;
      }
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
        _errorText = 'Не удалось обновить товар.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final strings = BusinessStringsScope.of(context);
    return AlertDialog(
      title: Text(widget.product.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UcraftTextField(
            controller: _stockController,
            label: strings.productStockLabel,
            keyboardType: TextInputType.number,
          ),
          CheckboxListTile(
            value: _isActive,
            contentPadding: EdgeInsets.zero,
            title: Text(strings.productActiveAtPosCheckbox),
            onChanged: (value) {
              setState(() {
                _isActive = value ?? true;
              });
            },
          ),
          if (_errorText != null)
            Text(
              _errorText!,
              style: UcraftTypography.caption.copyWith(
                color: colors.destructive,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(strings.cancelLabel),
        ),
        UcraftButton(
          label: strings.saveLabel,
          isLoading: _submitting,
          onPressed: _submitting ? null : () => unawaited(_save()),
        ),
      ],
    );
  }
}

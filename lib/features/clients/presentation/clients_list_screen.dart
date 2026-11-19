import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../../../core/l10n/business_localizations.dart';
import '../../../core/session/business_role.dart';
import '../../../core/session/business_session_controller.dart';
import '../domain/clients_models.dart';

/// CRM screen for searching, creating, and (for owners) merging clients.
final class ClientsListScreen extends StatefulWidget {
  const ClientsListScreen({
    super.key,
    required this.repository,
    required this.sessionController,
    this.onOpenClient,
  });

  final ClientsRepository repository;
  final BusinessSessionController sessionController;
  final void Function(ClientSummary client)? onOpenClient;

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

final class _ClientsListScreenState extends State<ClientsListScreen> {
  final _searchController = TextEditingController();

  bool _loading = true;
  bool _loadingMore = false;
  String? _errorMessage;
  List<ClientSummary> _clients = const <ClientSummary>[];
  int _page = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadClients(reset: true));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients({required bool reset}) async {
    final targetPage = reset ? 1 : _page + 1;
    setState(() {
      if (reset) {
        _loading = true;
      } else {
        _loadingMore = true;
      }
      _errorMessage = null;
    });

    try {
      final result = await widget.repository.listClients(
        search: _searchController.text,
        page: targetPage,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _clients = reset ? result.items : [..._clients, ...result.items];
        _page = result.page;
        _hasMore = result.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadingMore = false;
        _errorMessage = error.message;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadingMore = false;
        _errorMessage = 'Не удалось загрузить список клиентов.';
      });
    }
  }

  Future<void> _openCreateClient() async {
    final createdOrOpened = await showModalBottomSheet<ClientSummary?>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: CreateClientSheet(
            repository: widget.repository,
            onOpenExistingClient: (existing) {
              Navigator.of(sheetContext).pop(existing);
            },
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }
    if (createdOrOpened != null) {
      widget.onOpenClient?.call(createdOrOpened);
      return;
    }
    await _loadClients(reset: true);
  }

  Future<void> _openMergeDialog() async {
    final merged = await showDialog<bool>(
      context: context,
      builder: (_) => _MergeClientsDialog(repository: widget.repository),
    );
    if (merged == true && mounted) {
      await _loadClients(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sessionController,
      builder: (context, _) {
        final colors = context.ucraftColors;
        final strings = BusinessStringsScope.of(context);
        final canMutate = widget.sessionController.canMutate(
          BusinessPermission.manageClientsCrm,
        );
        final canMerge = widget.sessionController.canMutate(
          BusinessPermission.mergeDuplicateClients,
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
                  strings.subTabClients,
                  style: UcraftTypography.title.copyWith(
                    color: colors.foreground,
                  ),
                ),
                Wrap(
                  spacing: UcraftSpacing.space2,
                  children: [
                    if (canMerge)
                      UcraftButton(
                        label: strings.clientsMergeDuplicatesButton,
                        variant: UcraftButtonVariant.secondary,
                        onPressed: () => unawaited(_openMergeDialog()),
                      ),
                    UcraftButton(
                      label: strings.clientsAddButton,
                      onPressed: canMutate
                          ? () => unawaited(_openCreateClient())
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: UcraftSpacing.space3),
            Row(
              children: [
                Expanded(
                  child: UcraftTextField(
                    controller: _searchController,
                    label: strings.clientsSearchLabel,
                    hintText: strings.clientsSearchHint,
                    onSubmitted: (_) => unawaited(_loadClients(reset: true)),
                  ),
                ),
                const SizedBox(width: UcraftSpacing.space2),
                UcraftButton(
                  label: strings.clientsFindButton,
                  variant: UcraftButtonVariant.secondary,
                  onPressed: _loading
                      ? null
                      : () => unawaited(_loadClients(reset: true)),
                ),
              ],
            ),
            const SizedBox(height: UcraftSpacing.space3),
            if (_loading)
              UcraftLoadingState(message: strings.clientsLoading)
            else if (_errorMessage != null && _clients.isEmpty)
              UcraftErrorState(
                title: strings.posLoadErrorTitle,
                message: _errorMessage!,
                retryLabel: strings.retryLabel,
                onRetry: () => unawaited(_loadClients(reset: true)),
              )
            else if (_clients.isEmpty)
              UcraftEmptyState(
                title: strings.clientsEmptyTitle,
                description: strings.clientsEmptyDesc,
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final client in _clients) ...[
                    _ClientCard(
                      client: client,
                      onTap: widget.onOpenClient == null
                          ? null
                          : () => widget.onOpenClient!(client),
                    ),
                    const SizedBox(height: UcraftSpacing.space3),
                  ],
                  if (_hasMore)
                    UcraftButton(
                      label: strings.clientsShowMoreButton,
                      variant: UcraftButtonVariant.secondary,
                      isLoading: _loadingMore,
                      fullWidth: true,
                      onPressed: _loadingMore
                          ? null
                          : () => unawaited(_loadClients(reset: false)),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

final class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.client, this.onTap});

  final ClientSummary client;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final strings = BusinessStringsScope.of(context);
    return UcraftCard(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${client.name} (#${client.id})',
                    style: UcraftTypography.bodyMedium.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                ),
                Text(
                  client.linked
                      ? strings.clientLinkedBadge
                      : strings.clientOfflineBadge,
                  style: UcraftTypography.caption.copyWith(
                    color: client.linked
                        ? colors.success
                        : colors.foregroundSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UcraftSpacing.space1),
            Text(
              client.email != null
                  ? '${client.phone} • ${client.email}'
                  : client.phone,
              style: UcraftTypography.caption.copyWith(
                color: colors.foregroundSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal form to register a new client in the gym CRM.
final class CreateClientSheet extends StatefulWidget {
  const CreateClientSheet({
    super.key,
    required this.repository,
    this.onCreated,
    this.onOpenExistingClient,
  });

  final ClientsRepository repository;
  final void Function(int clientId)? onCreated;
  final void Function(ClientSummary client)? onOpenExistingClient;

  @override
  State<CreateClientSheet> createState() => _CreateClientSheetState();
}

final class _CreateClientSheetState extends State<CreateClientSheet> {
  static final RegExp _phoneRegex = RegExp(r'^\+?[0-9]{9,15}$');

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _submitting = false;
  bool _openingExisting = false;
  bool _phoneConflict = false;
  String? _nameError;
  String? _phoneError;
  String? _submitError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    String? nameError;
    if (name.isEmpty || name.length > 255) {
      nameError = 'Введите имя клиента (до 255 символов).';
    }

    String? phoneError;
    if (!_phoneRegex.hasMatch(phone)) {
      phoneError = 'Телефон должен содержать 9–15 цифр.';
    }

    if (nameError != null || phoneError != null) {
      setState(() {
        _nameError = nameError;
        _phoneError = phoneError;
        _submitError = null;
        _phoneConflict = false;
      });
      return;
    }

    setState(() {
      _submitting = true;
      _nameError = null;
      _phoneError = null;
      _submitError = null;
      _phoneConflict = false;
    });

    try {
      final id = await widget.repository.createClient(
        name: name,
        phone: phone,
        email: email.isEmpty ? null : email,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
      });
      widget.onCreated?.call(id);
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _submitError = error.message;
        _phoneConflict = error.code == 'CLIENT_PHONE_EXISTS';
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _submitError = 'Не удалось создать клиента.';
        _phoneConflict = false;
      });
    }
  }

  Future<void> _openExistingByPhone() async {
    if (_openingExisting) {
      return;
    }
    setState(() {
      _openingExisting = true;
    });
    try {
      final page = await widget.repository.listClients(
        search: _phoneController.text.trim(),
        perPage: 5,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _openingExisting = false;
      });
      if (page.items.isNotEmpty) {
        widget.onOpenExistingClient?.call(page.items.first);
      } else {
        setState(() {
          _submitError = 'Не удалось найти карточку по этому номеру.';
        });
      }
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _openingExisting = false;
        _submitError = 'Не удалось открыть существующую карточку.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final strings = BusinessStringsScope.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(UcraftSpacing.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.clientNewSheetTitle,
              style: UcraftTypography.title.copyWith(color: colors.foreground),
            ),
            const SizedBox(height: UcraftSpacing.space4),
            UcraftTextField(
              controller: _nameController,
              label: strings.clientNameLabel,
              errorText: _nameError,
            ),
            const SizedBox(height: UcraftSpacing.space3),
            UcraftTextField(
              controller: _phoneController,
              label: strings.clientPhoneLabel,
              hintText: '+992900001122',
              keyboardType: TextInputType.phone,
              errorText: _phoneError,
            ),
            const SizedBox(height: UcraftSpacing.space3),
            UcraftTextField(
              controller: _emailController,
              label: strings.clientEmailOptionalLabel,
              hintText: 'client@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: UcraftSpacing.space2),
            Text(
              strings.clientAutoLinkHint,
              style: UcraftTypography.caption.copyWith(
                color: colors.foregroundSecondary,
              ),
            ),
            if (_submitError != null) ...[
              const SizedBox(height: UcraftSpacing.space3),
              Text(
                _submitError!,
                style: UcraftTypography.bodyMedium.copyWith(
                  color: colors.destructive,
                ),
              ),
            ],
            if (_phoneConflict && widget.onOpenExistingClient != null) ...[
              const SizedBox(height: UcraftSpacing.space3),
              UcraftButton(
                label: strings.clientOpenExistingButton,
                variant: UcraftButtonVariant.secondary,
                fullWidth: true,
                isLoading: _openingExisting,
                onPressed: _openingExisting
                    ? null
                    : () => unawaited(_openExistingByPhone()),
              ),
            ],
            const SizedBox(height: UcraftSpacing.space4),
            UcraftButton(
              label: strings.clientCreateButton,
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

final class _MergeClientsDialog extends StatefulWidget {
  const _MergeClientsDialog({required this.repository});

  final ClientsRepository repository;

  @override
  State<_MergeClientsDialog> createState() => _MergeClientsDialogState();
}

final class _MergeClientsDialogState extends State<_MergeClientsDialog> {
  final _sourceController = TextEditingController();
  final _targetController = TextEditingController();

  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _sourceController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndMerge() async {
    final sourceId = int.tryParse(_sourceController.text.trim());
    final targetId = int.tryParse(_targetController.text.trim());
    if (sourceId == null ||
        targetId == null ||
        sourceId <= 0 ||
        targetId <= 0 ||
        sourceId == targetId) {
      setState(() {
        _errorText = 'Укажите два разных корректных ID клиента.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      await widget.repository.mergeClients(
        sourceId: sourceId,
        targetId: targetId,
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
        _errorText = 'Не удалось объединить карточки.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final strings = BusinessStringsScope.of(context);
    return AlertDialog(
      title: Text(strings.clientsMergeDuplicatesButton),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(strings.clientMergeDesc),
          const SizedBox(height: UcraftSpacing.space3),
          UcraftTextField(
            controller: _sourceController,
            label: 'ID (source_id)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: UcraftSpacing.space3),
          UcraftTextField(
            controller: _targetController,
            label: 'ID (target_id)',
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
          label: strings.clientMergeConfirmButton,
          variant: UcraftButtonVariant.destructive,
          isLoading: _submitting,
          onPressed: _submitting ? null : () => unawaited(_confirmAndMerge()),
        ),
      ],
    );
  }
}

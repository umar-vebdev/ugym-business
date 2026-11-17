import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../../../core/session/business_role.dart';
import '../../../core/session/business_session_controller.dart';
import '../domain/storefront_and_staff_models.dart';

/// Owner-only screen for managing company staff by verified email.
final class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({
    super.key,
    required this.repository,
    required this.sessionController,
  });

  final StorefrontAndStaffRepository repository;
  final BusinessSessionController sessionController;

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

final class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final _emailController = TextEditingController();

  StaffRoleValue _inviteRole = StaffRoleValue.admin;
  bool _loading = true;
  bool _inviting = false;
  bool _showOnboardingHint = false;
  int? _busyStaffId;
  String? _errorMessage;
  String? _inviteError;
  List<StaffMember> _staff = const <StaffMember>[];

  @override
  void initState() {
    super.initState();
    if (widget.sessionController.canView(BusinessPermission.manageStaff)) {
      unawaited(_load());
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final list = await widget.repository.listStaff();
      if (!mounted) {
        return;
      }
      setState(() {
        _staff = list;
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
        _errorMessage = 'Не удалось загрузить список сотрудников.';
      });
    }
  }

  Future<void> _invite() async {
    if (_inviting) {
      return;
    }
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _inviteError = 'Введите корректный email сотрудника.';
        _showOnboardingHint = false;
      });
      return;
    }

    setState(() {
      _inviting = true;
      _inviteError = null;
      _showOnboardingHint = false;
    });

    try {
      final added = await widget.repository.inviteStaff(
        email: email,
        role: _inviteRole,
      );
      if (!mounted) {
        return;
      }
      _emailController.clear();
      setState(() {
        _inviting = false;
        _staff = [..._staff, added];
      });
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      final isNotReady = error.statusCode == 400 || error.code == 'BAD_REQUEST';
      setState(() {
        _inviting = false;
        _inviteError = error.message;
        _showOnboardingHint = isNotReady;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _inviting = false;
        _inviteError = 'Не удалось добавить сотрудника.';
      });
    }
  }

  Future<void> _toggleRole(StaffMember member) async {
    if (_busyStaffId != null || member.role == StaffRoleValue.owner) {
      return;
    }
    final nextRole = member.role == StaffRoleValue.admin
        ? StaffRoleValue.trainer
        : StaffRoleValue.admin;

    setState(() {
      _busyStaffId = member.id;
      _errorMessage = null;
    });

    try {
      final updated = await widget.repository.updateStaffRole(
        staffId: member.id,
        role: nextRole,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _busyStaffId = null;
        _staff = _staff
            .map((s) => s.id == updated.id ? updated : s)
            .toList(growable: false);
      });
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyStaffId = null;
        _errorMessage = error.message;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyStaffId = null;
        _errorMessage = 'Не удалось изменить роль.';
      });
    }
  }

  Future<void> _deleteMember(StaffMember member) async {
    if (_busyStaffId != null || member.role == StaffRoleValue.owner) {
      return;
    }

    setState(() {
      _busyStaffId = member.id;
      _errorMessage = null;
    });

    try {
      await widget.repository.deleteStaff(staffId: member.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _busyStaffId = null;
        _staff = _staff.where((s) => s.id != member.id).toList(growable: false);
      });
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyStaffId = null;
        _errorMessage = error.message;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _busyStaffId = null;
        _errorMessage = 'Не удалось удалить сотрудника.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sessionController,
      builder: (context, _) {
        final colors = context.ucraftColors;
        if (!widget.sessionController.canView(BusinessPermission.manageStaff)) {
          return const UcraftEmptyState(
            title: 'Недостаточно прав',
            description: 'Управление штатом доступно только владельцу.',
          );
        }

        final canMutate = widget.sessionController.canMutate(
          BusinessPermission.manageStaff,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UcraftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Добавить сотрудника',
                    style: UcraftTypography.title.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: UcraftSpacing.space3),
                  UcraftTextField(
                    controller: _emailController,
                    label: 'Email сотрудника',
                    hintText: 'staff@gym.tj',
                    keyboardType: TextInputType.emailAddress,
                    enabled: canMutate && !_inviting,
                  ),
                  const SizedBox(height: UcraftSpacing.space2),
                  Wrap(
                    spacing: UcraftSpacing.space2,
                    children: [
                      UcraftButton(
                        label: 'Администратор',
                        variant: _inviteRole == StaffRoleValue.admin
                            ? UcraftButtonVariant.primary
                            : UcraftButtonVariant.secondary,
                        onPressed: canMutate && !_inviting
                            ? () => setState(
                                () => _inviteRole = StaffRoleValue.admin,
                              )
                            : null,
                      ),
                      UcraftButton(
                        label: 'Тренер',
                        variant: _inviteRole == StaffRoleValue.trainer
                            ? UcraftButtonVariant.primary
                            : UcraftButtonVariant.secondary,
                        onPressed: canMutate && !_inviting
                            ? () => setState(
                                () => _inviteRole = StaffRoleValue.trainer,
                              )
                            : null,
                      ),
                    ],
                  ),
                  if (_inviteError != null) ...[
                    const SizedBox(height: UcraftSpacing.space2),
                    Text(
                      _inviteError!,
                      style: UcraftTypography.bodyMedium.copyWith(
                        color: colors.destructive,
                      ),
                    ),
                  ],
                  if (_showOnboardingHint) ...[
                    const SizedBox(height: UcraftSpacing.space2),
                    Text(
                      'Памятка: сотрудник должен установить uGym/uGym Business, зарегистрироваться с этим email и ввести OTP-код подтверждения.',
                      style: UcraftTypography.caption.copyWith(
                        color: colors.foregroundSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: UcraftSpacing.space3),
                  UcraftButton(
                    label: 'Добавить в штат',
                    fullWidth: true,
                    isLoading: _inviting,
                    onPressed: canMutate && !_inviting
                        ? () => unawaited(_invite())
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: UcraftSpacing.space4),
            Text(
              'Штат компании',
              style: UcraftTypography.title.copyWith(color: colors.foreground),
            ),
            if (_errorMessage != null && _staff.isNotEmpty) ...[
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
              const UcraftLoadingState(message: 'Загружаем штат...')
            else if (_errorMessage != null && _staff.isEmpty)
              UcraftErrorState(
                title: 'Ошибка загрузки',
                message: _errorMessage!,
                onRetry: () => unawaited(_load()),
              )
            else if (_staff.isEmpty)
              const UcraftEmptyState(
                title: 'Сотрудников нет',
                description: 'Добавьте администратора или тренера по email.',
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final member in _staff) ...[
                    _StaffCard(
                      member: member,
                      canMutate:
                          canMutate && member.role != StaffRoleValue.owner,
                      isBusy: _busyStaffId == member.id,
                      onToggleRole: () => unawaited(_toggleRole(member)),
                      onDelete: () => unawaited(_deleteMember(member)),
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

final class _StaffCard extends StatelessWidget {
  const _StaffCard({
    required this.member,
    required this.canMutate,
    required this.isBusy,
    required this.onToggleRole,
    required this.onDelete,
  });

  final StaffMember member;
  final bool canMutate;
  final bool isBusy;
  final VoidCallback onToggleRole;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final displayName =
        member.name ?? member.email ?? 'Пользователь №${member.userId}';
    final roleLabel = switch (member.role) {
      StaffRoleValue.owner => 'Владелец',
      StaffRoleValue.admin => 'Администратор',
      StaffRoleValue.trainer => 'Тренер',
    };

    return UcraftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: UcraftTypography.bodyMedium.copyWith(
                    color: colors.foreground,
                  ),
                ),
              ),
              Text(
                roleLabel,
                style: UcraftTypography.caption.copyWith(
                  color: colors.foregroundSecondary,
                ),
              ),
            ],
          ),
          if (member.email != null) ...[
            const SizedBox(height: UcraftSpacing.space1),
            Text(
              member.email!,
              style: UcraftTypography.caption.copyWith(
                color: colors.foregroundSecondary,
              ),
            ),
          ],
          if (canMutate) ...[
            const SizedBox(height: UcraftSpacing.space3),
            Wrap(
              spacing: UcraftSpacing.space2,
              runSpacing: UcraftSpacing.space2,
              alignment: WrapAlignment.end,
              children: [
                UcraftButton(
                  label: member.role == StaffRoleValue.admin
                      ? 'Сделать тренером'
                      : 'Сделать админом',
                  variant: UcraftButtonVariant.secondary,
                  isLoading: isBusy,
                  onPressed: isBusy ? null : onToggleRole,
                ),
                UcraftButton(
                  label: 'Удалить',
                  variant: UcraftButtonVariant.destructive,
                  isLoading: isBusy,
                  onPressed: isBusy ? null : onDelete,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

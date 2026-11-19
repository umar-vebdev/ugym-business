import 'dart:async';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../../../core/l10n/business_localizations.dart';
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
        final strings = BusinessStringsScope.of(context);
        if (!widget.sessionController.canView(BusinessPermission.manageStaff)) {
          return UcraftEmptyState(
            title: strings.analyticsNoAccessTitle,
            description: strings.staffOwnerOnlyDesc,
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
                    strings.staffAddTitle,
                    style: UcraftTypography.title.copyWith(
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: UcraftSpacing.space3),
                  UcraftTextField(
                    controller: _emailController,
                    label: strings.staffEmailLabel,
                    hintText: 'staff@gym.tj',
                    keyboardType: TextInputType.emailAddress,
                    enabled: canMutate && !_inviting,
                  ),
                  const SizedBox(height: UcraftSpacing.space2),
                  UcraftSegmentedTabs<StaffRoleValue>(
                    items: [
                      UcraftSegmentedTabItem(
                        value: StaffRoleValue.admin,
                        label: strings.staffRoleAdmin,
                      ),
                      UcraftSegmentedTabItem(
                        value: StaffRoleValue.trainer,
                        label: strings.staffRoleTrainer,
                      ),
                    ],
                    selected: _inviteRole,
                    enabled: canMutate && !_inviting,
                    onSelected: (role) => setState(() => _inviteRole = role),
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
                      strings.staffOtpOnboardingHint,
                      style: UcraftTypography.caption.copyWith(
                        color: colors.foregroundSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: UcraftSpacing.space3),
                  UcraftButton(
                    label: strings.staffAddButton,
                    fullWidth: true,
                    isLoading: _inviting,
                    onPressed: canMutate && !_inviting
                        ? () => unawaited(_invite())
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: UcraftSpacing.sectionGap),
            UcraftSectionHeader(title: strings.staffListTitle),
            if (_errorMessage != null && _staff.isNotEmpty) ...[
              const SizedBox(height: UcraftSpacing.space2),
              Text(
                _errorMessage!,
                style: UcraftTypography.bodyMedium.copyWith(
                  color: colors.destructive,
                ),
              ),
            ],
            const SizedBox(height: UcraftSpacing.space2),
            if (_loading)
              const UcraftLoadingState(isSkeleton: true, skeletonCount: 3)
            else if (_errorMessage != null && _staff.isEmpty)
              UcraftErrorState(
                title: strings.posLoadErrorTitle,
                message: _errorMessage!,
                retryLabel: strings.retryLabel,
                onRetry: () => unawaited(_load()),
              )
            else if (_staff.isEmpty)
              UcraftEmptyState(
                icon: LucideIcons.users,
                title: strings.staffEmptyTitle,
                description: strings.staffEmptyDesc,
              )
            else
              UcraftListSection(
                children: [
                  for (final member in _staff)
                    _StaffRow(
                      member: member,
                      canMutate:
                          canMutate && member.role != StaffRoleValue.owner,
                      isBusy: _busyStaffId == member.id,
                      onToggleRole: () => unawaited(_toggleRole(member)),
                      onDelete: () => unawaited(_deleteMember(member)),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

final class _StaffRow extends StatelessWidget {
  const _StaffRow({
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
    final strings = BusinessStringsScope.of(context);
    final displayName =
        member.name ?? member.email ?? 'Пользователь №${member.userId}';
    final initial = displayName.trim().isEmpty
        ? '?'
        : displayName.trim().substring(0, 1).toUpperCase();
    final (roleLabel, roleIcon, roleTone) = switch (member.role) {
      StaffRoleValue.owner => (
        strings.staffRoleOwner,
        LucideIcons.crown,
        UcraftStatusTone.info,
      ),
      StaffRoleValue.admin => (
        strings.staffRoleAdmin,
        LucideIcons.shield,
        UcraftStatusTone.success,
      ),
      StaffRoleValue.trainer => (
        strings.staffRoleTrainer,
        LucideIcons.dumbbell,
        UcraftStatusTone.neutral,
      ),
    };

    return UcraftListRow(
      leading: Container(
        width: UcraftSpacing.space10,
        height: UcraftSpacing.space10,
        decoration: BoxDecoration(
          color: colors.primarySubtle,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: UcraftTypography.bodyMedium.copyWith(color: colors.primary),
        ),
      ),
      title: displayName,
      subtitle: member.email,
      trailing: UcraftStatusPill(
        icon: roleIcon,
        label: roleLabel,
        tone: roleTone,
      ),
      bottom: canMutate
          ? Wrap(
              spacing: UcraftSpacing.space2,
              runSpacing: UcraftSpacing.space2,
              alignment: WrapAlignment.end,
              children: [
                UcraftButton(
                  label: member.role == StaffRoleValue.admin
                      ? strings.staffMakeTrainerButton
                      : strings.staffMakeAdminButton,
                  variant: UcraftButtonVariant.secondary,
                  isLoading: isBusy,
                  onPressed: isBusy ? null : onToggleRole,
                ),
                UcraftButton(
                  label: strings.deleteLabel,
                  variant: UcraftButtonVariant.destructive,
                  isLoading: isBusy,
                  onPressed: isBusy ? null : onDelete,
                ),
              ],
            )
          : null,
    );
  }
}

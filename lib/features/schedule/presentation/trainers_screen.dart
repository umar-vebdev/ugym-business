import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../../../core/l10n/business_localizations.dart';
import '../../../core/session/business_role.dart';
import '../../../core/session/business_session_controller.dart';
import '../domain/trainers_schedule_models.dart';

/// Gym trainers management screen (`owner` creates/edits, `admin` views).
final class TrainersScreen extends StatefulWidget {
  const TrainersScreen({
    super.key,
    required this.repository,
    required this.sessionController,
  });

  final TrainersScheduleRepository repository;
  final BusinessSessionController sessionController;

  @override
  State<TrainersScreen> createState() => _TrainersScreenState();
}

final class _TrainersScreenState extends State<TrainersScreen> {
  bool _loading = true;
  String? _errorMessage;
  int? _loadedGymId;
  List<TrainerProfile> _trainers = const <TrainerProfile>[];

  @override
  void initState() {
    super.initState();
    widget.sessionController.addListener(_onSessionChanged);
    unawaited(_load());
  }

  @override
  void dispose() {
    widget.sessionController.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    final currentGymId = widget.sessionController.selectedGym?.id;
    if (currentGymId != _loadedGymId) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final gym = widget.sessionController.selectedGym;
    if (gym == null) {
      setState(() {
        _loadedGymId = null;
        _trainers = const <TrainerProfile>[];
        _loading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _loadedGymId = gym.id;
      _loading = true;
      _errorMessage = null;
    });

    try {
      final list = await widget.repository.listTrainers(gymId: gym.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _trainers = list;
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
        _errorMessage = 'Не удалось загрузить тренеров.';
      });
    }
  }

  Future<void> _openCreate(int gymId) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _TrainerFormDialog(gymId: gymId, repository: widget.repository),
    );
    if (created == true && mounted) {
      await _load();
    }
  }

  Future<void> _openEdit(TrainerProfile trainer) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _TrainerFormDialog(
        gymId: trainer.gymId,
        repository: widget.repository,
        existing: trainer,
      ),
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
        final gym = widget.sessionController.selectedGym;
        if (gym == null) {
          return UcraftEmptyState(
            title: strings.branchNotSelected,
            description: strings.trainersSelectBranchDesc,
          );
        }

        final canManage = widget.sessionController.canMutate(
          BusinessPermission.manageTrainers,
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
                  strings.trainersTitle,
                  style: UcraftTypography.title.copyWith(
                    color: colors.foreground,
                  ),
                ),
                if (canManage)
                  UcraftButton(
                    label: strings.trainersAddButton,
                    onPressed: () => unawaited(_openCreate(gym.id)),
                  ),
              ],
            ),
            const SizedBox(height: UcraftSpacing.space3),
            if (_loading)
              UcraftLoadingState(message: strings.trainersLoading)
            else if (_errorMessage != null && _trainers.isEmpty)
              UcraftErrorState(
                title: strings.posLoadErrorTitle,
                message: _errorMessage!,
                retryLabel: strings.retryLabel,
                onRetry: () => unawaited(_load()),
              )
            else if (_trainers.isEmpty)
              UcraftEmptyState(
                title: strings.trainersEmptyTitle,
                description: strings.trainersEmptyDesc,
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final trainer in _trainers) ...[
                    UcraftCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trainer.name,
                                  style: UcraftTypography.bodyMedium.copyWith(
                                    color: colors.foreground,
                                  ),
                                ),
                                if (trainer.bio != null &&
                                    trainer.bio!.isNotEmpty) ...[
                                  const SizedBox(height: UcraftSpacing.space1),
                                  Text(
                                    trainer.bio!,
                                    style: UcraftTypography.caption.copyWith(
                                      color: colors.foregroundSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: UcraftSpacing.space1),
                                Text(
                                  trainer.isActive
                                      ? strings.planStatusActive
                                      : strings.trainerStatusInactive,
                                  style: UcraftTypography.caption.copyWith(
                                    color: trainer.isActive
                                        ? colors.success
                                        : colors.foregroundSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (canManage)
                            UcraftButton(
                              label: strings.productEditButton,
                              variant: UcraftButtonVariant.secondary,
                              onPressed: () => unawaited(_openEdit(trainer)),
                            ),
                        ],
                      ),
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

final class _TrainerFormDialog extends StatefulWidget {
  const _TrainerFormDialog({
    required this.gymId,
    required this.repository,
    this.existing,
  });

  final int gymId;
  final TrainersScheduleRepository repository;
  final TrainerProfile? existing;

  @override
  State<_TrainerFormDialog> createState() => _TrainerFormDialogState();
}

final class _TrainerFormDialogState extends State<_TrainerFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late bool _isActive;
  bool _submitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _bioController = TextEditingController(text: widget.existing?.bio ?? '');
    _isActive = widget.existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();
    if (name.isEmpty || name.length > 100) {
      setState(() {
        _errorText = 'Введите имя тренера (1–100 символов).';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      if (widget.existing == null) {
        await widget.repository.createTrainer(
          gymId: widget.gymId,
          name: name,
          bio: bio.isEmpty ? null : bio,
        );
      } else {
        await widget.repository.updateTrainer(
          trainerId: widget.existing!.id,
          name: name,
          bio: bio.isEmpty ? null : bio,
          isActive: _isActive,
        );
      }
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
        _errorText = 'Не удалось сохранить тренера.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final strings = BusinessStringsScope.of(context);
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(
        isEdit ? strings.trainerEditDialogTitle : strings.trainerNewDialogTitle,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UcraftTextField(
            controller: _nameController,
            label: strings.clientNameLabel,
          ),
          const SizedBox(height: UcraftSpacing.space2),
          UcraftTextField(
            controller: _bioController,
            label: strings.trainerBioOptionalLabel,
            maxLines: 2,
          ),
          if (isEdit)
            CheckboxListTile(
              value: _isActive,
              contentPadding: EdgeInsets.zero,
              title: Text(strings.planStatusActive),
              onChanged: (v) => setState(() => _isActive = v ?? true),
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
          label: strings.saveLabel,
          isLoading: _submitting,
          onPressed: _submitting ? null : () => unawaited(_submit()),
        ),
      ],
    );
  }
}

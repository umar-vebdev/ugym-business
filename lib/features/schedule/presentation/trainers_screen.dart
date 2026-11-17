import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

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
        final gym = widget.sessionController.selectedGym;
        if (gym == null) {
          return const UcraftEmptyState(
            title: 'Филиал не выбран',
            description: 'Выберите зал, чтобы просматривать тренеров.',
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
                  'Тренеры зала',
                  style: UcraftTypography.title.copyWith(
                    color: colors.foreground,
                  ),
                ),
                if (canManage)
                  UcraftButton(
                    label: 'Добавить тренера',
                    onPressed: () => unawaited(_openCreate(gym.id)),
                  ),
              ],
            ),
            const SizedBox(height: UcraftSpacing.space3),
            if (_loading)
              const UcraftLoadingState(message: 'Загружаем тренеров...')
            else if (_errorMessage != null && _trainers.isEmpty)
              UcraftErrorState(
                title: 'Ошибка загрузки',
                message: _errorMessage!,
                onRetry: () => unawaited(_load()),
              )
            else if (_trainers.isEmpty)
              const UcraftEmptyState(
                title: 'Тренеров пока нет',
                description: 'Добавьте тренера, чтобы создавать шаблоны групповых занятий.',
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
                                  trainer.isActive ? 'Активен' : 'Неактивен',
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
                              label: 'Изменить',
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
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? 'Редактировать тренера' : 'Новый тренер'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UcraftTextField(controller: _nameController, label: 'Имя'),
          const SizedBox(height: UcraftSpacing.space2),
          UcraftTextField(
            controller: _bioController,
            label: 'О тренере (необязательно)',
            maxLines: 2,
          ),
          if (isEdit)
            CheckboxListTile(
              value: _isActive,
              contentPadding: EdgeInsets.zero,
              title: const Text('Активен'),
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
          child: const Text('Отмена'),
        ),
        UcraftButton(
          label: 'Сохранить',
          isLoading: _submitting,
          onPressed: _submitting ? null : () => unawaited(_submit()),
        ),
      ],
    );
  }
}

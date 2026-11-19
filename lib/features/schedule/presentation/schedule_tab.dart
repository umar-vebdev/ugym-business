import 'dart:async';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../../../core/l10n/business_localizations.dart';
import '../../../core/session/business_role.dart';
import '../../../core/session/business_session_controller.dart';
import '../domain/trainers_schedule_models.dart';

enum _ScheduleSubView { sessions, templates }

/// Group class schedule tab: weekly templates, 62-day generation, cancel, and bookings.
final class ScheduleTab extends StatefulWidget {
  const ScheduleTab({
    super.key,
    required this.repository,
    required this.sessionController,
    this.initialFromDate,
    this.initialToDate,
  });

  final TrainersScheduleRepository repository;
  final BusinessSessionController sessionController;
  final String? initialFromDate;
  final String? initialToDate;

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

final class _ScheduleTabState extends State<ScheduleTab> {
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  final _sessionIdController = TextEditingController();

  _ScheduleSubView _view = _ScheduleSubView.sessions;
  bool _loading = true;
  String? _errorMessage;
  String? _trainerLookupError;
  int? _loadedGymId;
  int? _cancellingSessionId;

  List<ClassSession> _sessions = const <ClassSession>[];
  List<ScheduleTemplate> _templates = const <ScheduleTemplate>[];
  List<TrainerProfile> _trainers = const <TrainerProfile>[];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc();
    final weekEnd = now.add(const Duration(days: 6));
    _fromController = TextEditingController(
      text: widget.initialFromDate ?? _formatDate(now),
    );
    _toController = TextEditingController(
      text: widget.initialToDate ?? _formatDate(weekEnd),
    );
    widget.sessionController.addListener(_onSessionChanged);
    if (widget.sessionController.selectedGym != null) {
      unawaited(_load());
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    widget.sessionController.removeListener(_onSessionChanged);
    _fromController.dispose();
    _toController.dispose();
    _sessionIdController.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    final currentGymId = widget.sessionController.selectedGym?.id;
    if (currentGymId != _loadedGymId) {
      unawaited(_load());
    }
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _load() async {
    final gym = widget.sessionController.selectedGym;
    if (gym == null) {
      setState(() {
        _loadedGymId = null;
        _sessions = const <ClassSession>[];
        _templates = const <ScheduleTemplate>[];
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
      final canManage = widget.sessionController.canMutate(
        BusinessPermission.manageSchedule,
      );
      final sessionsFuture = widget.repository.listSessions(
        gymId: gym.id,
        fromDate: _fromController.text.trim(),
        toDate: _toController.text.trim(),
      );
      final templatesFuture = canManage
          ? widget.repository.listTemplates(gymId: gym.id)
          : Future.value(const <ScheduleTemplate>[]);
      final trainersFuture = canManage
          ? widget.repository.listTrainers(gymId: gym.id)
          : Future.value(const <TrainerProfile>[]);

      final sessions = await sessionsFuture;
      final templates = await templatesFuture;
      final trainers = await trainersFuture;

      if (!mounted) {
        return;
      }
      setState(() {
        _sessions = sessions;
        _templates = templates;
        _trainers = trainers;
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
        _errorMessage = 'Не удалось загрузить расписание.';
      });
    }
  }

  Future<void> _openGenerateDialog(int gymId) async {
    final generated = await showDialog<bool>(
      context: context,
      builder: (_) => _GenerateSessionsDialog(
        gymId: gymId,
        repository: widget.repository,
        initialFrom: _fromController.text.trim(),
        initialTo: _toController.text.trim(),
      ),
    );
    if (generated == true && mounted) {
      await _load();
    }
  }

  Future<void> _openCreateTemplate(int gymId) async {
    final activeTrainers = _trainers
        .where((t) => t.isActive)
        .toList(growable: false);
    if (activeTrainers.isEmpty) {
      setState(() {
        _errorMessage = 'Сначала добавьте хотя бы одного активного тренера.';
      });
      return;
    }

    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _TemplateFormDialog(
        gymId: gymId,
        trainers: activeTrainers,
        repository: widget.repository,
      ),
    );
    if (created == true && mounted) {
      await _load();
    }
  }

  Future<void> _cancelSession(ClassSession session) async {
    final strings = BusinessStringsScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.scheduleCancelSessionTitle),
        content: Text(strings.scheduleCancelSessionDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.backLabel),
          ),
          UcraftButton(
            label: strings.scheduleCancelSessionTitle,
            variant: UcraftButtonVariant.destructive,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _cancellingSessionId = session.id;
      _errorMessage = null;
    });

    try {
      final updated = await widget.repository.cancelSession(
        sessionId: session.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _cancellingSessionId = null;
        _sessions = _sessions
            .map((s) => s.id == updated.id ? updated : s)
            .toList(growable: false);
      });
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _cancellingSessionId = null;
        _errorMessage = error.message;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _cancellingSessionId = null;
        _errorMessage = 'Не удалось отменить занятие.';
      });
    }
  }

  Future<void> _openBookings(ClassSession session) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SessionBookingsScreen(
          session: session,
          repository: widget.repository,
        ),
      ),
    );
  }

  Future<void> _openTrainerSessionById() async {
    final sessionId = int.tryParse(_sessionIdController.text.trim());
    if (sessionId == null || sessionId <= 0) {
      setState(() {
        _trainerLookupError = 'Введите корректный ID занятия.';
      });
      return;
    }

    setState(() {
      _trainerLookupError = null;
    });

    final now = DateTime.now().toUtc();
    final placeholder = ClassSession(
      id: sessionId,
      publicId: '',
      gymId: 0,
      templateId: 0,
      trainerId: 0,
      title: 'Занятие №$sessionId',
      capacity: 0,
      bookedCount: 0,
      availableSeats: 0,
      startsAt: now,
      endsAt: now,
      status: ClassSessionStatus.scheduled,
    );
    await _openBookings(placeholder);
  }

  Widget _buildTrainerSessionLookup(BuildContext context) {
    final colors = context.ucraftColors;
    final strings = BusinessStringsScope.of(context);
    return UcraftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.scheduleTrainerLookupTitle,
            style: UcraftTypography.title.copyWith(color: colors.foreground),
          ),
          const SizedBox(height: UcraftSpacing.space1),
          Text(
            strings.scheduleTrainerLookupDesc,
            style: UcraftTypography.caption.copyWith(
              color: colors.foregroundSecondary,
            ),
          ),
          const SizedBox(height: UcraftSpacing.space3),
          UcraftTextField(
            key: const ValueKey<String>('trainer_session_id_input'),
            controller: _sessionIdController,
            label: strings.scheduleSessionIdLabel,
            hintText: '101',
            keyboardType: TextInputType.number,
            errorText: _trainerLookupError,
          ),
          const SizedBox(height: UcraftSpacing.space3),
          UcraftButton(
            label: strings.scheduleOpenRosterButton,
            fullWidth: true,
            onPressed: () => unawaited(_openTrainerSessionById()),
          ),
        ],
      ),
    );
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
          if (widget.sessionController.role == BusinessRole.trainer) {
            return _buildTrainerSessionLookup(context);
          }
          return UcraftEmptyState(
            title: strings.branchNotSelected,
            description: strings.scheduleSelectBranchDesc,
          );
        }

        final canManage = widget.sessionController.canMutate(
          BusinessPermission.manageSchedule,
        );
        final canViewBookings = widget.sessionController.canView(
          BusinessPermission.viewSessionBookings,
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
                  strings.subTabSchedule,
                  style: UcraftTypography.title.copyWith(
                    color: colors.foreground,
                  ),
                ),
                if (canManage)
                  Wrap(
                    spacing: UcraftSpacing.space2,
                    children: [
                      UcraftButton(
                        label: strings.scheduleGenerateButton,
                        variant: UcraftButtonVariant.secondary,
                        onPressed: () => unawaited(_openGenerateDialog(gym.id)),
                      ),
                      UcraftButton(
                        label: strings.scheduleNewTemplateButton,
                        onPressed: () => unawaited(_openCreateTemplate(gym.id)),
                      ),
                    ],
                  ),
              ],
            ),
            if (canManage) ...[
              const SizedBox(height: UcraftSpacing.space3),
              UcraftSegmentedTabs<_ScheduleSubView>(
                items: [
                  UcraftSegmentedTabItem(
                    value: _ScheduleSubView.sessions,
                    label: strings.scheduleSessionsTab,
                  ),
                  UcraftSegmentedTabItem(
                    value: _ScheduleSubView.templates,
                    label: strings.scheduleTemplatesTab,
                  ),
                ],
                selected: _view,
                onSelected: (next) => setState(() => _view = next),
              ),
            ],
            if (_errorMessage != null) ...[
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
            else if (_view == _ScheduleSubView.templates && canManage)
              _buildTemplatesList(colors, strings)
            else
              _buildSessionsList(colors, strings, canManage, canViewBookings),
          ],
        );
      },
    );
  }

  Widget _buildSessionsList(
    UcraftColors colors,
    BusinessStrings strings,
    bool canManage,
    bool canViewBookings,
  ) {
    if (_sessions.isEmpty) {
      return UcraftEmptyState(
        icon: LucideIcons.calendar,
        title: strings.scheduleNoSessionsTitle,
        description: strings.scheduleNoSessionsDesc,
      );
    }

    return UcraftListSection(
      children: [
        for (final session in _sessions)
          UcraftListRow(
            monoLeadingWidth: true,
            leading: Text(
              DateFormatter.formatTime(
                session.startsAt,
                offset: DateFormatter.dushanbeOffset,
              ),
              style: UcraftTypography.mono.copyWith(color: colors.foreground),
            ),
            title: session.title,
            subtitle: DateFormatter.formatDateTime(
              session.startsAt,
              offset: DateFormatter.dushanbeOffset,
            ),
            trailing: UcraftStatusPill(
              icon: session.status == ClassSessionStatus.cancelled
                  ? LucideIcons.circleX
                  : LucideIcons.users,
              label: session.status == ClassSessionStatus.cancelled
                  ? strings.scheduleSessionCancelled
                  : '${session.bookedCount}/${session.capacity}',
              tone: session.status == ClassSessionStatus.cancelled
                  ? UcraftStatusTone.destructive
                  : session.bookedCount >= session.capacity
                  ? UcraftStatusTone.warning
                  : UcraftStatusTone.info,
            ),
            bottom:
                (canViewBookings ||
                    (canManage &&
                        session.status == ClassSessionStatus.scheduled))
                ? Wrap(
                    spacing: UcraftSpacing.space2,
                    runSpacing: UcraftSpacing.space2,
                    alignment: WrapAlignment.end,
                    children: [
                      if (canViewBookings)
                        UcraftButton(
                          label: strings.scheduleBookingsButton,
                          variant: UcraftButtonVariant.secondary,
                          onPressed: () => unawaited(_openBookings(session)),
                        ),
                      if (canManage &&
                          session.status == ClassSessionStatus.scheduled)
                        UcraftButton(
                          label: strings.membershipCancelButton,
                          variant: UcraftButtonVariant.destructive,
                          isLoading: _cancellingSessionId == session.id,
                          onPressed: _cancellingSessionId == session.id
                              ? null
                              : () => unawaited(_cancelSession(session)),
                        ),
                    ],
                  )
                : null,
          ),
      ],
    );
  }

  Widget _buildTemplatesList(UcraftColors colors, BusinessStrings strings) {
    if (_templates.isEmpty) {
      return UcraftEmptyState(
        icon: LucideIcons.repeat,
        title: strings.scheduleNoTemplatesTitle,
        description: strings.scheduleNoTemplatesDesc,
      );
    }

    return UcraftListSection(
      children: [
        for (final tmpl in _templates)
          UcraftListRow(
            monoLeadingWidth: true,
            leading: Text(
              tmpl.formattedStartTime,
              style: UcraftTypography.mono.copyWith(color: colors.foreground),
            ),
            title:
                '${tmpl.title} • ${_weekdayLabel(tmpl.weekday)} ${tmpl.formattedStartTime}',
            subtitle: '${tmpl.durationMinutes} мин • до ${tmpl.capacity} мест',
            trailing: UcraftStatusPill(
              icon: tmpl.isActive
                  ? LucideIcons.circleCheck
                  : LucideIcons.archive,
              label: tmpl.isActive
                  ? strings.planStatusActive
                  : strings.planStatusArchived,
              tone: tmpl.isActive
                  ? UcraftStatusTone.success
                  : UcraftStatusTone.neutral,
            ),
          ),
      ],
    );
  }

  String _weekdayLabel(int weekday) {
    return switch (weekday) {
      1 => 'Пн',
      2 => 'Вт',
      3 => 'Ср',
      4 => 'Чт',
      5 => 'Пт',
      6 => 'Сб',
      7 => 'Вс',
      _ => 'День $weekday',
    };
  }
}

/// Screen displaying client bookings for a group class session.
final class SessionBookingsScreen extends StatefulWidget {
  const SessionBookingsScreen({
    super.key,
    required this.session,
    required this.repository,
  });

  final ClassSession session;
  final TrainersScheduleRepository repository;

  @override
  State<SessionBookingsScreen> createState() => _SessionBookingsScreenState();
}

final class _SessionBookingsScreenState extends State<SessionBookingsScreen> {
  bool _loading = true;
  String? _errorMessage;
  List<ClassBooking> _bookings = const <ClassBooking>[];

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
      final list = await widget.repository.listSessionBookings(
        sessionId: widget.session.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _bookings = list;
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
        _errorMessage = 'Не удалось загрузить список записей.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final strings = BusinessStringsScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.session.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: UcraftSpacing.screenHorizontalPadding,
            vertical: UcraftSpacing.space4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UcraftCard(
                variant: UcraftCardVariant.highlight,
                child: Text(
                  widget.session.capacity > 0
                      ? 'Занято мест: ${widget.session.bookedCount} / ${widget.session.capacity}'
                      : 'Записей в списке: ${_bookings.length}',
                  style: UcraftTypography.title.copyWith(
                    color: colors.foreground,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: UcraftSpacing.sectionGap),
              Expanded(
                child: _loading
                    ? const UcraftLoadingState(
                        isSkeleton: true,
                        skeletonCount: 4,
                      )
                    : _errorMessage != null
                    ? UcraftErrorState(
                        title: strings.posLoadErrorTitle,
                        message: _errorMessage!,
                        retryLabel: strings.retryLabel,
                        onRetry: () => unawaited(_load()),
                      )
                    : _bookings.isEmpty
                    ? UcraftEmptyState(
                        icon: LucideIcons.users,
                        title: strings.bookingsEmptyTitle,
                        description: strings.bookingsEmptyDesc,
                      )
                    : SingleChildScrollView(
                        child: UcraftListSection(
                          children: [
                            for (final booking in _bookings)
                              UcraftListRow(
                                title: 'Клиент №${booking.clientId}',
                                trailing: UcraftStatusPill(
                                  icon:
                                      booking.status ==
                                          ClassBookingStatus.cancelled
                                      ? LucideIcons.circleX
                                      : LucideIcons.circleCheck,
                                  label:
                                      booking.status ==
                                          ClassBookingStatus.cancelled
                                      ? strings.bookingStatusCancelled
                                      : strings.bookingStatusBooked,
                                  tone:
                                      booking.status ==
                                          ClassBookingStatus.cancelled
                                      ? UcraftStatusTone.destructive
                                      : UcraftStatusTone.success,
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _GenerateSessionsDialog extends StatefulWidget {
  const _GenerateSessionsDialog({
    required this.gymId,
    required this.repository,
    required this.initialFrom,
    required this.initialTo,
  });

  final int gymId;
  final TrainersScheduleRepository repository;
  final String initialFrom;
  final String initialTo;

  @override
  State<_GenerateSessionsDialog> createState() =>
      _GenerateSessionsDialogState();
}

final class _GenerateSessionsDialogState
    extends State<_GenerateSessionsDialog> {
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  bool _submitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.initialFrom);
    _toController = TextEditingController(text: widget.initialTo);
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final fromStr = _fromController.text.trim();
    final toStr = _toController.text.trim();
    final fromDate = DateTime.tryParse(fromStr);
    final toDate = DateTime.tryParse(toStr);

    if (fromDate == null || toDate == null || toDate.isBefore(fromDate)) {
      setState(() {
        _errorText = 'Укажите корректный период (ГГГГ-ММ-ДД).';
      });
      return;
    }

    final days = toDate.difference(fromDate).inDays + 1;
    if (days > 62) {
      setState(() {
        _errorText = 'Период генерации не должен превышать 62 дня.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      await widget.repository.generateSessions(
        gymId: widget.gymId,
        fromDate: fromStr,
        toDate: toStr,
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
        _errorText = 'Не удалось сгенерировать занятия.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final strings = BusinessStringsScope.of(context);
    return AlertDialog(
      title: Text(strings.scheduleGenerateDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UcraftTextField(
            controller: _fromController,
            label: strings.scheduleStartDateLabel,
          ),
          const SizedBox(height: UcraftSpacing.space2),
          UcraftTextField(
            controller: _toController,
            label: strings.scheduleEndDateLabel,
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
          label: strings.scheduleGenerateButton,
          isLoading: _submitting,
          onPressed: _submitting ? null : () => unawaited(_submit()),
        ),
      ],
    );
  }
}

final class _TemplateFormDialog extends StatefulWidget {
  const _TemplateFormDialog({
    required this.gymId,
    required this.trainers,
    required this.repository,
  });

  final int gymId;
  final List<TrainerProfile> trainers;
  final TrainersScheduleRepository repository;

  @override
  State<_TemplateFormDialog> createState() => _TemplateFormDialogState();
}

final class _TemplateFormDialogState extends State<_TemplateFormDialog> {
  final _titleController = TextEditingController();
  final _timeController = TextEditingController(text: '09:00');
  final _durationController = TextEditingController(text: '60');
  final _capacityController = TextEditingController(text: '15');

  late int _trainerId;
  int _weekday = 1;
  bool _submitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _trainerId = widget.trainers.first.id;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    _durationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  int? _parseTimeMinute(String raw) {
    final parts = raw.trim().split(':');
    if (parts.length != 2) {
      return null;
    }
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return h * 60 + m;
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final startMinute = _parseTimeMinute(_timeController.text);
    final duration = int.tryParse(_durationController.text.trim());
    final capacity = int.tryParse(_capacityController.text.trim());

    if (title.isEmpty ||
        startMinute == null ||
        duration == null ||
        duration < 15 ||
        duration > 240 ||
        capacity == null ||
        capacity < 1 ||
        capacity > 200) {
      setState(() {
        _errorText = 'Проверьте название, время ЧЧ:ММ, длительность (15–240) и места (1–200).';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      await widget.repository.createTemplate(
        gymId: widget.gymId,
        trainerId: _trainerId,
        title: title,
        weekday: _weekday,
        startTimeMinute: startMinute,
        durationMinutes: duration,
        capacity: capacity,
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
        _errorText = 'Не удалось создать шаблон.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final strings = BusinessStringsScope.of(context);
    return AlertDialog(
      title: Text(strings.scheduleNewTemplateDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UcraftTextField(
              controller: _titleController,
              label: strings.planNameLabel,
            ),
            const SizedBox(height: UcraftSpacing.space2),
            DropdownButtonFormField<int>(
              initialValue: _trainerId,
              decoration: InputDecoration(labelText: strings.staffRoleTrainer),
              items: [
                for (final t in widget.trainers)
                  DropdownMenuItem<int>(value: t.id, child: Text(t.name)),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _trainerId = v);
                }
              },
            ),
            const SizedBox(height: UcraftSpacing.space2),
            DropdownButtonFormField<int>(
              initialValue: _weekday,
              decoration: InputDecoration(
                labelText: strings.scheduleWeekdayLabel,
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Понедельник')),
                DropdownMenuItem(value: 2, child: Text('Вторник')),
                DropdownMenuItem(value: 3, child: Text('Среда')),
                DropdownMenuItem(value: 4, child: Text('Четверг')),
                DropdownMenuItem(value: 5, child: Text('Пятница')),
                DropdownMenuItem(value: 6, child: Text('Суббота')),
                DropdownMenuItem(value: 7, child: Text('Воскресенье')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _weekday = v);
                }
              },
            ),
            const SizedBox(height: UcraftSpacing.space2),
            UcraftTextField(
              controller: _timeController,
              label: strings.scheduleStartTimeLabel,
            ),
            const SizedBox(height: UcraftSpacing.space2),
            UcraftTextField(
              controller: _durationController,
              label: strings.scheduleDurationMinLabel,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: UcraftSpacing.space2),
            UcraftTextField(
              controller: _capacityController,
              label: strings.scheduleCapacityLabel,
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

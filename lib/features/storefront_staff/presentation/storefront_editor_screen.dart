import 'dart:async';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../../../core/l10n/business_localizations.dart';
import '../../../core/session/business_role.dart';
import '../../../core/session/business_session_controller.dart';
import '../domain/storefront_and_staff_models.dart';

/// Selected image payload passed to [GymPhotosManager].
typedef PickedGymPhoto = ({List<int> bytes, String filename});

/// Callback used to pick/compress a gym photo from gallery or camera.
typedef GymPhotoPicker = Future<PickedGymPhoto?> Function();

/// Owner-only editor for public gym storefront, moderation, and gallery.
final class StorefrontEditorScreen extends StatefulWidget {
  const StorefrontEditorScreen({
    super.key,
    required this.repository,
    required this.sessionController,
    this.initialProfile,
    this.initialPhotos = const <GymPhoto>[],
    this.photoPicker,
  });

  final StorefrontAndStaffRepository repository;
  final BusinessSessionController sessionController;
  final GymProfile? initialProfile;
  final List<GymPhoto> initialPhotos;
  final GymPhotoPicker? photoPicker;

  @override
  State<StorefrontEditorScreen> createState() => _StorefrontEditorScreenState();
}

final class _StorefrontEditorScreenState extends State<StorefrontEditorScreen> {
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amenitiesController = TextEditingController();
  final _hoursController = TextEditingController(text: '07:00-23:00');

  GymProfile? _profile;
  List<GymPhoto> _photos = const <GymPhoto>[];
  bool _submitting = false;
  String? _errorMessage;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    _photos = List<GymPhoto>.of(widget.initialPhotos);
    _hydrateControllers(widget.initialProfile);
  }

  void _hydrateControllers(GymProfile? profile) {
    if (profile == null) {
      return;
    }
    _descriptionController.text = profile.description ?? '';
    _addressController.text = profile.address ?? '';
    _districtController.text = profile.district ?? '';
    _latitudeController.text = profile.latitude?.toString() ?? '';
    _longitudeController.text = profile.longitude?.toString() ?? '';
    _phoneController.text = profile.phone ?? '';
    _amenitiesController.text = profile.amenities.join(', ');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _phoneController.dispose();
    _amenitiesController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  ModerationStatus get _status =>
      _profile?.moderationStatus ?? ModerationStatus.draft;

  bool get _isPending => _status == ModerationStatus.pending;

  bool get _isApproved => _status == ModerationStatus.approved;

  Future<void> _saveProfile(int gymId) async {
    if (_submitting || _isPending) {
      return;
    }

    final description = _descriptionController.text.trim();
    final address = _addressController.text.trim();
    final district = _districtController.text.trim();
    final phone = _phoneController.text.trim();
    final latText = _latitudeController.text.trim();
    final lngText = _longitudeController.text.trim();

    double? lat;
    double? lng;
    String? validationError;

    if (description.length > 5000) {
      validationError = 'Описание не должно превышать 5000 символов.';
    } else if (address.length > 255) {
      validationError = 'Адрес не должен превышать 255 символов.';
    } else if (district.length > 100) {
      validationError = 'Район не должен превышать 100 символов.';
    } else if (phone.length > 32) {
      validationError = 'Телефон не должен превышать 32 символа.';
    } else if ((latText.isEmpty) != (lngText.isEmpty)) {
      validationError = 'Укажите и широту, и долготу вместе.';
    } else if (latText.isNotEmpty) {
      lat = double.tryParse(latText.replaceAll(',', '.'));
      lng = double.tryParse(lngText.replaceAll(',', '.'));
      if (lat == null ||
          lng == null ||
          lat < -90 ||
          lat > 90 ||
          lng < -180 ||
          lng > 180) {
        validationError =
            'Координаты должны быть в диапазоне [-90..90] и [-180..180].';
      }
    }

    final amenities = _amenitiesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (validationError == null) {
      if (amenities.length > 30) {
        validationError = 'Можно указать не более 30 удобств.';
      } else if (amenities.any((tag) => tag.length > 50)) {
        validationError = 'Каждый тег удобства должен быть до 50 символов.';
      }
    }

    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
        _statusMessage = null;
      });
      return;
    }

    final hoursText = _hoursController.text.trim();
    final workingHours = hoursText.isEmpty
        ? null
        : <String, Object?>{
            for (final day in const [
              'mon',
              'tue',
              'wed',
              'thu',
              'fri',
              'sat',
              'sun',
            ])
              day: hoursText,
          };

    setState(() {
      _submitting = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final updated = await widget.repository.updateGymProfile(
        gymId: gymId,
        input: GymProfileInput(
          description: description,
          address: address,
          district: district,
          latitude: lat,
          longitude: lng,
          phone: phone,
          workingHours: workingHours,
          amenities: amenities.isEmpty ? null : amenities,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = updated;
        _submitting = false;
        _statusMessage =
            'Витрина сохранена (статус: ${updated.moderationStatus.apiValue}).';
      });
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
        _errorMessage = 'Не удалось сохранить витрину.';
      });
    }
  }

  Future<void> _submitForModeration(int gymId) async {
    if (_submitting || _isPending) {
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final updated = await widget.repository.submitGymProfile(gymId: gymId);
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = updated;
        _submitting = false;
        _statusMessage = 'Витрина отправлена на модерацию.';
      });
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
        _errorMessage = 'Не удалось отправить витрину на модерацию.';
      });
    }
  }

  Future<void> _togglePublication(int gymId, bool targetPublic) async {
    if (_submitting) {
      return;
    }
    if (targetPublic && !_isApproved) {
      setState(() {
        _errorMessage =
            'Публикация доступна только после одобрения витрины модератором.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final updated = await widget.repository.setGymPublication(
        gymId: gymId,
        isPublic: targetPublic,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = updated;
        _submitting = false;
        _statusMessage = updated.isPublic
            ? 'Зал опубликован в каталоге uGym.'
            : 'Публикация зала отключена.';
      });
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
        _errorMessage = 'Не удалось изменить статус публикации.';
      });
    }
  }

  void _resetLocalProfileToDraft() {
    final current = _profile;
    if (current == null) {
      return;
    }
    setState(() {
      _profile = GymProfile(
        gymId: current.gymId,
        isPublic: false,
        moderationStatus: ModerationStatus.draft,
        description: current.description,
        address: current.address,
        district: current.district,
        latitude: current.latitude,
        longitude: current.longitude,
        phone: current.phone,
        workingHours: current.workingHours,
        amenities: current.amenities,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sessionController,
      builder: (context, _) {
        final colors = context.ucraftColors;
        final strings = BusinessStringsScope.of(context);
        if (!widget.sessionController.canView(
          BusinessPermission.manageStorefront,
        )) {
          return UcraftEmptyState(
            title: strings.analyticsNoAccessTitle,
            description: strings.storefrontOwnerOnlyDesc,
          );
        }

        final gym = widget.sessionController.selectedGym;
        if (gym == null) {
          return UcraftEmptyState(
            title: strings.branchNotSelected,
            description: strings.storefrontSelectBranchDesc,
          );
        }

        final canEdit =
            !widget.sessionController.isReadOnly && !_isPending && !_submitting;
        final isPublic = _profile?.isPublic ?? false;
        final (moderationIcon, moderationTone) = switch (_status) {
          ModerationStatus.approved => (
            LucideIcons.circleCheck,
            UcraftStatusTone.success,
          ),
          ModerationStatus.pending => (
            LucideIcons.clock,
            UcraftStatusTone.warning,
          ),
          ModerationStatus.rejected => (
            LucideIcons.circleX,
            UcraftStatusTone.destructive,
          ),
          ModerationStatus.draft => (
            LucideIcons.filePen,
            UcraftStatusTone.neutral,
          ),
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UcraftCard(
              variant: UcraftCardVariant.highlight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${strings.storefrontTitlePrefix} • ${gym.name}',
                          style: UcraftTypography.titleLarge.copyWith(
                            color: colors.foreground,
                          ),
                        ),
                      ),
                      const SizedBox(width: UcraftSpacing.space2),
                      UcraftStatusPill(
                        icon: moderationIcon,
                        label: _moderationLabel(_status, strings),
                        tone: moderationTone,
                      ),
                    ],
                  ),
                  if (_isApproved) ...[
                    const SizedBox(height: UcraftSpacing.space2),
                    Text(
                      strings.storefrontApprovedWarning,
                      style: UcraftTypography.caption.copyWith(
                        color: colors.destructive,
                      ),
                    ),
                  ],
                  if (_isPending) ...[
                    const SizedBox(height: UcraftSpacing.space2),
                    Text(
                      strings.storefrontPendingHint,
                      style: UcraftTypography.caption.copyWith(
                        color: colors.foregroundSecondary,
                      ),
                    ),
                  ],
                  if (_status == ModerationStatus.rejected &&
                      _profile?.rejectionReason != null) ...[
                    const SizedBox(height: UcraftSpacing.space2),
                    Text(
                      'Причина отклонения: ${_profile!.rejectionReason}',
                      style: UcraftTypography.bodyMedium.copyWith(
                        color: colors.destructive,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: UcraftSpacing.sectionGap),
            UcraftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UcraftTextField(
                    controller: _descriptionController,
                    label: strings.storefrontDescriptionLabel,
                    maxLines: 3,
                    enabled: canEdit,
                  ),
                  const SizedBox(height: UcraftSpacing.space3),
                  UcraftTextField(
                    controller: _addressController,
                    label: strings.storefrontAddressLabel,
                    enabled: canEdit,
                  ),
                  const SizedBox(height: UcraftSpacing.space3),
                  UcraftTextField(
                    controller: _districtController,
                    label: strings.storefrontDistrictLabel,
                    enabled: canEdit,
                  ),
                  const SizedBox(height: UcraftSpacing.space3),
                  Row(
                    children: [
                      Expanded(
                        child: UcraftTextField(
                          controller: _latitudeController,
                          label: strings.storefrontLatitudeLabel,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          enabled: canEdit,
                        ),
                      ),
                      const SizedBox(width: UcraftSpacing.space2),
                      Expanded(
                        child: UcraftTextField(
                          controller: _longitudeController,
                          label: strings.storefrontLongitudeLabel,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          enabled: canEdit,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: UcraftSpacing.space3),
                  UcraftTextField(
                    controller: _phoneController,
                    label: strings.storefrontPhoneLabel,
                    enabled: canEdit,
                  ),
                  const SizedBox(height: UcraftSpacing.space3),
                  UcraftTextField(
                    controller: _hoursController,
                    label: strings.storefrontHoursLabel,
                    enabled: canEdit,
                  ),
                  const SizedBox(height: UcraftSpacing.space3),
                  UcraftTextField(
                    controller: _amenitiesController,
                    label: strings.storefrontAmenitiesLabel,
                    hintText: 'душ, парковка, сауна',
                    enabled: canEdit,
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
                  if (_statusMessage != null) ...[
                    const SizedBox(height: UcraftSpacing.space3),
                    Text(
                      _statusMessage!,
                      style: UcraftTypography.bodyMedium.copyWith(
                        color: colors.success,
                      ),
                    ),
                  ],
                  const SizedBox(height: UcraftSpacing.space4),
                  Wrap(
                    spacing: UcraftSpacing.space2,
                    runSpacing: UcraftSpacing.space2,
                    children: [
                      UcraftButton(
                        label: strings.storefrontSaveButton,
                        isLoading: _submitting,
                        onPressed: canEdit
                            ? () => unawaited(_saveProfile(gym.id))
                            : null,
                      ),
                      UcraftButton(
                        label: strings.storefrontSubmitModerationButton,
                        variant: UcraftButtonVariant.secondary,
                        onPressed: canEdit
                            ? () => unawaited(_submitForModeration(gym.id))
                            : null,
                      ),
                      UcraftButton(
                        label: isPublic
                            ? strings.storefrontUnpublishButton
                            : strings.storefrontPublishButton,
                        variant: UcraftButtonVariant.secondary,
                        onPressed:
                            !widget.sessionController.isReadOnly &&
                                !_submitting &&
                                (isPublic || _isApproved)
                            ? () => unawaited(
                                _togglePublication(gym.id, !isPublic),
                              )
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: UcraftSpacing.sectionGap),
            GymPhotosManager(
              gymId: gym.id,
              repository: widget.repository,
              photos: _photos,
              isLocked: widget.sessionController.isReadOnly || _isPending,
              photoPicker: widget.photoPicker,
              onPhotosChanged: (updatedPhotos) {
                setState(() {
                  _photos = updatedPhotos;
                });
                _resetLocalProfileToDraft();
              },
            ),
          ],
        );
      },
    );
  }

  String _moderationLabel(ModerationStatus status, BusinessStrings strings) {
    return switch (status) {
      ModerationStatus.draft => strings.storefrontModerationDraft,
      ModerationStatus.pending => strings.storefrontModerationPending,
      ModerationStatus.approved => strings.storefrontModerationApproved,
      ModerationStatus.rejected => strings.storefrontModerationRejected,
    };
  }
}

/// Photo gallery manager for a gym branch (max 10 photos, <= 5 MB, jpeg/png/webp).
final class GymPhotosManager extends StatefulWidget {
  const GymPhotosManager({
    super.key,
    required this.gymId,
    required this.repository,
    required this.photos,
    required this.isLocked,
    required this.onPhotosChanged,
    this.photoPicker,
  });

  static const int maxPhotos = 10;
  static const int maxFileBytes = 5 * 1024 * 1024;
  static const Set<String> allowedExtensions = <String>{
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  final int gymId;
  final StorefrontAndStaffRepository repository;
  final List<GymPhoto> photos;
  final bool isLocked;
  final ValueChanged<List<GymPhoto>> onPhotosChanged;
  final GymPhotoPicker? photoPicker;

  @override
  State<GymPhotosManager> createState() => _GymPhotosManagerState();
}

final class _GymPhotosManagerState extends State<GymPhotosManager> {
  bool _busy = false;
  String? _errorMessage;

  Future<void> _pickAndUpload() async {
    if (_busy ||
        widget.isLocked ||
        widget.photos.length >= GymPhotosManager.maxPhotos) {
      return;
    }

    final picker = widget.photoPicker;
    if (picker == null) {
      setState(() {
        _errorMessage = 'Выбор фото недоступен на этом устройстве.';
      });
      return;
    }

    PickedGymPhoto? picked;
    try {
      picked = await picker();
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage =
            'Не удалось выбрать фото. Проверьте доступ к фотогалерее.';
      });
      return;
    }
    if (picked == null || !mounted) {
      return;
    }

    final ext = picked.filename.split('.').last.toLowerCase();
    if (!GymPhotosManager.allowedExtensions.contains(ext)) {
      setState(() {
        _errorMessage = 'Допустимы только форматы JPEG, PNG или WEBP.';
      });
      return;
    }
    if (picked.bytes.isEmpty ||
        picked.bytes.length > GymPhotosManager.maxFileBytes) {
      setState(() {
        _errorMessage = 'Размер фото должен быть до 5 МБ.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      final uploaded = await widget.repository.uploadGymPhoto(
        gymId: widget.gymId,
        bytes: picked.bytes,
        filename: picked.filename,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
      });
      widget.onPhotosChanged([...widget.photos, uploaded]);
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _errorMessage = error.message;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _errorMessage = 'Не удалось загрузить фотографию.';
      });
    }
  }

  Future<void> _deletePhoto(GymPhoto photo) async {
    if (_busy || widget.isLocked) {
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      await widget.repository.deleteGymPhoto(
        gymId: widget.gymId,
        photoId: photo.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
      });
      widget.onPhotosChanged(
        widget.photos.where((p) => p.id != photo.id).toList(growable: false),
      );
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _errorMessage = error.message;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _errorMessage = 'Не удалось удалить фотографию.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final strings = BusinessStringsScope.of(context);
    final atLimit = widget.photos.length >= GymPhotosManager.maxPhotos;

    return UcraftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${strings.galleryTitlePrefix} (${widget.photos.length}/${GymPhotosManager.maxPhotos})',
                  style: UcraftTypography.title.copyWith(
                    color: colors.foreground,
                  ),
                ),
              ),
              UcraftButton(
                label: strings.galleryUploadButton,
                variant: UcraftButtonVariant.secondary,
                isLoading: _busy,
                onPressed: !widget.isLocked && !atLimit && !_busy
                    ? () => unawaited(_pickAndUpload())
                    : null,
              ),
            ],
          ),
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
          if (widget.photos.isEmpty)
            Text(
              strings.galleryEmptyHint,
              style: UcraftTypography.caption.copyWith(
                color: colors.foregroundSecondary,
              ),
            )
          else
            UcraftListSection(
              children: [
                for (final photo in widget.photos)
                  UcraftListRow(
                    leading: ClipRRect(
                      borderRadius: UcraftRadius.borderSm,
                      child: Image.network(
                        photo.url,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        semanticLabel: 'Фото зала №${photo.id}',
                        errorBuilder: (_, _, _) => Container(
                          width: 56,
                          height: 56,
                          color: colors.surfaceSecondary,
                          alignment: Alignment.center,
                          child: Icon(
                            LucideIcons.image,
                            size: 20,
                            color: colors.foregroundSecondary,
                          ),
                        ),
                      ),
                    ),
                    title: 'Фото №${photo.id}',
                    subtitle: photo.url,
                    trailing: UcraftButton(
                      label: strings.deleteLabel,
                      variant: UcraftButtonVariant.destructive,
                      onPressed: !widget.isLocked && !_busy
                          ? () => unawaited(_deletePhoto(photo))
                          : null,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

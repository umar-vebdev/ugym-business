import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_business/core/config/app_config.dart';
import 'package:ugym_business/core/l10n/business_localizations.dart';
import 'package:ugym_business/core/router/business_shell.dart';
import 'package:ugym_business/core/session/business_role.dart';
import 'package:ugym_business/core/session/business_session_controller.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_business/core/theme/theme_controller.dart';
import 'package:ugym_business/features/storefront_staff/domain/storefront_and_staff_models.dart';
import 'package:ugym_business/features/storefront_staff/presentation/gym_photo_picker.dart';
import 'package:ugym_business/features/storefront_staff/presentation/storefront_editor_screen.dart';
import 'package:ugym_core/ugym_core.dart';

final class _FakeStorefrontRepo implements StorefrontAndStaffRepository {
  GymProfile? lastUpdated;
  bool submitCalled = false;
  bool? lastIsPublic;
  int uploadCalls = 0;
  int? deletedPhotoId;

  @override
  Future<GymProfile> updateGymProfile({
    required int gymId,
    required GymProfileInput input,
  }) async {
    lastUpdated = GymProfile(
      gymId: gymId,
      isPublic: false,
      moderationStatus: ModerationStatus.draft,
      description: input.description,
      address: input.address,
      district: input.district,
      amenities: input.amenities ?? const [],
    );
    return lastUpdated!;
  }

  @override
  Future<GymProfile> submitGymProfile({required int gymId}) async {
    submitCalled = true;
    return GymProfile(
      gymId: gymId,
      isPublic: false,
      moderationStatus: ModerationStatus.pending,
    );
  }

  @override
  Future<GymProfile> setGymPublication({
    required int gymId,
    required bool isPublic,
  }) async {
    lastIsPublic = isPublic;
    return GymProfile(
      gymId: gymId,
      isPublic: isPublic,
      moderationStatus: ModerationStatus.approved,
    );
  }

  @override
  Future<GymPhoto> uploadGymPhoto({
    required int gymId,
    required List<int> bytes,
    required String filename,
  }) async {
    uploadCalls++;
    return GymPhoto(
      id: 100 + uploadCalls,
      gymId: gymId,
      url: 'https://cdn.ugym.tj/$filename',
      order: uploadCalls,
      createdAt: DateTime.utc(2026, 11, 17, 12, 0),
    );
  }

  @override
  Future<void> deleteGymPhoto({
    required int gymId,
    required int photoId,
  }) async {
    deletedPhotoId = photoId;
  }

  @override
  Future<void> deleteStaff({required int staffId}) =>
      throw UnimplementedError();

  @override
  Future<StaffMember> inviteStaff({
    required String email,
    required StaffRoleValue role,
  }) => throw UnimplementedError();

  @override
  Future<List<StaffMember>> listStaff() => throw UnimplementedError();

  @override
  Future<StaffMember> updateStaffRole({
    required int staffId,
    required StaffRoleValue role,
  }) => throw UnimplementedError();
}

Future<BusinessSessionController> _ownerSession() async {
  final prefs = AppPreferences(storage: InMemoryTokenStorage());
  final session = BusinessSessionController(preferences: prefs)
    ..setRole(BusinessRole.owner);
  await session.setGyms(const [GymSummary(id: 10, name: 'Центр')]);
  return session;
}

void main() {
  testWidgets(
    'StorefrontEditorScreen warns on approved edit, locks pending, and controls publication',
    (tester) async {
      final repo = _FakeStorefrontRepo();
      final session = await _ownerSession();

      // 1. Approved profile shows draft-reset warning and allows publication.
      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: StorefrontEditorScreen(
                repository: repo,
                sessionController: session,
                initialProfile: const GymProfile(
                  gymId: 10,
                  isPublic: false,
                  moderationStatus: ModerationStatus.approved,
                  district: 'Сино',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('переведёт витрину в статус draft'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Опубликовать в каталоге'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Опубликовать в каталоге'));
      await tester.pumpAndSettle();
      expect(repo.lastIsPublic, isTrue);

      // 2. Submit moves to pending and locks editing.
      await tester.ensureVisible(find.text('На модерацию'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('На модерацию'));
      await tester.pumpAndSettle();
      expect(repo.submitCalled, isTrue);
      expect(find.text('На модерации (pending)'), findsOneWidget);
      final saveButton = tester.widget<UcraftButton>(
        find.widgetWithText(UcraftButton, 'Сохранить витрину'),
      );
      expect(saveButton.onPressed, isNull);
    },
  );

  testWidgets(
    'GymPhotosManager validates formats, size limit, and 10-photo cap',
    (tester) async {
      final repo = _FakeStorefrontRepo();
      final session = await _ownerSession();

      PickedGymPhoto? nextPick = (bytes: const [1, 2, 3], filename: 'bad.gif');

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: StorefrontEditorScreen(
                repository: repo,
                sessionController: session,
                photoPicker: () async => nextPick,
                initialPhotos: List<GymPhoto>.generate(
                  9,
                  (i) => GymPhoto(
                    id: i + 1,
                    gymId: 10,
                    url: 'https://cdn.ugym.tj/$i.jpg',
                    order: i,
                    createdAt: DateTime.utc(2026, 11, 17, 12, 0),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Unsupported format rejected.
      await tester.ensureVisible(find.text('Загрузить фото'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Загрузить фото'));
      await tester.pumpAndSettle();
      expect(
        find.text('Допустимы только форматы JPEG, PNG или WEBP.'),
        findsOneWidget,
      );
      expect(repo.uploadCalls, 0);

      // Valid 10th photo uploaded and locks button at 10/10.
      nextPick = (bytes: const [1, 2, 3], filename: 'hall.webp');
      await tester.ensureVisible(find.text('Загрузить фото'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Загрузить фото'));
      await tester.pumpAndSettle();

      expect(repo.uploadCalls, 1);
      expect(find.text('Фотогалерея (10/10)'), findsOneWidget);
      final uploadBtn = tester.widget<UcraftButton>(
        find.widgetWithText(UcraftButton, 'Загрузить фото'),
      );
      expect(uploadBtn.onPressed, isNull);
    },
  );

  test('normalizePickedPhotoFilename handles paths, missing extensions, and blanks', () {
    expect(normalizePickedPhotoFilename(''), 'gym_photo.jpg');
    expect(normalizePickedPhotoFilename('/tmp/img/hall.webp'), 'hall.webp');
    expect(normalizePickedPhotoFilename(r'C:\photos\cardio'), 'cardio.jpg');
    expect(normalizePickedPhotoFilename('raw_photo.'), 'raw_photo.jpg');
  });

  testWidgets(
    'GymPhotosManager shows picker permission error gracefully and renders photo preview in BusinessShell',
    (tester) async {
      final repo = _FakeStorefrontRepo();
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final session = BusinessSessionController(
        preferences: prefs,
        initialRole: BusinessRole.owner,
      );
      final locale = LocaleController(preferences: prefs);
      final theme = ThemeController(preferences: prefs);
      await session.setGyms(const [GymSummary(id: 10, name: 'Центр')]);
      addTearDown(session.dispose);
      addTearDown(locale.dispose);
      addTearDown(theme.dispose);

      var shouldThrow = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: BusinessShell(
            config: const AppConfig.dev(),
            sessionController: session,
            localeController: locale,
            themeController: theme,
            storefrontAndStaffRepository: repo,
            gymPhotoPicker: () async {
              if (shouldThrow) {
                throw StateError('photo_access_denied');
              }
              return (bytes: const [1, 2, 3, 4], filename: 'gym_hall.jpg');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ещё'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(UcraftButton, 'Витрина'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Загрузить фото'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Загрузить фото'));
      await tester.pumpAndSettle();

      expect(
        find.text('Не удалось выбрать фото. Проверьте доступ к фотогалерее.'),
        findsOneWidget,
      );
      expect(repo.uploadCalls, 0);

      shouldThrow = false;
      await tester.tap(find.text('Загрузить фото'));
      await tester.pumpAndSettle();

      expect(repo.uploadCalls, 1);
      expect(find.text('Фотогалерея (1/10)'), findsOneWidget);
      expect(find.text('Фото №101'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    },
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_business/core/session/business_role.dart';
import 'package:ugym_business/core/session/business_session_controller.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_business/features/storefront_staff/domain/storefront_and_staff_models.dart';
import 'package:ugym_business/features/storefront_staff/presentation/staff_management_screen.dart';
import 'package:ugym_core/ugym_core.dart';

final class _FakeStaffRepo implements StorefrontAndStaffRepository {
  List<StaffMember> members = const [
    StaffMember(
      id: 1,
      userId: 5,
      companyId: 1,
      role: StaffRoleValue.owner,
      name: 'Али',
      email: 'ali@gym.tj',
    ),
    StaffMember(
      id: 2,
      userId: 6,
      companyId: 1,
      role: StaffRoleValue.admin,
      name: 'Мадина',
      email: 'madina@gym.tj',
    ),
  ];

  bool failInvite400 = false;
  ({int staffId, StaffRoleValue role})? lastRoleUpdate;
  int? lastDeletedStaffId;

  @override
  Future<List<StaffMember>> listStaff() async => members;

  @override
  Future<StaffMember> inviteStaff({
    required String email,
    required StaffRoleValue role,
  }) async {
    if (failInvite400) {
      throw const UgymApiException(
        code: 'BAD_REQUEST',
        statusCode: 400,
        message: 'Пользователь не найден или email не подтверждён.',
      );
    }
    return StaffMember(
      id: 3,
      userId: 7,
      companyId: 1,
      role: role,
      email: email,
    );
  }

  @override
  Future<StaffMember> updateStaffRole({
    required int staffId,
    required StaffRoleValue role,
  }) async {
    lastRoleUpdate = (staffId: staffId, role: role);
    return StaffMember(
      id: staffId,
      userId: 6,
      companyId: 1,
      role: role,
      name: 'Мадина',
      email: 'madina@gym.tj',
    );
  }

  @override
  Future<void> deleteStaff({required int staffId}) async {
    lastDeletedStaffId = staffId;
  }

  @override
  Future<void> deleteGymPhoto({required int gymId, required int photoId}) =>
      throw UnimplementedError();

  @override
  Future<GymProfile> setGymPublication({
    required int gymId,
    required bool isPublic,
  }) => throw UnimplementedError();

  @override
  Future<GymProfile> submitGymProfile({required int gymId}) =>
      throw UnimplementedError();

  @override
  Future<GymProfile> updateGymProfile({
    required int gymId,
    required GymProfileInput input,
  }) => throw UnimplementedError();

  @override
  Future<GymPhoto> uploadGymPhoto({
    required int gymId,
    required List<int> bytes,
    required String filename,
  }) => throw UnimplementedError();
}

BusinessSessionController _session(BusinessRole role) {
  final prefs = AppPreferences(storage: InMemoryTokenStorage());
  return BusinessSessionController(preferences: prefs)..setRole(role);
}

void main() {
  testWidgets(
    'StaffManagementScreen blocks non-owner, shows OTP hint on 400, toggles role, and deletes',
    (tester) async {
      final repo = _FakeStaffRepo()..failInvite400 = true;

      // 1. Admin cannot view/manage staff.
      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: StaffManagementScreen(
              repository: repo,
              sessionController: _session(BusinessRole.admin),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Недостаточно прав'), findsOneWidget);

      // 2. Owner sees staff, gets OTP onboarding hint on 400.
      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: StaffManagementScreen(
                repository: repo,
                sessionController: _session(BusinessRole.owner),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Али'), findsOneWidget);
      expect(find.text('Мадина'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'new@gym.tj');
      await tester.ensureVisible(find.text('Добавить в штат'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Добавить в штат'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('зарегистрироваться с этим email и ввести OTP-код'),
        findsOneWidget,
      );

      // 3. Successful invite as trainer.
      repo.failInvite400 = false;
      await tester.tap(find.text('Тренер'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Добавить в штат'));
      await tester.pumpAndSettle();
      expect(find.text('new@gym.tj'), findsWidgets);

      // 4. Toggle role admin -> trainer for Madina (id: 2).
      await tester.ensureVisible(find.text('Сделать тренером'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сделать тренером'));
      await tester.pumpAndSettle();
      expect(repo.lastRoleUpdate, (staffId: 2, role: StaffRoleValue.trainer));

      // 5. Delete staff member id: 2.
      await tester.ensureVisible(find.text('Удалить').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить').first);
      await tester.pumpAndSettle();
      expect(repo.lastDeletedStaffId, 2);
      expect(find.text('Мадина'), findsNothing);
    },
  );
}

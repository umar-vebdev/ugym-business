import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_business/core/l10n/business_localizations.dart';
import 'package:ugym_business/core/session/business_role.dart';
import 'package:ugym_business/core/session/business_session_controller.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_business/features/memberships/domain/memberships_models.dart';
import 'package:ugym_business/features/memberships/presentation/memberships_screens.dart';
import 'package:ugym_core/ugym_core.dart';

final class _FakeMembershipsRepository implements MembershipsRepository {
  List<MembershipType> types = const [
    MembershipType(
      id: 1,
      name: 'Безлимит 30 дней',
      kind: MembershipKind.unlimitedTime,
      startMode: MembershipStartMode.onPurchase,
      priceMinor: 25000,
      currency: 'TJS',
      durationDays: 30,
      dailyLimit: 1,
      isActive: true,
    ),
  ];

  List<ClientMembership> expiring = [
    ClientMembership(
      id: 51,
      clientId: 11,
      typeId: 1,
      kind: MembershipKind.unlimitedTime,
      status: MembershipStatus.active,
      endsAt: DateTime.utc(2026, 11, 22, 12, 0),
    ),
  ];

  CreateMembershipTypeInput? lastCreatedInput;
  bool throwInvalidRules = false;
  int? lastToggledTypeId;
  bool? lastToggledActive;
  int? lastFrozenId;
  int? lastUnfrozenId;
  ({int id, String reason})? lastCancelled;

  @override
  Future<int> createMembershipType(CreateMembershipTypeInput input) async {
    lastCreatedInput = input;
    if (throwInvalidRules) {
      throw const UgymApiException(
        code: 'INVALID_MEMBERSHIP_RULES',
        message: 'Для этого типа нельзя выбрать старт с первого визита.',
      );
    }
    return 10;
  }

  @override
  Future<List<MembershipType>> listMembershipTypes({bool? onlyActive}) async =>
      types;

  @override
  Future<bool> setMembershipTypeActive({
    required int typeId,
    required bool isActive,
  }) async {
    lastToggledTypeId = typeId;
    lastToggledActive = isActive;
    return true;
  }

  @override
  Future<List<ClientMembership>> listExpiringMemberships() async => expiring;

  @override
  Future<MembershipFreezeState> freezeMembership({
    required int membershipId,
  }) async {
    lastFrozenId = membershipId;
    return MembershipFreezeState(
      id: membershipId,
      status: MembershipStatus.frozen,
      freezeDaysUsed: 0,
      freezeTimesUsed: 1,
    );
  }

  @override
  Future<MembershipFreezeState> unfreezeMembership({
    required int membershipId,
  }) async {
    lastUnfrozenId = membershipId;
    return MembershipFreezeState(
      id: membershipId,
      status: MembershipStatus.active,
      freezeDaysUsed: 2,
      freezeTimesUsed: 1,
    );
  }

  @override
  Future<ClientMembership> cancelMembership({
    required int membershipId,
    required String reason,
  }) async {
    lastCancelled = (id: membershipId, reason: reason);
    return ClientMembership(
      id: membershipId,
      clientId: 11,
      typeId: 1,
      kind: MembershipKind.unlimitedTime,
      status: MembershipStatus.cancelled,
      cancellationReason: reason,
    );
  }

  @override
  Future<List<ClientMembership>> listClientMemberships({
    required int clientId,
  }) {
    throw UnimplementedError();
  }
}

BusinessSessionController _session(BusinessRole role) {
  final prefs = AppPreferences(storage: InMemoryTokenStorage());
  return BusinessSessionController(preferences: prefs)..setRole(role);
}

void main() {
  testWidgets(
    'MembershipTypesScreen hides create/archive from admin and allows owner to toggle',
    (tester) async {
      final repo = _FakeMembershipsRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: MembershipTypesScreen(
                repository: repo,
                sessionController: _session(BusinessRole.admin),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Безлимит 30 дней'), findsOneWidget);
      expect(find.text('Создать тариф'), findsNothing);
      expect(find.text('В архив'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: MembershipTypesScreen(
                repository: repo,
                sessionController: _session(BusinessRole.owner),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Создать тариф'), findsOneWidget);
      await tester.tap(find.text('В архив'));
      await tester.pumpAndSettle();

      expect(repo.lastToggledTypeId, 1);
      expect(repo.lastToggledActive, isFalse);
    },
  );

  testWidgets(
    'CreateMembershipTypeScreen validates mixed kind and shows server INVALID_MEMBERSHIP_RULES',
    (tester) async {
      final repo = _FakeMembershipsRepository()..throwInvalidRules = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: CreateMembershipTypeScreen(repository: repo),
        ),
      );

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Комбо 10');
      await tester.enterText(fields.at(1), '300');
      await tester.tap(find.text('Визиты + срок'));
      await tester.pumpAndSettle();

      // Missing visits_count for mixed -> client validation blocks submit.
      await tester.enterText(fields.at(2), '30');
      await tester.ensureVisible(find.text('Сохранить тариф'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сохранить тариф'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Для смешанного тарифа укажите и визиты, и длительность в днях.',
        ),
        findsOneWidget,
      );
      expect(repo.lastCreatedInput, isNull);

      await tester.enterText(fields.at(3), '10');
      await tester.ensureVisible(find.text('Сохранить тариф'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сохранить тариф'));
      await tester.pumpAndSettle();

      expect(repo.lastCreatedInput?.priceMinor, 30000);
      expect(
        find.text('Для этого типа нельзя выбрать старт с первого визита.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'ExpiringMembershipsTab supports freeze/unfreeze for admin and cancel with reason for owner',
    (tester) async {
      final repo = _FakeMembershipsRepository();

      // Admin: can freeze/unfreeze, cannot cancel.
      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExpiringMembershipsTab(
                repository: repo,
                sessionController: _session(BusinessRole.admin),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Заморозить'), findsOneWidget);
      expect(find.text('Отменить'), findsNothing);

      await tester.tap(find.text('Заморозить'));
      await tester.pumpAndSettle();
      expect(repo.lastFrozenId, 51);
      expect(find.text('Разморозить'), findsOneWidget);

      await tester.tap(find.text('Разморозить'));
      await tester.pumpAndSettle();
      expect(repo.lastUnfrozenId, 51);

      // Owner: can cancel with required reason.
      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExpiringMembershipsTab(
                repository: repo,
                sessionController: _session(BusinessRole.owner),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Отменить'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Клиент уехал');
      await tester.tap(find.text('Подтвердить отмену'));
      await tester.pumpAndSettle();

      expect(repo.lastCancelled, (id: 51, reason: 'Клиент уехал'));
      expect(find.text('cancelled'), findsOneWidget);
    },
  );

  testWidgets(
    'MembershipTypesScreen and ExpiringMembershipsTab render localized labels in tg and en',
    (tester) async {
      final repo = _FakeMembershipsRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: BusinessStringsScope(
            strings: BusinessStrings.tg,
            child: Scaffold(
              body: SingleChildScrollView(
                child: MembershipTypesScreen(
                  repository: repo,
                  sessionController: _session(BusinessRole.owner),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Тарифҳои обуна'), findsOneWidget);
      expect(find.text('Сохтани тариф'), findsOneWidget);
      expect(find.text('Ба бойгонӣ'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: BusinessStringsScope(
            strings: BusinessStrings.en,
            child: Scaffold(
              body: SingleChildScrollView(
                child: ExpiringMembershipsTab(
                  repository: repo,
                  sessionController: _session(BusinessRole.owner),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Expiring in 7 days'), findsOneWidget);
      expect(find.text('Freeze'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    },
  );
}

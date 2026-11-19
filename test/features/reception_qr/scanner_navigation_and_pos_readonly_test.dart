import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_business/core/config/app_config.dart';
import 'package:ugym_business/core/l10n/business_localizations.dart';
import 'package:ugym_business/core/router/business_shell.dart';
import 'package:ugym_business/core/router/role_guard_and_banners.dart';
import 'package:ugym_business/core/session/business_role.dart';
import 'package:ugym_business/core/session/business_session_controller.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_business/core/theme/theme_controller.dart';
import 'package:ugym_business/features/clients/domain/clients_models.dart';
import 'package:ugym_business/features/clients/presentation/clients_list_screen.dart';
import 'package:ugym_business/features/memberships/domain/memberships_models.dart';
import 'package:ugym_business/features/reception_qr/domain/reception_visits_models.dart';
import 'package:ugym_business/features/sales/domain/sales_and_requests_models.dart';
import 'package:ugym_business/features/sales/presentation/pos_and_products_screens.dart';
import 'package:ugym_core/ugym_core.dart';

final class _RefusingVisitsRepo implements ReceptionVisitsRepository {
  _RefusingVisitsRepo(this.nextError);

  UgymApiException nextError;

  @override
  Future<CheckInResult> checkInByClientQr({
    required int gymId,
    required String token,
    String? device,
    String? idempotencyKey,
  }) async {
    throw nextError;
  }

  @override
  Future<List<VisitRecord>> listCompanyVisits() async => const [];

  @override
  Future<List<VisitRecord>> listClientVisits({required int clientId}) async =>
      const [];

  @override
  Future<VisitRecord> cancelVisit({
    required int visitId,
    required String reason,
  }) => throw UnimplementedError();

  @override
  Future<GymQrToken> fetchGymQr({required int gymId}) =>
      throw UnimplementedError();

  @override
  Future<CheckInResult> registerManualVisit({
    required int clientId,
    required int gymId,
    DateTime? visitedAt,
    String? device,
    String? idempotencyKey,
  }) => throw UnimplementedError();
}

final class _FakeClientsRepo implements ClientsRepository {
  @override
  Future<ClientsPage> listClients({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async => const ClientsPage(
    items: [
      ClientSummary(
        id: 11,
        name: 'Фарход',
        phone: '+992900001122',
        linked: true,
      ),
    ],
    page: 1,
    perPage: 20,
    total: 1,
  );

  @override
  Future<int> createClient({
    required String name,
    required String phone,
    String? email,
  }) => throw UnimplementedError();

  @override
  Future<bool> mergeClients({required int sourceId, required int targetId}) =>
      throw UnimplementedError();
}

final class _FakeSalesRepo implements SalesAndRequestsRepository {
  @override
  Future<List<ProductItem>> listProducts({bool? onlyActive}) async => const [];

  @override
  Future<List<MembershipRequestRecord>> listMembershipRequests({
    MembershipRequestStatus? status,
  }) async => const [];

  @override
  Future<List<SaleRecord>> listSales() async => const [];

  @override
  Future<List<SaleRecord>> listClientSales({required int clientId}) async =>
      const [];

  @override
  Future<MembershipRequestStatus> cancelMembershipRequest({
    required int requestId,
    String? reason,
  }) => throw UnimplementedError();

  @override
  Future<int> createProduct({
    required String name,
    required int priceMinor,
    String? currency,
    int? stockQuantity,
  }) => throw UnimplementedError();

  @override
  Future<PayRequestResult> payMembershipRequest({
    required int requestId,
    required PaymentMethod paymentMethod,
    String? idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<SaleRecord> refundSale({
    required int saleId,
    required String reason,
  }) => throw UnimplementedError();

  @override
  Future<SaleRecord> registerSale({
    int? clientId,
    required PaymentMethod paymentMethod,
    List<SaleProductLineInput> products = const <SaleProductLineInput>[],
    List<int> membershipTypeIds = const <int>[],
    String? idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<ProductItem> updateProduct({
    required int productId,
    bool? isActive,
    int? stockQuantity,
  }) => throw UnimplementedError();
}

final class _FakeMembershipsRepo implements MembershipsRepository {
  @override
  Future<List<MembershipType>> listMembershipTypes({bool? onlyActive}) async =>
      const [
        MembershipType(
          id: 3,
          name: 'Безлимит 30д',
          kind: MembershipKind.unlimitedTime,
          startMode: MembershipStartMode.onPurchase,
          priceMinor: 25000,
          currency: 'TJS',
          dailyLimit: 1,
          isActive: true,
        ),
      ];

  @override
  Future<List<ClientMembership>> listExpiringMemberships() async => const [];

  @override
  Future<List<ClientMembership>> listClientMemberships({
    required int clientId,
  }) async => const [];

  @override
  Future<ClientMembership> cancelMembership({
    required int membershipId,
    required String reason,
  }) => throw UnimplementedError();

  @override
  Future<int> createMembershipType(CreateMembershipTypeInput input) =>
      throw UnimplementedError();

  @override
  Future<MembershipFreezeState> freezeMembership({required int membershipId}) =>
      throw UnimplementedError();

  @override
  Future<bool> setMembershipTypeActive({
    required int typeId,
    required bool isActive,
  }) => throw UnimplementedError();

  @override
  Future<MembershipFreezeState> unfreezeMembership({
    required int membershipId,
  }) => throw UnimplementedError();
}

Widget _fakeScanner(BuildContext context, ValueChanged<String> onDetect) {
  return Center(
    child: ElevatedButton(
      onPressed: () => onDetect('client-qr-token'),
      child: const Text('simulate-client-qr'),
    ),
  );
}

void main() {
  testWidgets(
    'BusinessShell scanner navigates to PosCheckoutScreen on NO_ACTIVE_MEMBERSHIP and ClientsListScreen on MEMBERSHIP_FROZEN',
    (tester) async {
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final session = BusinessSessionController(
        preferences: prefs,
        initialRole: BusinessRole.admin,
      );
      final locale = LocaleController(preferences: prefs);
      final theme = ThemeController(preferences: prefs);
      await session.setGyms(const [GymSummary(id: 10, name: 'Центр')]);
      addTearDown(session.dispose);
      addTearDown(locale.dispose);
      addTearDown(theme.dispose);

      final visitsRepo = _RefusingVisitsRepo(
        const UgymApiException(
          statusCode: 422,
          code: 'NO_ACTIVE_MEMBERSHIP',
          message: 'У клиента нет активного абонемента.',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: BusinessShell(
            config: const AppConfig.dev(),
            sessionController: session,
            localeController: locale,
            themeController: theme,
            visitsRepository: visitsRepo,
            clientsRepository: _FakeClientsRepo(),
            salesRepository: _FakeSalesRepo(),
            membershipsRepository: _FakeMembershipsRepo(),
            qrScannerBuilder: _fakeScanner,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Open scanner -> NO_ACTIVE_MEMBERSHIP -> tap "Принять оплату" -> opens POS.
      await tester.tap(find.text('Сканер QR клиента'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('simulate-client-qr'));
      await tester.pumpAndSettle();

      expect(find.text('Нет активного абонемента'), findsOneWidget);
      expect(find.text('Принять оплату'), findsOneWidget);
      expect(find.text('Открыть клиентов'), findsOneWidget);

      await tester.tap(find.text('Принять оплату'));
      await tester.pumpAndSettle();

      expect(find.byType(PosCheckoutScreen), findsOneWidget);
      expect(find.text('Касса'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      // 2. Open scanner -> MEMBERSHIP_FROZEN -> tap "Открыть клиентов" -> switches to Clients tab.
      visitsRepo.nextError = const UgymApiException(
        statusCode: 422,
        code: 'MEMBERSHIP_FROZEN',
        message: 'Абонемент клиента заморожен.',
      );

      await tester.tap(find.text('Сканер QR клиента'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('simulate-client-qr'));
      await tester.pumpAndSettle();

      expect(find.text('Абонемент заморожен'), findsOneWidget);
      expect(find.text('Принять оплату'), findsNothing);
      await tester.tap(find.text('Открыть клиентов'));
      await tester.pumpAndSettle();

      expect(find.byType(ClientsListScreen), findsOneWidget);
      expect(find.text('Фарход (#11)'), findsOneWidget);
    },
  );

  testWidgets(
    'PosCheckoutScreen displays read-only banner and disables submit when subscription expires',
    (tester) async {
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final session = BusinessSessionController(
        preferences: prefs,
        initialRole: BusinessRole.owner,
      );
      addTearDown(session.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: PosCheckoutScreen(
            salesRepository: _FakeSalesRepo(),
            membershipsRepository: _FakeMembershipsRepo(),
            sessionController: session,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SubscriptionReadOnlyBanner), findsOneWidget);
      expect(
        find.text('Подписка истекла — доступен только просмотр'),
        findsNothing,
      );

      final submitBefore = tester.widget<UcraftButton>(
        find.widgetWithText(UcraftButton, 'Провести продажу'),
      );
      expect(submitBefore.onPressed, isNotNull);

      session.markSubscriptionExpired();
      await tester.pumpAndSettle();

      expect(
        find.text('Подписка истекла — доступен только просмотр'),
        findsOneWidget,
      );
      final submitAfter = tester.widget<UcraftButton>(
        find.widgetWithText(UcraftButton, 'Провести продажу'),
      );
      expect(submitAfter.onPressed, isNull);
    },
  );
}

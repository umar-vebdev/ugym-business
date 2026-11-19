import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_business/core/l10n/business_localizations.dart';
import 'package:ugym_business/core/session/business_role.dart';
import 'package:ugym_business/core/session/business_session_controller.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_business/features/clients/domain/clients_models.dart';
import 'package:ugym_business/features/clients/presentation/clients_list_screen.dart';
import 'package:ugym_core/ugym_core.dart';

final class _FakeClientsRepository implements ClientsRepository {
  List<ClientSummary> items = const [
    ClientSummary(
      id: 1,
      name: 'Фарход',
      phone: '+992900001122',
      email: 'farhod@gym.tj',
      linked: true,
    ),
    ClientSummary(id: 2, name: 'Зарина', phone: '+992900003344', linked: false),
  ];

  String? lastSearch;
  bool throwPhoneExistsOnCreate = false;
  final List<({int sourceId, int targetId})> mergeCalls =
      <({int sourceId, int targetId})>[];

  @override
  Future<ClientsPage> listClients({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    lastSearch = search;
    final trimmed = search?.trim().toLowerCase() ?? '';
    final filtered = trimmed.isEmpty
        ? items
        : items
              .where(
                (c) =>
                    c.name.toLowerCase().contains(trimmed) ||
                    c.phone.toLowerCase().contains(trimmed),
              )
              .toList(growable: false);
    return ClientsPage(
      items: filtered,
      page: page,
      perPage: perPage,
      total: filtered.length,
    );
  }

  @override
  Future<int> createClient({
    required String name,
    required String phone,
    String? email,
  }) async {
    if (throwPhoneExistsOnCreate) {
      throw const UgymApiException(
        code: 'CLIENT_PHONE_EXISTS',
        message: 'Клиент с таким телефоном уже существует.',
      );
    }
    return 99;
  }

  @override
  Future<bool> mergeClients({
    required int sourceId,
    required int targetId,
  }) async {
    mergeCalls.add((sourceId: sourceId, targetId: targetId));
    return true;
  }
}

BusinessSessionController _sessionFor(
  BusinessRole role, {
  bool isReadOnly = false,
}) {
  final prefs = AppPreferences(storage: InMemoryTokenStorage());
  return BusinessSessionController(preferences: prefs)
    ..setRole(role)
    ..setSubscriptionStatus(isReadOnly: isReadOnly);
}

void main() {
  testWidgets(
    'ClientsListScreen shows linked badges, searches, and restricts merge to owner',
    (tester) async {
      final repo = _FakeClientsRepository();
      final adminSession = _sessionFor(BusinessRole.admin);

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClientsListScreen(
                repository: repo,
                sessionController: adminSession,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Фарход (#1)'), findsOneWidget);
      expect(find.text('Привязан к uGym'), findsOneWidget);
      expect(find.text('Оффлайн-карточка'), findsOneWidget);
      expect(find.text('Объединить дубли'), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'Фарход');
      await tester.tap(find.text('Найти'));
      await tester.pumpAndSettle();
      expect(repo.lastSearch, 'Фарход');
      expect(find.text('Фарход (#1)'), findsOneWidget);
      expect(find.text('Зарина (#2)'), findsNothing);
    },
  );

  testWidgets('Owner can merge duplicate clients after confirmation dialog', (
    tester,
  ) async {
    final repo = _FakeClientsRepository();
    final ownerSession = _sessionFor(BusinessRole.owner);

    await tester.pumpWidget(
      MaterialApp(
        theme: UcraftTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClientsListScreen(
              repository: repo,
              sessionController: ownerSession,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Объединить дубли'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), '2');
    await tester.enterText(fields.at(2), '1');
    await tester.tap(find.text('Подтвердить слияние'));
    await tester.pumpAndSettle();

    expect(repo.mergeCalls.length, 1);
    expect(repo.mergeCalls.single, (sourceId: 2, targetId: 1));
  });

  testWidgets(
    'CreateClientSheet shows email hint and opens existing client on 409 CLIENT_PHONE_EXISTS',
    (tester) async {
      final repo = _FakeClientsRepository()..throwPhoneExistsOnCreate = true;
      ClientSummary? openedExisting;

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: CreateClientSheet(
              repository: repo,
              onOpenExistingClient: (client) => openedExisting = client,
            ),
          ),
        ),
      );

      expect(
        find.textContaining(
          'Если клиент подтвердит этот email в приложении uGym',
        ),
        findsOneWidget,
      );

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Фарход');
      await tester.enterText(fields.at(1), '+992900001122');

      await tester.ensureVisible(find.text('Создать клиента'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Создать клиента'));
      await tester.pumpAndSettle();

      expect(
        find.text('Клиент с таким телефоном уже существует.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Открыть существующую карточку'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Открыть существующую карточку'));
      await tester.pumpAndSettle();

      expect(openedExisting?.id, 1);
    },
  );

  testWidgets(
    'ClientsListScreen and CreateClientSheet render localized labels in tg and en',
    (tester) async {
      final repo = _FakeClientsRepository();
      final session = BusinessSessionController(
        preferences: AppPreferences(storage: InMemoryTokenStorage()),
        initialRole: BusinessRole.owner,
      );
      addTearDown(session.dispose);

      // Tajik
      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: BusinessStringsScope(
            strings: BusinessStrings.tg,
            child: Scaffold(
              body: SingleChildScrollView(
                child: ClientsListScreen(
                  repository: repo,
                  sessionController: session,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Иловаи мизоҷ'), findsOneWidget);
      expect(find.text('Муттаҳид кардани такрорҳо'), findsOneWidget);
      expect(find.text('Ба uGym пайваст'), findsOneWidget);
      expect(find.text('Корти офлайн'), findsOneWidget);

      // English
      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: BusinessStringsScope(
            strings: BusinessStrings.en,
            child: Scaffold(
              body: SingleChildScrollView(
                child: ClientsListScreen(
                  repository: repo,
                  sessionController: session,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add client'), findsOneWidget);
      expect(find.text('Merge duplicates'), findsOneWidget);
      expect(find.text('Linked to uGym'), findsOneWidget);
      expect(find.text('Offline profile'), findsOneWidget);
    },
  );
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_business/core/session/business_role.dart';
import 'package:ugym_business/core/session/business_session_controller.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_business/features/company_onboarding/data/remote_company_onboarding_repository.dart';
import 'package:ugym_business/features/company_onboarding/domain/company_onboarding_models.dart';
import 'package:ugym_business/features/company_onboarding/presentation/company_onboarding_screen.dart';
import 'package:ugym_core/ugym_core.dart';

final class _FakeCompanyAdapter implements HttpClientAdapter {
  _FakeCompanyAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int statusCode, Map<String, Object?> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

final class _InMemoryCompanyRepo implements CompanyOnboardingRepository {
  final List<GymBranch> gyms = <GymBranch>[
    const GymBranch(
      id: 1,
      companyId: 10,
      name: 'Main Gym',
      address: 'Rudaki 10',
    ),
  ];

  final List<CurrencyOption> currencies = const <CurrencyOption>[
    CurrencyOption(id: 1, code: 'TJS', name: 'Сомони', symbol: 'SM'),
    CurrencyOption(id: 2, code: 'USD', name: 'Доллар', symbol: r'$'),
  ];

  String selectedCurrency = 'TJS';

  @override
  Future<CreatedCompanyResult> createCompany({
    required String companyName,
    required String gymName,
    String? gymAddress,
  }) async {
    gyms
      ..clear()
      ..add(
        GymBranch(
          id: 99,
          companyId: 50,
          name: gymName.trim(),
          address: gymAddress?.trim().isEmpty ?? true
              ? null
              : gymAddress?.trim(),
        ),
      );
    return const CreatedCompanyResult(companyId: 50, gymId: 99);
  }

  @override
  Future<List<GymBranch>> listGyms() async =>
      List<GymBranch>.unmodifiable(gyms);

  @override
  Future<GymBranch> createGym({
    required String name,
    String? address,
    String timezone = 'Asia/Dushanbe',
    bool geoCheckEnabled = false,
    int geoCheckRadiusMeters = 200,
  }) async {
    final branch = GymBranch(
      id: gyms.length + 1,
      companyId: 10,
      name: name.trim(),
      address: address?.trim().isEmpty ?? true ? null : address?.trim(),
      timezone: timezone,
      geoCheckEnabled: geoCheckEnabled,
      geoCheckRadiusMeters: geoCheckRadiusMeters,
    );
    gyms.add(branch);
    return branch;
  }

  @override
  Future<GymBranch> updateGym({
    required int gymId,
    required String name,
    String? address,
    String timezone = 'Asia/Dushanbe',
    bool geoCheckEnabled = false,
    int geoCheckRadiusMeters = 200,
  }) async {
    final updated = GymBranch(
      id: gymId,
      companyId: 10,
      name: name.trim(),
      address: address?.trim().isEmpty ?? true ? null : address?.trim(),
      timezone: timezone,
      geoCheckEnabled: geoCheckEnabled,
      geoCheckRadiusMeters: geoCheckRadiusMeters,
    );
    final idx = gyms.indexWhere((g) => g.id == gymId);
    if (idx >= 0) {
      gyms[idx] = updated;
    }
    return updated;
  }

  @override
  Future<List<CurrencyOption>> listCurrencies() async => currencies;

  @override
  Future<String> updateCompanyCurrency({required int currencyId}) async {
    selectedCurrency = currencies.firstWhere((c) => c.id == currencyId).code;
    return selectedCurrency;
  }
}

void main() {
  group('RemoteCompanyOnboardingRepository', () {
    test(
      'handles company creation, gym CRUD, and currency endpoints',
      () async {
        final client = UgymHttpClient(
          baseUrl: 'https://api.ugym.tj/api/v1',
          tokenStorage: InMemoryTokenStorage(initialToken: 'tok'),
        );
        final adapter = _FakeCompanyAdapter((options) async {
          if (options.path == '/business/companies' &&
              options.method == 'POST') {
            return _json(201, <String, Object?>{
              'data': <String, Object?>{'company_id': 11, 'gym_id': 22},
            });
          }
          if (options.path == '/business/gyms' && options.method == 'GET') {
            return _json(200, <String, Object?>{
              'data': <Object?>[
                <String, Object?>{
                  'id': 22,
                  'company_id': 11,
                  'name': 'Center',
                  'address': 'Rudaki 5',
                  'timezone': 'Asia/Dushanbe',
                  'geo_check_enabled': true,
                  'geo_check_radius_meters': 350,
                },
              ],
            });
          }
          if (options.path == '/business/gyms' && options.method == 'POST') {
            return _json(201, <String, Object?>{
              'data': <String, Object?>{
                'id': 23,
                'company_id': 11,
                'name': 'North',
                'address': null,
                'timezone': 'Asia/Dushanbe',
                'geo_check_enabled': false,
                'geo_check_radius_meters': 200,
              },
            });
          }
          if (options.path == '/business/gyms/22' &&
              options.method == 'PATCH') {
            return _json(200, <String, Object?>{
              'data': <String, Object?>{
                'id': 22,
                'company_id': 11,
                'name': 'Center Updated',
                'address': 'Rudaki 10',
                'timezone': 'Asia/Dushanbe',
                'geo_check_enabled': true,
                'geo_check_radius_meters': 500,
              },
            });
          }
          if (options.path == '/business/currencies') {
            return _json(200, <String, Object?>{
              'data': <Object?>[
                <String, Object?>{
                  'id': 1,
                  'code': 'TJS',
                  'name': 'Somoni',
                  'symbol': 'SM',
                },
              ],
            });
          }
          return _json(200, <String, Object?>{
            'data': <String, Object?>{
              'company_id': 11,
              'currency_id': 2,
              'currency_code': 'USD',
            },
          });
        });
        client.dio.httpClientAdapter = adapter;

        final repo = RemoteCompanyOnboardingRepository(httpClient: client);

        final created = await repo.createCompany(
          companyName: 'FitCo',
          gymName: 'Center',
        );
        expect(created, const CreatedCompanyResult(companyId: 11, gymId: 22));

        final gyms = await repo.listGyms();
        expect(gyms.single.geoCheckEnabled, isTrue);
        expect(gyms.single.geoCheckRadiusMeters, 350);

        final newGym = await repo.createGym(name: 'North');
        expect(newGym.id, 23);

        final updated = await repo.updateGym(
          gymId: 22,
          name: 'Center Updated',
          address: 'Rudaki 10',
          geoCheckEnabled: true,
          geoCheckRadiusMeters: 500,
        );
        expect(updated.name, 'Center Updated');
        expect(updated.geoCheckRadiusMeters, 500);

        final currencies = await repo.listCurrencies();
        expect(currencies.single.code, 'TJS');

        final code = await repo.updateCompanyCurrency(currencyId: 2);
        expect(code, 'USD');
      },
    );
  });

  group('CompanyOnboarding widgets', () {
    testWidgets('CompanyOnboardingCard promotes noCompany user to owner', (
      tester,
    ) async {
      final repo = _InMemoryCompanyRepo();
      final session = BusinessSessionController(
        preferences: AppPreferences(storage: InMemoryTokenStorage()),
        initialRole: BusinessRole.noCompany,
      );
      var completed = false;
      addTearDown(session.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CompanyOnboardingCard(
                repository: repo,
                sessionController: session,
                onCompleted: () => completed = true,
              ),
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('onboarding_company_name')),
        'Atlas Fitness',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('onboarding_gym_name')),
        'Atlas Main',
      );
      await tester.tap(find.text('Создать компанию (14 дней бесплатно)'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(session.role, BusinessRole.owner);
      expect(session.selectedGym?.id, 99);
      expect(session.selectedGym?.name, 'Atlas Main');
    });

    testWidgets(
      'CompanyBranchesAndCurrencyCard adds gym with geofence and updates currency',
      (tester) async {
        final repo = _InMemoryCompanyRepo();
        final session = BusinessSessionController(
          preferences: AppPreferences(storage: InMemoryTokenStorage()),
          initialRole: BusinessRole.owner,
        );
        addTearDown(session.dispose);

        await tester.pumpWidget(
          MaterialApp(
            theme: UcraftTheme.dark(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: CompanyBranchesAndCurrencyCard(
                  repository: repo,
                  sessionController: session,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Main Gym'), findsOneWidget);

        await tester.enterText(
          find.byKey(const ValueKey<String>('gym_branch_name')),
          'Sino Branch',
        );
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey<String>('gym_geofence_radius')),
          '400',
        );
        await tester.tap(find.widgetWithText(UcraftButton, 'Добавить филиал'));
        await tester.pumpAndSettle();

        expect(find.text('Sino Branch'), findsOneWidget);
        expect(find.text('400 м'), findsOneWidget);
        expect(session.gyms, hasLength(2));

        final currency = find.byKey(const ValueKey('company_currency'));
        await tester.ensureVisible(currency);
        await tester.pumpAndSettle();
        await tester.tap(currency);
        await tester.pumpAndSettle();
        await tester.tap(find.text('USD (Доллар)'));
        await tester.pumpAndSettle();
        expect(repo.selectedCurrency, 'USD');
        expect(find.text('Валюта компании: USD'), findsOneWidget);
      },
    );
  });
}

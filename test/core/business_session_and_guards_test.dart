import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_business/core/router/role_guard_and_banners.dart';
import 'package:ugym_business/core/session/business_role.dart';
import 'package:ugym_business/core/session/business_session_controller.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_core/ugym_core.dart';

final class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
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

void main() {
  group('BusinessRole RBAC matrix', () {
    test('owner, admin, trainer, and noCompany enforce exact permissions', () {
      expect(BusinessRole.owner.can(BusinessPermission.viewAnalytics), isTrue);
      expect(BusinessRole.owner.can(BusinessPermission.manageStaff), isTrue);
      expect(BusinessRole.owner.can(BusinessPermission.createCompany), isFalse);

      expect(BusinessRole.admin.can(BusinessPermission.viewGyms), isTrue);
      expect(
        BusinessRole.admin.can(
          BusinessPermission.manageMembershipRequestsAndSales,
        ),
        isTrue,
      );
      expect(BusinessRole.admin.can(BusinessPermission.viewAnalytics), isFalse);
      expect(BusinessRole.admin.can(BusinessPermission.manageStaff), isFalse);

      expect(
        BusinessRole.trainer.can(BusinessPermission.viewSessionBookings),
        isTrue,
      );
      expect(
        BusinessRole.trainer.can(BusinessPermission.manageClientsCrm),
        isFalse,
      );

      expect(
        BusinessRole.noCompany.can(BusinessPermission.createCompany),
        isTrue,
      );
      expect(BusinessRole.noCompany.can(BusinessPermission.viewGyms), isFalse);
    });
  });

  group('BusinessSessionController', () {
    test(
      'bootstraps owner with gyms and expired read-only subscription',
      () async {
        final prefs = AppPreferences(storage: InMemoryTokenStorage());
        final session = BusinessSessionController(preferences: prefs);
        final client = UgymHttpClient(
          baseUrl: 'https://api.ugym.tj/api/v1',
          tokenStorage: InMemoryTokenStorage(initialToken: 'tok'),
        );

        client.dio.httpClientAdapter = _MockAdapter((options) async {
          if (options.path == '/business/staff') {
            return _json(200, <String, Object?>{'data': <Object?>[]});
          }
          if (options.path == '/business/gyms') {
            return _json(200, <String, Object?>{
              'data': <Object?>[
                <String, Object?>{
                  'id': 10,
                  'name': 'Dushanbe Central',
                  'timezone': 'Asia/Dushanbe',
                },
                <String, Object?>{
                  'id': 20,
                  'name': 'Khujand North',
                  'timezone': 'Asia/Dushanbe',
                },
              ],
            });
          }
          return _json(200, <String, Object?>{
            'data': <String, Object?>{
              'id': 1,
              'company_id': 5,
              'status': 'expired',
              'is_read_only': true,
            },
          });
        });

        final role = await session.bootstrapFromApi(client);
        expect(role, BusinessRole.owner);
        expect(session.isReadOnly, isTrue);
        expect(session.gyms, hasLength(2));
        expect(session.selectedGym?.id, 10);
        expect(session.canView(BusinessPermission.viewAnalytics), isTrue);
        expect(session.canMutate(BusinessPermission.manageStaff), isFalse);
      },
    );

    test('bootstraps admin when /business/staff returns 403', () async {
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final session = BusinessSessionController(preferences: prefs);
      final client = UgymHttpClient(
        baseUrl: 'https://api.ugym.tj/api/v1',
        tokenStorage: InMemoryTokenStorage(initialToken: 'tok'),
      );

      client.dio.httpClientAdapter = _MockAdapter((options) async {
        if (options.path == '/business/staff') {
          return _json(403, <String, Object?>{
            'error': <String, Object?>{
              'code': 'FORBIDDEN',
              'message': 'Forbidden',
            },
          });
        }
        if (options.path == '/business/gyms') {
          return _json(200, <String, Object?>{
            'data': <Object?>[
              <String, Object?>{'id': 7, 'name': 'Gym 7'},
            ],
          });
        }
        return _json(200, <String, Object?>{
          'data': <String, Object?>{'status': 'trial', 'is_read_only': false},
        });
      });

      final role = await session.bootstrapFromApi(client);
      expect(role, BusinessRole.admin);
      expect(session.isReadOnly, isFalse);
      expect(session.selectedGym?.id, 7);
      expect(
        session.canMutate(BusinessPermission.manageMembershipRequestsAndSales),
        isTrue,
      );
      expect(session.canView(BusinessPermission.viewAnalytics), isFalse);
    });

    test('bootstraps noCompany and persists selected gym branch', () async {
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      await prefs.writeSelectedGymId(2);
      final session = BusinessSessionController(preferences: prefs);
      final client = UgymHttpClient(
        baseUrl: 'https://api.ugym.tj/api/v1',
        tokenStorage: InMemoryTokenStorage(initialToken: 'tok'),
      );

      client.dio.httpClientAdapter = _MockAdapter(
        (_) async => _json(403, <String, Object?>{
          'error': <String, Object?>{
            'code': 'FORBIDDEN',
            'message': 'Forbidden',
          },
        }),
      );

      final role = await session.bootstrapFromApi(client);
      expect(role, BusinessRole.noCompany);

      await session.setGyms(const [
        GymSummary(id: 1, name: 'Branch 1'),
        GymSummary(id: 2, name: 'Branch 2'),
      ]);
      expect(session.selectedGym?.id, 2);

      await session.selectGym(const GymSummary(id: 1, name: 'Branch 1'));
      expect(await prefs.readSelectedGymId(), 1);
      expect(await prefs.readSelectedGymTimezone(), 'Asia/Dushanbe');
    });
  });

  group('Guards and Banner widgets', () {
    Widget wrap(Widget child) {
      return MaterialApp(
        theme: UcraftTheme.light(),
        home: Scaffold(body: child),
      );
    }

    testWidgets('SubscriptionReadOnlyBanner reacts to read-only state', (
      tester,
    ) async {
      final session = BusinessSessionController(
        preferences: AppPreferences(storage: InMemoryTokenStorage()),
      );

      await tester.pumpWidget(
        wrap(SubscriptionReadOnlyBanner(controller: session)),
      );
      expect(
        find.text('Подписка истекла — доступен только просмотр'),
        findsNothing,
      );

      session.markSubscriptionExpired();
      await tester.pump();
      expect(
        find.text('Подписка истекла — доступен только просмотр'),
        findsOneWidget,
      );
    });

    testWidgets('RoleGuard handles owner, restricted admin, and noCompany', (
      tester,
    ) async {
      final session = BusinessSessionController(
        preferences: AppPreferences(storage: InMemoryTokenStorage()),
        initialRole: BusinessRole.owner,
      );

      await tester.pumpWidget(
        wrap(
          RoleGuard(
            controller: session,
            permission: BusinessPermission.viewAnalytics,
            onCreateCompany: () {},
            onOpenClientApp: () {},
            child: const Text('Revenue Chart'),
          ),
        ),
      );
      expect(find.text('Revenue Chart'), findsOneWidget);

      session.setRole(BusinessRole.admin);
      await tester.pump();
      expect(find.text('Revenue Chart'), findsNothing);
      expect(
        find.text('Недостаточно прав для доступа к разделу'),
        findsOneWidget,
      );

      session.setRole(BusinessRole.noCompany);
      await tester.pump();
      expect(find.text('Вы не являетесь сотрудником зала'), findsOneWidget);
      expect(find.text('Создать компанию (14 дней бесплатно)'), findsOneWidget);
    });

    testWidgets('GymBranchSelector switches active branch', (tester) async {
      final session = BusinessSessionController(
        preferences: AppPreferences(storage: InMemoryTokenStorage()),
      );
      await session.setGyms(const [
        GymSummary(id: 1, name: 'Branch 1'),
        GymSummary(id: 2, name: 'Branch 2'),
      ]);

      await tester.pumpWidget(wrap(GymBranchSelector(controller: session)));
      expect(find.text('Branch 1'), findsOneWidget);

      await tester.tap(find.byType(GymBranchSelector));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Branch 2').last);
      await tester.pumpAndSettle();

      expect(session.selectedGym?.id, 2);
      expect(find.text('Branch 2'), findsOneWidget);
    });
  });
}

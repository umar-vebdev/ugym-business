import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ugym_business/core/config/app_config.dart';
import 'package:ugym_business/core/network/business_api_client.dart';
import 'package:ugym_business/features/memberships/data/remote_memberships_repository.dart';
import 'package:ugym_business/features/memberships/domain/memberships_models.dart';
import 'package:ugym_core/ugym_core.dart';

final class _MockMembershipsAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;
  Object? lastData;
  int nextStatusCode = 200;
  Object? nextBody;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    lastData = options.data;
    return ResponseBody.fromString(
      jsonEncode(nextBody),
      nextStatusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  late _MockMembershipsAdapter adapter;
  late RemoteMembershipsRepository repository;

  setUp(() {
    adapter = _MockMembershipsAdapter();
    final apiClient = BusinessApiClient(
      config: const AppConfig.dev(),
      tokenStorage: InMemoryTokenStorage(),
    );
    apiClient.httpClient.dio.httpClientAdapter = adapter;
    repository = RemoteMembershipsRepository(httpClient: apiClient.httpClient);
  });

  test(
    'listMembershipTypes parses tariffs and sends only_active filter',
    () async {
      adapter.nextStatusCode = 200;
      adapter.nextBody = {
        'data': [
          {
            'id': 3,
            'name': 'Безлимит 30 дней',
            'kind': 'unlimited_time',
            'start_mode': 'on_purchase',
            'price_minor': 25000,
            'currency': 'TJS',
            'duration_days': 30,
            'daily_limit': 1,
            'freeze_max_days': 7,
            'freeze_max_times': 1,
            'is_active': true,
          },
        ],
      };

      final types = await repository.listMembershipTypes(onlyActive: true);

      expect(adapter.lastRequest?.path, '/business/membership-types');
      expect(adapter.lastRequest?.queryParameters, {'only_active': true});
      expect(types, hasLength(1));
      expect(types.first.kind, MembershipKind.unlimitedTime);
      expect(types.first.priceMinor, 25000);
      expect(types.first.durationDays, 30);
      expect(types.first.isActive, isTrue);
    },
  );

  test(
    'createMembershipType sends payload and maps 422 INVALID_MEMBERSHIP_RULES',
    () async {
      adapter.nextStatusCode = 201;
      adapter.nextBody = {
        'data': {'id': 9},
      };

      final createdId = await repository.createMembershipType(
        const CreateMembershipTypeInput(
          name: '12 визитов',
          priceMinor: 18000,
          kind: MembershipKind.visitsPack,
          startMode: MembershipStartMode.onFirstVisit,
          visitsCount: 12,
          validityDays: 45,
        ),
      );
      expect(createdId, 9);
      expect(adapter.lastData, {
        'name': '12 визитов',
        'price_minor': 18000,
        'kind': 'visits_pack',
        'start_mode': 'on_first_visit',
        'visits_count': 12,
        'validity_days': 45,
      });

      adapter.nextStatusCode = 422;
      adapter.nextBody = {
        'error': {
          'code': 'INVALID_MEMBERSHIP_RULES',
          'message': 'Некорректная комбинация правил тарифа.',
        },
      };
      expect(
        () => repository.createMembershipType(
          const CreateMembershipTypeInput(
            name: 'Bad',
            priceMinor: 1000,
            kind: MembershipKind.unlimitedTime,
            startMode: MembershipStartMode.onFirstVisit,
          ),
        ),
        throwsA(
          isA<UgymApiException>().having(
            (e) => e.code,
            'code',
            'INVALID_MEMBERSHIP_RULES',
          ),
        ),
      );
    },
  );

  test(
    'setMembershipTypeActive and listExpiringMemberships work properly',
    () async {
      adapter.nextStatusCode = 200;
      adapter.nextBody = {
        'data': {'updated': true},
      };
      final updated = await repository.setMembershipTypeActive(
        typeId: 3,
        isActive: false,
      );
      expect(adapter.lastRequest?.path, '/business/membership-types/3/active');
      expect(updated, isTrue);

      adapter.nextBody = {
        'data': [
          {
            'id': 51,
            'client_id': 11,
            'type_id': 3,
            'kind': 'mixed',
            'status': 'active',
            'remaining_visits': 2,
            'ends_at': '2026-11-22T12:00:00Z',
          },
        ],
      };
      final expiring = await repository.listExpiringMemberships();
      expect(adapter.lastRequest?.path, '/business/memberships/expiring');
      expect(expiring.single.id, 51);
      expect(expiring.single.remainingVisits, 2);
    },
  );

  test(
    'freeze, unfreeze, and cancelMembership map responses correctly',
    () async {
      adapter.nextStatusCode = 200;
      adapter.nextBody = {
        'data': {
          'id': 51,
          'status': 'frozen',
          'freeze_days_used': 0,
          'freeze_times_used': 1,
          'frozen_at': '2026-11-17T10:00:00Z',
        },
      };
      final frozen = await repository.freezeMembership(membershipId: 51);
      expect(frozen.status, MembershipStatus.frozen);
      expect(frozen.freezeTimesUsed, 1);

      adapter.nextBody = {
        'data': {
          'id': 51,
          'status': 'active',
          'freeze_days_used': 3,
          'freeze_times_used': 1,
          'ends_at': '2026-12-03T10:00:00Z',
        },
      };
      final unfrozen = await repository.unfreezeMembership(membershipId: 51);
      expect(unfrozen.status, MembershipStatus.active);
      expect(unfrozen.freezeDaysUsed, 3);

      adapter.nextBody = {
        'data': {
          'id': 51,
          'status': 'cancelled',
          'cancellation_reason': 'Возврат по просьбе клиента',
        },
      };
      final cancelled = await repository.cancelMembership(
        membershipId: 51,
        reason: 'Возврат по просьбе клиента',
      );
      expect(cancelled.status, MembershipStatus.cancelled);
      expect(cancelled.cancellationReason, 'Возврат по просьбе клиента');
    },
  );
}

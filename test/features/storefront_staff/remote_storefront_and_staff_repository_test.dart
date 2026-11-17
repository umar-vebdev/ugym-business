import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ugym_business/core/config/app_config.dart';
import 'package:ugym_business/core/network/business_api_client.dart';
import 'package:ugym_business/features/storefront_staff/data/remote_storefront_and_staff_repository.dart';
import 'package:ugym_business/features/storefront_staff/domain/storefront_and_staff_models.dart';
import 'package:ugym_core/ugym_core.dart';

final class _MockStorefrontAdapter implements HttpClientAdapter {
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
  late _MockStorefrontAdapter adapter;
  late RemoteStorefrontAndStaffRepository repository;

  setUp(() {
    adapter = _MockStorefrontAdapter();
    final apiClient = BusinessApiClient(
      config: const AppConfig.dev(),
      tokenStorage: InMemoryTokenStorage(),
    );
    apiClient.httpClient.dio.httpClientAdapter = adapter;
    repository = RemoteStorefrontAndStaffRepository(
      httpClient: apiClient.httpClient,
    );
  });

  test(
    'updateGymProfile, submitGymProfile, and setGymPublication work',
    () async {
      adapter.nextStatusCode = 200;
      adapter.nextBody = {
        'data': {
          'gym_id': 10,
          'district': 'Сино',
          'description': 'Большой зал',
          'is_public': false,
          'moderation_status': 'draft',
          'amenities': ['душ', 'парковка'],
        },
      };

      final updated = await repository.updateGymProfile(
        gymId: 10,
        input: const GymProfileInput(
          district: 'Сино',
          description: 'Большой зал',
          amenities: ['душ', 'парковка'],
        ),
      );
      expect(adapter.lastRequest?.method, 'PUT');
      expect(updated.moderationStatus, ModerationStatus.draft);
      expect(updated.amenities, ['душ', 'парковка']);

      adapter.nextBody = {
        'data': {
          'gym_id': 10,
          'district': 'Сино',
          'is_public': false,
          'moderation_status': 'pending',
        },
      };
      final submitted = await repository.submitGymProfile(gymId: 10);
      expect(adapter.lastRequest?.path, '/business/gyms/10/profile/submit');
      expect(submitted.moderationStatus, ModerationStatus.pending);

      adapter.nextBody = {
        'data': {
          'gym_id': 10,
          'district': 'Сино',
          'is_public': true,
          'moderation_status': 'approved',
        },
      };
      final published = await repository.setGymPublication(
        gymId: 10,
        isPublic: true,
      );
      expect(published.isPublic, isTrue);
      expect(published.moderationStatus, ModerationStatus.approved);
    },
  );

  test(
    'uploadGymPhoto sends FormData and deleteGymPhoto hits DELETE',
    () async {
      adapter.nextStatusCode = 201;
      adapter.nextBody = {
        'data': {
          'id': 31,
          'gym_id': 10,
          'url': 'https://cdn.ugym.tj/gyms/10/31.jpg',
          'order': 0,
          'created_at': '2026-11-17T12:00:00Z',
        },
      };

      final photo = await repository.uploadGymPhoto(
        gymId: 10,
        bytes: const [1, 2, 3],
        filename: 'gym.jpg',
      );
      expect(adapter.lastData, isA<FormData>());
      expect(photo.id, 31);
      expect(photo.url, 'https://cdn.ugym.tj/gyms/10/31.jpg');

      adapter.nextStatusCode = 200;
      adapter.nextBody = {'data': null};
      await repository.deleteGymPhoto(gymId: 10, photoId: 31);
      expect(adapter.lastRequest?.method, 'DELETE');
      expect(adapter.lastRequest?.path, '/business/gyms/10/photos/31');
    },
  );

  test(
    'staff list, invite, role update, delete, and 400 BAD_REQUEST work',
    () async {
      adapter.nextStatusCode = 200;
      adapter.nextBody = {
        'data': [
          {
            'id': 1,
            'user_id': 5,
            'company_id': 1,
            'role': 'owner',
            'name': 'Али',
            'email': 'ali@gym.tj',
          },
        ],
      };
      final staff = await repository.listStaff();
      expect(staff.single.role, StaffRoleValue.owner);

      adapter.nextStatusCode = 201;
      adapter.nextBody = {
        'data': {
          'id': 2,
          'user_id': 6,
          'company_id': 1,
          'role': 'trainer',
          'email': 'trainer@gym.tj',
        },
      };
      final invited = await repository.inviteStaff(
        email: 'trainer@gym.tj',
        role: StaffRoleValue.trainer,
      );
      expect(invited.role, StaffRoleValue.trainer);

      adapter.nextStatusCode = 400;
      adapter.nextBody = {
        'error': {
          'code': 'BAD_REQUEST',
          'message': 'Пользователь с этим email не подтверждён.',
        },
      };
      expect(
        () => repository.inviteStaff(
          email: 'unverified@gym.tj',
          role: StaffRoleValue.admin,
        ),
        throwsA(
          isA<UgymApiException>().having((e) => e.code, 'code', 'BAD_REQUEST'),
        ),
      );
    },
  );
}

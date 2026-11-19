import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_business/core/config/app_config.dart';
import 'package:ugym_business/core/session/business_role.dart';
import 'package:ugym_business/core/session/business_session_controller.dart';
import 'package:ugym_business/core/storage/app_preferences.dart';
import 'package:ugym_business/features/analytics_billing/domain/analytics_and_billing_models.dart';
import 'package:ugym_business/features/analytics_billing/presentation/analytics_and_billing_screens.dart';
import 'package:ugym_business/features/company_onboarding/domain/company_onboarding_models.dart';
import 'package:ugym_business/features/company_onboarding/presentation/company_onboarding_screen.dart';
import 'package:ugym_business/features/sales/domain/sales_and_requests_models.dart';
import 'package:ugym_business/features/sales/presentation/membership_requests_and_sales_tabs.dart';
import 'package:ugym_business/features/storefront_staff/domain/storefront_and_staff_models.dart';
import 'package:ugym_business/features/storefront_staff/presentation/storefront_editor_screen.dart';
import 'package:ugym_core/ugym_core.dart';

final class _AcceptanceBillingRepo implements AnalyticsAndBillingRepository {
  @override
  Future<CompanySubscription> fetchBillingSubscription() async =>
      CompanySubscription(
        id: 1,
        companyId: 5,
        planId: 2,
        status: CompanySubscriptionStatus.expired,
        isReadOnly: true,
        startsAt: DateTime.utc(2026, 11, 1),
        endsAt: DateTime.utc(2026, 11, 15),
      );

  @override
  Future<List<PlatformPlan>> listBillingPlans() async => const [
    PlatformPlan(
      id: 2,
      name: 'Business Pro',
      period: BillingPlanPeriod.month,
      priceMinor: 39900,
      currency: 'TJS',
      maxGyms: 5,
      maxStaff: 25,
      isActive: true,
    ),
  ];

  @override
  Future<OverviewAnalytics> fetchOverview({
    String? from,
    String? to,
    int inactiveDays = 14,
  }) => throw UnimplementedError();

  @override
  Future<RevenueReport> fetchRevenueReport({String? from, String? to}) =>
      throw UnimplementedError();

  @override
  Future<AnnouncementQueuedResult> sendAnnouncement({
    required AnnouncementChannel channel,
    required String title,
    required String body,
  }) => throw UnimplementedError();
}

final class _AcceptanceOnboardingRepo implements CompanyOnboardingRepository {
  @override
  Future<CreatedCompanyResult> createCompany({
    required String companyName,
    required String gymName,
    String? gymAddress,
  }) async => const CreatedCompanyResult(companyId: 77, gymId: 88);

  @override
  Future<List<GymBranch>> listGyms() async => const [
    GymBranch(id: 88, companyId: 77, name: 'Demo Club'),
  ];

  @override
  Future<GymBranch> createGym({
    required String name,
    String? address,
    String timezone = 'Asia/Dushanbe',
    bool geoCheckEnabled = false,
    int geoCheckRadiusMeters = 200,
  }) => throw UnimplementedError();

  @override
  Future<GymBranch> updateGym({
    required int gymId,
    required String name,
    String? address,
    String timezone = 'Asia/Dushanbe',
    bool geoCheckEnabled = false,
    int geoCheckRadiusMeters = 200,
  }) => throw UnimplementedError();

  @override
  Future<List<CurrencyOption>> listCurrencies() => throw UnimplementedError();

  @override
  Future<String> updateCompanyCurrency({required int currencyId}) =>
      throw UnimplementedError();
}

final class _AcceptanceSalesRepo implements SalesAndRequestsRepository {
  final List<({int requestId, PaymentMethod method, String? key})> payCalls =
      <({int requestId, PaymentMethod method, String? key})>[];
  MembershipRequestStatus _status = MembershipRequestStatus.pending;

  @override
  Future<List<MembershipRequestRecord>> listMembershipRequests({
    MembershipRequestStatus? status,
  }) async {
    if (status != null && status != _status) {
      return const [];
    }
    return [
      MembershipRequestRecord(
        id: 501,
        companyId: 77,
        gymId: 88,
        userId: 9,
        clientId: 11,
        membershipTypeId: 3,
        status: _status,
        expiresAt: DateTime.utc(2026, 11, 19, 12, 0),
      ),
    ];
  }

  @override
  Future<PayRequestResult> payMembershipRequest({
    required int requestId,
    required PaymentMethod paymentMethod,
    String? idempotencyKey,
  }) async {
    payCalls.add((
      requestId: requestId,
      method: paymentMethod,
      key: idempotencyKey,
    ));
    _status = MembershipRequestStatus.paid;
    return PayRequestResult(
      requestId: requestId,
      saleId: 901,
      membershipId: 301,
      clientId: 11,
      status: MembershipRequestStatus.paid,
      paidAt: DateTime.utc(2026, 11, 18, 12, 0),
    );
  }

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
  Future<List<SaleRecord>> listClientSales({required int clientId}) =>
      throw UnimplementedError();

  @override
  Future<List<ProductItem>> listProducts({bool? onlyActive}) =>
      throw UnimplementedError();

  @override
  Future<List<SaleRecord>> listSales() => throw UnimplementedError();

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

final class _AcceptanceStorefrontRepo implements StorefrontAndStaffRepository {
  @override
  Future<GymProfile> updateGymProfile({
    required int gymId,
    required GymProfileInput input,
  }) async => GymProfile(
    gymId: gymId,
    isPublic: false,
    moderationStatus: ModerationStatus.draft,
    description: input.description,
    address: input.address,
  );

  @override
  Future<GymProfile> submitGymProfile({required int gymId}) async => GymProfile(
    gymId: gymId,
    isPublic: false,
    moderationStatus: ModerationStatus.pending,
  );

  @override
  Future<GymProfile> setGymPublication({
    required int gymId,
    required bool isPublic,
  }) => throw UnimplementedError();

  @override
  Future<GymPhoto> uploadGymPhoto({
    required int gymId,
    required List<int> bytes,
    required String filename,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteGymPhoto({required int gymId, required int photoId}) =>
      throw UnimplementedError();

  @override
  Future<List<StaffMember>> listStaff() => throw UnimplementedError();

  @override
  Future<StaffMember> inviteStaff({
    required String email,
    required StaffRoleValue role,
  }) => throw UnimplementedError();

  @override
  Future<StaffMember> updateStaffRole({
    required int staffId,
    required StaffRoleValue role,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteStaff({required int staffId}) =>
      throw UnimplementedError();
}

void main() {
  test('iOS Info.plist, PrivacyInfo.xcprivacy, and AndroidManifest.xml meet store release requirements', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(infoPlist, contains('<key>NSCameraUsageDescription</key>'));
    expect(infoPlist, contains('<key>NSPhotoLibraryUsageDescription</key>'));
    expect(
      infoPlist,
      contains('<key>UISupportedInterfaceOrientations~ipad</key>'),
    );
    expect(infoPlist, contains('UIInterfaceOrientationLandscapeLeft'));
    expect(infoPlist, contains('UIInterfaceOrientationLandscapeRight'));

    final privacyFile = File('ios/Runner/PrivacyInfo.xcprivacy');
    expect(privacyFile.existsSync(), isTrue);
    final privacy = privacyFile.readAsStringSync();
    expect(privacy, contains('<key>NSPrivacyTracking</key>\n\t<false/>'));
    expect(privacy, contains('NSPrivacyAccessedAPICategoryUserDefaults'));
    expect(privacy, contains('<string>CA92.1</string>'));

    final androidManifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(androidManifest, contains('android.permission.INTERNET'));
    expect(androidManifest, contains('android.permission.CAMERA'));
    expect(
      androidManifest,
      contains('android.hardware.camera" android:required="false"'),
    );
    expect(androidManifest, isNot(contains('ACCESS_BACKGROUND_LOCATION')));
    expect(androidManifest, isNot(contains('android.permission.BLUETOOTH')));
  });

  testWidgets(
    'Complies with App Store 3.1.1 & Google Play: no IAP packages and strictly informational billing screen',
    (tester) async {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final bannedIapPattern = RegExp(
        r'^\s*(in_app_purchase|purchases_flutter|flutter_stripe|stripe_payment|pay|razorpay_flutter|yookassa_payments_flutter|url_launcher):',
        multiLine: true,
      );
      expect(bannedIapPattern.hasMatch(pubspec), isFalse);

      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final session = BusinessSessionController(
        preferences: prefs,
        initialRole: BusinessRole.owner,
        initialReadOnly: true,
      );
      addTearDown(session.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: BillingStatusScreen(
                repository: _AcceptanceBillingRepo(),
                sessionController: session,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Подписка платформы: Истекла (expired)'),
        findsOneWidget,
      );
      expect(find.textContaining('Business Pro'), findsOneWidget);
      expect(find.text('Оплатить'), findsNothing);
      expect(find.text('Купить'), findsNothing);
      expect(find.text('Продлить'), findsNothing);
      expect(find.textContaining('http://'), findsNothing);
      expect(find.textContaining('https://'), findsNothing);
    },
  );

  testWidgets(
    'Acceptance checklist 7.2: prod HTTPS, 14-day onboarding, PaymentMark with Idempotency-Key, and approved->draft storefront warning',
    (tester) async {
      const prod = AppConfig.prod();
      expect(prod.apiBaseUrl, startsWith('https://'));
      expect(prod.enableKioskMode, isTrue);

      // 1. Company onboarding promotes noCompany -> owner + selects branch.
      final prefs = AppPreferences(storage: InMemoryTokenStorage());
      final session = BusinessSessionController(
        preferences: prefs,
        initialRole: BusinessRole.noCompany,
      );
      addTearDown(session.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CompanyOnboardingCard(
                repository: _AcceptanceOnboardingRepo(),
                sessionController: session,
              ),
            ),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('onboarding_company_name')),
        'Demo Fitness',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('onboarding_gym_name')),
        'Demo Club',
      );
      await tester.tap(find.text('Создать компанию (14 дней бесплатно)'));
      await tester.pumpAndSettle();
      expect(session.role, BusinessRole.owner);
      expect(session.selectedGym?.id, 88);

      // 2. PaymentMark (cash) confirms pending request with Idempotency-Key.
      final salesRepo = _AcceptanceSalesRepo();
      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: MembershipRequestsQueueTab(
                repository: salesRepo,
                sessionController: session,
                clock: () => DateTime.utc(2026, 11, 18, 12, 0),
                idempotencyKeyGenerator: () => 'accept-pay-key',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Принять оплату'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Подтвердить оплату'));
      await tester.pumpAndSettle();
      expect(salesRepo.payCalls.single.method, PaymentMethod.cash);
      expect(salesRepo.payCalls.single.key, 'accept-pay-key');

      // 3. Approved storefront warns before edit and resets to draft -> submits to pending.
      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: StorefrontEditorScreen(
                repository: _AcceptanceStorefrontRepo(),
                sessionController: session,
                initialProfile: const GymProfile(
                  gymId: 88,
                  isPublic: true,
                  moderationStatus: ModerationStatus.approved,
                  description: 'Old description',
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

      await tester.ensureVisible(find.text('Сохранить витрину'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сохранить витрину'));
      await tester.pumpAndSettle();
      expect(find.text('Черновик (draft)'), findsOneWidget);

      await tester.ensureVisible(find.text('На модерацию'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('На модерацию'));
      await tester.pumpAndSettle();
      expect(find.text('На модерации (pending)'), findsOneWidget);
    },
  );

  test('Android release signing uses android/key.properties with safe fallback and ignores secrets in git', () {
    final gitignore = File('.gitignore').readAsStringSync();
    expect(gitignore, contains('android/key.properties'));
    expect(gitignore, contains('*.jks'));
    expect(gitignore, contains('*.keystore'));

    final exampleFile = File('android/key.properties.example');
    expect(exampleFile.existsSync(), isTrue);
    final exampleContent = exampleFile.readAsStringSync();
    expect(exampleContent, contains('storePassword='));
    expect(exampleContent, contains('keyPassword='));
    expect(exampleContent, contains('keyAlias='));
    expect(exampleContent, contains('storeFile='));

    final gradleFile = File('android/app/build.gradle.kts');
    expect(gradleFile.existsSync(), isTrue);
    final gradleContent = gradleFile.readAsStringSync();
    expect(gradleContent, contains('rootProject.file("key.properties")'));
    expect(gradleContent, contains('create("release")'));
    expect(gradleContent, contains('signingConfigs.getByName("release")'));
    expect(gradleContent, contains('applicationId = "tj.ugym.business"'));
  });
}

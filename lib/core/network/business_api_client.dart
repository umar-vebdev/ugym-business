import 'package:ugym_core/ugym_core.dart';

import '../config/app_config.dart';

/// Business application API client wrapping [UgymHttpClient] from `ugym_core`.
final class BusinessApiClient {
  BusinessApiClient({
    required AppConfig config,
    required TokenStorage tokenStorage,
    String Function()? localeProvider,
    void Function()? onUnauthorized,
    void Function()? onSubscriptionExpired,
  }) : httpClient = UgymHttpClient(
         baseUrl: config.apiBaseUrl,
         tokenStorage: tokenStorage,
         localeProvider: localeProvider,
         onUnauthorized: onUnauthorized,
         onSubscriptionExpired: onSubscriptionExpired,
       );

  final UgymHttpClient httpClient;
}

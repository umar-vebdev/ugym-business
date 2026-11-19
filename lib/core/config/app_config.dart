/// Target deployment flavor for uGym Business.
enum AppFlavor { dev, staging, prod }

/// Environment configuration injected at application startup.
final class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.apiBaseUrl,
    this.enableKioskMode = true,
  });

  const AppConfig.dev()
    : flavor = AppFlavor.dev,
      apiBaseUrl = 'http://10.0.2.2:8000/api/v1',
      enableKioskMode = true;

  const AppConfig.staging()
    : flavor = AppFlavor.staging,
      apiBaseUrl = 'https://staging-api.ugym.tj/api/v1',
      enableKioskMode = true;

  const AppConfig.prod()
    : flavor = AppFlavor.prod,
      apiBaseUrl = 'https://api.ugym.tj/api/v1',
      enableKioskMode = true;

  /// Resolves build-time `--dart-define` values (`FLAVOR`, `API_BASE_URL`,
  /// `ENABLE_KIOSK_MODE`).
  factory AppConfig.fromEnvironment() {
    const rawFlavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    const rawApiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const enableKiosk = bool.fromEnvironment(
      'ENABLE_KIOSK_MODE',
      defaultValue: true,
    );
    return AppConfig.resolve(
      flavorName: rawFlavor,
      apiBaseUrlOverride: rawApiBaseUrl,
      enableKioskMode: enableKiosk,
    );
  }

  /// Pure resolver for flavor and URL overrides, used by [fromEnvironment] and tests.
  factory AppConfig.resolve({
    String flavorName = 'dev',
    String apiBaseUrlOverride = '',
    bool enableKioskMode = true,
  }) {
    final normalized = flavorName.trim().toLowerCase();
    final base = switch (normalized) {
      'staging' => const AppConfig.staging(),
      'prod' || 'production' => const AppConfig.prod(),
      _ => const AppConfig.dev(),
    };
    final overrideUrl = apiBaseUrlOverride.trim();
    return AppConfig(
      flavor: base.flavor,
      apiBaseUrl: overrideUrl.isNotEmpty ? overrideUrl : base.apiBaseUrl,
      enableKioskMode: enableKioskMode,
    );
  }

  final AppFlavor flavor;
  final String apiBaseUrl;
  final bool enableKioskMode;
}

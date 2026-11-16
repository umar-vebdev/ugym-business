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

  final AppFlavor flavor;
  final String apiBaseUrl;
  final bool enableKioskMode;
}

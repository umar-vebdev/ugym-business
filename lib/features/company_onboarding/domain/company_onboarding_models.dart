/// Result of creating a new company and its initial gym branch.
final class CreatedCompanyResult {
  const CreatedCompanyResult({required this.companyId, required this.gymId});

  final int companyId;
  final int gymId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreatedCompanyResult &&
          runtimeType == other.runtimeType &&
          companyId == other.companyId &&
          gymId == other.gymId;

  @override
  int get hashCode => Object.hash(companyId, gymId);
}

/// Full gym branch details managed by the company owner.
final class GymBranch {
  const GymBranch({
    required this.id,
    required this.companyId,
    required this.name,
    this.address,
    this.timezone = 'Asia/Dushanbe',
    this.geoCheckEnabled = false,
    this.geoCheckRadiusMeters = 200,
  });

  final int id;
  final int companyId;
  final String name;
  final String? address;
  final String timezone;
  final bool geoCheckEnabled;
  final int geoCheckRadiusMeters;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymBranch &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          companyId == other.companyId &&
          name == other.name &&
          address == other.address &&
          timezone == other.timezone &&
          geoCheckEnabled == other.geoCheckEnabled &&
          geoCheckRadiusMeters == other.geoCheckRadiusMeters;

  @override
  int get hashCode => Object.hash(
    id,
    companyId,
    name,
    address,
    timezone,
    geoCheckEnabled,
    geoCheckRadiusMeters,
  );
}

/// Supported platform currency option for a company.
final class CurrencyOption {
  const CurrencyOption({
    required this.id,
    required this.code,
    required this.name,
    this.symbol,
  });

  final int id;
  final String code;
  final String name;
  final String? symbol;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyOption &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          name == other.name &&
          symbol == other.symbol;

  @override
  int get hashCode => Object.hash(id, code, name, symbol);
}

/// Contract for company onboarding, gym branches, and company currency.
abstract interface class CompanyOnboardingRepository {
  Future<CreatedCompanyResult> createCompany({
    required String companyName,
    required String gymName,
    String? gymAddress,
  });

  Future<List<GymBranch>> listGyms();

  Future<GymBranch> createGym({
    required String name,
    String? address,
    String timezone = 'Asia/Dushanbe',
    bool geoCheckEnabled = false,
    int geoCheckRadiusMeters = 200,
  });

  Future<GymBranch> updateGym({
    required int gymId,
    required String name,
    String? address,
    String timezone = 'Asia/Dushanbe',
    bool geoCheckEnabled = false,
    int geoCheckRadiusMeters = 200,
  });

  Future<List<CurrencyOption>> listCurrencies();

  Future<String> updateCompanyCurrency({required int currencyId});
}

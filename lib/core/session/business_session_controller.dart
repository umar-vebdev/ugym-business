import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../storage/app_preferences.dart';
import 'business_role.dart';

/// Holds active staff role, subscription read-only state, and selected gym branch.
final class BusinessSessionController extends ChangeNotifier {
  BusinessSessionController({
    required this.preferences,
    BusinessRole? initialRole,
    bool initialReadOnly = false,
  }) : _role = initialRole,
       _isReadOnly = initialReadOnly;

  final AppPreferences preferences;

  BusinessRole? _role;
  bool _isReadOnly;
  List<GymSummary> _gyms = const <GymSummary>[];
  GymSummary? _selectedGym;

  BusinessRole? get role => _role;
  bool get isReadOnly => _isReadOnly;
  List<GymSummary> get gyms => List<GymSummary>.unmodifiable(_gyms);
  GymSummary? get selectedGym => _selectedGym;

  bool canView(BusinessPermission permission) =>
      _role?.can(permission) ?? false;

  bool canMutate(BusinessPermission permission) =>
      !_isReadOnly && canView(permission);

  void setRole(BusinessRole? newRole) {
    if (newRole == _role) {
      return;
    }
    _role = newRole;
    notifyListeners();
  }

  void markSubscriptionExpired() {
    if (_isReadOnly) {
      return;
    }
    _isReadOnly = true;
    notifyListeners();
  }

  void setSubscriptionStatus({required bool isReadOnly}) {
    if (isReadOnly == _isReadOnly) {
      return;
    }
    _isReadOnly = isReadOnly;
    notifyListeners();
  }

  Future<void> setGyms(List<GymSummary> availableGyms) async {
    _gyms = List<GymSummary>.unmodifiable(availableGyms);
    if (_gyms.isEmpty) {
      _selectedGym = null;
      await preferences.writeSelectedGymId(null);
      notifyListeners();
      return;
    }

    final savedGymId = await preferences.readSelectedGymId();
    GymSummary resolved = _gyms.first;
    if (savedGymId != null) {
      for (final gym in _gyms) {
        if (gym.id == savedGymId) {
          resolved = gym;
          break;
        }
      }
    }

    _selectedGym = resolved;
    await preferences.writeSelectedGymId(resolved.id);
    await preferences.writeSelectedGymTimezone(resolved.timezone);
    notifyListeners();
  }

  Future<void> selectGym(GymSummary gym) async {
    _selectedGym = gym;
    await preferences.writeSelectedGymId(gym.id);
    await preferences.writeSelectedGymTimezone(gym.timezone);
    notifyListeners();
  }

  /// Resolves the authenticated user's role, gyms, and billing read-only state.
  Future<BusinessRole> bootstrapFromApi(
    UgymHttpClient httpClient, {
    bool isTrainerHint = false,
  }) async {
    try {
      await httpClient.dio.get<Object?>('/business/staff');
      _role = BusinessRole.owner;
      await _loadGyms(httpClient);
      await _loadSubscriptionStatus(httpClient);
      notifyListeners();
      return BusinessRole.owner;
    } on DioException catch (error) {
      final apiError = _extractApiError(error);
      if (apiError.isSubscriptionExpired) {
        _isReadOnly = true;
      }
      if (!apiError.isForbidden) {
        rethrow;
      }
    }

    try {
      final gymsResponse = await httpClient.dio.get<Object?>('/business/gyms');
      _role = BusinessRole.admin;
      await setGyms(_parseGymsFromResponse(gymsResponse.data));
      await _loadSubscriptionStatus(httpClient);
      notifyListeners();
      return BusinessRole.admin;
    } on DioException catch (error) {
      final apiError = _extractApiError(error);
      if (apiError.isSubscriptionExpired) {
        _isReadOnly = true;
      }
      if (!apiError.isForbidden) {
        rethrow;
      }
    }

    final bool isTrainer =
        isTrainerHint || await _probeTrainerAccess(httpClient);
    _role = isTrainer ? BusinessRole.trainer : BusinessRole.noCompany;
    if (isTrainer) {
      final savedGymId = await preferences.readSelectedGymId();
      if (savedGymId != null) {
        final timezone = await preferences.readSelectedGymTimezone();
        final restored = GymSummary(
          id: savedGymId,
          name: 'Филиал #$savedGymId',
          timezone: timezone,
        );
        _gyms = <GymSummary>[restored];
        _selectedGym = restored;
      } else {
        _gyms = const <GymSummary>[];
        _selectedGym = null;
      }
    } else {
      _gyms = const <GymSummary>[];
      _selectedGym = null;
    }
    notifyListeners();
    return _role!;
  }

  Future<bool> _probeTrainerAccess(UgymHttpClient httpClient) async {
    try {
      await httpClient.dio.get<Object?>(
        '/business/schedule/sessions/1/bookings',
      );
      return true;
    } on DioException catch (error) {
      final apiError = _extractApiError(error);
      if (apiError.isSubscriptionExpired) {
        _isReadOnly = true;
        return true;
      }
      if (apiError.statusCode == 404 || apiError.code == 'NOT_FOUND') {
        return true;
      }
      if (apiError.isForbidden) {
        return false;
      }
      rethrow;
    }
  }

  Future<void> _loadGyms(UgymHttpClient httpClient) async {
    final response = await httpClient.dio.get<Object?>('/business/gyms');
    await setGyms(_parseGymsFromResponse(response.data));
  }

  Future<void> _loadSubscriptionStatus(UgymHttpClient httpClient) async {
    try {
      final response = await httpClient.dio.get<Object?>(
        '/business/billing/subscription',
      );
      final data = response.data;
      if (data is Map<Object?, Object?>) {
        final payload = data['data'];
        if (payload is Map<Object?, Object?>) {
          final isReadOnly = payload['is_read_only'];
          final status = payload['status'];
          if (isReadOnly is bool) {
            _isReadOnly = isReadOnly;
          } else if (status == 'expired') {
            _isReadOnly = true;
          }
        }
      }
    } on DioException catch (error) {
      final apiError = _extractApiError(error);
      if (apiError.isSubscriptionExpired) {
        _isReadOnly = true;
      } else if (!apiError.isForbidden) {
        rethrow;
      }
    }
  }

  List<GymSummary> _parseGymsFromResponse(Object? body) {
    if (body is! Map<Object?, Object?>) {
      return const <GymSummary>[];
    }
    final rawList = body['data'];
    if (rawList is! List<Object?>) {
      return const <GymSummary>[];
    }
    return rawList
        .map(GymSummary.tryFromJson)
        .whereType<GymSummary>()
        .toList(growable: false);
  }

  UgymApiException _extractApiError(DioException error) {
    final existing = error.error;
    if (existing is UgymApiException) {
      return existing;
    }
    return UgymErrorMapper.fromDioException(error);
  }
}

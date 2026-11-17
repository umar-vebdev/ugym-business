import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../domain/reception_visits_models.dart';

/// Phase of the reception client-QR scan flow.
enum ScanPhase { idle, processing, success, refused, networkError }

/// Drives the client QR check-in flow on the reception desk.
///
/// After a code is read the scanner is paused until the server answers or the
/// operator taps "scan next". A retry after a network failure reuses the same
/// token and `Idempotency-Key`, so a visit can never be charged twice.
final class ReceptionScanController extends ChangeNotifier {
  ReceptionScanController({
    required this.repository,
    required this.gymId,
    this.device = 'uGym Business',
  });

  final ReceptionVisitsRepository repository;
  final int gymId;
  final String device;

  ScanPhase _phase = ScanPhase.idle;
  CheckInResult? _result;
  UgymApiException? _error;
  String? _pendingToken;
  String? _pendingKey;

  ScanPhase get phase => _phase;
  CheckInResult? get result => _result;
  UgymApiException? get error => _error;
  String? get pendingIdempotencyKey => _pendingKey;
  bool get isScannerPaused => _phase != ScanPhase.idle;

  Future<void> onCodeScanned(String token) async {
    if (_phase != ScanPhase.idle) {
      return;
    }
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _pendingToken = trimmed;
    _pendingKey = UgymUuid.v4();
    await _submit();
  }

  Future<void> retry() async {
    if (_phase != ScanPhase.networkError || _pendingToken == null) {
      return;
    }
    await _submit();
  }

  void scanNext() {
    _phase = ScanPhase.idle;
    _result = null;
    _error = null;
    _pendingToken = null;
    _pendingKey = null;
    notifyListeners();
  }

  Future<void> _submit() async {
    _phase = ScanPhase.processing;
    _error = null;
    notifyListeners();

    try {
      _result = await repository.checkInByClientQr(
        gymId: gymId,
        token: _pendingToken!,
        device: device,
        idempotencyKey: _pendingKey,
      );
      _phase = ScanPhase.success;
      _pendingToken = null;
      _pendingKey = null;
    } on UgymApiException catch (error) {
      _error = error;
      _phase = error.isNetworkError
          ? ScanPhase.networkError
          : ScanPhase.refused;
      if (_phase == ScanPhase.refused) {
        _pendingToken = null;
        _pendingKey = null;
      }
    }
    notifyListeners();
  }
}

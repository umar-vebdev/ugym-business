import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:ugym_core/ugym_core.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Abstraction controlling screen wake lock while kiosk mode is active.
abstract interface class KioskWakeLock {
  Future<void> enable();
  Future<void> disable();
}

/// Platform implementation backed by `wakelock_plus`.
final class PlatformKioskWakeLock implements KioskWakeLock {
  const PlatformKioskWakeLock();

  @override
  Future<void> enable() => WakelockPlus.enable();

  @override
  Future<void> disable() => WakelockPlus.disable();
}

/// Test/desktop no-op implementation of [KioskWakeLock].
final class NoOpKioskWakeLock implements KioskWakeLock {
  const NoOpKioskWakeLock();

  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}
}

/// Stores and verifies the kiosk exit PIN as a salted SHA-256 hash.
final class KioskPinGuard {
  const KioskPinGuard({required this.storage});

  static const String _saltKey = 'ugym_business_kiosk_pin_salt';
  static const String _hashKey = 'ugym_business_kiosk_pin_hash';

  final TokenStorage storage;

  static bool isValidPinFormat(String pin) {
    return RegExp(r'^\d{4}$').hasMatch(pin.trim());
  }

  Future<bool> isLocked() async {
    final salt = await storage.read(_saltKey);
    final hash = await storage.read(_hashKey);
    return salt != null && salt.isNotEmpty && hash != null && hash.isNotEmpty;
  }

  Future<void> lockWithPin(String pin) async {
    final normalized = pin.trim();
    if (!isValidPinFormat(normalized)) {
      throw ArgumentError.value(pin, 'pin', 'PIN must consist of 4 digits.');
    }

    final salt = UgymUuid.v4();
    final digest = _computeDigest(salt: salt, pin: normalized);
    await storage.write(_saltKey, salt);
    await storage.write(_hashKey, digest);
  }

  Future<bool> unlockWithPin(String pin) async {
    final normalized = pin.trim();
    if (!isValidPinFormat(normalized)) {
      return false;
    }

    final salt = await storage.read(_saltKey);
    final expectedHash = await storage.read(_hashKey);
    if (salt == null || expectedHash == null) {
      return false;
    }

    final actualHash = _computeDigest(salt: salt, pin: normalized);
    if (actualHash != expectedHash) {
      return false;
    }

    await storage.delete(_saltKey);
    await storage.delete(_hashKey);
    return true;
  }

  String _computeDigest({required String salt, required String pin}) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }
}

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ugym_core/ugym_core.dart';

import '../../../core/l10n/business_localizations.dart';
import '../domain/kiosk_security.dart';
import '../domain/reception_visits_models.dart';

/// Reception desk kiosk screen showing an auto-refreshing 60s HMAC gym QR.
final class GymQrKioskScreen extends StatefulWidget {
  const GymQrKioskScreen({
    super.key,
    required this.gymId,
    required this.repository,
    required this.pinGuard,
    this.wakeLock = const NoOpKioskWakeLock(),
    this.clock,
    this.onExitKiosk,
  });

  final int gymId;
  final ReceptionVisitsRepository repository;
  final KioskPinGuard pinGuard;
  final KioskWakeLock wakeLock;
  final DateTime Function()? clock;
  final VoidCallback? onExitKiosk;

  @override
  State<GymQrKioskScreen> createState() => _GymQrKioskScreenState();
}

final class _GymQrKioskScreenState extends State<GymQrKioskScreen> {
  final _setPinController = TextEditingController();
  final _unlockPinController = TextEditingController();

  Timer? _ticker;
  GymQrToken? _qr;
  int _secondsRemaining = 60;
  bool _loading = true;
  bool _refreshing = false;
  bool _isLocked = false;
  bool _showSetPinForm = false;
  bool _showUnlockForm = false;
  String? _errorMessage;
  String? _pinError;

  DateTime _nowUtc() => (widget.clock?.call() ?? DateTime.now()).toUtc();

  @override
  void initState() {
    super.initState();
    unawaited(widget.wakeLock.enable());
    unawaited(_initKiosk());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    unawaited(widget.wakeLock.disable());
    _setPinController.dispose();
    _unlockPinController.dispose();
    super.dispose();
  }

  Future<void> _initKiosk() async {
    final locked = await widget.pinGuard.isLocked();
    if (mounted) {
      setState(() {
        _isLocked = locked;
      });
    }
    await _refreshQr();
  }

  Future<void> _refreshQr() async {
    if (_refreshing) {
      return;
    }

    if (mounted) {
      setState(() {
        _refreshing = true;
        if (_qr == null) {
          _loading = true;
        }
        _errorMessage = null;
      });
    }

    try {
      final token = await widget.repository.fetchGymQr(gymId: widget.gymId);
      if (!mounted) {
        return;
      }
      final remaining = token.expiresAt.toUtc().difference(_nowUtc()).inSeconds;
      setState(() {
        _qr = token;
        _secondsRemaining = remaining.clamp(0, token.ttlSeconds);
        _loading = false;
      });
    } on UgymApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _loading = false;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Не удалось обновить QR-код зала.';
        _loading = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
        });
      }
    }
  }

  void _onTick() {
    final currentQr = _qr;
    if (currentQr == null) {
      return;
    }

    final remaining = currentQr.expiresAt
        .toUtc()
        .difference(_nowUtc())
        .inSeconds;
    final clamped = remaining.clamp(0, currentQr.ttlSeconds);

    if (mounted && clamped != _secondsRemaining) {
      setState(() {
        _secondsRemaining = clamped;
      });
    }

    // Refresh 4 seconds before expiration to prevent client scan failures.
    if (remaining <= 4 && !_refreshing) {
      unawaited(_refreshQr());
    }
  }

  Future<void> _enablePinLock(BusinessStrings strings) async {
    final pin = _setPinController.text.trim();
    if (!KioskPinGuard.isValidPinFormat(pin)) {
      setState(() {
        _pinError = strings.kioskPinFormatError;
      });
      return;
    }

    await widget.pinGuard.lockWithPin(pin);
    if (!mounted) {
      return;
    }
    setState(() {
      _isLocked = true;
      _showSetPinForm = false;
      _pinError = null;
      _setPinController.clear();
    });
  }

  Future<void> _confirmUnlockAndExit(BusinessStrings strings) async {
    final unlocked = await widget.pinGuard.unlockWithPin(
      _unlockPinController.text,
    );
    if (!mounted) {
      return;
    }
    if (!unlocked) {
      setState(() {
        _pinError = strings.kioskWrongPinError;
      });
      return;
    }

    setState(() {
      _isLocked = false;
      _showUnlockForm = false;
      _pinError = null;
      _unlockPinController.clear();
    });
    widget.onExitKiosk?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final strings = BusinessStringsScope.of(context);

    return PopScope(
      canPop: !_isLocked,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 840;
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(
                    UcraftSpacing.screenHorizontalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWide ? 880 : 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'uGym',
                              style: UcraftTypography.titleLarge.copyWith(
                                color: colors.primary,
                              ),
                            ),
                            Text(
                              _isLocked
                                  ? strings.kioskLockedBadge
                                  : strings.kioskModeBadge,
                              style: UcraftTypography.label.copyWith(
                                color: colors.foregroundSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: UcraftSpacing.space4),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildQrContent(colors, strings),
                              ),
                              const SizedBox(width: UcraftSpacing.space6),
                              Expanded(
                                flex: 2,
                                child: _buildPinControls(strings),
                              ),
                            ],
                          )
                        else ...[
                          _buildQrContent(colors, strings),
                          const SizedBox(height: UcraftSpacing.space4),
                          _buildPinControls(strings),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildQrContent(UcraftColors colors, BusinessStrings strings) {
    if (_loading) {
      return UcraftCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: UcraftSpacing.space8),
          child: UcraftLoadingState(message: strings.kioskLoadingQr),
        ),
      );
    }

    if (_errorMessage != null && _qr == null) {
      return UcraftCard(
        child: UcraftErrorState(
          message: _errorMessage!,
          retryLabel: strings.retryLabel,
          onRetry: _refreshQr,
        ),
      );
    }

    final qr = _qr!;
    return UcraftCard(
      child: Column(
        children: [
          Text(
            qr.gymName,
            style: UcraftTypography.headline.copyWith(color: colors.foreground),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: UcraftSpacing.space2),
          Text(
            strings.kioskScanPrompt,
            style: UcraftTypography.body.copyWith(
              color: colors.foregroundSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: UcraftSpacing.space6),
          Container(
            padding: const EdgeInsets.all(UcraftSpacing.space4),
            decoration: BoxDecoration(
              color: UcraftBrandColors.white,
              borderRadius: UcraftRadius.borderMd,
              border: Border.all(
                color: colors.border,
                width: UcraftElevation.borderDefault,
              ),
            ),
            child: QrImageView(
              data: qr.token,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: UcraftBrandColors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: UcraftBrandColors.midnight,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: UcraftBrandColors.midnight,
              ),
            ),
          ),
          const SizedBox(height: UcraftSpacing.space4),
          Text(
            '${strings.kioskRefreshPrefix}$_secondsRemaining${strings.kioskSecondsSuffix}',
            style: UcraftTypography.mono.copyWith(color: colors.foreground),
          ),
          const SizedBox(height: UcraftSpacing.space2),
          Text(
            '${strings.kioskSlotPrefix}${qr.slot}',
            style: UcraftTypography.mono.copyWith(
              color: colors.foregroundSecondary,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: UcraftSpacing.space3),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: UcraftTypography.caption.copyWith(
                color: colors.destructive,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPinControls(BusinessStrings strings) {
    if (!_isLocked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showSetPinForm)
            UcraftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UcraftTextField(
                    key: const ValueKey<String>('kiosk_set_pin_input'),
                    label: strings.kioskSetPinLabel,
                    hintText: '1234',
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    controller: _setPinController,
                    errorText: _pinError,
                  ),
                  const SizedBox(height: UcraftSpacing.space4),
                  UcraftButton(
                    label: strings.kioskEnableLockButton,
                    fullWidth: true,
                    onPressed: () => unawaited(_enablePinLock(strings)),
                  ),
                  const SizedBox(height: UcraftSpacing.space2),
                  UcraftButton(
                    label: strings.cancelLabel,
                    variant: UcraftButtonVariant.tertiary,
                    fullWidth: true,
                    onPressed: () {
                      setState(() {
                        _showSetPinForm = false;
                        _pinError = null;
                      });
                    },
                  ),
                ],
              ),
            )
          else ...[
            UcraftButton(
              label: strings.kioskLockWithPinButton,
              variant: UcraftButtonVariant.secondary,
              fullWidth: true,
              onPressed: () {
                setState(() {
                  _showSetPinForm = true;
                  _pinError = null;
                });
              },
            ),
            const SizedBox(height: UcraftSpacing.space3),
            UcraftButton(
              label: strings.kioskExitButton,
              variant: UcraftButtonVariant.tertiary,
              fullWidth: true,
              onPressed: widget.onExitKiosk,
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showUnlockForm)
          UcraftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UcraftTextField(
                  key: const ValueKey<String>('kiosk_unlock_pin_input'),
                  label: strings.kioskUnlockPinLabel,
                  hintText: '1234',
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  controller: _unlockPinController,
                  errorText: _pinError,
                ),
                const SizedBox(height: UcraftSpacing.space4),
                UcraftButton(
                  label: strings.kioskConfirmPinButton,
                  fullWidth: true,
                  onPressed: () => unawaited(_confirmUnlockAndExit(strings)),
                ),
                const SizedBox(height: UcraftSpacing.space2),
                UcraftButton(
                  label: strings.cancelLabel,
                  variant: UcraftButtonVariant.tertiary,
                  fullWidth: true,
                  onPressed: () {
                    setState(() {
                      _showUnlockForm = false;
                      _pinError = null;
                    });
                  },
                ),
              ],
            ),
          )
        else
          UcraftButton(
            label: strings.kioskUnlockAndExitButton,
            variant: UcraftButtonVariant.secondary,
            fullWidth: true,
            onPressed: () {
              setState(() {
                _showUnlockForm = true;
                _pinError = null;
              });
            },
          ),
      ],
    );
  }
}

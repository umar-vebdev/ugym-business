import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Builds a camera view that reports every raw QR string via [onDetect].
///
/// Injected into the screen so tests can replace the camera with a fake.
typedef QrScannerBuilder = Widget Function(
  BuildContext context,
  ValueChanged<String> onDetect,
);

/// Default [QrScannerBuilder] backed by `mobile_scanner`.
Widget buildMobileQrScanner(
  BuildContext context,
  ValueChanged<String> onDetect,
) {
  return _MobileQrScannerView(onDetect: onDetect);
}

final class _MobileQrScannerView extends StatefulWidget {
  const _MobileQrScannerView({required this.onDetect});

  final ValueChanged<String> onDetect;

  @override
  State<_MobileQrScannerView> createState() => _MobileQrScannerViewState();
}

final class _MobileQrScannerViewState extends State<_MobileQrScannerView> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: _controller,
      onDetect: (capture) {
        for (final barcode in capture.barcodes) {
          final value = barcode.rawValue;
          if (value != null && value.isNotEmpty) {
            widget.onDetect(value);
            break;
          }
        }
      },
    );
  }
}

import 'package:material_ui/material_ui.dart';

/// Page container that respects the active light or dark theme without
/// forcing a white background in dark mode.
final class BusinessPageSurface extends StatelessWidget {
  const BusinessPageSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (padding == EdgeInsets.zero) {
      return child;
    }
    return Padding(padding: padding, child: child);
  }
}

/// Standard frame for full-screen task routes with an app bar.
final class BusinessPageScaffold extends StatelessWidget {
  const BusinessPageScaffold({
    super.key,
    required this.appBar,
    required this.body,
  });

  final PreferredSizeWidget appBar;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: appBar, body: body);
  }
}

import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import 'business_theme.dart';

/// Keeps text and controls on a light work surface against the Midnight canvas.
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
    if (Theme.of(context).brightness == Brightness.light) {
      return child;
    }

    return Theme(
      data: BusinessTheme.light,
      child: ClipRRect(
        borderRadius: UcraftRadius.borderLg,
        child: ColoredBox(
          color: BusinessTheme.light.scaffoldBackgroundColor,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
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
    final darkCanvas = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: appBar,
      body: darkCanvas
          ? Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: UcraftSpacing.space2,
              ),
              child: BusinessPageSurface(child: body),
            )
          : body,
    );
  }
}

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import 'business_typography.dart';

/// Builds Material 3 light and dark themes for uGym Business.
///
/// In dark mode, surfaces and cards use the Midnight Soft dark palette while
/// primary buttons retain the same cobalt blue fill and white text as light mode.
abstract final class BusinessTheme {
  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static Color canvasText(BuildContext context, {bool secondary = false}) {
    final colors = context.ucraftColors;
    return secondary ? colors.foregroundSecondary : colors.foreground;
  }

  static ThemeData _build(Brightness brightness) {
    final darkCanvas = brightness == Brightness.dark;
    final colors = darkCanvas ? UcraftColors.softDark : UcraftColors.softLight;
    final base = UcraftTheme.material3(
      colors: colors,
      brightness: brightness,
      visualDensity: VisualDensity.standard,
    );
    final activeColor = darkCanvas ? colors.accent : colors.primary;
    final systemChrome = darkCanvas
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    final textTheme = UcraftTypography.buildTextTheme(
      colors.foreground,
      colors.foregroundSecondary,
    );
    final fieldBorder = OutlineInputBorder(
      borderRadius: UcraftRadius.borderSm,
      borderSide: BorderSide(color: colors.borderStrong),
    );
    return base.copyWith(
      primaryColor: colors.primary,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.surface,
      textTheme: textTheme.copyWith(
        displayLarge: BusinessTypography.display.copyWith(
          color: colors.foreground,
        ),
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontSize: BusinessTypography.display.fontSize,
          height: BusinessTypography.display.height,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        headlineMedium: BusinessTypography.headline.copyWith(
          color: colors.foreground,
        ),
        titleLarge: BusinessTypography.titleLarge.copyWith(
          color: colors.foreground,
        ),
        titleMedium: BusinessTypography.title.copyWith(
          color: colors.foreground,
        ),
        bodyLarge: BusinessTypography.bodyLarge.copyWith(
          color: colors.foreground,
        ),
        labelLarge: BusinessTypography.label.copyWith(color: colors.foreground),
        labelSmall: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: colors.surface,
        foregroundColor: colors.foreground,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: UcraftSpacing.space12 + UcraftSpacing.space2,
        shape: Border(bottom: BorderSide(color: colors.border)),
        systemOverlayStyle: systemChrome.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: colors.surface,
          systemNavigationBarIconBrightness: darkCanvas
              ? Brightness.light
              : Brightness.dark,
        ),
        titleTextStyle: BusinessTypography.titleLarge.copyWith(
          color: colors.foreground,
          letterSpacing: 0,
        ),
      ),
      dividerTheme: base.dividerTheme.copyWith(color: colors.border),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: colors.surface,
        height: 68,
        indicatorColor: colors.primarySubtle,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? activeColor
                : colors.foregroundMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => UcraftTypography.caption.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? activeColor
                : colors.foregroundMuted,
          ),
        ),
      ),
      navigationRailTheme: base.navigationRailTheme.copyWith(
        backgroundColor: colors.surface,
        indicatorColor: colors.primarySubtle,
        selectedIconTheme: IconThemeData(size: 24, color: activeColor),
        selectedLabelTextStyle: UcraftTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: activeColor,
        ),
        unselectedIconTheme: IconThemeData(
          size: 24,
          color: colors.foregroundMuted,
        ),
        unselectedLabelTextStyle: UcraftTypography.caption.copyWith(
          fontWeight: FontWeight.w500,
          color: colors.foregroundMuted,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        visualDensity: VisualDensity.standard,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(
            color: colors.focusRing,
            width: UcraftElevation.borderFocus,
          ),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(backgroundColor: colors.surface),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: colors.surface,
        modalBackgroundColor: colors.surface,
      ),
      extensions: [colors],
    );
  }
}

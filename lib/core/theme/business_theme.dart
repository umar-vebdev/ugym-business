import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import 'business_typography.dart';

/// The app uses the light uCraft component palette over both page backgrounds.
abstract final class BusinessTheme {
  static const Color _midnightSoft = Color(0xFF151C29);
  static const Color _midnightForeground = Color(0xFFE5EAF2);
  static const Color _midnightSecondary = Color(0xFFA8B4C5);

  static final UcraftColors _components = UcraftColors.light.copyWith(
    background: const Color(0xFFF5F7FA),
    surfaceSecondary: const Color(0xFFECF1F8),
    surfaceTertiary: const Color(0xFFD7DFED),
    foreground: const Color(0xFF151D2B),
    foregroundSecondary: const Color(0xFF526078),
    foregroundMuted: const Color(0xFF526078),
    border: const Color(0xFFDFE5EF),
    borderStrong: const Color(0xFF7989A4),
    primary: const Color(0xFF315FCB),
    primaryHover: const Color(0xFF244CAA),
    primaryPressed: const Color(0xFF244CAA),
    primarySubtle: const Color(0xFFE4EBF7),
    accent: const Color(0xFF315FCB),
    focusRing: const Color(0xFF315FCB),
    disabledBackground: const Color(0xFFE3EAF7),
    disabledForeground: const Color(0xFF4E608D),
    success: const Color(0xFF116443),
    successBackground: const Color(0xFFE0F6EC),
    successForeground: const Color(0xFF116443),
    warning: const Color(0xFF835219),
    warningBackground: const Color(0xFFFFF0D8),
    warningForeground: const Color(0xFF835219),
    destructive: const Color(0xFFA82B3B),
    destructiveBackground: const Color(0xFFFFEBEF),
    destructiveForeground: const Color(0xFFA82B3B),
  );

  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static Color canvasText(BuildContext context, {bool secondary = false}) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return secondary ? _midnightSecondary : _midnightForeground;
    }
    final colors = context.ucraftColors;
    return secondary ? colors.foregroundSecondary : colors.foreground;
  }

  static ThemeData _build(Brightness brightness) {
    final base = UcraftTheme.light();
    final colors = _components;
    final darkCanvas = brightness == Brightness.dark;
    final background = darkCanvas ? _midnightSoft : colors.background;
    final canvasForeground = darkCanvas
        ? _midnightForeground
        : colors.foreground;
    final systemChrome = darkCanvas
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    final scheme = base.colorScheme.copyWith(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: colors.primarySubtle,
      onPrimaryContainer: colors.foreground,
      secondary: colors.accent,
      onSecondary: colors.onPrimary,
      secondaryContainer: colors.surfaceSecondary,
      onSecondaryContainer: colors.foreground,
      surface: colors.surface,
      surfaceContainerLow: colors.background,
      surfaceContainer: colors.surfaceSecondary,
      surfaceContainerHigh: colors.surface,
      surfaceContainerHighest: colors.surfaceSecondary,
      onSurface: colors.foreground,
      onSurfaceVariant: colors.foregroundSecondary,
      error: colors.destructive,
      onError: colors.onPrimary,
      errorContainer: colors.destructiveBackground,
      onErrorContainer: colors.destructiveForeground,
      outline: colors.borderStrong,
      outlineVariant: colors.border,
      surfaceTint: Colors.transparent,
    );
    final textTheme = UcraftTypography.buildTextTheme(
      colors.foreground,
      colors.foregroundSecondary,
    );
    final fieldBorder = OutlineInputBorder(
      borderRadius: UcraftRadius.borderSm,
      borderSide: BorderSide(color: colors.borderStrong),
    );
    return base.copyWith(
      colorScheme: scheme,
      primaryColor: colors.primary,
      scaffoldBackgroundColor: background,
      canvasColor: colors.surface,
      textTheme: textTheme.copyWith(
        displayLarge: BusinessTypography.display.copyWith(
          color: colors.foreground,
        ),
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
        labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        labelSmall: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: background,
        foregroundColor: canvasForeground,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: systemChrome.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: colors.surface,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: UcraftTypography.title.copyWith(
          color: canvasForeground,
          letterSpacing: 0,
        ),
      ),
      dividerTheme: base.dividerTheme.copyWith(color: colors.border),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: colors.surface,
        indicatorColor: colors.primarySubtle,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.foregroundMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => UcraftTypography.caption.copyWith(
            fontWeight: FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.foregroundMuted,
          ),
        ),
      ),
      navigationRailTheme: base.navigationRailTheme.copyWith(
        backgroundColor: colors.surface,
        indicatorColor: colors.primarySubtle,
        selectedIconTheme: IconThemeData(size: 24, color: colors.primary),
        selectedLabelTextStyle: UcraftTypography.caption.copyWith(
          fontWeight: FontWeight.w500,
          color: colors.primary,
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

import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

/// Business display styles from the approved uCraft mockups.
abstract final class BusinessTypography {
  static final TextStyle display = UcraftTypography.display.copyWith(
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static final TextStyle amount = UcraftTypography.bodyMedium.copyWith(
    letterSpacing: 0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static final TextStyle amountLarge = UcraftTypography.headlineLarge.copyWith(
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

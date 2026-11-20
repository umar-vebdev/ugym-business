import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

/// Business display styles from the approved uCraft mockups.
abstract final class BusinessTypography {
  static final TextStyle display = UcraftTypography.display.copyWith(
    fontSize: UcraftTypography.headline.fontSize,
    height: UcraftTypography.headline.height,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static final TextStyle headline = UcraftTypography.titleLarge.copyWith(
    height: 1.25,
    letterSpacing: 0,
  );

  static final TextStyle title = UcraftTypography.bodyLarge.copyWith(
    fontWeight: FontWeight.w600,
    height: 1.375,
  );

  static final TextStyle titleLarge = title.copyWith(
    fontWeight: FontWeight.w500,
  );

  static final TextStyle label = UcraftTypography.label.copyWith(
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodyLarge = UcraftTypography.body;

  static final TextStyle bodyMedium = UcraftTypography.label.copyWith(
    fontWeight: FontWeight.w500,
  );

  static final TextStyle amount = UcraftTypography.bodyMedium.copyWith(
    letterSpacing: 0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static final TextStyle amountLarge = UcraftTypography.headlineLarge.copyWith(
    fontSize: 22,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

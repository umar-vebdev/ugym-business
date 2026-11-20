import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

/// Business display styles with clear hierarchy between headings, labels, and values.
abstract final class BusinessTypography {
  static final TextStyle display = UcraftTypography.display.copyWith(
    fontSize: 26,
    height: 34 / 26,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static final TextStyle headline = UcraftTypography.titleLarge.copyWith(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static final TextStyle titleLarge = UcraftTypography.title.copyWith(
    fontSize: 18,
    height: 25 / 18,
    fontWeight: FontWeight.w700,
  );

  static final TextStyle title = UcraftTypography.title.copyWith(
    fontSize: 17,
    height: 24 / 17,
    fontWeight: FontWeight.w700,
  );

  static final TextStyle label = UcraftTypography.label.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLarge = UcraftTypography.bodyLarge;

  static final TextStyle bodyMedium = UcraftTypography.bodyMedium.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static final TextStyle amount = UcraftTypography.bodyLarge.copyWith(
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static final TextStyle amountLarge = UcraftTypography.headlineLarge.copyWith(
    fontSize: 26,
    height: 32 / 26,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

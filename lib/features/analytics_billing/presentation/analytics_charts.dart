import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../domain/analytics_and_billing_models.dart';

/// Accessible vertical bar chart for daily gym visits following uCraft 1.0 §15.
final class VisitsByDayBarChart extends StatelessWidget {
  const VisitsByDayBarChart({
    super.key,
    required this.byDay,
    this.seriesLabel = 'Посещения по дням',
    this.peakLabelPrefix = 'Максимум за день',
    this.emptyMessage = 'Нет данных по посещениям за выбранный период.',
  });

  final Map<String, int> byDay;
  final String seriesLabel;
  final String peakLabelPrefix;
  final String emptyMessage;

  static const double _barPlotHeight = 120;

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final entries = byDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final int maxCount = entries.fold<int>(
      0,
      (prev, entry) => math.max(prev, entry.value),
    );

    if (entries.isEmpty || maxCount <= 0) {
      return Container(
        padding: const EdgeInsets.all(UcraftSpacing.space4),
        decoration: BoxDecoration(
          color: colors.surfaceSecondary,
          borderRadius: UcraftRadius.borderSm,
          border: Border.all(
            color: colors.border,
            width: UcraftElevation.borderDefault,
          ),
        ),
        child: Text(
          emptyMessage,
          style: UcraftTypography.caption.copyWith(
            color: colors.foregroundSecondary,
          ),
        ),
      );
    }

    final int midCount = (maxCount / 2).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: UcraftSpacing.space3,
          runSpacing: UcraftSpacing.space1,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: UcraftRadius.borderXs,
                  ),
                ),
                const SizedBox(width: UcraftSpacing.space2),
                Text(
                  seriesLabel,
                  style: UcraftTypography.label.copyWith(
                    color: colors.foreground,
                  ),
                ),
              ],
            ),
            Text(
              '$peakLabelPrefix: $maxCount',
              style: UcraftTypography.caption.copyWith(
                fontFamily: UcraftTypography.monoFontFamily,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: colors.foregroundSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: UcraftSpacing.space3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              height: _barPlotHeight + 24,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$maxCount',
                    style: UcraftTypography.overline.copyWith(
                      fontFamily: UcraftTypography.monoFontFamily,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: colors.foregroundSecondary,
                    ),
                  ),
                  Text(
                    '$midCount',
                    style: UcraftTypography.overline.copyWith(
                      fontFamily: UcraftTypography.monoFontFamily,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: colors.foregroundSecondary,
                    ),
                  ),
                  Text(
                    '0',
                    style: UcraftTypography.overline.copyWith(
                      fontFamily: UcraftTypography.monoFontFamily,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: colors.foregroundSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: UcraftSpacing.space2),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: math.max(entries.length * 48.0, 220.0),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        top: 24,
                        bottom: 24,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Divider(height: 1, color: colors.border),
                            Divider(height: 1, color: colors.border),
                            Divider(height: 1, color: colors.border),
                          ],
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          for (final entry in entries)
                            _VisitBarColumn(
                              dateKey: entry.key,
                              count: entry.value,
                              maxCount: maxCount,
                              plotHeight: _barPlotHeight,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

final class _VisitBarColumn extends StatelessWidget {
  const _VisitBarColumn({
    required this.dateKey,
    required this.count,
    required this.maxCount,
    required this.plotHeight,
  });

  final String dateKey;
  final int count;
  final int maxCount;
  final double plotHeight;

  String _shortDateLabel(String raw) {
    final parts = raw.split('-');
    if (parts.length == 3) {
      return '${parts[2]}.${parts[1]}';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final double ratio = maxCount > 0 ? (count / maxCount).clamp(0.0, 1.0) : 0;
    final double barHeight = count > 0
        ? math.max(4.0, ratio * plotHeight)
        : 0.0;

    return Semantics(
      label: '$dateKey: $count',
      excludeSemantics: true,
      child: SizedBox(
        width: 44,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 24,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  '$count',
                  style: UcraftTypography.overline.copyWith(
                    fontFamily: UcraftTypography.monoFontFamily,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: colors.foreground,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: plotHeight,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 24,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(UcraftRadius.xs),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: UcraftSpacing.space1),
            SizedBox(
              height: 20,
              child: Text(
                _shortDateLabel(dateKey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UcraftTypography.caption.copyWith(
                  color: colors.foregroundSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Accessible payment-method breakdown bar with legend following uCraft 1.0 §15.
final class RevenuePaymentMixBar extends StatelessWidget {
  const RevenuePaymentMixBar({
    super.key,
    required this.byPaymentMethod,
    required this.currency,
    this.cashLabel = 'Наличные',
    this.terminalLabel = 'Терминал',
    this.transferLabel = 'Перевод',
    this.emptyMessage = 'Оплат за выбранный период нет.',
  });

  final RevenueByPaymentMethod byPaymentMethod;
  final String currency;
  final String cashLabel;
  final String terminalLabel;
  final String transferLabel;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    final int total =
        byPaymentMethod.cash +
        byPaymentMethod.cardTerminal +
        byPaymentMethod.transfer;

    if (total <= 0) {
      return Text(
        emptyMessage,
        style: UcraftTypography.caption.copyWith(
          color: colors.foregroundSecondary,
        ),
      );
    }

    final segments = <({String label, int minor, Color color})>[
      (label: cashLabel, minor: byPaymentMethod.cash, color: colors.primary),
      (
        label: terminalLabel,
        minor: byPaymentMethod.cardTerminal,
        color: colors.info,
      ),
      (
        label: transferLabel,
        minor: byPaymentMethod.transfer,
        color: colors.success,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: UcraftRadius.borderFull,
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                for (final segment in segments)
                  if (segment.minor > 0)
                    Expanded(
                      flex: segment.minor,
                      child: Container(color: segment.color),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: UcraftSpacing.space2),
        Wrap(
          spacing: UcraftSpacing.space4,
          runSpacing: UcraftSpacing.space2,
          children: [
            for (final segment in segments)
              _LegendEntry(
                label: segment.label,
                color: segment.color,
                percent: ((segment.minor / total) * 100).round(),
                amountText: MoneyFormatter.format(
                  segment.minor,
                  currency: currency,
                  alwaysShowDecimals: true,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

final class _LegendEntry extends StatelessWidget {
  const _LegendEntry({
    required this.label,
    required this.color,
    required this.percent,
    required this.amountText,
  });

  final String label;
  final Color color;
  final int percent;
  final String amountText;

  @override
  Widget build(BuildContext context) {
    final colors = context.ucraftColors;
    return Semantics(
      label: '$label: $percent%, $amountText',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: UcraftRadius.borderFull,
            ),
          ),
          const SizedBox(width: UcraftSpacing.space1),
          Text(
            '$label $percent% ($amountText)',
            style: UcraftTypography.caption.copyWith(
              color: colors.foregroundSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

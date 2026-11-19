import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_business/features/analytics_billing/domain/analytics_and_billing_models.dart';
import 'package:ugym_business/features/analytics_billing/presentation/analytics_charts.dart';
import 'package:ugym_core/ugym_core.dart';

void main() {
  testWidgets(
    'VisitsByDayBarChart sorts dates, displays peak and bars in Light and Dark themes',
    (tester) async {
      for (final theme in [UcraftTheme.light(), UcraftTheme.dark()]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(UcraftSpacing.space4),
                child: VisitsByDayBarChart(
                  byDay: {'2026-11-19': 28, '2026-11-17': 14, '2026-11-18': 21},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Посещения по дням'), findsOneWidget);
        expect(find.text('Максимум за день: 28'), findsOneWidget);
        expect(find.text('17.11'), findsOneWidget);
        expect(find.text('18.11'), findsOneWidget);
        expect(find.text('19.11'), findsOneWidget);
        expect(find.bySemanticsLabel('2026-11-19: 28'), findsOneWidget);
      }
    },
  );

  testWidgets('VisitsByDayBarChart shows empty state when no visits exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: UcraftTheme.light(),
        home: const Scaffold(body: VisitsByDayBarChart(byDay: {})),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Нет данных по посещениям за выбранный период.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'RevenuePaymentMixBar renders payment percentages and empty state cleanly',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.light(),
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(UcraftSpacing.space4),
              child: RevenuePaymentMixBar(
                byPaymentMethod: RevenueByPaymentMethod(
                  cash: 30000,
                  cardTerminal: 15000,
                  transfer: 5000,
                ),
                currency: 'TJS',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Наличные 60% (300.00 TJS)'), findsOneWidget);
      expect(find.text('Терминал 30% (150.00 TJS)'), findsOneWidget);
      expect(find.text('Перевод 10% (50.00 TJS)'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: UcraftTheme.dark(),
          home: const Scaffold(
            body: RevenuePaymentMixBar(
              byPaymentMethod: RevenueByPaymentMethod(
                cash: 0,
                cardTerminal: 0,
                transfer: 0,
              ),
              currency: 'TJS',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Оплат за выбранный период нет.'), findsOneWidget);
    },
  );
}

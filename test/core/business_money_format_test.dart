import 'package:flutter_test/flutter_test.dart';
import 'package:ugym_business/core/l10n/business_localizations.dart';

void main() {
  test('formats integer money values for each supported interface locale', () {
    for (final strings in [BusinessStrings.ru, BusinessStrings.tg]) {
      expect(
        strings.formatMoney(1147682, currency: 'TJS'),
        '11\u00a0476,82\u00a0TJS',
      );
    }
    expect(
      BusinessStrings.en.formatMoney(-1147682, currency: ' USD '),
      '-11,476.82\u00a0USD',
    );
    expect(
      BusinessStrings.ru.formatMoney(
        500,
        currency: 'TJS',
        alwaysShowDecimals: false,
      ),
      '5\u00a0TJS',
    );
    expect(BusinessStrings.ru.formatMoney(501, currency: ''), '5,01');
  });
}

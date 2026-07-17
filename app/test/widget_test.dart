import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scheme_app/l10n/strings.dart';

void main() {
  testWidgets('S localizations resolve through the widget tree',
      (tester) async {
    late S s;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('hi'),
        delegates: const [
          SDelegate(),
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Builder(
          builder: (context) {
            s = S.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(s.code, 'hi');
    expect(s.get('appTitle'), isNotEmpty);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:yadav_ka_alarm/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const YadavAlarmApp());
    expect(find.text('YADAV KA ALARM'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:drift_app/main.dart';

void main() {
  testWidgets('DriFt app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const DriFtApp());
    await tester.pump();
  });
}

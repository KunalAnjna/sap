import 'package:flutter_test/flutter_test.dart';
import 'package:staff_attendance_pro/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
  });
}

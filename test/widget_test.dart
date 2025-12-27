// CardFlow widget tests

import 'package:flutter_test/flutter_test.dart';
import 'package:cardflow/main.dart';

void main() {
  testWidgets('CardFlow app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const CardFlowApp());
    
    // Verify that app title is present
    expect(find.text('CardFlow'), findsOneWidget);
  });
}

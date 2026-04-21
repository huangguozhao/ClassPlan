import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:class_plan/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ClassPlanApp()));
    await tester.pumpAndSettle();

    // Verify the app starts and shows the bottom navigation
    expect(find.text('本周课表'), findsOneWidget);
    expect(find.text('导入课程'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
  });
}

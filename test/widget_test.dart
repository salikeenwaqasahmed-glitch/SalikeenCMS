import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salik_management_system/main.dart';

void main() {
  testWidgets('App loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SalikManagementApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('SALIK'), findsWidgets);
  });
}

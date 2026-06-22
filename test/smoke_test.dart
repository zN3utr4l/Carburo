import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tanko/src/app/app.dart';

void main() {
  testWidgets('App renders title', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    expect(find.text('Tanko'), findsOneWidget);
  });
}

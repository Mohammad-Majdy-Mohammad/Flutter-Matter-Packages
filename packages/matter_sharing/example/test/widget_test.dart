import 'package:flutter_test/flutter_test.dart';

import 'package:matter_sharing_example/main.dart';

void main() {
  testWidgets('example app builds its home page', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Matter Sharing Example'), findsWidgets);
  });
}

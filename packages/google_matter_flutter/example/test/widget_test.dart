import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:google_matter_flutter_example/main.dart';

void main() {
  testWidgets('example app builds its home page', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Google Matter example app'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsWidgets);
  });
}

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gooey_fab/gooey_fab.dart';

void main() {
  testWidgets('GooeyFab smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GooeyFabScaffold(
          body: const Center(child: Text('Home')),
          items: [
            GooeyFabItem(
              icon: Icons.add,
              label: 'Add',
              onTap: (_) {},
            ),
          ],
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.byType(GooeyFab), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}

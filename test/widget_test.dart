import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:room_o_matic_mobile/interface/app.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: RoomOMaticApp(),
      ),
    );

    // Verify that we can find the app
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myogrip_ai/theme.dart';
import 'package:myogrip_ai/widgets.dart';

void main() {
  testWidgets('a missing image asset renders a placeholder without crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: ImageOrPlaceholder(
            asset: 'assets/images/missing-test-image.png',
            width: 120,
            height: 80,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

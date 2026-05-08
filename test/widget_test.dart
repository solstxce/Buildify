import 'package:buildify_flutter/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('shows mobile AI server home', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BuildifyApp()));

    expect(find.text('Buildify AI'), findsOneWidget);
    expect(find.text('Server Stopped'), findsOneWidget);
    expect(find.text('TinyLlama 1.1B Q4'), findsOneWidget);
    expect(find.text('Start AI Server'), findsOneWidget);
  });
}

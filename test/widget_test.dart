import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_test/main.dart';

void main() {
  testWidgets('splash reveals the login form after two seconds', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byKey(const ValueKey('splashSubtitle')), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.byKey(const ValueKey('authButton')), findsOneWidget);
  });

  testWidgets('can switch between login and sign up', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 1500));

    final switchMode = find.byKey(const ValueKey('switchMode'));
    await tester.ensureVisible(switchMode);
    await tester.tap(switchMode);
    await tester.pumpAndSettle();

    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Enter your name'), findsOneWidget);
    expect(find.text('Already have an account? '), findsOneWidget);
  });

  testWidgets('shows loader and completes the curtain transition', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 1500));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'hello@slate.app');
    await tester.enterText(fields.at(1), '123456');
    await tester.tap(find.byKey(const ValueKey('authButton')));
    await tester.pump();

    expect(find.byKey(const ValueKey('waterDropLoader')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pump(const Duration(milliseconds: 1800));

    expect(find.text('Welcome to SLATE'), findsOneWidget);
  });
}

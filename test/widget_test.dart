import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_test/main.dart';
import 'package:flutter_application_test/screens/home_screen.dart';
import 'package:flutter_application_test/services/expense_service.dart';
import 'package:flutter_application_test/widgets/preview_expense_dialog.dart';

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

  testWidgets('shows loader and transitions directly to HomeScreen', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 1500));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'hello@crouket.app');
    await tester.enterText(fields.at(1), '123456');
    await tester.tap(find.byKey(const ValueKey('authButton')));
    await tester.pump();

    expect(find.byKey(const ValueKey('waterDropLoader')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();

    expect(find.text('Chụp món đồ bạn vừa chi tiêu'), findsOneWidget);
  });

  testWidgets('forgot password flow works from login page', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 1500));

    // Tap Forgot password?
    final forgotBtn = find.byKey(const ValueKey('forgotPasswordButton'));
    await tester.ensureVisible(forgotBtn);
    await tester.tap(forgotBtn);
    await tester.pumpAndSettle();

    // Verify on Forgot Password Page
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.byKey(const ValueKey('forgotEmailField')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('sendInstructionsButton')),
      findsOneWidget,
    );

    // Test validation: submit empty
    await tester.tap(find.byKey(const ValueKey('sendInstructionsButton')));
    await tester.pump();
    expect(find.text('Please enter your email'), findsOneWidget);

    // Test validation: invalid email
    await tester.enterText(
      find.byKey(const ValueKey('forgotEmailField')),
      'invalid-email',
    );
    await tester.tap(find.byKey(const ValueKey('sendInstructionsButton')));
    await tester.pump();
    expect(find.text('Email is not valid'), findsOneWidget);

    // Enter valid email and submit
    await tester.enterText(
      find.byKey(const ValueKey('forgotEmailField')),
      'user@crouket.app',
    );
    await tester.tap(find.byKey(const ValueKey('sendInstructionsButton')));
    await tester.pump();

    // Loader is shown
    expect(find.byKey(const ValueKey('waterDropLoaderForgot')), findsOneWidget);

    // Advance time for async submit
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();

    // Verify success view
    expect(find.byKey(const ValueKey('successView')), findsOneWidget);
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.textContaining('user@crouket.app'), findsOneWidget);

    // Tap Back to Login
    await tester.tap(find.byKey(const ValueKey('backToLoginButton')));
    await tester.pumpAndSettle();

    // Verify back on login page
    expect(find.text('Enter your email'), findsOneWidget);
  });

  testWidgets('can navigate directly from login to HomeScreen', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 1500));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'test@crouket.app');
    await tester.enterText(fields.at(1), '123456');
    await tester.tap(find.byKey(const ValueKey('authButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();

    // Verify inside HomeScreen directly
    expect(find.text('Chụp món đồ bạn vừa chi tiêu'), findsOneWidget);
    expect(find.byKey(const ValueKey('shutterButton')), findsOneWidget);
  });

  testWidgets(
    'HomeScreen tabs switch between camera, feed, stats, and categories',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      // Camera tab
      expect(find.text('Chụp món đồ bạn vừa chi tiêu'), findsOneWidget);

      // Switch to Feed tab
      await tester.tap(find.text('Feed bạn bè'));
      await tester.pumpAndSettle();
      expect(find.text('C R O U K E T   F E E D'), findsOneWidget);

      // Switch to Stats tab
      await tester.tap(find.text('Thống kê'));
      await tester.pumpAndSettle();
      expect(find.text('THỐNG KÊ CHI TIÊU'), findsOneWidget);
      expect(find.text('TỔNG CHI TIÊU CỦA BẠN'), findsOneWidget);

      // Switch to Categories tab
      await tester.tap(find.text('Danh mục'));
      await tester.pumpAndSettle();
      expect(find.text('DANH MỤC & BẠN BÈ'), findsOneWidget);
      expect(find.byKey(const ValueKey('addCatButton')), findsOneWidget);
    },
  );

  testWidgets(
    'Camera tab gestures: swipe down to feed, swipe right to stats, and back to camera button',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      // Start on camera tab
      expect(find.text('Chụp món đồ bạn vừa chi tiêu'), findsOneWidget);

      // 1. Swipe up on camera tab -> should open Feed
      await tester.drag(find.text('Chụp món đồ bạn vừa chi tiêu'), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('C R O U K E T   F E E D'), findsOneWidget);

      // 2. Tap back button on Feed -> should return to Camera
      final backFromFeed = find.byKey(const ValueKey('backToCameraFromFeed'));
      expect(backFromFeed, findsOneWidget);
      await tester.tap(backFromFeed);
      await tester.pumpAndSettle();
      expect(find.text('Chụp món đồ bạn vừa chi tiêu'), findsOneWidget);

      // 3. Swipe right on camera tab -> should open Stats
      await tester.drag(find.text('Chụp món đồ bạn vừa chi tiêu'), const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(find.text('THỐNG KÊ CHI TIÊU'), findsOneWidget);

      // 4. Tap back button on Stats -> should return to Camera
      final backFromStats = find.byKey(const ValueKey('backToCameraFromStats'));
      expect(backFromStats, findsOneWidget);
      await tester.tap(backFromStats);
      await tester.pumpAndSettle();
      expect(find.text('Chụp món đồ bạn vừa chi tiêu'), findsOneWidget);
    },
  );

  testWidgets('FeedScreen allows reacting with emojis', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    // Go to feed tab
    await tester.tap(find.text('Feed bạn bè'));
    await tester.pumpAndSettle();

    // Scroll feed item up to reveal reaction buttons
    await tester.drag(find.byType(ListView), const Offset(0, -450));
    await tester.pumpAndSettle();

    // Tap a reaction
    final reactionChip = find.byKey(const ValueKey('react_seed_1_💸'));
    expect(reactionChip, findsOneWidget);
    await tester.tap(reactionChip, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Tapping again toggles off
    await tester.tap(reactionChip, warnIfMissed: false);
    await tester.pumpAndSettle();
  });

  testWidgets('PreviewExpenseDialog validates amount and creates transaction', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PreviewExpenseDialog(photoPath: 'test_path')),
    );
    await tester.pumpAndSettle();

    // Verify fields exist
    expect(find.byKey(const ValueKey('captionInput')), findsOneWidget);
    expect(find.byKey(const ValueKey('amountInput')), findsOneWidget);
    expect(find.byKey(const ValueKey('submitExpenseButton')), findsOneWidget);

    // Enter caption and amount
    await tester.enterText(
      find.byKey(const ValueKey('captionInput')),
      'Trà sữa chiều 🧋',
    );
    await tester.enterText(find.byKey(const ValueKey('amountInput')), '45000');

    // Tap submit button
    final submitBtn = find.byKey(const ValueKey('submitExpenseButton'));
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // Verify transaction added to ExpenseService
    final service = ExpenseService();
    expect(service.transactions.first.caption, 'Trà sữa chiều 🧋');
    expect(service.transactions.first.amount, 45000);
  });
}

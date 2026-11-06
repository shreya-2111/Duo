import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:duo/features/navigation/screens/main_navigation_screen.dart';
import 'package:duo/features/expenses/screens/add_expense_screen.dart';
import 'package:duo/features/tasks/screens/add_task_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('MainNavigationScreen: Switching tabs and back navigation to Home', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainNavigationScreen(initialIndex: 1), // Starts on Money tab
      ),
    );
    await tester.pumpAndSettle();

    // Verify Money screen is visible
    expect(find.text('My Money'), findsOneWidget);

    // Trigger system back on Money tab
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // Should switch smoothly to Home tab (index 0) instead of exiting
    expect(find.text('Money Managed. Tasks Shared.'), findsOneWidget);
  });

  testWidgets('AddExpenseScreen: Clean form pops immediately without discard dialog', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
            child: const Text('Open Add Expense'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open screen
    await tester.tap(find.text('Open Add Expense'));
    await tester.pumpAndSettle();
    expect(find.text('Add Expense'), findsOneWidget);

    // Tap AppBar back arrow
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // Should pop directly back to parent screen without showing discard dialog
    expect(find.text('Discard Changes?'), findsNothing);
    expect(find.text('Open Add Expense'), findsOneWidget);
  });

  testWidgets('AddExpenseScreen: Shows Discard Changes dialog when form has edits', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
            child: const Text('Open Add Expense'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open screen
    await tester.tap(find.text('Open Add Expense'));
    await tester.pumpAndSettle();

    // Enter expense title
    await tester.enterText(find.byType(TextField).first, 'Grocery shopping');
    await tester.pumpAndSettle();

    // Tap AppBar back arrow
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // Discard dialog MUST appear
    expect(find.text('Discard Changes?'), findsOneWidget);
    expect(find.text('Keep Editing'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);

    // Tap Keep Editing
    await tester.tap(find.text('Keep Editing'));
    await tester.pumpAndSettle();

    // Dialog dismissed, user stays on form
    expect(find.text('Discard Changes?'), findsNothing);
    expect(find.text('Add Expense'), findsOneWidget);

    // Tap Back again, then Discard
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    // Screen dismissed, returns to parent
    expect(find.text('Open Add Expense'), findsOneWidget);
  });

  testWidgets('AddTaskScreen: Shows Discard Changes dialog when form has edits', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTaskScreen())),
            child: const Text('Open Add Task'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open screen
    await tester.tap(find.text('Open Add Task'));
    await tester.pumpAndSettle();

    // Enter task title
    await tester.enterText(find.byType(TextField).first, 'Submit tax documents');
    await tester.pumpAndSettle();

    // Tap AppBar back arrow
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // Discard dialog MUST appear
    expect(find.text('Discard Changes?'), findsOneWidget);

    // Tap Discard
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    // Screen dismissed, returns to parent
    expect(find.text('Open Add Task'), findsOneWidget);
  });
}

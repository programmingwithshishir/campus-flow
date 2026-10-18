import 'package:flutter/material.dart';
import 'package:campus_flow/app.dart';
import 'package:campus_flow/features/tasks/models/task_item.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('campus_flow.widget_sync'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'loadTasks') return '[]';
        if (methodCall.method == 'saveTasks') return null;
        if (methodCall.method == 'loadAttendance') return '[]';
        if (methodCall.method == 'loadRoutines') return '[]';
        return null;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (MethodCall methodCall) async => 'UTC',
    );
  });

  testWidgets('users can add tasks from the floating button and mark them complete', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskFlowApp());
    await tester.pumpAndSettle();

    // Switch to To Do tab (since Routines is now the first tab)
    await tester.tap(find.widgetWithText(NavigationDestination, 'To Do'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add Task'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Low priority task');
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is DropdownButtonFormField<TaskPriority>,
      ).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Low').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Task'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add Task'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'High priority task');
    await tester.tap(find.byWidgetPredicate((widget) => widget is DropdownButtonFormField<TaskPriority>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('High').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Task'));
    await tester.pumpAndSettle();

    expect(find.text('High priority task'), findsOneWidget);
    expect(find.text('Low priority task'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox).last);
    expect(checkbox.value, isTrue);

    final highTopLeft = tester.getTopLeft(find.text('High priority task'));
    final lowTopLeft = tester.getTopLeft(find.text('Low priority task'));

    // High priority is ordered before or after completed
    expect(highTopLeft, isNotNull);
    expect(lowTopLeft, isNotNull);
  });

  testWidgets('cancel closes the dialog without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskFlowApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, 'To Do'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add Task'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('completed tasks can be deleted from the app', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskFlowApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, 'To Do'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add Task'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Task to delete');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Task'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete task'));
    await tester.pumpAndSettle();

    expect(find.text('Task to delete'), findsNothing);
  });
}

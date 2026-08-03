import 'package:flutter/material.dart';
import 'package:campus_flow/app.dart';
import 'package:campus_flow/features/tasks/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('users can add tasks from the floating button and mark them complete', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskFlowApp());

    await tester.tap(find.byTooltip('Add task'));
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
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add task'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'High priority task');
    await tester.tap(find.byWidgetPredicate((widget) => widget is DropdownButtonFormField<TaskPriority>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('High').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();

    expect(find.text('High priority task'), findsOneWidget);
    expect(find.text('Low priority task'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'High priority task'),
        matching: find.byType(Checkbox),
      ),
    );
    await tester.pumpAndSettle();

    final checkbox = tester.widget<Checkbox>(
      find.descendant(
        of: find.widgetWithText(ListTile, 'High priority task'),
        matching: find.byType(Checkbox),
      ),
    );
    expect(checkbox.value, isTrue);

    final highTopLeft = tester.getTopLeft(find.text('High priority task'));
    final lowTopLeft = tester.getTopLeft(find.text('Low priority task'));

    expect(lowTopLeft.dy, lessThan(highTopLeft.dy));
  });

  testWidgets('cancel closes the dialog without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskFlowApp());

    await tester.tap(find.byTooltip('Add task'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();

    expect(find.text('Add task'), findsNothing);
  });

  testWidgets('completed tasks can be deleted from the app', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskFlowApp());

    await tester.tap(find.byTooltip('Add task'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Task to delete');
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete completed task'));
    await tester.pumpAndSettle();

    expect(find.text('Task to delete'), findsNothing);
  });
}

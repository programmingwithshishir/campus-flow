import 'package:campus_flow/app.dart';
import 'package:campus_flow/features/routines/models/routine_item.dart';
import 'package:campus_flow/features/routines/pages/routine_dialog.dart';
import 'package:campus_flow/features/routines/pages/routines_page.dart';
import 'package:flutter/material.dart';
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
        if (methodCall.method == 'loadRoutines') {
          return '[]';
        }
        if (methodCall.method == 'saveRoutines') {
          return null;
        }
        if (methodCall.method == 'loadTasks') {
          return '[]';
        }
        if (methodCall.method == 'loadAttendance') {
          return '[]';
        }
        return null;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (MethodCall methodCall) async {
        return 'UTC';
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (MethodCall methodCall) async {
        return true;
      },
    );
  });

  group('RoutineItem Model Tests', () {
    test('creates routine item and formats time correctly', () {
      final routine = RoutineItem(
        id: '123',
        name: 'Morning Run',
        hour: 7,
        minute: 30,
        days: {1, 2, 3, 4, 5},
        createdAt: DateTime(2026, 1, 1),
      );

      expect(routine.timeString, '7:30 AM');
      expect(routine.daysSummary, 'Weekdays');
      expect(routine.isEnabled, isTrue);
    });

    test('formats PM time and weekend days correctly', () {
      final routine = RoutineItem(
        id: '124',
        name: 'Weekend Study',
        hour: 14,
        minute: 5,
        days: {6, 7},
        createdAt: DateTime(2026, 1, 1),
      );

      expect(routine.timeString, '2:05 PM');
      expect(routine.daysSummary, 'Weekends');
    });

    test('formats midnight and every day correctly', () {
      final routine = RoutineItem(
        id: '125',
        name: 'Midnight Routine',
        hour: 0,
        minute: 0,
        days: {1, 2, 3, 4, 5, 6, 7},
        createdAt: DateTime(2026, 1, 1),
      );

      expect(routine.timeString, '12:00 AM');
      expect(routine.daysSummary, 'Every day');
    });

    test('JSON serialization and deserialization works correctly', () {
      final original = RoutineItem(
        id: 'routine_1',
        name: 'Physics Lab',
        hour: 16,
        minute: 45,
        days: {1, 3, 5},
        isEnabled: false,
        createdAt: DateTime(2026, 3, 10, 12, 0),
      );

      final json = original.toJson();
      final fromJson = RoutineItem.fromJson(json);

      expect(fromJson.id, original.id);
      expect(fromJson.name, original.name);
      expect(fromJson.hour, original.hour);
      expect(fromJson.minute, original.minute);
      expect(fromJson.days, original.days);
      expect(fromJson.isEnabled, original.isEnabled);

      final encoded = encodeRoutines([original]);
      final decodedList = decodeRoutines(encoded);
      expect(decodedList.length, 1);
      expect(decodedList.first.name, 'Physics Lab');
    });
  });

  group('RoutineDialog Widget Tests', () {
    testWidgets('renders dialog with all 7 day checkboxes and inputs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RoutineDialog(),
          ),
        ),
      );

      expect(find.widgetWithText(ElevatedButton, 'Add Routine'), findsOneWidget);
      expect(find.text('Routine Name'), findsOneWidget);
      expect(find.text('Reminder Time'), findsOneWidget);
      expect(find.text('Days of Week'), findsOneWidget);

      // Verify all 7 days of the week are listed
      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Tuesday'), findsOneWidget);
      expect(find.text('Wednesday'), findsOneWidget);
      expect(find.text('Thursday'), findsOneWidget);
      expect(find.text('Friday'), findsOneWidget);
      expect(find.text('Saturday'), findsOneWidget);
      expect(find.text('Sunday'), findsOneWidget);

      // Verify 7 checkboxes exist for the 7 days of the week
      expect(find.byType(Checkbox), findsNWidgets(7));
    });

    testWidgets('validates empty name input on submit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RoutineDialog(),
          ),
        ),
      );

      // Tap Add Routine without entering a name
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Routine'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a routine name'), findsOneWidget);
    });

    testWidgets('allows entering routine name and selecting days', (tester) async {
      RoutineItem? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<RoutineItem>(
                    context: context,
                    builder: (_) => const RoutineDialog(),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Enter routine name
      await tester.enterText(find.byType(TextField), 'Algorithms Study');

      // Tap "Weekends" quick chip
      await tester.tap(find.text('Weekends'));
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Routine'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.name, 'Algorithms Study');
      expect(result!.days, {6, 7});
    });
  });

  group('Navigation and Routines Page Tests', () {
    testWidgets('shows Routines as first tab in main navigation', (tester) async {
      await tester.pumpWidget(const TaskFlowApp());
      await tester.pumpAndSettle();

      // Check navigation destinations
      expect(find.widgetWithText(NavigationDestination, 'Routines'), findsOneWidget);
      expect(find.widgetWithText(NavigationDestination, 'To Do'), findsOneWidget);
      expect(find.widgetWithText(NavigationDestination, 'Attendance'), findsOneWidget);

      // Header should say Routines (since it is the default first tab)
      expect(find.widgetWithText(AppBar, 'Routines'), findsOneWidget);
      expect(find.byType(RoutinesPage), findsOneWidget);
      expect(find.widgetWithText(FloatingActionButton, 'Add Routine'), findsOneWidget);

      // Navigate to To Do
      await tester.tap(find.widgetWithText(NavigationDestination, 'To Do'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'To Do'), findsOneWidget);

      // Navigate back to Routines
      await tester.tap(find.widgetWithText(NavigationDestination, 'Routines'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Routines'), findsOneWidget);
    });

    test('daily checkbox completion and automatic next-day reset logic', () {
      final todayStr = RoutineItem.todayDateString;
      final routine = RoutineItem(
        id: 'r1',
        name: 'Morning Workout',
        hour: 6,
        minute: 30,
        days: {1, 2, 3, 4, 5, 6, 7},
        createdAt: DateTime(2026, 1, 1),
      );

      // Initially not completed
      expect(routine.isCompletedToday, isFalse);

      // Mark completed today
      final completedToday = routine.copyWith(lastCompletedDate: todayStr);
      expect(completedToday.isCompletedToday, isTrue);

      // Completed yesterday - must automatically be uncompleted today
      final completedYesterday = routine.copyWith(lastCompletedDate: '2020-01-01');
      expect(completedYesterday.isCompletedToday, isFalse);

      // Clear completion
      final cleared = completedToday.copyWith(clearCompleted: true);
      expect(cleared.isCompletedToday, isFalse);
      expect(cleared.lastCompletedDate, isNull);
    });

    testWidgets('filters today routines by default and allows switching to all routines', (tester) async {
      final currentWeekday = DateTime.now().weekday;
      final otherWeekday = currentWeekday == 7 ? 1 : currentWeekday + 1;

      final todayRoutine = RoutineItem(
        id: 'today_r',
        name: 'Today Only Routine',
        hour: 8,
        minute: 0,
        days: {currentWeekday},
        createdAt: DateTime(2026, 1, 1),
      );
      final otherDayRoutine = RoutineItem(
        id: 'other_r',
        name: 'Other Day Routine',
        hour: 9,
        minute: 0,
        days: {otherWeekday},
        createdAt: DateTime(2026, 1, 2),
      );

      final encoded = encodeRoutines([todayRoutine, otherDayRoutine]);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('campus_flow.widget_sync'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'loadRoutines') {
            return encoded;
          }
          if (methodCall.method == 'saveRoutines') {
            return null;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: RoutinesPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify "Today" filter pill is selected by default
      expect(find.text('Today Only Routine'), findsOneWidget);
      expect(find.text('Other Day Routine'), findsNothing);

      // Switch to "All Routines"
      await tester.tap(find.text('All Routines'));
      await tester.pumpAndSettle();

      // Both should now be visible
      expect(find.text('Today Only Routine'), findsOneWidget);
      expect(find.text('Other Day Routine'), findsOneWidget);

      // Switch back to "Today"
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      expect(find.text('Today Only Routine'), findsOneWidget);
      expect(find.text('Other Day Routine'), findsNothing);

      // Tap checkbox to mark completed
      final checkbox = find.byType(Checkbox).first;
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      expect(find.text('1/1 completed'), findsOneWidget);
    });
  });
}

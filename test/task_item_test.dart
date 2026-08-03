import 'package:campus_flow/features/tasks/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('task comparator orders by priority then creation time', () {
    final tasks = [
      TaskItem(
        id: '1',
        title: 'Low',
        priority: TaskPriority.low,
        createdAt: DateTime(2026, 1, 1, 10),
      ),
      TaskItem(
        id: '2',
        title: 'High',
        priority: TaskPriority.high,
        createdAt: DateTime(2026, 1, 1, 11),
      ),
      TaskItem(
        id: '3',
        title: 'Medium',
        priority: TaskPriority.medium,
        createdAt: DateTime(2026, 1, 1, 9),
      ),
    ];

    tasks.sort(compareTaskItems);

    expect(tasks.map((task) => task.title), ['High', 'Medium', 'Low']);
  });
}
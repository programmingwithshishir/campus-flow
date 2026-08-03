import 'package:flutter/material.dart';

import '../data/task_storage.dart';
import '../models/task_item.dart';

class TaskManagerPage extends StatefulWidget {
  const TaskManagerPage({super.key});

  @override
  State<TaskManagerPage> createState() => _TaskManagerPageState();
}

class _TaskManagerPageState extends State<TaskManagerPage> with WidgetsBindingObserver {
  final List<TaskItem> _tasks = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    TaskStorage.setTaskUpdateListener(_loadTasks);
    _loadTasks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTasks();
    }
  }

  Future<void> _loadTasks() async {
    final tasks = await TaskStorage.loadTasks();
    if (!mounted) {
      return;
    }

    setState(() {
      _tasks
        ..clear()
        ..addAll(tasks)
        ..sort(compareTaskItems);
      sortTaskItems(_tasks);
    });
  }

  void _addTask(TaskItem task) {
    setState(() {
      _tasks.add(task);
      sortTaskItems(_tasks);
    });
    TaskStorage.saveTasks(_tasks);
  }

  void _toggleTaskCompletion(String id, bool? isCompleted) {
    setState(() {
      final taskIndex = _tasks.indexWhere((task) => task.id == id);
      if (taskIndex == -1) {
        return;
      }

      _tasks[taskIndex] = _tasks[taskIndex].copyWith(isCompleted: isCompleted ?? false);
      sortTaskItems(_tasks);
    });
    TaskStorage.saveTasks(_tasks);
  }

  void _changePriority(String id, TaskPriority newPriority) {
    setState(() {
      final taskIndex = _tasks.indexWhere((task) => task.id == id);
      if (taskIndex == -1) {
        return;
      }

      _tasks[taskIndex] = _tasks[taskIndex].copyWith(priority: newPriority);
      sortTaskItems(_tasks);
    });
    TaskStorage.saveTasks(_tasks);
  }

  void _deleteTask(String id) {
    setState(() {
      _tasks.removeWhere((task) => task.id == id);
    });
    TaskStorage.saveTasks(_tasks);
  }

  Future<void> _showAddTaskDialog() async {
    final task = await showDialog<TaskItem>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => const _AddTaskDialog(),
    );

    if (task != null) {
      _addTask(task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final titleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final counterBgColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final counterTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final taskActiveTextColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final taskCompletedTextColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final checkboxBorderColor = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Campus Flow',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: titleColor,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: counterBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_tasks.length} tasks',
              style: TextStyle(
                color: counterTextColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _tasks.isEmpty
                ? Center(
                    child: Text(
                      'No tasks available',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: taskCompletedTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cardBorderColor),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? const Color(0x33000000) : const Color(0x08000000),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                Container(
                                  width: 5,
                                  decoration: BoxDecoration(
                                    color: task.priority.color,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                  ),
                                ),
                                Checkbox(
                                  value: task.isCompleted,
                                  activeColor: const Color(0xFF2563EB),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  side: BorderSide(
                                    color: checkboxBorderColor,
                                    width: 1.5,
                                  ),
                                  onChanged: (value) => _toggleTaskCompletion(task.id, value),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Text(
                                      task.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: task.isCompleted
                                            ? taskCompletedTextColor
                                            : taskActiveTextColor,
                                        decoration: task.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                                PopupMenuButton<TaskPriority>(
                                  tooltip: 'Change Priority',
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    Icons.flag_rounded,
                                    size: 18,
                                    color: task.priority.color,
                                  ),
                                  color: cardBgColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: cardBorderColor),
                                  ),
                                  onSelected: (newPriority) => _changePriority(task.id, newPriority),
                                  itemBuilder: (context) => TaskPriority.values
                                      .map(
                                        (priority) => PopupMenuItem<TaskPriority>(
                                          value: priority,
                                          child: Row(
                                            children: [
                                              Icon(Icons.flag_rounded, size: 16, color: priority.color),
                                              const SizedBox(width: 8),
                                              Text(
                                                priority.label,
                                                style: TextStyle(
                                                  color: priority.color,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                                if (task.isCompleted)
                                  IconButton(
                                    iconSize: 18,
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _deleteTask(task.id),
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: taskCompletedTextColor,
                                    ),
                                    tooltip: 'Delete task',
                                  )
                                else
                                  const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        backgroundColor: isDark ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _AddTaskDialog extends StatefulWidget {
  const _AddTaskDialog();

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final TextEditingController _titleController = TextEditingController();
  TaskPriority _selectedPriority = TaskPriority.medium;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      TaskItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        priority: _selectedPriority,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dialogBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dialogTitleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final inputFillColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final inputTextColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return AlertDialog(
      backgroundColor: dialogBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Add Task',
        style: TextStyle(fontWeight: FontWeight.w700, color: dialogTitleColor),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            style: TextStyle(color: inputTextColor),
            decoration: InputDecoration(
              hintText: 'Enter task title...',
              hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              filled: true,
              fillColor: inputFillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TaskPriority>(
            initialValue: _selectedPriority,
            dropdownColor: dialogBgColor,
            style: TextStyle(color: inputTextColor),
            decoration: InputDecoration(
              labelText: 'Priority',
              labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              filled: true,
              fillColor: inputFillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            items: TaskPriority.values
                .map(
                  (priority) => DropdownMenuItem(
                    value: priority,
                    child: Row(
                      children: [
                        Icon(Icons.flag_rounded, size: 16, color: priority.color),
                        const SizedBox(width: 8),
                        Text(
                          priority.label,
                          style: TextStyle(color: priority.color, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _selectedPriority = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _submit,
          child: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

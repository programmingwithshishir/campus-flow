import 'package:flutter/material.dart';

import '../models/routine_item.dart';

class RoutineDialog extends StatefulWidget {
  const RoutineDialog({
    super.key,
    this.initialRoutine,
  });

  final RoutineItem? initialRoutine;

  @override
  State<RoutineDialog> createState() => _RoutineDialogState();
}

class _RoutineDialogState extends State<RoutineDialog> {
  late final TextEditingController _nameController;
  late TimeOfDay _selectedTime;
  late Set<int> _selectedDays;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialRoutine?.name ?? '');
    _selectedTime = widget.initialRoutine?.timeOfDay ??
        const TimeOfDay(hour: 8, minute: 0);
    _selectedDays = widget.initialRoutine != null
        ? Set<int>.from(widget.initialRoutine!.days)
        : {1, 2, 3, 4, 5}; // Default Monday to Friday
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
      _errorMessage = null;
    });
  }

  void _selectAllDays() {
    setState(() {
      _selectedDays = {1, 2, 3, 4, 5, 6, 7};
      _errorMessage = null;
    });
  }

  void _selectWeekdays() {
    setState(() {
      _selectedDays = {1, 2, 3, 4, 5};
      _errorMessage = null;
    });
  }

  void _selectWeekends() {
    setState(() {
      _selectedDays = {6, 7};
      _errorMessage = null;
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a routine name';
      });
      return;
    }

    if (_selectedDays.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one day for the reminder';
      });
      return;
    }

    final routine = RoutineItem(
      id: widget.initialRoutine?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
      days: _selectedDays,
      isEnabled: widget.initialRoutine?.isEnabled ?? true,
      createdAt: widget.initialRoutine?.createdAt ?? DateTime.now(),
    );

    Navigator.of(context).pop(routine);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final inputFill = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final primaryColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);

    final isEdit = widget.initialRoutine != null;

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.alarm_rounded, color: primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit Routine' : 'Add Routine',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    color: subtitleColor,
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Routine Name
                      Text(
                        'Routine Name',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        autofocus: !isEdit,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'e.g. Morning Workout, Math Practice...',
                          hintStyle: TextStyle(
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: inputFill,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryColor, width: 1.5),
                          ),
                        ),
                        onChanged: (_) {
                          if (_errorMessage != null) {
                            setState(() => _errorMessage = null);
                          }
                        },
                      ),
                      const SizedBox(height: 18),

                      // Reminder Time Picker
                      Text(
                        'Reminder Time',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: inputFill,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time_rounded, color: primaryColor, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                _formatTime(_selectedTime),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Change Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right_rounded, size: 18, color: primaryColor),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Day checkboxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Days of Week',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: subtitleColor,
                            ),
                          ),
                          Wrap(
                            spacing: 4,
                            children: [
                              _QuickDayFilterChip(
                                label: 'All',
                                onTap: _selectAllDays,
                                isDark: isDark,
                              ),
                              _QuickDayFilterChip(
                                label: 'Weekdays',
                                onTap: _selectWeekdays,
                                isDark: isDark,
                              ),
                              _QuickDayFilterChip(
                                label: 'Weekends',
                                onTap: _selectWeekends,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Checkbox for each day of the week
                      Container(
                        decoration: BoxDecoration(
                          color: inputFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            for (int day = 1; day <= 7; day++) ...[
                              InkWell(
                                onTap: () => _toggleDay(day),
                                borderRadius: BorderRadius.vertical(
                                  top: day == 1 ? const Radius.circular(12) : Radius.zero,
                                  bottom: day == 7 ? const Radius.circular(12) : Radius.zero,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _selectedDays.contains(day),
                                          activeColor: primaryColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          onChanged: (_) => _toggleDay(day),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        RoutineItem.dayFullNames[day] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: _selectedDays.contains(day)
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: textColor,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        RoutineItem.dayShortNames[day] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _selectedDays.contains(day)
                                              ? primaryColor
                                              : subtitleColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (day < 7)
                                Divider(height: 1, thickness: 1, color: borderColor.withValues(alpha: 0.5)),
                            ],
                          ],
                        ),
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: subtitleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _submit,
                      child: Text(
                        isEdit ? 'Save Changes' : 'Add Routine',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickDayFilterChip extends StatelessWidget {
  const _QuickDayFilterChip({
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

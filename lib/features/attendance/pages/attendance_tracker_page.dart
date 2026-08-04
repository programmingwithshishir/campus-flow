import 'dart:async';
import 'package:flutter/material.dart';

import '../data/attendance_storage.dart';
import '../models/absence_record.dart';
import 'subject_detail_sheet.dart';

class AttendanceTrackerPage extends StatefulWidget {
  const AttendanceTrackerPage({super.key});

  @override
  State<AttendanceTrackerPage> createState() => _AttendanceTrackerPageState();
}

class _AttendanceTrackerPageState extends State<AttendanceTrackerPage> {
  final List<String> _subjects = [];
  final List<AbsenceRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    final data = await AttendanceStorage.loadAttendanceData();
    if (!mounted) {
      return;
    }

    setState(() {
      _subjects
        ..clear()
        ..addAll(data.subjects);
      _records
        ..clear()
        ..addAll(data.records);
    });
  }

  void _saveData() {
    AttendanceStorage.saveAttendanceData(
      AttendanceData(subjects: _subjects, records: _records),
    );
  }

  void _addSubject(String name) {
    if (_subjects.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$name" is already added.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _subjects.add(name);
      _subjects.sort();
    });
    _saveData();
  }

  void _deleteSubject(String subjectName) {
    setState(() {
      _subjects.remove(subjectName);
      _records.removeWhere((r) => r.subjectName == subjectName);
    });
    _saveData();
  }

  void _deleteAllSubjects() {
    setState(() {
      _subjects.clear();
      _records.clear();
    });
    _saveData();
  }

  Future<void> _confirmDeleteSubject(String subjectName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DeleteWarningDialog(
        title: 'Are you sure you want to delete "$subjectName"?',
        message: 'This action will permanently remove this subject and all associated absence history logs.',
        countdownSeconds: 5,
      ),
    );

    if (confirmed == true) {
      _deleteSubject(subjectName);
    }
  }

  Future<void> _confirmDeleteAllSubjects() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const _DeleteWarningDialog(
        title: 'Are you sure you want to delete ALL subjects?',
        message: 'This action will permanently delete ALL subjects and clear all associated absence history logs. This action cannot be undone.',
        countdownSeconds: 5,
      ),
    );

    if (confirmed == true) {
      _deleteAllSubjects();
    }
  }

  void _addAbsenceRecords(List<AbsenceRecord> newRecords) {
    setState(() {
      _records.addAll(newRecords);
    });
    _saveData();
  }

  void _deleteAbsenceRecord(String id) {
    setState(() {
      _records.removeWhere((r) => r.id == id);
    });
    _saveData();
  }

  Future<void> _showAddSubjectDialog() async {
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => const _AddSubjectDialog(),
    );

    if (name != null && name.isNotEmpty) {
      _addSubject(name);
    }
  }

  Future<void> _showMarkAbsentDialog() async {
    if (_subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a subject first using the + button at top right.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newRecords = await showDialog<List<AbsenceRecord>>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _MarkAbsentDialog(availableSubjects: _subjects),
    );

    if (newRecords != null && newRecords.isNotEmpty) {
      _addAbsenceRecords(newRecords);
    }
  }

  void _openSubjectDetails(String subjectName) {
    final subjectRecords = _records.where((r) => r.subjectName == subjectName).toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollController) => SubjectDetailSheet(
          subjectName: subjectName,
          records: subjectRecords,
          onDeleteRecord: _deleteAbsenceRecord,
        ),
      ),
    );
  }

  double get _totalHoursMissedAll {
    return _records.fold(0.0, (sum, r) => sum + r.hours);
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
    final primaryTextColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final totalMissedAll = _totalHoursMissedAll;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Attendance Tracker',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: titleColor,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          if (_subjects.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: counterBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${formatHours(totalMissedAll)} Missed',
                style: TextStyle(
                  color: counterTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              color: const Color(0xFFEF4444),
              tooltip: 'Delete All Subjects',
              onPressed: _confirmDeleteAllSubjects,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.add_rounded),
            color: titleColor,
            tooltip: 'Add Subject',
            onPressed: _showAddSubjectDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _subjects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined, size: 48, color: secondaryTextColor),
                        const SizedBox(height: 12),
                        Text(
                          'No subjects added yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap + in the top right to add your subjects',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 96),
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) {
                      final subject = _subjects[index];
                      final subjectRecords = _records.where((r) => r.subjectName == subject).toList();
                      final totalHours = subjectRecords.fold(0.0, (sum, r) => sum + r.hours);
                      final validCount = subjectRecords.where((r) => r.isValid).fold(0.0, (sum, r) => sum + r.hours);
                      final invalidCount = subjectRecords.where((r) => !r.isValid).fold(0.0, (sum, r) => sum + r.hours);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => _openSubjectDetails(subject),
                          borderRadius: BorderRadius.circular(12),
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
                                      color: invalidCount > 0
                                          ? const Color(0xFFEF4444)
                                          : (totalHours > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            subject,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: primaryTextColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                '${formatHours(totalHours)} Missed',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: totalHours == 0
                                                      ? const Color(0xFF10B981)
                                                      : (invalidCount > 0 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '(${formatHoursShort(validCount)} Valid · ${formatHoursShort(invalidCount)} Invalid)',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: secondaryTextColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    iconSize: 20,
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Delete Subject',
                                    onPressed: () => _confirmDeleteSubject(subject),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                              ),
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
        onPressed: _showMarkAbsentDialog,
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.event_busy_rounded),
        label: const Text('Mark Absent', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _DeleteWarningDialog extends StatefulWidget {
  const _DeleteWarningDialog({
    required this.title,
    required this.message,
    this.countdownSeconds = 5,
  });

  final String title;
  final String message;
  final int countdownSeconds;

  @override
  State<_DeleteWarningDialog> createState() => _DeleteWarningDialogState();
}

class _DeleteWarningDialogState extends State<_DeleteWarningDialog> {
  late int _secondsRemaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.countdownSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dialogBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dialogTitleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final canDelete = _secondsRemaining == 0;

    return AlertDialog(
      backgroundColor: dialogBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Warning',
              style: TextStyle(fontWeight: FontWeight.w800, color: dialogTitleColor),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: dialogTitleColor),
          ),
          const SizedBox(height: 8),
          Text(
            widget.message,
            style: TextStyle(fontSize: 13, color: secondaryTextColor),
          ),
          const SizedBox(height: 16),
          if (!canDelete)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Please wait ${_secondsRemaining}s before confirming...',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: TextStyle(color: secondaryTextColor)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: canDelete ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: canDelete ? () => Navigator.of(context).pop(true) : null,
          child: Text(
            canDelete ? 'Confirm Delete' : 'Delete (${_secondsRemaining}s)',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _AddSubjectDialog extends StatefulWidget {
  const _AddSubjectDialog();

  @override
  State<_AddSubjectDialog> createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends State<_AddSubjectDialog> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dialogBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dialogTitleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final inputFillColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final inputTextColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return AlertDialog(
      backgroundColor: dialogBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Add Subject',
        style: TextStyle(fontWeight: FontWeight.w700, color: dialogTitleColor),
      ),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        style: TextStyle(color: inputTextColor),
        decoration: InputDecoration(
          hintText: 'Subject Name (e.g. Data Structures)',
          hintStyle: TextStyle(color: secondaryTextColor),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: secondaryTextColor)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _submit,
          child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _MarkAbsentDialog extends StatefulWidget {
  const _MarkAbsentDialog({required this.availableSubjects});

  final List<String> availableSubjects;

  @override
  State<_MarkAbsentDialog> createState() => _MarkAbsentDialogState();
}

class _MarkAbsentDialogState extends State<_MarkAbsentDialog> {
  final TextEditingController _reasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isValidAbsence = true;
  final Map<String, double> _subjectHours = {};
  String? _reasonError;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() {
    setState(() {
      _reasonError = null;
    });

    final reason = _reasonController.text.trim();

    if (_subjectHours.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one subject.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isValidAbsence && reason.isEmpty) {
      setState(() {
        _reasonError = 'Reason is required for a valid absence.';
      });
      return;
    }

    final finalReason = reason.isEmpty ? 'Unexcused absence' : reason;

    final records = _subjectHours.entries.map((entry) {
      final subject = entry.key;
      final hours = entry.value;
      return AbsenceRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString() + subject.hashCode.toString(),
        subjectName: subject,
        date: _selectedDate,
        reason: finalReason,
        isValid: _isValidAbsence,
        hours: hours,
      );
    }).toList();

    Navigator.of(context).pop(records);
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dialogBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dialogTitleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final inputFillColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final inputTextColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return AlertDialog(
      backgroundColor: dialogBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Mark Absent',
        style: TextStyle(fontWeight: FontWeight.w700, color: dialogTitleColor),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Picker Field
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: inputFillColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date of Absence', style: TextStyle(fontSize: 11, color: secondaryTextColor)),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(_selectedDate),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: inputTextColor),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.edit_calendar_rounded, size: 18, color: secondaryTextColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Select Subjects Header
            Text(
              'Select Subject(s)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondaryTextColor),
            ),
            const SizedBox(height: 6),

            // Multi-Select FilterChips of Available Added Subjects
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.availableSubjects.map((subject) {
                final isSelected = _subjectHours.containsKey(subject);
                return FilterChip(
                  label: Text(subject),
                  selected: isSelected,
                  selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.2),
                  checkmarkColor: const Color(0xFF2563EB),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  backgroundColor: inputFillColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                    ),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _subjectHours[subject] = 1.0;
                      } else {
                        _subjectHours.remove(subject);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            // Per-Subject Hours Stepper Section (0.5 hour increments)
            if (_subjectHours.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Hours Missed per Subject',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondaryTextColor),
              ),
              const SizedBox(height: 6),
              ..._subjectHours.keys.map((subject) {
                final hours = _subjectHours[subject] ?? 1.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: inputFillColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          subject,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: inputTextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded),
                            iconSize: 18,
                            visualDensity: VisualDensity.compact,
                            color: secondaryTextColor,
                            onPressed: hours > 0.5
                                ? () => setState(() {
                                      _subjectHours[subject] = hours - 0.5;
                                    })
                                : null,
                          ),
                          Text(
                            formatHoursShort(hours),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: inputTextColor),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            iconSize: 18,
                            visualDensity: VisualDensity.compact,
                            color: const Color(0xFF2563EB),
                            onPressed: () => setState(() {
                              _subjectHours[subject] = hours + 0.5;
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 14),

            // Absence Reason Type Header
            Text(
              'Absence Reason Type',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondaryTextColor),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Valid')),
                    selected: _isValidAbsence,
                    selectedColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: _isValidAbsence ? const Color(0xFF10B981) : secondaryTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _isValidAbsence = true;
                          _reasonError = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Invalid')),
                    selected: !_isValidAbsence,
                    selectedColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: !_isValidAbsence ? const Color(0xFFEF4444) : secondaryTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _isValidAbsence = false;
                          _reasonError = null;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Reason Input
            TextField(
              controller: _reasonController,
              style: TextStyle(color: inputTextColor),
              onChanged: (_) {
                if (_reasonError != null) {
                  setState(() => _reasonError = null);
                }
              },
              decoration: InputDecoration(
                hintText: _isValidAbsence ? 'Reason (Required)' : 'Reason (Optional)',
                hintStyle: TextStyle(color: secondaryTextColor),
                labelText: _isValidAbsence ? 'Reason for Absence *' : 'Reason for Absence',
                labelStyle: TextStyle(color: _reasonError != null ? const Color(0xFFEF4444) : secondaryTextColor),
                errorText: _reasonError,
                filled: true,
                fillColor: inputFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: secondaryTextColor)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _submit,
          child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

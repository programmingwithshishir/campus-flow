import 'package:flutter/material.dart';

import '../data/routine_storage.dart';
import '../models/routine_item.dart';
import '../services/notification_service.dart';
import 'routine_dialog.dart';

class RoutinesPage extends StatefulWidget {
  const RoutinesPage({super.key});

  @override
  State<RoutinesPage> createState() => _RoutinesPageState();
}

class _RoutinesPageState extends State<RoutinesPage> with WidgetsBindingObserver {
  final List<RoutineItem> _routines = [];
  bool _isLoading = true;
  bool _showTodayOnly = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    RoutineStorage.setRoutineUpdateListener(_loadRoutines);
    _initAndLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadRoutines();
    }
  }

  Future<void> _initAndLoad() async {
    try {
      await NotificationService.instance.initialize();
    } catch (_) {}
    await _loadRoutines();
    await NotificationService.instance.rescheduleAllRoutines(_routines);
  }

  Future<void> _loadRoutines() async {
    try {
      final routines = await RoutineStorage.loadRoutines();
      if (!mounted) return;

      setState(() {
        _routines
          ..clear()
          ..addAll(routines);
        _sortRoutines();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addRoutine(RoutineItem routine) async {
    await NotificationService.instance.requestPermissions();
    setState(() {
      _routines.add(routine);
      _sortRoutines();
    });
    await RoutineStorage.saveRoutines(_routines);
    await NotificationService.instance.scheduleRoutine(routine);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Routine "${routine.name}" scheduled!'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateRoutine(RoutineItem updatedRoutine) async {
    final index = _routines.indexWhere((r) => r.id == updatedRoutine.id);
    if (index == -1) return;

    setState(() {
      _routines[index] = updatedRoutine;
      _sortRoutines();
    });
    await RoutineStorage.saveRoutines(_routines);
    await NotificationService.instance.scheduleRoutine(updatedRoutine);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Routine "${updatedRoutine.name}" updated!'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleRoutine(RoutineItem routine, bool isEnabled) async {
    final updated = routine.copyWith(isEnabled: isEnabled);
    await _updateRoutine(updated);
  }

  Future<void> _toggleRoutineCompletion(RoutineItem routine, bool isCompleted) async {
    final updated = routine.copyWith(
      lastCompletedDate: isCompleted ? RoutineItem.todayDateString : null,
      clearCompleted: !isCompleted,
    );
    final index = _routines.indexWhere((r) => r.id == updated.id);
    if (index == -1) return;

    setState(() {
      _routines[index] = updated;
      _sortRoutines();
    });
    await RoutineStorage.saveRoutines(_routines);
  }

  Future<void> _deleteRoutine(RoutineItem routine) async {
    final deletedIndex = _routines.indexWhere((r) => r.id == routine.id);
    if (deletedIndex == -1) return;

    setState(() {
      _routines.removeAt(deletedIndex);
    });
    await RoutineStorage.saveRoutines(_routines);
    await NotificationService.instance.cancelRoutineNotifications(routine);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Routine "${routine.name}" deleted'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              setState(() {
                _routines.insert(deletedIndex, routine);
                _sortRoutines();
              });
              await RoutineStorage.saveRoutines(_routines);
              await NotificationService.instance.scheduleRoutine(routine);
            },
          ),
        ),
      );
    }
  }

  void _sortRoutines() {
    _routines.sort((a, b) {
      final aMinutes = (a.hour * 60) + a.minute;
      final bMinutes = (b.hour * 60) + b.minute;
      if (aMinutes != bMinutes) {
        return aMinutes.compareTo(bMinutes);
      }
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  Future<void> _showAddRoutineDialog() async {
    await NotificationService.instance.requestPermissions();
    if (!mounted) return;

    final routine = await showDialog<RoutineItem>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const RoutineDialog(),
    );

    if (routine != null) {
      await _addRoutine(routine);
    }
  }

  Future<void> _showEditRoutineDialog(RoutineItem routine) async {
    final updated = await showDialog<RoutineItem>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => RoutineDialog(initialRoutine: routine),
    );

    if (updated != null) {
      await _updateRoutine(updated);
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
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);

    final activeCount = _routines.where((r) => r.isEnabled).length;
    final todayRoutines = _routines.where((r) => r.isScheduledForToday).toList();
    final todayCompletedCount = todayRoutines.where((r) => r.isCompletedToday).length;
    final displayedRoutines = _showTodayOnly ? todayRoutines : _routines;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Routines',
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
              _showTodayOnly
                  ? '$todayCompletedCount/${todayRoutines.length} completed'
                  : '$activeCount active / ${_routines.length} total',
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // Filter toggle bar
                      if (_routines.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Row(
                            children: [
                              _FilterPill(
                                label: 'Today',
                                count: todayRoutines.length,
                                isSelected: _showTodayOnly,
                                onTap: () {
                                  if (!_showTodayOnly) {
                                    setState(() => _showTodayOnly = true);
                                  }
                                },
                                isDark: isDark,
                                primaryColor: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              _FilterPill(
                                label: 'All Routines',
                                count: _routines.length,
                                isSelected: !_showTodayOnly,
                                onTap: () {
                                  if (_showTodayOnly) {
                                    setState(() => _showTodayOnly = false);
                                  }
                                },
                                isDark: isDark,
                                primaryColor: primaryColor,
                              ),
                            ],
                          ),
                        ),

                      // List / Empty State
                      Expanded(
                        child: _routines.isEmpty
                            ? _buildEmptyState(theme, textSecondary, primaryColor, isDark)
                            : displayedRoutines.isEmpty
                                ? _buildNoTodayRoutinesState(theme, textSecondary, primaryColor, isDark)
                                : ListView.builder(
                                    padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 96),
                                    itemCount: displayedRoutines.length,
                                    itemBuilder: (context, index) {
                                      final routine = displayedRoutines[index];
                                      return _buildRoutineCard(
                                        routine: routine,
                                        cardBgColor: cardBgColor,
                                        cardBorderColor: cardBorderColor,
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                        primaryColor: primaryColor,
                                        isDark: isDark,
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRoutineDialog,
        backgroundColor: isDark ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Routine', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    Color textSecondary,
    Color primaryColor,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.alarm_add_rounded,
                size: 56,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No routines yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create daily or weekly routines with automatic priority notifications to stay on track.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _showAddRoutineDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Your First Routine',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTodayRoutinesState(
    ThemeData theme,
    Color textSecondary,
    Color primaryColor,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_available_rounded,
                size: 56,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No routines for today',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have no routines scheduled for today. Enjoy your day or explore all your routines.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => setState(() => _showTodayOnly = false),
              icon: const Icon(Icons.list_alt_rounded, size: 18),
              label: const Text('View All Routines', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineCard({
    required RoutineItem routine,
    required Color cardBgColor,
    required Color cardBorderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryColor,
    required bool isDark,
  }) {
    final statusColor = !routine.isEnabled
        ? (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))
        : (routine.isCompletedToday ? const Color(0xFF10B981) : primaryColor);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: isDark ? const Color(0x33000000) : const Color(0x08000000),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left status stripe
                Container(
                  width: 5,
                  color: statusColor,
                ),

                // Main card content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Row 1: Checkbox + Routine Name + Edit + Delete + Switch
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: routine.isCompletedToday,
                                activeColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                onChanged: (value) {
                                  if (value != null) {
                                    _toggleRoutineCompletion(routine, value);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                routine.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: (!routine.isEnabled || routine.isCompletedToday)
                                      ? textSecondary
                                      : textPrimary,
                                  decoration: (routine.isCompletedToday || !routine.isEnabled)
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            IconButton(
                              iconSize: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Edit routine',
                              icon: Icon(Icons.edit_outlined, color: textSecondary),
                              onPressed: () => _showEditRoutineDialog(routine),
                            ),
                            IconButton(
                              iconSize: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Delete routine',
                              icon: Icon(Icons.delete_outline_rounded, color: textSecondary),
                              onPressed: () => _deleteRoutine(routine),
                            ),
                            const SizedBox(width: 4),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch.adaptive(
                                value: routine.isEnabled,
                                activeTrackColor: primaryColor,
                                onChanged: (value) => _toggleRoutine(routine, value),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        // Row 2: Time + Day Badges + Summary
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_filled_rounded,
                              size: 13,
                              color: routine.isEnabled ? primaryColor : textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              routine.timeString,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: routine.isEnabled ? textPrimary : textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('•', style: TextStyle(color: textSecondary)),
                            const SizedBox(width: 8),
                            for (int day = 1; day <= 7; day++) ...[
                              _DayBadge(
                                day: day,
                                isSelected: routine.days.contains(day),
                                isEnabled: routine.isEnabled,
                                primaryColor: primaryColor,
                                isDark: isDark,
                              ),
                              if (day < 7) const SizedBox(width: 3),
                            ],
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                routine.daysSummary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.primaryColor,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final activeBg = primaryColor.withValues(alpha: isDark ? 0.25 : 0.12);
    final activeBorder = primaryColor;
    final activeText = isDark ? const Color(0xFF60A5FA) : primaryColor;

    final inactiveBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inactiveBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final inactiveText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? activeBorder : inactiveBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeText : inactiveText,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withValues(alpha: isDark ? 0.35 : 0.2)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? activeText : inactiveText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayBadge extends StatelessWidget {
  const _DayBadge({
    required this.day,
    required this.isSelected,
    required this.isEnabled,
    required this.primaryColor,
    required this.isDark,
  });

  final int day;
  final bool isSelected;
  final bool isEnabled;
  final Color primaryColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final activeBg = isEnabled ? primaryColor : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8));
    final inactiveBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final inactiveText = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);

    final dayLetter = RoutineItem.dayShortNames[day]?.substring(0, 1) ?? '';

    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? activeBg : inactiveBg,
        shape: BoxShape.circle,
        border: isSelected
            ? null
            : Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1,
              ),
      ),
      child: Text(
        dayLetter,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : inactiveText,
        ),
      ),
    );
  }
}

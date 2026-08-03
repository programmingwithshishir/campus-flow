import 'package:flutter/material.dart';

import '../models/absence_record.dart';

enum AbsenceFilter { all, validOnly, invalidOnly }

class SubjectDetailSheet extends StatefulWidget {
  const SubjectDetailSheet({
    super.key,
    required this.subjectName,
    required this.records,
    required this.onDeleteRecord,
  });

  final String subjectName;
  final List<AbsenceRecord> records;
  final Function(String id) onDeleteRecord;

  @override
  State<SubjectDetailSheet> createState() => _SubjectDetailSheetState();
}

class _SubjectDetailSheetState extends State<SubjectDetailSheet> {
  AbsenceFilter _filter = AbsenceFilter.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sheetBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryTextColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final filterBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    final validHours = widget.records.where((r) => r.isValid).fold(0.0, (sum, r) => sum + r.hours);
    final invalidHours = widget.records.where((r) => !r.isValid).fold(0.0, (sum, r) => sum + r.hours);
    final totalHours = validHours + invalidHours;

    // Filter records based on selected filter option
    final filteredRecords = widget.records.where((r) {
      if (_filter == AbsenceFilter.validOnly) {
        return r.isValid;
      }
      if (_filter == AbsenceFilter.invalidOnly) {
        return !r.isValid;
      }
      return true;
    }).toList();

    // Sort strictly by date descending (recent dates on top irrespective of valid/invalid status)
    filteredRecords.sort((a, b) => b.date.compareTo(a.date));

    return Container(
      decoration: BoxDecoration(
        color: sheetBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject Title & Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.subjectName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatHours(totalHours)} missed (${formatHours(validHours)} Valid · ${formatHours(invalidHours)} Invalid)',
                        style: TextStyle(fontSize: 13, color: secondaryTextColor, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: secondaryTextColor,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Filter Bar (All / Valid Only / Invalid Only)
            Row(
              children: [
                Icon(Icons.filter_list_rounded, size: 16, color: secondaryTextColor),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All (${widget.records.length})', AbsenceFilter.all, filterBgColor, primaryTextColor, secondaryTextColor),
                        const SizedBox(width: 6),
                        _buildFilterChip('Valid Only', AbsenceFilter.validOnly, filterBgColor, const Color(0xFF10B981), secondaryTextColor),
                        const SizedBox(width: 6),
                        _buildFilterChip('Invalid Only', AbsenceFilter.invalidOnly, filterBgColor, const Color(0xFFEF4444), secondaryTextColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Absence Log List (Recent dates on top)
            if (filteredRecords.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    _filter == AbsenceFilter.all
                        ? 'No absence entries for this subject'
                        : 'No ${_filter == AbsenceFilter.validOnly ? 'valid' : 'invalid'} absences logged',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredRecords.length,
                  itemBuilder: (context, index) {
                    final record = filteredRecords[index];
                    return _buildRecordTile(
                      context,
                      record: record,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    AbsenceFilter value,
    Color bgColor,
    Color activeColor,
    Color inactiveTextColor,
  ) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: activeColor.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? activeColor : inactiveTextColor,
      ),
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? activeColor : Colors.transparent,
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filter = value;
          });
        }
      },
    );
  }

  Widget _buildRecordTile(
    BuildContext context, {
    required AbsenceRecord record,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final dateStr = _formatDate(record.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: record.isValid
            ? const Color(0xFF10B981).withValues(alpha: 0.06)
            : const Color(0xFFEF4444).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: record.isValid
                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                : const Color(0xFFEF4444).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            record.isValid ? Icons.verified_rounded : Icons.cancel_outlined,
            size: 18,
            color: record.isValid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        ),
        title: Text(
          '$dateStr (${formatHoursShort(record.hours)})',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: primaryTextColor,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            'Reason: ${record.reason}',
            style: TextStyle(
              fontSize: 12,
              color: secondaryTextColor,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: record.isValid
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                record.isValid ? 'Valid' : 'Invalid',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: record.isValid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
              onPressed: () {
                widget.onDeleteRecord(record.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekdayStr = weekdays[date.weekday - 1];
    final monthStr = months[date.month - 1];
    return '$weekdayStr, $monthStr ${date.day}, ${date.year}';
  }
}

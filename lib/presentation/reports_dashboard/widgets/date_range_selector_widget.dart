import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Date Range Selector Widget
/// Provides preset date ranges and custom date picker
class DateRangeSelectorWidget extends StatelessWidget {
  final DateTimeRange selectedDateRange;
  final String selectedPreset;
  final Function(DateTimeRange, String) onDateRangeChanged;

  const DateRangeSelectorWidget({
    super.key,
    required this.selectedDateRange,
    required this.selectedPreset,
    required this.onDateRangeChanged,
  });

  void _selectPreset(BuildContext context, String preset) {
    final now = DateTime.now();
    DateTimeRange range;

    switch (preset) {
      case 'Hoy':
        range = DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: now,
        );
        break;
      case 'Semana':
        range = DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
        break;
      case 'Mes':
        range = DateTimeRange(
          start: DateTime(now.year, now.month - 1, now.day),
          end: now,
        );
        break;
      default:
        return;
    }

    onDateRangeChanged(range, preset);
  }

  Future<void> _selectCustomRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: theme.colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateRangeChanged(picked, 'Personalizado');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPresetChip(context, 'Hoy'),
              SizedBox(width: 2.w),
              _buildPresetChip(context, 'Semana'),
              SizedBox(width: 2.w),
              _buildPresetChip(context, 'Mes'),
              SizedBox(width: 2.w),
              _buildCustomButton(context),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            '${dateFormat.format(selectedDateRange.start)} - ${dateFormat.format(selectedDateRange.end)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(BuildContext context, String label) {
    final theme = Theme.of(context);
    final isSelected = selectedPreset == label;

    return GestureDetector(
      onTap: () => _selectPreset(context, label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomButton(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = selectedPreset == 'Personalizado';

    return GestureDetector(
      onTap: () => _selectCustomRange(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: 'calendar_today',
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              size: 16,
            ),
            SizedBox(width: 1.w),
            Text(
              'Personalizado',
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

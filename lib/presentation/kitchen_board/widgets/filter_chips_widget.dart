import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';


/// Filter Chips Widget - Provides order type and time range filtering
/// Displays horizontal scrolling filter chips
class FilterChipsWidget extends StatelessWidget {
  final String selectedOrderType;
  final String selectedTimeRange;
  final Function(String) onOrderTypeChanged;
  final Function(String) onTimeRangeChanged;

  const FilterChipsWidget({
    super.key,
    required this.selectedOrderType,
    required this.selectedTimeRange,
    required this.onOrderTypeChanged,
    required this.onTimeRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order type filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  'Todos',
                  selectedOrderType == 'Todos',
                  () {
                    HapticFeedback.selectionClick();
                    onOrderTypeChanged('Todos');
                  },
                ),
                SizedBox(width: 2.w),
                _buildFilterChip(
                  context,
                  'En Mesa',
                  selectedOrderType == 'Dine-in',
                  () {
                    HapticFeedback.selectionClick();
                    onOrderTypeChanged('Dine-in');
                  },
                ),
                SizedBox(width: 2.w),
                _buildFilterChip(
                  context,
                  'Para Llevar',
                  selectedOrderType == 'Takeaway',
                  () {
                    HapticFeedback.selectionClick();
                    onOrderTypeChanged('Takeaway');
                  },
                ),
                SizedBox(width: 2.w),
                _buildFilterChip(
                  context,
                  'Domicilio',
                  selectedOrderType == 'Delivery',
                  () {
                    HapticFeedback.selectionClick();
                    onOrderTypeChanged('Delivery');
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 1.5.h),

          // Time range filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  'Hoy',
                  selectedTimeRange == 'Hoy',
                  () {
                    HapticFeedback.selectionClick();
                    onTimeRangeChanged('Hoy');
                  },
                ),
                SizedBox(width: 2.w),
                _buildFilterChip(
                  context,
                  'Última Hora',
                  selectedTimeRange == 'Última Hora',
                  () {
                    HapticFeedback.selectionClick();
                    onTimeRangeChanged('Última Hora');
                  },
                ),
                SizedBox(width: 2.w),
                _buildFilterChip(
                  context,
                  'Últimos 30 min',
                  selectedTimeRange == 'Últimos 30 min',
                  () {
                    HapticFeedback.selectionClick();
                    onTimeRangeChanged('Últimos 30 min');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';
import './order_card_widget.dart';

/// Status Column Widget - Displays orders grouped by status
/// Provides vertical scrolling list of order cards
class StatusColumnWidget extends StatelessWidget {
  final String title;
  final Color statusColor;
  final List<Map<String, dynamic>> orders;
  final Function(Map<String, dynamic>) onOrderTap;
  final Function(Map<String, dynamic>) onOrderLongPress;

  const StatusColumnWidget({
    super.key,
    required this.title,
    required this.statusColor,
    required this.orders,
    required this.onOrderTap,
    required this.onOrderLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 85.w,
      margin: EdgeInsets.symmetric(horizontal: 2.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            margin: EdgeInsets.only(bottom: 2.h),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        fontSize: 15.sp,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${orders.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Orders list
          Expanded(
            child: orders.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    padding: EdgeInsets.only(bottom: 2.h),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      return OrderCardWidget(
                        order: orders[index],
                        onAdvance: () => onOrderTap(orders[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'check_circle_outline',
            size: 48,
            color: statusColor.withValues(alpha: 0.3),
          ),
          SizedBox(height: 2.h),
          Text(
            'Sin pedidos',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
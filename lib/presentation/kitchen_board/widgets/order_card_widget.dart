import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../widgets/custom_icon_widget.dart';

class OrderCardWidget extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onAdvance;

  const OrderCardWidget({
    super.key,
    required this.order,
    required this.onAdvance,
  });

  String _getTimeSinceOrder() {
    final createdAt = DateTime.parse(order['created_at'] as String);
    final difference = DateTime.now().difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Hace menos de 1 min';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else {
      return 'Hace ${difference.inHours}h ${difference.inMinutes % 60}min';
    }
  }

  bool _isUrgent() {
    final createdAt = DateTime.parse(order['created_at'] as String);
    final difference = DateTime.now().difference(createdAt);
    return difference.inMinutes > 15;
  }

  String _getOrderType() {
    if (order['table_number'] != null &&
        (order['table_number'] as String).isNotEmpty) {
      return 'Dine-in';
    }
    return 'Takeaway';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUrgent = _isUrgent();
    final orderItems = order['order_items'] as List<dynamic>? ?? [];
    final orderType = _getOrderType();
    final tableNumber = order['table_number'] as String? ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent
              ? Colors.red
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: isUrgent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with order number and type
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${order['order_number']}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: orderType == 'Dine-in'
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  orderType == 'Dine-in' && tableNumber.isNotEmpty
                      ? tableNumber
                      : orderType,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: orderType == 'Dine-in' ? Colors.blue : Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isUrgent)
                Container(
                  padding: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: 'warning',
                    size: 20,
                    color: Colors.red,
                  ),
                ),
              Text(
                _getTimeSinceOrder(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color:
                      isUrgent ? Colors.red : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isUrgent ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Order items
          ...orderItems.map((item) {
            return Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${item['quantity']}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['product_name'] ?? 'Producto',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item['notes'] != null &&
                            (item['notes'] as String).isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 0.5.h),
                            child: Text(
                              item['notes'],
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          // Special notes if any
          if (order['notes'] != null &&
              (order['notes'] as String).isNotEmpty) ...[
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info',
                    size: 20,
                    color: Colors.orange,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      order['notes'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 2.h),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAdvance,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'restaurant',
                    size: 20,
                    color: Colors.white,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Iniciar Preparación',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


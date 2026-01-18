import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CustomerCardWidget extends StatelessWidget {
  final Map<String, dynamic> customer;
  final VoidCallback onTap;
  final Function(String) onQuickAction;

  const CustomerCardWidget({
    super.key,
    required this.customer,
    required this.onTap,
    required this.onQuickAction,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Slidable(
        key: ValueKey(customer["id"]),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) {
                HapticFeedback.lightImpact();
                onQuickAction('points');
              },
              backgroundColor: theme.brightness == Brightness.light
                  ? const Color(0xFF059669)
                  : const Color(0xFF10B981),
              foregroundColor: Colors.white,
              icon: Icons.add_circle_outline,
              label: 'Puntos',
              borderRadius: BorderRadius.circular(12),
            ),
            SlidableAction(
              onPressed: (_) {
                HapticFeedback.lightImpact();
                onQuickAction('order');
              },
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              icon: Icons.shopping_cart_outlined,
              label: 'Pedido',
              borderRadius: BorderRadius.circular(12),
            ),
            SlidableAction(
              onPressed: (_) {
                HapticFeedback.lightImpact();
                onQuickAction('edit');
              },
              backgroundColor: theme.brightness == Brightness.light
                  ? const Color(0xFF64748B)
                  : const Color(0xFF94A3B8),
              foregroundColor: Colors.white,
              icon: Icons.edit_outlined,
              label: 'Editar',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: Card(
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomImageWidget(
                      imageUrl: customer["avatar"] as String,
                      width: 15.w,
                      height: 15.w,
                      fit: BoxFit.cover,
                      semanticLabel: customer["semanticLabel"] as String,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer["name"] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'phone',
                              color: theme.brightness == Brightness.light
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                              size: 14,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              customer["phone"] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.brightness == Brightness.light
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'access_time',
                              color: theme.brightness == Brightness.light
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                              size: 14,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              'Última visita: ${_formatDate(customer["lastVisit"] as DateTime)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.brightness == Brightness.light
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomIconWidget(
                              iconName: 'stars',
                              color: theme.colorScheme.primary,
                              size: 16,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              '${customer["points"]}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '${customer["totalOrders"]} pedidos',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.brightness == Brightness.light
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

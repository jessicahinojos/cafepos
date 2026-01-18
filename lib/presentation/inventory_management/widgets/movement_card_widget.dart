import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Movement Card Widget
/// Displays individual inventory movement transaction
class MovementCardWidget extends StatelessWidget {
  final Map<String, dynamic> movement;
  final VoidCallback onTap;

  const MovementCardWidget({
    super.key,
    required this.movement,
    required this.onTap,
  });

  Color _getMovementTypeColor(String type, ThemeData theme) {
    switch (type) {
      case 'IN':
        return theme.brightness == Brightness.light
            ? Color(0xFF059669)
            : Color(0xFF10B981);
      case 'OUT':
        return theme.brightness == Brightness.light
            ? Color(0xFFDC2626)
            : Color(0xFFEF4444);
      case 'ADJUSTMENT':
        return theme.brightness == Brightness.light
            ? Color(0xFFD97706)
            : Color(0xFFF59E0B);
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _getMovementTypeText(String type) {
    switch (type) {
      case 'IN':
        return 'Entrada';
      case 'OUT':
        return 'Salida';
      case 'ADJUSTMENT':
        return 'Ajuste';
      default:
        return 'Desconocido';
    }
  }

  IconData _getMovementTypeIcon(String type) {
    switch (type) {
      case 'IN':
        return Icons.arrow_downward;
      case 'OUT':
        return Icons.arrow_upward;
      case 'ADJUSTMENT':
        return Icons.sync;
      default:
        return Icons.help;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = _getMovementTypeColor(movement["type"], theme);
    final quantity = movement["quantity"] as double;
    final isNegative = quantity < 0;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getMovementTypeIcon(movement["type"]),
                  color: typeColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement["supplyName"],
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      _getMovementTypeText(movement["type"]),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: typeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Por: ${movement["user"]}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    movement["note"] != null && movement["note"].isNotEmpty
                        ? Padding(
                            padding: EdgeInsets.only(top: 0.5.h),
                            child: Text(
                              movement["note"],
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : SizedBox.shrink(),
                  ],
                ),
              ),
              SizedBox(width: 3.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isNegative ? '' : '+'}${quantity.toStringAsFixed(1)} ${movement["unit"]}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: typeColor,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _formatDateTime(movement["timestamp"]),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

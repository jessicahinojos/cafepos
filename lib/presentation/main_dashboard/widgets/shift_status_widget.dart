import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ShiftStatusWidget extends StatelessWidget {
  final bool isActive;
  final DateTime startTime;

  const ShiftStatusWidget({
    super.key,
    required this.isActive,
    required this.startTime,
  });

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = DateTime.now().difference(startTime);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 2.w,
            height: 2.w,
            decoration: BoxDecoration(
              color: isActive
                  ? (theme.brightness == Brightness.light
                        ? const Color(0xFF059669)
                        : const Color(0xFF10B981))
                  : (theme.brightness == Brightness.light
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8)),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 2.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isActive ? 'Turno Activo' : 'Turno Cerrado',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isActive)
                Text(
                  _formatDuration(duration),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                    fontSize: 9.sp,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

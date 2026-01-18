import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class SyncStatusWidget extends StatelessWidget {
  final bool isOffline;
  final DateTime lastSyncTime;

  const SyncStatusWidget({
    super.key,
    required this.isOffline,
    required this.lastSyncTime,
  });

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else {
      return 'Hace ${difference.inDays}d';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: isOffline
            ? (theme.brightness == Brightness.light
                  ? const Color(0xFFD97706).withValues(alpha: 0.12)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.12))
            : (theme.brightness == Brightness.light
                  ? const Color(0xFF059669).withValues(alpha: 0.12)
                  : const Color(0xFF10B981).withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: isOffline ? 'cloud_off' : 'cloud_done',
            color: isOffline
                ? (theme.brightness == Brightness.light
                      ? const Color(0xFFD97706)
                      : const Color(0xFFF59E0B))
                : (theme.brightness == Brightness.light
                      ? const Color(0xFF059669)
                      : const Color(0xFF10B981)),
            size: 4.w,
          ),
          SizedBox(width: 1.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isOffline ? 'Sin conexión' : 'Sincronizado',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isOffline
                      ? (theme.brightness == Brightness.light
                            ? const Color(0xFFD97706)
                            : const Color(0xFFF59E0B))
                      : (theme.brightness == Brightness.light
                            ? const Color(0xFF059669)
                            : const Color(0xFF10B981)),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isOffline)
                Text(
                  _getTimeAgo(lastSyncTime),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

/// Account Section Widget - Displays current user profile and logout option
class AccountSectionWidget extends StatelessWidget {
  final Map<String, dynamic> currentUser;
  final VoidCallback onLogout;

  const AccountSectionWidget({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Safely parse lastLogin from database (can be String or DateTime)
    DateTime? lastLoginDate;
    try {
      final lastLoginValue = currentUser["lastLogin"];
      if (lastLoginValue is String) {
        lastLoginDate = DateTime.parse(lastLoginValue);
      } else if (lastLoginValue is DateTime) {
        lastLoginDate = lastLoginValue;
      }
    } catch (e) {
      // If parsing fails, use current time as fallback
      lastLoginDate = DateTime.now();
    }

    final timeAgo = _getTimeAgo(lastLoginDate ?? DateTime.now());

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cuenta',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Container(
                  width: 16.w,
                  height: 16.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: CustomImageWidget(
                      imageUrl: currentUser["avatar"] ?? "",
                      width: 16.w,
                      height: 16.w,
                      fit: BoxFit.cover,
                      semanticLabel:
                          currentUser["semanticLabel"] ?? "User avatar",
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser["name"] ?? "Usuario",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        currentUser["email"] ?? "",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              currentUser["role"] ?? "usuario",
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          CustomIconWidget(
                            iconName: 'access_time',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 12,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            timeAgo,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            const Divider(),
            SizedBox(height: 1.h),
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onLogout();
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'logout',
                      color: theme.colorScheme.error,
                      size: 24,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      'Cerrar Sesión',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return 'hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'hace ${difference.inHours} h';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    }
  }
}

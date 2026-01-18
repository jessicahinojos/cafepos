import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Business Settings Widget - Restaurant configuration for admin users
class BusinessSettingsWidget extends StatelessWidget {
  final Map<String, dynamic> businessSettings;
  final VoidCallback onEditReceipt;
  final VoidCallback onEditBusiness;

  const BusinessSettingsWidget({
    super.key,
    required this.businessSettings,
    required this.onEditReceipt,
    required this.onEditBusiness,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuración del Negocio',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            _buildSettingItem(
              context: context,
              icon: 'store',
              title: 'Información del Restaurante',
              subtitle: businessSettings["restaurantName"],
              onTap: () {
                HapticFeedback.lightImpact();
                onEditBusiness();
              },
            ),
            const Divider(),
            _buildSettingItem(
              context: context,
              icon: 'receipt_long',
              title: 'Personalizar Recibo',
              subtitle: 'Logo, pie de página y formato',
              onTap: () {
                HapticFeedback.lightImpact();
                onEditReceipt();
              },
            ),
            const Divider(),
            _buildSettingItem(
              context: context,
              icon: 'calculate',
              title: 'Tasa de IVA',
              subtitle: '${businessSettings["taxRate"]}%',
              onTap: () {
                HapticFeedback.lightImpact();
                onEditBusiness();
              },
            ),
            const Divider(),
            _buildSettingItem(
              context: context,
              icon: 'loyalty',
              title: 'Programa de Fidelidad',
              subtitle:
                  '${businessSettings["loyaltyPointsRate"]} puntos por boliviano',
              onTap: () {
                HapticFeedback.lightImpact();
                onEditBusiness();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: icon,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

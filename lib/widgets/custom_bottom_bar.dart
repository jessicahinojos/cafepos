import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom Bottom Navigation Bar for Restaurant POS Application
/// Implements thumb-reachable primary actions with haptic feedback
/// Supports role-based navigation with 48dp minimum touch targets
class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            // Haptic feedback for navigation actions
            HapticFeedback.lightImpact();
            onTap(index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: theme.brightness == Brightness.light
              ? const Color(0xFF475569)
              : const Color(0xFFCBD5E1),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
            height: 1.33,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            letterSpacing: 0.4,
            height: 1.33,
          ),
          items: [
            // Sales/POS - Primary revenue generation
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.point_of_sale_outlined, size: 24),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.point_of_sale, size: 24),
              ),
              label: 'Ventas',
              tooltip: 'Sales Screen - Process orders and payments',
            ),

            // Kitchen Board - Real-time order management
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.restaurant_menu_outlined, size: 24),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.restaurant_menu, size: 24),
              ),
              label: 'Cocina',
              tooltip: 'Kitchen Board - Manage kitchen orders',
            ),

            // Cash Register - Session and transaction tracking
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.help_outline, size: 24),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.help_outline, size: 24),
              ),
              label: 'Caja',
              tooltip: 'Cash Register - Manage cash sessions',
            ),

            // Reports Dashboard - Business insights
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.analytics_outlined, size: 24),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.analytics, size: 24),
              ),
              label: 'Reportes',
              tooltip: 'Reports Dashboard - View business analytics',
            ),

            // More - Contextual access to additional features
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.more_horiz_outlined, size: 24),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.more_horiz, size: 24),
              ),
              label: 'Más',
              tooltip: 'More Options - Access additional features',
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension to provide custom icons for cash register
/// Uses Material Icons with fallback to alternative icons
extension CustomIcons on Icons {
  static const IconData cash_register = Icons.app_registration;
  static const IconData cash_register_outlined =
      Icons.app_registration_outlined;
}

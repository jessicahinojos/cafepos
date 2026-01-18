import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import './widgets/quick_action_card_widget.dart';
import './widgets/shift_status_widget.dart';
import './widgets/sync_status_widget.dart';
import './widgets/dashboard_metrics_widget.dart';

class MainDashboardInitialPage extends StatefulWidget {
  const MainDashboardInitialPage({super.key});

  @override
  State<MainDashboardInitialPage> createState() =>
      _MainDashboardInitialPageState();
}

class _MainDashboardInitialPageState extends State<MainDashboardInitialPage> {
  bool _isRefreshing = false;
  bool _isOffline = false;
  final String _currentUserRole = 'Cajero';
  final String _currentUserName = 'María González';
  DateTime _lastSyncTime = DateTime.now();

  // Mock quick actions based on role
  final List<Map<String, dynamic>> _quickActions = [
    {
      "id": 1,
      "title": "Nueva Orden",
      "description": "Crear pedido nuevo",
      "icon": "add_shopping_cart",
      "route": "/sales-screen",
      "color": 0xFF2563EB,
      "roles": ["Cajero", "Mesero", "Administrador"],
    },
    {
      "id": 2,
      "title": "Gestión de Mesas",
      "description": "Ver estado de mesas",
      "icon": "table_restaurant",
      "route": "/sales-screen",
      "color": 0xFF059669,
      "roles": ["Mesero", "Administrador"],
    },
    {
      "id": 3,
      "title": "Buscar Cliente",
      "description": "Consultar información",
      "icon": "person_search",
      "route": "/customer-management",
      "color": 0xFF7C3AED,
      "roles": ["Cajero", "Mesero", "Administrador"],
    },
    {
      "id": 4,
      "title": "Cola de Pedidos",
      "description": "Ver pedidos pendientes",
      "icon": "restaurant_menu",
      "route": "/kitchen-board",
      "color": 0xFFD97706,
      "roles": ["Cocina", "Administrador"],
    },
    {
      "id": 5,
      "title": "Verificar Inventario",
      "description": "Consultar existencias",
      "icon": "inventory_2",
      "route": "/inventory-management",
      "color": 0xFF0891B2,
      "roles": ["Cocina", "Administrador"],
    },
    {
      "id": 6,
      "title": "Guía de Recetas",
      "description": "Ver preparaciones",
      "icon": "menu_book",
      "route": "/product-management",
      "color": 0xFFDC2626,
      "roles": ["Cocina", "Administrador"],
    },
    {
      "id": 7,
      "title": "Resumen Diario",
      "description": "Ver ventas del día",
      "icon": "analytics",
      "route": "/reports-dashboard",
      "color": 0xFF2563EB,
      "roles": ["Administrador"],
    },
    {
      "id": 8,
      "title": "Gestión de Personal",
      "description": "Administrar usuarios",
      "icon": "people",
      "route": "/settings-screen",
      "color": 0xFF059669,
      "roles": ["Administrador"],
    },
    {
      "id": 9,
      "title": "Configuración",
      "description": "Ajustes del sistema",
      "icon": "settings",
      "route": "/settings-screen",
      "color": 0xFF64748B,
      "roles": ["Administrador"],
    },
  ];

  List<Map<String, dynamic>> get _filteredActions {
    return _quickActions.where((action) {
      final roles = action["roles"] as List<String>;
      return roles.contains(_currentUserRole);
    }).toList();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);

    // Simulate sync with Supabase
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isRefreshing = false;
      _lastSyncTime = DateTime.now();
      _isOffline = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Datos sincronizados correctamente'),
          backgroundColor: Theme.of(context).brightness == Brightness.light
              ? const Color(0xFF059669)
              : const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Custom App Bar with greeting and status
          SliverAppBar(
            expandedHeight: 20.h,
            floating: false,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '¡Hola, $_currentUserName!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Rol: $_currentUserRole',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary.withValues(
                              alpha: 0.9,
                            ),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Row(
                          children: [
                            Expanded(
                              child: ShiftStatusWidget(
                                isActive: true,
                                startTime: DateTime.now().subtract(
                                  const Duration(hours: 3),
                                ),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            SyncStatusWidget(
                              isOffline: _isOffline,
                              lastSyncTime: _lastSyncTime,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Quick Actions Grid
          SliverPadding(
            padding: EdgeInsets.all(4.w),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acciones Rápidas',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  _isRefreshing
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.h),
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 3.w,
                                mainAxisSpacing: 2.h,
                                childAspectRatio: 1.1,
                              ),
                          itemCount: _filteredActions.length,
                          itemBuilder: (context, index) {
                            final action = _filteredActions[index];
                            return QuickActionCardWidget(
                              title: action["title"],
                              description: action["description"],
                              iconName: action["icon"],
                              color: Color(action["color"]),
                              onTap: () {
                                Navigator.pushNamed(context, action["route"]);
                              },
                            );
                          },
                        ),
                  SizedBox(height: 3.h),
                  const DashboardMetricsWidget(),
                ],
              ),
            ),
          ),

          // Bottom spacing for safe area
          SliverPadding(padding: EdgeInsets.only(bottom: 2.h)),
        ],
      ),
    );
  }
}

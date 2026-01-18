import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/add_movement_dialog.dart';
import './widgets/alert_card_widget.dart';
import './widgets/movement_card_widget.dart';
import './widgets/supply_card_widget.dart';

/// Inventory Management Screen
/// Provides comprehensive supply tracking with movement recording and stock level monitoring
/// Implements tab-based layout with Supplies, Movements, and Alerts sections
class InventoryManagement extends StatefulWidget {
  const InventoryManagement({super.key});

  @override
  State<InventoryManagement> createState() => _InventoryManagementState();
}

class _InventoryManagementState extends State<InventoryManagement>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isRefreshing = false;

  // Mock data for supplies
  final List<Map<String, dynamic>> _supplies = [
    {
      "id": 1,
      "name": "Harina de Trigo",
      "currentStock": 25.5,
      "unit": "kg",
      "minStock": 10.0,
      "maxStock": 50.0,
      "status": "adequate",
      "lastUpdated": DateTime.now().subtract(Duration(hours: 2)),
      "supplier": "Distribuidora Central",
      "supplierPhone": "+591 2234 5678",
    },
    {
      "id": 2,
      "name": "Leche Entera",
      "currentStock": 8.2,
      "unit": "L",
      "minStock": 15.0,
      "maxStock": 40.0,
      "status": "low",
      "lastUpdated": DateTime.now().subtract(Duration(hours: 5)),
      "supplier": "Lácteos del Norte",
      "supplierPhone": "+591 2345 6789",
    },
    {
      "id": 3,
      "name": "Café en Grano",
      "currentStock": 2.1,
      "unit": "kg",
      "minStock": 5.0,
      "maxStock": 20.0,
      "status": "critical",
      "lastUpdated": DateTime.now().subtract(Duration(hours: 1)),
      "supplier": "Café Premium S.L.",
      "supplierPhone": "+591 2456 7890",
    },
    {
      "id": 4,
      "name": "Azúcar Blanco",
      "currentStock": 18.0,
      "unit": "kg",
      "minStock": 8.0,
      "maxStock": 30.0,
      "status": "adequate",
      "lastUpdated": DateTime.now().subtract(Duration(hours: 3)),
      "supplier": "Distribuidora Central",
      "supplierPhone": "+591 2234 5678",
    },
    {
      "id": 5,
      "name": "Aceite de Oliva",
      "currentStock": 12.5,
      "unit": "L",
      "minStock": 10.0,
      "maxStock": 25.0,
      "status": "adequate",
      "lastUpdated": DateTime.now().subtract(Duration(hours: 4)),
      "supplier": "Aceites Mediterráneos",
      "supplierPhone": "+591 2567 8901",
    },
    {
      "id": 6,
      "name": "Tomate Triturado",
      "currentStock": 6.8,
      "unit": "kg",
      "minStock": 12.0,
      "maxStock": 35.0,
      "status": "low",
      "lastUpdated": DateTime.now().subtract(Duration(hours: 6)),
      "supplier": "Conservas del Sur",
      "supplierPhone": "+591 2678 9012",
    },
  ];

  // Mock data for movements
  final List<Map<String, dynamic>> _movements = [
    {
      "id": 1,
      "supplyName": "Harina de Trigo",
      "type": "IN",
      "quantity": 20.0,
      "unit": "kg",
      "timestamp": DateTime.now().subtract(Duration(hours: 2)),
      "user": "María García",
      "note": "Compra semanal",
    },
    {
      "id": 2,
      "supplyName": "Café en Grano",
      "type": "OUT",
      "quantity": 1.5,
      "unit": "kg",
      "timestamp": DateTime.now().subtract(Duration(hours: 1)),
      "user": "Carlos Ruiz",
      "note": "Consumo diario",
    },
    {
      "id": 3,
      "supplyName": "Leche Entera",
      "type": "OUT",
      "quantity": 3.2,
      "unit": "L",
      "timestamp": DateTime.now().subtract(Duration(hours: 3)),
      "user": "Ana López",
      "note": "Preparación de postres",
    },
    {
      "id": 4,
      "supplyName": "Azúcar Blanco",
      "type": "ADJUSTMENT",
      "quantity": -2.0,
      "unit": "kg",
      "timestamp": DateTime.now().subtract(Duration(hours: 4)),
      "user": "María García",
      "note": "Corrección de inventario",
    },
    {
      "id": 5,
      "supplyName": "Aceite de Oliva",
      "type": "IN",
      "quantity": 5.0,
      "unit": "L",
      "timestamp": DateTime.now().subtract(Duration(hours: 5)),
      "user": "Carlos Ruiz",
      "note": "Reposición",
    },
  ];

  // Mock data for alerts
  List<Map<String, dynamic>> get _alerts {
    return _supplies
        .where(
          (supply) =>
              supply["status"] == "low" || supply["status"] == "critical",
        )
        .map(
          (supply) => {
            "id": supply["id"],
            "supplyName": supply["name"],
            "currentStock": supply["currentStock"],
            "minStock": supply["minStock"],
            "unit": supply["unit"],
            "status": supply["status"],
            "supplier": supply["supplier"],
            "supplierPhone": supply["supplierPhone"],
            "reorderSuggestion": (supply["maxStock"] as double) * 0.75,
          },
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(Duration(seconds: 1));
    setState(() => _isRefreshing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inventario sincronizado'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAddMovementDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AddMovementDialog(
        supplies: _supplies,
        onMovementAdded: (movement) {
          setState(() {
            _movements.insert(0, movement);
            // Update supply stock
            final supply = _supplies.firstWhere(
              (s) => s["name"] == movement["supplyName"],
            );
            final quantity = movement["quantity"] as double;
            if (movement["type"] == "IN") {
              supply["currentStock"] += quantity;
            } else if (movement["type"] == "OUT") {
              supply["currentStock"] -= quantity;
            } else if (movement["type"] == "ADJUSTMENT") {
              supply["currentStock"] += quantity;
            }
            // Update status
            if (supply["currentStock"] <= supply["minStock"] * 0.5) {
              supply["status"] = "critical";
            } else if (supply["currentStock"] <= supply["minStock"]) {
              supply["status"] = "low";
            } else {
              supply["status"] = "adequate";
            }
            supply["lastUpdated"] = DateTime.now();
          });
        },
      ),
    );
  }

  void _showSupplyDetails(Map<String, dynamic> supply) {
    HapticFeedback.lightImpact();
    final recentMovements = _movements
        .where((m) => m["supplyName"] == supply["name"])
        .take(5)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 10.w,
                          height: 0.5.h,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        supply["name"],
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                supply["status"],
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getStatusText(supply["status"]),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _getStatusColor(supply["status"]),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            '${supply["currentStock"]} ${supply["unit"]}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.all(4.w),
                    children: [
                      Text(
                        'Información del Suministro',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      _buildInfoRow(
                        'Stock Mínimo',
                        '${supply["minStock"]} ${supply["unit"]}',
                        theme,
                      ),
                      _buildInfoRow(
                        'Stock Máximo',
                        '${supply["maxStock"]} ${supply["unit"]}',
                        theme,
                      ),
                      _buildInfoRow('Proveedor', supply["supplier"], theme),
                      _buildInfoRow('Teléfono', supply["supplierPhone"], theme),
                      _buildInfoRow(
                        'Última Actualización',
                        _formatDateTime(supply["lastUpdated"]),
                        theme,
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'Movimientos Recientes',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      recentMovements.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 4.h),
                                child: Text(
                                  'No hay movimientos recientes',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: recentMovements
                                  .map(
                                    (movement) => MovementCardWidget(
                                      movement: movement,
                                      onTap: () {},
                                    ),
                                  )
                                  .toList(),
                            ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showSupplyActions(Map<String, dynamic> supply) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    Container(
                      width: 10.w,
                      height: 0.5.h,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      supply["name"],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'add_circle_outline',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: Text('Ajustar Stock'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddMovementDialog();
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'shopping_cart',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: Text('Registrar Compra'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddMovementDialog();
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'delete_outline',
                  color: theme.brightness == Brightness.light
                      ? Color(0xFFDC2626)
                      : Color(0xFFEF4444),
                  size: 24,
                ),
                title: Text('Marcar como Desperdicio'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddMovementDialog();
                },
              ),
              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }

  void _exportToCSV() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exportando inventario a CSV...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Color _getStatusColor(String status) {
    final theme = Theme.of(context);
    switch (status) {
      case 'adequate':
        return theme.brightness == Brightness.light
            ? Color(0xFF059669)
            : Color(0xFF10B981);
      case 'low':
        return theme.brightness == Brightness.light
            ? Color(0xFFD97706)
            : Color(0xFFF59E0B);
      case 'critical':
        return theme.brightness == Brightness.light
            ? Color(0xFFDC2626)
            : Color(0xFFEF4444);
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'adequate':
        return 'Adecuado';
      case 'low':
        return 'Bajo';
      case 'critical':
        return 'Crítico';
      default:
        return 'Desconocido';
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
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  List<Map<String, dynamic>> get _filteredSupplies {
    if (_searchQuery.isEmpty) return _supplies;
    return _supplies
        .where(
          (supply) =>
              supply["name"].toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestión de Inventario',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'file_download',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _exportToCSV,
            tooltip: 'Exportar CSV',
          ),
          SizedBox(width: 2.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(12.h),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _isSearching = value.isNotEmpty;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar suministros...',
                    prefixIcon: CustomIconWidget(
                      iconName: 'search',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    suffixIcon: _isSearching
                        ? IconButton(
                            icon: CustomIconWidget(
                              iconName: 'clear',
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _isSearching = false;
                              });
                            },
                          )
                        : IconButton(
                            icon: CustomIconWidget(
                              iconName: 'qr_code_scanner',
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Escáner de código de barras'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                    filled: true,
                    fillColor: theme.brightness == Brightness.light
                        ? Color(0xFFF8FAFC)
                        : Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.5.h,
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'Suministros'),
                  Tab(text: 'Movimientos'),
                  Tab(text: 'Alertas'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Supplies Tab
          RefreshIndicator(
            onRefresh: _handleRefresh,
            child: _filteredSupplies.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'inventory_2',
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                          size: 64,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'No se encontraron suministros',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: _filteredSupplies.length,
                    itemBuilder: (context, index) {
                      final supply = _filteredSupplies[index];
                      return SupplyCardWidget(
                        supply: supply,
                        onTap: () => _showSupplyDetails(supply),
                        onLongPress: () => _showSupplyActions(supply),
                      );
                    },
                  ),
          ),
          // Movements Tab
          RefreshIndicator(
            onRefresh: _handleRefresh,
            child: _movements.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'swap_horiz',
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                          size: 64,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'No hay movimientos registrados',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: _movements.length,
                    itemBuilder: (context, index) {
                      final movement = _movements[index];
                      return MovementCardWidget(
                        movement: movement,
                        onTap: () {},
                      );
                    },
                  ),
          ),
          // Alerts Tab
          RefreshIndicator(
            onRefresh: _handleRefresh,
            child: _alerts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'check_circle',
                          color: theme.brightness == Brightness.light
                              ? Color(0xFF059669)
                              : Color(0xFF10B981),
                          size: 64,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'No hay alertas de stock',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Todos los suministros están en niveles adecuados',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) {
                      final alert = _alerts[index];
                      return AlertCardWidget(
                        alert: alert,
                        onReorder: () {
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Contactando con ${alert["supplier"]}...',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMovementDialog,
        icon: CustomIconWidget(
          iconName: 'add',
          color: theme.colorScheme.onPrimary,
          size: 24,
        ),
        label: Text('Registrar Movimiento'),
      ),
    );
  }
}

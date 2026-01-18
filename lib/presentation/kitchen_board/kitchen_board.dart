import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/pos_service.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/filter_chips_widget.dart';
import './widgets/order_card_widget.dart';

/// Kitchen Board Screen - Real-time kitchen dashboard with order management
/// Displays pending orders with filters and real-time synchronization
class KitchenBoard extends StatefulWidget {
  const KitchenBoard({super.key});

  @override
  State<KitchenBoard> createState() => _KitchenBoardState();
}

class _KitchenBoardState extends State<KitchenBoard> {
  final _posService = PosService();
  RealtimeChannel? _ordersSubscription;

  String _selectedOrderType = 'Todos';
  String _selectedTimeRange = 'Hoy';
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  List<Map<String, dynamic>> _allOrders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _ordersSubscription?.unsubscribe();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    _ordersSubscription = _posService.subscribeToOrders(
      onInsert: (newOrder) {
        setState(() {
          _allOrders.insert(0, newOrder);
        });
        _showNotification('Nuevo pedido: #${newOrder['order_number']}');
      },
      onUpdate: (updatedOrder) {
        setState(() {
          final index = _allOrders.indexWhere(
            (o) => o['id'] == updatedOrder['id'],
          );
          if (index != -1) {
            _allOrders[index] = updatedOrder;
          }
        });
      },
      onDelete: (deletedOrder) {
        setState(() {
          _allOrders.removeWhere((o) => o['id'] == deletedOrder['id']);
        });
      },
    );
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final orders = await _posService.getOrdersWithItems(status: 'pending');

      if (mounted) {
        setState(() {
          _allOrders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    return _allOrders.where((order) {
      // Only show pending orders
      if (order['status'] != 'pending') return false;

      // Filter by order type (table_number indicates dine-in vs takeaway/delivery)
      bool matchesType = _selectedOrderType == 'Todos';
      if (!matchesType) {
        if (_selectedOrderType == 'Dine-in') {
          matchesType =
              order['table_number'] != null &&
              (order['table_number'] as String).isNotEmpty;
        } else if (_selectedOrderType == 'Takeaway') {
          matchesType =
              order['table_number'] == null ||
              (order['table_number'] as String).isEmpty;
        }
      }

      // Filter by time range
      bool matchesTime = true;
      if (_selectedTimeRange == 'Última Hora') {
        final createdAt = DateTime.parse(order['created_at'] as String);
        matchesTime = createdAt.isAfter(
          DateTime.now().subtract(Duration(hours: 1)),
        );
      } else if (_selectedTimeRange == 'Últimos 30 min') {
        final createdAt = DateTime.parse(order['created_at'] as String);
        matchesTime = createdAt.isAfter(
          DateTime.now().subtract(Duration(minutes: 30)),
        );
      }

      return matchesType && matchesTime;
    }).toList();
  }

  Future<void> _refreshOrders() async {
    setState(() => _isRefreshing = true);
    await _loadOrders();
    setState(() => _isRefreshing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedidos actualizados'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _advanceOrderStatus(Map<String, dynamic> order) async {
    HapticFeedback.mediumImpact();

    try {
      await _posService.updateOrderStatus(order['id'], 'preparing');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pedido #${order['order_number']} avanzado a Preparando',
            ),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar pedido: $e'),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showNotification(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.white),
              SizedBox(width: 2.w),
              Expanded(child: Text(message)),
            ],
          ),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            // Filter chips at top
            FilterChipsWidget(
              selectedOrderType: _selectedOrderType,
              selectedTimeRange: _selectedTimeRange,
              onOrderTypeChanged: (value) {
                setState(() => _selectedOrderType = value);
              },
              onTimeRangeChanged: (value) {
                setState(() => _selectedTimeRange = value);
              },
            ),

            // Pendiente section header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'schedule',
                    size: 24,
                    color: Colors.orange,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Pendiente',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.orange,
                      fontSize: 20.sp,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_filteredOrders.length}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Spacer(),
                  // Real-time indicator
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'En vivo',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Orders list
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'error_outline',
                            size: 64,
                            color: Colors.red.withValues(alpha: 0.5),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Error al cargar pedidos',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          ElevatedButton(
                            onPressed: _loadOrders,
                            child: Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : _filteredOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'check_circle_outline',
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.3),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'No hay pedidos pendientes',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshOrders,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.h,
                        ),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = _filteredOrders[index];
                          return OrderCardWidget(
                            order: order,
                            onAdvance: () => _advanceOrderStatus(order),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

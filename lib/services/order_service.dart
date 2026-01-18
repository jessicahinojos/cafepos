import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

/// Service for managing orders, order items, and payments
class OrderService {
  final _client = SupabaseService.client;

  // ============================================================================
  // ORDERS - Complete CRUD Operations
  // ============================================================================

  /// Generate a unique order number using database function
  Future<String> generateOrderNumber() async {
    try {
      final response = await _client.rpc('generate_order_number');
      return response as String;
    } catch (e) {
      final datePrefix = DateTime.now()
          .toString()
          .substring(0, 10)
          .replaceAll('-', '');
      final random = DateTime.now().millisecondsSinceEpoch % 10000;
      return '$datePrefix-${random.toString().padLeft(4, '0')}';
    }
  }

  /// Create a new order with items
  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    String? clientId,
    String? cashSessionId,
    String? tableNumber,
    double discount = 0,
    String? notes,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final subtotal = items.fold<double>(
        0,
        (sum, item) => sum + (item['unit_price'] * item['quantity']),
      );
      final tax = subtotal * 0.13;
      final total = subtotal + tax - discount;

      final orderNumber = await generateOrderNumber();

      final orderData = {
        'order_number': orderNumber,
        'user_id': userId,
        'client_id': clientId,
        'cash_session_id': cashSessionId,
        'table_number': tableNumber,
        'subtotal': subtotal,
        'tax': tax,
        'discount': discount,
        'total': total,
        'notes': notes,
        'status': 'pending',
      };

      final order = await _client
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      final orderItems = items
          .map(
            (item) => {
              'order_id': order['id'],
              'product_id': item['product_id'],
              'product_name': item['product_name'],
              'quantity': item['quantity'],
              'unit_price': item['unit_price'],
              'subtotal': item['unit_price'] * item['quantity'],
              'notes': item['notes'],
            },
          )
          .toList();

      await _client.from('order_items').insert(orderItems);

      return order;
    } catch (e) {
      throw Exception('Error al crear orden: $e');
    }
  }

  /// Retrieve orders with optional filtering
  Future<List<Map<String, dynamic>>> getOrders({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? clientId,
    String? cashSessionId,
  }) async {
    try {
      var query = _client
          .from('orders')
          .select('*, user_profiles(full_name), clients(name)');

      if (status != null) {
        query = query.eq('status', status);
      }

      if (clientId != null) {
        query = query.eq('client_id', clientId);
      }

      if (cashSessionId != null) {
        query = query.eq('cash_session_id', cashSessionId);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al cargar órdenes: $e');
    }
  }

  /// Get a single order with full details
  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      final order = await _client
          .from('orders')
          .select('*, user_profiles(full_name), clients(name, phone)')
          .eq('id', orderId)
          .single();

      final items = await _client
          .from('order_items')
          .select()
          .eq('order_id', orderId);

      final payments = await _client
          .from('payments')
          .select()
          .eq('order_id', orderId);

      return {...order, 'items': items, 'payments': payments};
    } catch (e) {
      throw Exception('Error al cargar detalles de orden: $e');
    }
  }

  /// Get orders with items for kitchen board
  Future<List<Map<String, dynamic>>> getOrdersWithItems({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client.from('orders').select('''
        *,
        order_items(*),
        user_profiles(full_name)
      ''');

      if (status != null) {
        query = query.eq('status', status);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al cargar órdenes con items: $e');
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final data = {'status': status};

      if (status == 'delivered') {
        data['completed_at'] = DateTime.now().toIso8601String();
      }

      await _client.from('orders').update(data).eq('id', orderId);
    } catch (e) {
      throw Exception('Error al actualizar estado de orden: $e');
    }
  }

  /// Update order information
  Future<void> updateOrder(String orderId, Map<String, dynamic> updates) async {
    try {
      await _client.from('orders').update(updates).eq('id', orderId);
    } catch (e) {
      throw Exception('Error al actualizar orden: $e');
    }
  }

  /// Cancel an order
  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      await _client
          .from('orders')
          .update({'status': 'cancelled', 'notes': reason})
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Error al cancelar orden: $e');
    }
  }

  /// Subscribe to real-time order changes
  RealtimeChannel subscribeToOrders({
    required Function(Map<String, dynamic>) onInsert,
    required Function(Map<String, dynamic>) onUpdate,
    required Function(Map<String, dynamic>) onDelete,
  }) {
    final channel = _client
        .channel('orders_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            onInsert(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            onDelete(payload.oldRecord);
          },
        )
        .subscribe();

    return channel;
  }

  // ============================================================================
  // ORDER ITEMS - Complete CRUD Operations
  // ============================================================================

  /// Get items for a specific order
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    try {
      final response = await _client
          .from('order_items')
          .select()
          .eq('order_id', orderId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al cargar items de orden: $e');
    }
  }

  /// Add an item to an existing order
  Future<Map<String, dynamic>> addOrderItem({
    required String orderId,
    required String productId,
    required String productName,
    required int quantity,
    required double unitPrice,
    String? notes,
  }) async {
    try {
      final subtotal = quantity * unitPrice;

      final data = {
        'order_id': orderId,
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'subtotal': subtotal,
        'notes': notes,
      };

      final item = await _client
          .from('order_items')
          .insert(data)
          .select()
          .single();

      // Update order total
      final order = await _client
          .from('orders')
          .select('subtotal, tax, discount')
          .eq('id', orderId)
          .single();

      final newSubtotal = (order['subtotal'] as num).toDouble() + subtotal;
      final tax = newSubtotal * 0.13;
      final discount = (order['discount'] as num).toDouble();
      final total = newSubtotal + tax - discount;

      await _client
          .from('orders')
          .update({'subtotal': newSubtotal, 'tax': tax, 'total': total})
          .eq('id', orderId);

      return item;
    } catch (e) {
      throw Exception('Error al agregar item a orden: $e');
    }
  }

  /// Update an order item
  Future<void> updateOrderItem(
    String itemId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _client.from('order_items').update(updates).eq('id', itemId);
    } catch (e) {
      throw Exception('Error al actualizar item de orden: $e');
    }
  }

  /// Remove an item from an order
  Future<void> removeOrderItem(String itemId) async {
    try {
      final item = await _client
          .from('order_items')
          .select('order_id, subtotal')
          .eq('id', itemId)
          .single();

      await _client.from('order_items').delete().eq('id', itemId);

      // Update order total
      final orderId = item['order_id'];
      final order = await _client
          .from('orders')
          .select('subtotal, tax, discount')
          .eq('id', orderId)
          .single();

      final itemSubtotal = (item['subtotal'] as num).toDouble();
      final newSubtotal = (order['subtotal'] as num).toDouble() - itemSubtotal;
      final tax = newSubtotal * 0.13;
      final discount = (order['discount'] as num).toDouble();
      final total = newSubtotal + tax - discount;

      await _client
          .from('orders')
          .update({'subtotal': newSubtotal, 'tax': tax, 'total': total})
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Error al eliminar item de orden: $e');
    }
  }

  // ============================================================================
  // PAYMENTS - Complete CRUD Operations
  // ============================================================================

  /// Create a payment for an order
  Future<Map<String, dynamic>> createPayment({
    required String orderId,
    required String method,
    required double amount,
    String? cashSessionId,
    String? referenceNumber,
    String? notes,
  }) async {
    try {
      final data = {
        'order_id': orderId,
        'cash_session_id': cashSessionId,
        'method': method,
        'amount': amount,
        'reference_number': referenceNumber,
        'notes': notes,
      };

      final payment = await _client
          .from('payments')
          .insert(data)
          .select()
          .single();

      // Mark order as delivered after payment
      await updateOrderStatus(orderId, 'delivered');

      return payment;
    } catch (e) {
      throw Exception('Error al registrar pago: $e');
    }
  }

  /// Get payments for a specific order
  Future<List<Map<String, dynamic>>> getPaymentsByOrder(String orderId) async {
    try {
      final response = await _client
          .from('payments')
          .select()
          .eq('order_id', orderId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al cargar pagos: $e');
    }
  }

  /// Get payments by cash session
  Future<List<Map<String, dynamic>>> getPaymentsByCashSession(
    String cashSessionId,
  ) async {
    try {
      final response = await _client
          .from('payments')
          .select('*, orders(order_number)')
          .eq('cash_session_id', cashSessionId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al cargar pagos por sesión: $e');
    }
  }

  /// Get payment summary by method for a date range
  Future<Map<String, dynamic>> getPaymentSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final payments = await _client
          .from('payments')
          .select()
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      final byMethod = <String, double>{};
      double total = 0;

      for (final payment in payments) {
        final method = payment['method'] as String;
        final amount = (payment['amount'] as num).toDouble();

        byMethod[method] = (byMethod[method] ?? 0) + amount;
        total += amount;
      }

      return {
        'total_amount': total,
        'payment_count': payments.length,
        'by_method': byMethod,
      };
    } catch (e) {
      throw Exception('Error al cargar resumen de pagos: $e');
    }
  }

  // ============================================================================
  // ORDER STATISTICS
  // ============================================================================

  /// Get order statistics for a date range
  Future<Map<String, dynamic>> getOrderStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final orders = await getOrders(startDate: startDate, endDate: endDate);

      final deliveredOrders = orders
          .where((o) => o['status'] == 'delivered')
          .toList();
      final cancelledOrders = orders
          .where((o) => o['status'] == 'cancelled')
          .toList();

      final totalSales = deliveredOrders.fold<double>(
        0,
        (sum, order) => sum + ((order['total'] as num).toDouble()),
      );

      final averageTicket = deliveredOrders.isNotEmpty
          ? totalSales / deliveredOrders.length
          : 0;

      return {
        'total_orders': orders.length,
        'delivered_orders': deliveredOrders.length,
        'cancelled_orders': cancelledOrders.length,
        'total_sales': totalSales,
        'average_ticket': averageTicket,
      };
    } catch (e) {
      throw Exception('Error al cargar estadísticas de órdenes: $e');
    }
  }

  /// Get hourly sales distribution
  Future<List<Map<String, dynamic>>> getHourlySales({
    required DateTime date,
  }) async {
    try {
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = startDate.add(const Duration(days: 1));

      final orders = await getOrders(
        startDate: startDate,
        endDate: endDate,
        status: 'delivered',
      );

      final hourlyData = <int, Map<String, dynamic>>{};

      for (final order in orders) {
        final createdAt = DateTime.parse(order['created_at']);
        final hour = createdAt.hour;

        if (!hourlyData.containsKey(hour)) {
          hourlyData[hour] = {'hour': hour, 'orders': 0, 'total': 0.0};
        }

        hourlyData[hour]!['orders'] = (hourlyData[hour]!['orders'] as int) + 1;
        hourlyData[hour]!['total'] =
            (hourlyData[hour]!['total'] as double) +
            ((order['total'] as num).toDouble());
      }

      return hourlyData.values.toList()
        ..sort((a, b) => a['hour'].compareTo(b['hour']));
    } catch (e) {
      throw Exception('Error al cargar ventas por hora: $e');
    }
  }
}

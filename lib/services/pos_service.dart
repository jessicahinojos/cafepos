import './supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PosService {
  final _client = SupabaseService.client;

  // ============================================================================
  // CATEGORIES
  // ============================================================================

  Future<List<Map<String, dynamic>>> getCategories({
    bool activeOnly = true,
  }) async {
    try {
      var query = _client.from('categories').select();

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('display_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al cargar categorías: $e');
    }
  }

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('categories')
          .insert(data)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Error al crear categoría: $e');
    }
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      await _client.from('categories').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar categoría: $e');
    }
  }

  // ============================================================================
  // PRODUCTS
  // ============================================================================

  Future<List<Map<String, dynamic>>> getProducts({
    String? categoryId,
    bool activeOnly = true,
  }) async {
    try {
      var query = _client.from('products').select('*, categories(name, color)');

      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al cargar productos: $e');
    }
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('products')
          .insert(data)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Error al crear producto: $e');
    }
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      await _client.from('products').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _client.from('products').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }

  // ============================================================================
  // INGREDIENTS
  // ============================================================================

  Future<List<Map<String, dynamic>>> getIngredients() async {
    try {
      final response = await _client
          .from('ingredients')
          .select()
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al cargar ingredientes: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getLowStockIngredients() async {
    try {
      final response = await _client
          .from('ingredients')
          .select()
          .lt('current_stock', 'min_stock')
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al cargar alertas de stock: $e');
    }
  }

  Future<void> updateIngredientStock(String id, double newStock) async {
    try {
      await _client
          .from('ingredients')
          .update({'current_stock': newStock})
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar stock: $e');
    }
  }

  // ============================================================================
  // ORDERS
  // ============================================================================

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

  Future<List<Map<String, dynamic>>> getOrders({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client
          .from('orders')
          .select('*, user_profiles(full_name), clients(name)');

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
      throw Exception('Error al cargar órdenes: $e');
    }
  }

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

  /// Get orders with items for kitchen board
  Future<List<Map<String, dynamic>>> getOrdersWithItems({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client.from('orders').select('''
            *,
            order_items(*)
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
  // PAYMENTS
  // ============================================================================

  Future<void> createPayment({
    required String orderId,
    required String method,
    required double amount,
    String? cashSessionId,
    String? referenceNumber,
    String? notes,
  }) async {
    try {
      await _client.from('payments').insert({
        'order_id': orderId,
        'cash_session_id': cashSessionId,
        'method': method,
        'amount': amount,
        'reference_number': referenceNumber,
        'notes': notes,
      });

      await updateOrderStatus(orderId, 'delivered');
    } catch (e) {
      throw Exception('Error al registrar pago: $e');
    }
  }

  // ============================================================================
  // CASH SESSIONS
  // ============================================================================

  Future<Map<String, dynamic>?> getActiveCashSession() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('cash_sessions')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Error al cargar sesión de caja: $e');
    }
  }

  Future<Map<String, dynamic>> openCashSession(double openingAmount) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final response = await _client
          .from('cash_sessions')
          .insert({
            'user_id': userId,
            'opening_amount': openingAmount,
            'is_active': true,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Error al abrir caja: $e');
    }
  }

  Future<void> closeCashSession({
    required String sessionId,
    required double closingAmount,
    String? notes,
  }) async {
    try {
      final session = await _client
          .from('cash_sessions')
          .select('opening_amount, total_sales')
          .eq('id', sessionId)
          .single();

      final expectedAmount =
          (session['opening_amount'] as num).toDouble() +
          (session['total_sales'] as num).toDouble();
      final difference = closingAmount - expectedAmount;

      await _client
          .from('cash_sessions')
          .update({
            'closing_amount': closingAmount,
            'expected_amount': expectedAmount,
            'difference': difference,
            'closed_at': DateTime.now().toIso8601String(),
            'is_active': false,
            'notes': notes,
          })
          .eq('id', sessionId);
    } catch (e) {
      throw Exception('Error al cerrar caja: $e');
    }
  }

  // ============================================================================
  // CLIENTS
  // ============================================================================

  Future<List<Map<String, dynamic>>> getClients({String? searchQuery}) async {
    try {
      var query = _client.from('clients').select();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'name.ilike.%$searchQuery%,phone.ilike.%$searchQuery%',
        );
      }

      final response = await query
          .eq('is_active', true)
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al cargar clientes: $e');
    }
  }

  Future<Map<String, dynamic>> createClient(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('clients')
          .insert(data)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Error al crear cliente: $e');
    }
  }

  Future<void> updateClient(String id, Map<String, dynamic> data) async {
    try {
      await _client.from('clients').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar cliente: $e');
    }
  }

  Future<void> addLoyaltyPoints(String clientId, int points) async {
    try {
      final client = await _client
          .from('clients')
          .select('loyalty_points')
          .eq('id', clientId)
          .single();

      final currentPoints = (client['loyalty_points'] as num).toInt();
      final newPoints = currentPoints + points;

      await _client
          .from('clients')
          .update({'loyalty_points': newPoints})
          .eq('id', clientId);
    } catch (e) {
      throw Exception('Error al agregar puntos: $e');
    }
  }

  // ============================================================================
  // REPORTS
  // ============================================================================

  Future<Map<String, dynamic>> getSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final orders = await _client
          .from('orders')
          .select('total, created_at')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .eq('status', 'delivered');

      final totalSales = orders.fold<double>(
        0,
        (sum, order) => sum + (order['total'] as num).toDouble(),
      );

      final orderCount = orders.length;
      final averageTicket = orderCount > 0 ? totalSales / orderCount : 0;

      return {
        'total_sales': totalSales,
        'order_count': orderCount,
        'average_ticket': averageTicket,
        'orders': orders,
      };
    } catch (e) {
      throw Exception('Error al generar reporte de ventas: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTopProducts({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    try {
      final items = await _client
          .from('order_items')
          .select(
            'product_id, product_name, quantity, subtotal, orders!inner(created_at, status)',
          )
          .gte('orders.created_at', startDate.toIso8601String())
          .lte('orders.created_at', endDate.toIso8601String())
          .eq('orders.status', 'delivered');

      final productMap = <String, Map<String, dynamic>>{};

      for (final item in items) {
        final productId = item['product_id'] as String;
        if (!productMap.containsKey(productId)) {
          productMap[productId] = {
            'product_name': item['product_name'],
            'total_quantity': 0,
            'total_sales': 0.0,
          };
        }

        productMap[productId]!['total_quantity'] += item['quantity'] as int;
        productMap[productId]!['total_sales'] += (item['subtotal'] as num)
            .toDouble();
      }

      final topProducts = productMap.entries.map((e) => e.value).toList()
        ..sort(
          (a, b) => (b['total_sales'] as double).compareTo(
            a['total_sales'] as double,
          ),
        );

      return topProducts.take(limit).toList();
    } catch (e) {
      throw Exception('Error al cargar productos más vendidos: $e');
    }
  }
}

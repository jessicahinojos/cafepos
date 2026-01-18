import './supabase_service.dart';

/// Service for managing customers and loyalty program
class CustomerService {
  final _client = SupabaseService.client;

  // ============================================================================
  // CUSTOMERS - Complete CRUD Operations
  // ============================================================================

  /// Retrieve all customers with optional filtering
  Future<List<Map<String, dynamic>>> getCustomers({
    bool activeOnly = true,
    String? searchQuery,
  }) async {
    try {
      var query = _client.from('clients').select();

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'name.ilike.%$searchQuery%,phone.ilike.%$searchQuery%,email.ilike.%$searchQuery%',
        );
      }

      final response = await query.order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al cargar clientes: $e');
    }
  }

  /// Get a single customer by ID
  Future<Map<String, dynamic>> getCustomerById(String id) async {
    try {
      final response = await _client
          .from('clients')
          .select()
          .eq('id', id)
          .single();
      return response;
    } catch (e) {
      throw Exception('Error al cargar cliente: $e');
    }
  }

  /// Get customer by phone number
  Future<Map<String, dynamic>?> getCustomerByPhone(String phone) async {
    try {
      final response = await _client
          .from('clients')
          .select()
          .eq('phone', phone)
          .eq('is_active', true)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Error al buscar cliente por teléfono: $e');
    }
  }

  /// Create a new customer
  Future<Map<String, dynamic>> createCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    int loyaltyPoints = 0,
    bool isActive = true,
  }) async {
    try {
      final data = {
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'loyalty_points': loyaltyPoints,
        'is_active': isActive,
        'total_purchases': 0,
      };

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

  /// Update an existing customer
  Future<void> updateCustomer(String id, Map<String, dynamic> updates) async {
    try {
      await _client.from('clients').update(updates).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar cliente: $e');
    }
  }

  /// Soft delete a customer
  Future<void> deleteCustomer(String id) async {
    try {
      await _client.from('clients').update({'is_active': false}).eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar cliente: $e');
    }
  }

  // ============================================================================
  // LOYALTY PROGRAM
  // ============================================================================

  /// Add loyalty points to a customer
  Future<void> addLoyaltyPoints(String customerId, int points) async {
    try {
      final customer = await getCustomerById(customerId);

      final currentPoints = (customer['loyalty_points'] as num).toInt();
      final newPoints = currentPoints + points;

      await _client
          .from('clients')
          .update({'loyalty_points': newPoints})
          .eq('id', customerId);
    } catch (e) {
      throw Exception('Error al agregar puntos de lealtad: $e');
    }
  }

  /// Redeem loyalty points
  Future<void> redeemLoyaltyPoints(String customerId, int points) async {
    try {
      final customer = await getCustomerById(customerId);

      final currentPoints = (customer['loyalty_points'] as num).toInt();

      if (currentPoints < points) {
        throw Exception('Puntos insuficientes');
      }

      final newPoints = currentPoints - points;

      await _client
          .from('clients')
          .update({'loyalty_points': newPoints})
          .eq('id', customerId);
    } catch (e) {
      throw Exception('Error al canjear puntos de lealtad: $e');
    }
  }

  /// Get customers with most loyalty points
  Future<List<Map<String, dynamic>>> getTopLoyaltyCustomers({
    int limit = 10,
  }) async {
    try {
      final response = await _client
          .from('clients')
          .select()
          .eq('is_active', true)
          .order('loyalty_points', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al cargar clientes con más puntos: $e');
    }
  }

  /// Calculate points to award based on purchase amount
  int calculatePointsFromPurchase(double purchaseAmount) {
    // Award 1 point for every $10 spent
    return (purchaseAmount / 10).floor();
  }

  /// Get discount amount for points redemption
  double calculateDiscountFromPoints(int points) {
    // 100 points = $10 discount
    return (points / 100) * 10;
  }

  // ============================================================================
  // CUSTOMER ANALYTICS
  // ============================================================================

  /// Get customer purchase history
  Future<List<Map<String, dynamic>>> getCustomerOrders(
    String customerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client
          .from('orders')
          .select('*, order_items(*)')
          .eq('client_id', customerId);

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al cargar historial de compras: $e');
    }
  }

  /// Get customer statistics
  Future<Map<String, dynamic>> getCustomerStatistics(String customerId) async {
    try {
      final orders = await getCustomerOrders(customerId);

      final deliveredOrders = orders
          .where((o) => o['status'] == 'delivered')
          .toList();

      final totalSpent = deliveredOrders.fold<double>(
        0,
        (sum, order) => sum + ((order['total'] as num).toDouble()),
      );

      final averageOrderValue = deliveredOrders.isNotEmpty
          ? totalSpent / deliveredOrders.length
          : 0;

      final lastOrder = deliveredOrders.isNotEmpty
          ? DateTime.parse(deliveredOrders.first['created_at'])
          : null;

      return {
        'total_orders': deliveredOrders.length,
        'total_spent': totalSpent,
        'average_order_value': averageOrderValue,
        'last_order_date': lastOrder?.toIso8601String(),
      };
    } catch (e) {
      throw Exception('Error al cargar estadísticas del cliente: $e');
    }
  }

  /// Get customers who haven't purchased recently
  Future<List<Map<String, dynamic>>> getInactiveCustomers({
    int daysInactive = 30,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysInactive));

      final customers = await getCustomers(activeOnly: true);
      final inactiveCustomers = <Map<String, dynamic>>[];

      for (final customer in customers) {
        final orders = await getCustomerOrders(customer['id']);

        if (orders.isEmpty) {
          inactiveCustomers.add(customer);
          continue;
        }

        final lastOrderDate = DateTime.parse(orders.first['created_at']);
        if (lastOrderDate.isBefore(cutoffDate)) {
          inactiveCustomers.add(customer);
        }
      }

      return inactiveCustomers;
    } catch (e) {
      throw Exception('Error al cargar clientes inactivos: $e');
    }
  }

  /// Get customer lifetime value (CLV)
  Future<Map<String, dynamic>> getCustomerLifetimeValue() async {
    try {
      final customers = await getCustomers(activeOnly: true);
      final clvData = <Map<String, dynamic>>[];

      for (final customer in customers) {
        final stats = await getCustomerStatistics(customer['id']);

        clvData.add({
          'customer_id': customer['id'],
          'customer_name': customer['name'],
          'total_spent': stats['total_spent'],
          'total_orders': stats['total_orders'],
          'average_order_value': stats['average_order_value'],
          'loyalty_points': customer['loyalty_points'],
        });
      }

      clvData.sort(
        (a, b) =>
            (b['total_spent'] as double).compareTo(a['total_spent'] as double),
      );

      return {
        'customers': clvData,
        'total_customers': clvData.length,
        'total_clv': clvData.fold<double>(
          0,
          (sum, c) => sum + ((c['total_spent'] as num).toDouble()),
        ),
      };
    } catch (e) {
      throw Exception('Error al calcular valor de vida del cliente: $e');
    }
  }

  /// Get customer segmentation data
  Future<Map<String, dynamic>> getCustomerSegmentation() async {
    try {
      final customers = await getCustomers(activeOnly: true);

      final vipCustomers = customers
          .where((c) => (c['loyalty_points'] as num).toInt() >= 1000)
          .toList();

      final regularCustomers = customers.where((c) {
        final points = (c['loyalty_points'] as num).toInt();
        return points >= 100 && points < 1000;
      }).toList();

      final newCustomers = customers
          .where((c) => (c['loyalty_points'] as num).toInt() < 100)
          .toList();

      return {
        'total_customers': customers.length,
        'vip_customers': vipCustomers.length,
        'regular_customers': regularCustomers.length,
        'new_customers': newCustomers.length,
        'vip_list': vipCustomers,
        'regular_list': regularCustomers,
        'new_list': newCustomers,
      };
    } catch (e) {
      throw Exception('Error al segmentar clientes: $e');
    }
  }
}

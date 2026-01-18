import './supabase_service.dart';

/// Service for generating comprehensive reports and analytics
class ReportService {
  final _client = SupabaseService.client;

  // ============================================================================
  // SALES REPORTS
  // ============================================================================

  /// Generate comprehensive sales report for a date range
  Future<Map<String, dynamic>> getSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final orders = await _client
          .from('orders')
          .select('*')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .eq('status', 'delivered');

      final totalSales = orders.fold<double>(
        0,
        (sum, order) => sum + ((order['total'] as num).toDouble()),
      );

      final totalSubtotal = orders.fold<double>(
        0,
        (sum, order) => sum + ((order['subtotal'] as num).toDouble()),
      );

      final totalTax = orders.fold<double>(
        0,
        (sum, order) => sum + ((order['tax'] as num).toDouble()),
      );

      final totalDiscount = orders.fold<double>(
        0,
        (sum, order) => sum + ((order['discount'] as num).toDouble()),
      );

      final orderCount = orders.length;
      final averageTicket = orderCount > 0 ? totalSales / orderCount : 0;

      return {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'total_sales': totalSales,
        'total_subtotal': totalSubtotal,
        'total_tax': totalTax,
        'total_discount': totalDiscount,
        'order_count': orderCount,
        'average_ticket': averageTicket,
        'orders': orders,
      };
    } catch (e) {
      throw Exception('Error al generar reporte de ventas: $e');
    }
  }

  /// Get daily sales summary
  Future<List<Map<String, dynamic>>> getDailySalesSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final orders = await _client
          .from('orders')
          .select('created_at, total')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .eq('status', 'delivered');

      final dailyData = <String, Map<String, dynamic>>{};

      for (final order in orders) {
        final createdAt = DateTime.parse(order['created_at']);
        final dateKey =
            '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';

        if (!dailyData.containsKey(dateKey)) {
          dailyData[dateKey] = {
            'date': dateKey,
            'orders': 0,
            'total_sales': 0.0,
          };
        }

        dailyData[dateKey]!['orders'] =
            (dailyData[dateKey]!['orders'] as int) + 1;
        dailyData[dateKey]!['total_sales'] =
            (dailyData[dateKey]!['total_sales'] as double) +
            ((order['total'] as num).toDouble());
      }

      final result = dailyData.values.toList()
        ..sort((a, b) => a['date'].compareTo(b['date']));
      return result;
    } catch (e) {
      throw Exception('Error al generar resumen diario de ventas: $e');
    }
  }

  /// Get hourly sales distribution
  Future<List<Map<String, dynamic>>> getHourlySales({
    required DateTime date,
  }) async {
    try {
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = startDate.add(const Duration(days: 1));

      final orders = await _client
          .from('orders')
          .select('created_at, total')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .eq('status', 'delivered');

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

      final result = List.generate(24, (hour) {
        return hourlyData[hour] ?? {'hour': hour, 'orders': 0, 'total': 0.0};
      });

      return result;
    } catch (e) {
      throw Exception('Error al generar ventas por hora: $e');
    }
  }

  // ============================================================================
  // PRODUCT REPORTS
  // ============================================================================

  /// Get top selling products
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
            'product_id': productId,
            'product_name': item['product_name'],
            'total_quantity': 0,
            'total_sales': 0.0,
          };
        }

        productMap[productId]!['total_quantity'] += item['quantity'] as int;
        productMap[productId]!['total_sales'] += (item['subtotal'] as num)
            .toDouble();
      }

      final topProducts = productMap.values.toList()
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

  /// Get product performance analysis
  Future<Map<String, dynamic>> getProductPerformance({
    required DateTime startDate,
    required DateTime endDate,
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
            'product_id': productId,
            'product_name': item['product_name'],
            'total_quantity': 0,
            'total_sales': 0.0,
            'order_count': 0,
          };
        }

        productMap[productId]!['total_quantity'] += item['quantity'] as int;
        productMap[productId]!['total_sales'] += (item['subtotal'] as num)
            .toDouble();
        productMap[productId]!['order_count'] =
            (productMap[productId]!['order_count'] as int) + 1;
      }

      final products = productMap.values.toList();

      return {'total_products_sold': products.length, 'products': products};
    } catch (e) {
      throw Exception('Error al analizar rendimiento de productos: $e');
    }
  }

  /// Get low performing products
  Future<List<Map<String, dynamic>>> getLowPerformingProducts({
    required DateTime startDate,
    required DateTime endDate,
    int threshold = 5,
  }) async {
    try {
      final performance = await getProductPerformance(
        startDate: startDate,
        endDate: endDate,
      );

      final products = performance['products'] as List<Map<String, dynamic>>;

      final lowPerforming = products.where((p) {
        return (p['total_quantity'] as int) <= threshold;
      }).toList();

      lowPerforming.sort(
        (a, b) =>
            (a['total_quantity'] as int).compareTo(b['total_quantity'] as int),
      );

      return lowPerforming;
    } catch (e) {
      throw Exception('Error al cargar productos de bajo rendimiento: $e');
    }
  }

  // ============================================================================
  // INVENTORY REPORTS
  // ============================================================================

  /// Get inventory status report
  Future<Map<String, dynamic>> getInventoryReport() async {
    try {
      final ingredients = await _client.from('ingredients').select();

      final lowStock = ingredients.where((i) {
        final currentStock = (i['current_stock'] as num).toDouble();
        final minStock = (i['min_stock'] as num).toDouble();
        return currentStock < minStock;
      }).toList();

      final outOfStock = ingredients.where((i) {
        final currentStock = (i['current_stock'] as num).toDouble();
        return currentStock <= 0;
      }).toList();

      final totalValue = ingredients.fold<double>(0, (sum, i) {
        final currentStock = (i['current_stock'] as num).toDouble();
        final unitCost = (i['unit_cost'] as num).toDouble();
        return sum + (currentStock * unitCost);
      });

      return {
        'total_ingredients': ingredients.length,
        'low_stock_count': lowStock.length,
        'out_of_stock_count': outOfStock.length,
        'total_inventory_value': totalValue,
        'low_stock_items': lowStock,
        'out_of_stock_items': outOfStock,
      };
    } catch (e) {
      throw Exception('Error al generar reporte de inventario: $e');
    }
  }

  /// Get inventory movement report
  Future<Map<String, dynamic>> getInventoryMovementReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final movements = await _client
          .from('inventory_movements')
          .select('*, ingredients(name, unit)')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      final byType = <String, int>{};
      final totalCostByType = <String, double>{};

      for (final movement in movements) {
        final type = movement['type'] as String;
        byType[type] = (byType[type] ?? 0) + 1;
        totalCostByType[type] =
            (totalCostByType[type] ?? 0) +
            ((movement['total_cost'] as num).toDouble());
      }

      return {
        'total_movements': movements.length,
        'movements_by_type': byType,
        'total_cost_by_type': totalCostByType,
        'movements': movements,
      };
    } catch (e) {
      throw Exception('Error al generar reporte de movimientos: $e');
    }
  }

  // ============================================================================
  // FINANCIAL REPORTS
  // ============================================================================

  /// Get profit and loss report
  Future<Map<String, dynamic>> getProfitLossReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final salesReport = await getSalesReport(
        startDate: startDate,
        endDate: endDate,
      );

      final movementReport = await getInventoryMovementReport(
        startDate: startDate,
        endDate: endDate,
      );

      final revenue = salesReport['total_sales'] as double;
      final costByType =
          movementReport['total_cost_by_type'] as Map<String, double>;

      final cogs = costByType['purchase'] ?? 0;
      final waste = costByType['waste'] ?? 0;

      final grossProfit = revenue - cogs;
      final netProfit = grossProfit - waste;

      final grossMargin = revenue > 0 ? (grossProfit / revenue) * 100 : 0;
      final netMargin = revenue > 0 ? (netProfit / revenue) * 100 : 0;

      return {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'revenue': revenue,
        'cost_of_goods_sold': cogs,
        'waste_cost': waste,
        'gross_profit': grossProfit,
        'net_profit': netProfit,
        'gross_margin_percent': grossMargin,
        'net_margin_percent': netMargin,
      };
    } catch (e) {
      throw Exception('Error al generar reporte de ganancias y pérdidas: $e');
    }
  }

  /// Get payment method distribution
  Future<Map<String, dynamic>> getPaymentMethodDistribution({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final payments = await _client
          .from('payments')
          .select('method, amount')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      final byMethod = <String, Map<String, dynamic>>{};

      for (final payment in payments) {
        final method = payment['method'] as String;
        final amount = (payment['amount'] as num).toDouble();

        if (!byMethod.containsKey(method)) {
          byMethod[method] = {'count': 0, 'total': 0.0};
        }

        byMethod[method]!['count'] = (byMethod[method]!['count'] as int) + 1;
        byMethod[method]!['total'] =
            (byMethod[method]!['total'] as double) + amount;
      }

      final totalAmount = byMethod.values.fold<double>(
        0,
        (sum, v) => sum + (v['total'] as double),
      );

      // Calculate percentages
      byMethod.forEach((method, data) {
        final methodTotal = data['total'] as double;
        data['percentage'] = totalAmount > 0
            ? (methodTotal / totalAmount) * 100
            : 0;
      });

      return {
        'total_amount': totalAmount,
        'total_payments': payments.length,
        'by_method': byMethod,
      };
    } catch (e) {
      throw Exception('Error al generar distribución de métodos de pago: $e');
    }
  }

  // ============================================================================
  // DASHBOARD METRICS
  // ============================================================================

  /// Get comprehensive dashboard metrics
  Future<Map<String, dynamic>> getDashboardMetrics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final salesReport = await getSalesReport(
        startDate: startDate,
        endDate: endDate,
      );

      final topProducts = await getTopProducts(
        startDate: startDate,
        endDate: endDate,
        limit: 5,
      );

      final inventoryReport = await getInventoryReport();

      final paymentDistribution = await getPaymentMethodDistribution(
        startDate: startDate,
        endDate: endDate,
      );

      return {
        'period': {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
        'sales': {
          'total': salesReport['total_sales'],
          'orders': salesReport['order_count'],
          'average_ticket': salesReport['average_ticket'],
        },
        'top_products': topProducts,
        'inventory': {
          'total_value': inventoryReport['total_inventory_value'],
          'low_stock_count': inventoryReport['low_stock_count'],
          'out_of_stock_count': inventoryReport['out_of_stock_count'],
        },
        'payment_methods': paymentDistribution['by_method'],
      };
    } catch (e) {
      throw Exception('Error al cargar métricas del dashboard: $e');
    }
  }
}

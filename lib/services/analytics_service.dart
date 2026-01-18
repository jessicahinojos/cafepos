import './supabase_service.dart';

class AnalyticsService {
  final _supabase = SupabaseService.client;

  // Get product performance analytics
  Future<List<Map<String, dynamic>>> getProductAnalytics({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('product_analytics')
          .select('*, products(name, image_url, category_id, categories(name))')
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('revenue', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting product analytics: $e');
      return [];
    }
  }

  // Get top selling products
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    try {
      final analytics = await getProductAnalytics(
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );

      // Group by product and sum units
      final productSales = <String, Map<String, dynamic>>{};
      for (final item in analytics) {
        final productId = item['product_id'] as String;
        if (productSales.containsKey(productId)) {
          productSales[productId]!['units_sold'] =
              (productSales[productId]!['units_sold'] as int) +
              (item['units_sold'] as int);
          productSales[productId]!['revenue'] =
              (productSales[productId]!['revenue'] as num) +
              (item['revenue'] as num);
        } else {
          productSales[productId] = {
            'product': item['products'],
            'units_sold': item['units_sold'],
            'revenue': item['revenue'],
          };
        }
      }

      final sorted = productSales.values.toList()
        ..sort(
          (a, b) => (b['units_sold'] as int).compareTo(a['units_sold'] as int),
        );

      return sorted;
    } catch (e) {
      print('Error getting top selling products: $e');
      return [];
    }
  }

  // Get staff performance
  Future<List<Map<String, dynamic>>> getStaffAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase
          .from('staff_analytics')
          .select('*, user_profiles(full_name, role)')
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('total_sales', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting staff analytics: $e');
      return [];
    }
  }

  // Get hourly sales pattern
  Future<List<Map<String, dynamic>>> getHourlyAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase
          .from('hourly_analytics')
          .select()
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('date', ascending: true)
          .order('hour', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting hourly analytics: $e');
      return [];
    }
  }

  // Get peak hours
  Future<List<Map<String, dynamic>>> getPeakHours({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 5,
  }) async {
    try {
      final hourlyData = await getHourlyAnalytics(
        startDate: startDate,
        endDate: endDate,
      );

      // Group by hour and sum revenue
      final hourRevenue = <int, double>{};
      for (final item in hourlyData) {
        final hour = item['hour'] as int;
        final revenue = (item['revenue'] as num).toDouble();
        hourRevenue[hour] = (hourRevenue[hour] ?? 0) + revenue;
      }

      // Convert to list and sort
      final sorted =
          hourRevenue.entries
              .map((e) => {'hour': e.key, 'revenue': e.value})
              .toList()
            ..sort(
              (a, b) =>
                  (b['revenue'] as double).compareTo(a['revenue'] as double),
            );

      return sorted.take(limit).toList();
    } catch (e) {
      print('Error getting peak hours: $e');
      return [];
    }
  }

  // Aggregate analytics for date range
  Future<Map<String, dynamic>> getAnalyticsSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final hourlyData = await getHourlyAnalytics(
        startDate: startDate,
        endDate: endDate,
      );

      double totalRevenue = 0;
      int totalOrders = 0;
      int totalCustomers = 0;

      for (final item in hourlyData) {
        totalRevenue += (item['revenue'] as num).toDouble();
        totalOrders += item['orders_count'] as int;
        totalCustomers += item['unique_customers'] as int;
      }

      final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

      return {
        'total_revenue': totalRevenue,
        'total_orders': totalOrders,
        'unique_customers': totalCustomers,
        'avg_order_value': avgOrderValue,
        'days_analyzed': endDate.difference(startDate).inDays + 1,
      };
    } catch (e) {
      print('Error getting analytics summary: $e');
      return {};
    }
  }

  // Get category performance
  Future<List<Map<String, dynamic>>> getCategoryAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final productAnalytics = await getProductAnalytics(
        startDate: startDate,
        endDate: endDate,
        limit: 1000,
      );

      // Group by category
      final categoryData = <String, Map<String, dynamic>>{};
      for (final item in productAnalytics) {
        final category = item['products']?['categories'];
        if (category != null) {
          final categoryName = category['name'] as String;
          if (categoryData.containsKey(categoryName)) {
            categoryData[categoryName]!['units_sold'] =
                (categoryData[categoryName]!['units_sold'] as int) +
                (item['units_sold'] as int);
            categoryData[categoryName]!['revenue'] =
                (categoryData[categoryName]!['revenue'] as num) +
                (item['revenue'] as num);
          } else {
            categoryData[categoryName] = {
              'category': categoryName,
              'units_sold': item['units_sold'],
              'revenue': item['revenue'],
            };
          }
        }
      }

      final sorted = categoryData.values.toList()
        ..sort((a, b) => (b['revenue'] as num).compareTo(a['revenue'] as num));

      return sorted;
    } catch (e) {
      print('Error getting category analytics: $e');
      return [];
    }
  }

  // Trigger daily aggregation manually
  Future<bool> runDailyAggregation() async {
    try {
      await _supabase.rpc('aggregate_daily_analytics');
      return true;
    } catch (e) {
      print('Error running daily aggregation: $e');
      return false;
    }
  }
}

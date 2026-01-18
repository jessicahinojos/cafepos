import './supabase_service.dart';

class BarcodeService {
  final _supabase = SupabaseService.client;

  // Scan barcode and log result
  Future<Map<String, dynamic>?> scanBarcode(
    String barcode, {
    String? userId,
    String scanType = 'sale',
  }) async {
    try {
      final response = await _supabase.rpc(
        'log_barcode_scan',
        params: {
          'p_barcode': barcode,
          'p_user_id': userId,
          'p_scan_type': scanType,
        },
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error scanning barcode: $e');
      return null;
    }
  }

  // Quick product lookup by barcode
  Future<Map<String, dynamic>?> lookupProductByBarcode(String barcode) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, categories(name, color)')
          .eq('barcode', barcode)
          .eq('is_active', true)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error looking up product: $e');
      return null;
    }
  }

  // Get scan history
  Future<List<Map<String, dynamic>>> getScanHistory({int limit = 50}) async {
    try {
      final response = await _supabase
          .from('barcode_scans')
          .select('*, products(name, image_url), user_profiles(full_name)')
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting scan history: $e');
      return [];
    }
  }

  // Get failed scans (products not found)
  Future<List<Map<String, dynamic>>> getFailedScans({int limit = 20}) async {
    try {
      final response = await _supabase
          .from('barcode_scans')
          .select()
          .eq('found', false)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting failed scans: $e');
      return [];
    }
  }

  // Update product barcode
  Future<bool> updateProductBarcode(String productId, String barcode) async {
    try {
      await _supabase
          .from('products')
          .update({'barcode': barcode})
          .eq('id', productId);

      return true;
    } catch (e) {
      print('Error updating barcode: $e');
      return false;
    }
  }

  // Generate barcode for product (simple sequential number)
  Future<String> generateBarcode() async {
    try {
      final lastProduct = await _supabase
          .from('products')
          .select('barcode')
          .not('barcode', 'is', null)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (lastProduct == null) {
        return '1000000001'; // Start from 10-digit number
      }

      final lastBarcode = lastProduct['barcode'] as String;
      final nextNumber = (int.tryParse(lastBarcode) ?? 1000000000) + 1;
      return nextNumber.toString().padLeft(10, '0');
    } catch (e) {
      print('Error generating barcode: $e');
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  // Get most scanned products
  Future<List<Map<String, dynamic>>> getMostScannedProducts({
    int days = 7,
    int limit = 10,
  }) async {
    try {
      final cutoffDate = DateTime.now()
          .subtract(Duration(days: days))
          .toIso8601String();

      final response = await _supabase
          .from('barcode_scans')
          .select('product_id, products(name, image_url, price)')
          .eq('found', true)
          .gte('created_at', cutoffDate)
          .order('created_at', ascending: false);

      // Group by product_id and count
      final productCounts = <String, Map<String, dynamic>>{};
      for (final scan in response) {
        final productId = scan['product_id'] as String?;
        if (productId != null) {
          if (productCounts.containsKey(productId)) {
            productCounts[productId]!['count'] =
                (productCounts[productId]!['count'] as int) + 1;
          } else {
            productCounts[productId] = {
              'product_id': productId,
              'product': scan['products'],
              'count': 1,
            };
          }
        }
      }

      final sortedProducts = productCounts.values.toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      return sortedProducts.take(limit).toList();
    } catch (e) {
      print('Error getting most scanned products: $e');
      return [];
    }
  }
}

import './supabase_service.dart';

/// Service for managing products and categories in the POS system
class ProductService {
  final _client = SupabaseService.client;

  // ============================================================================
  // CATEGORIES - Complete CRUD Operations
  // ============================================================================

  /// Retrieve all categories with optional filtering
  Future<List<Map<String, dynamic>>> getCategories({
    bool activeOnly = true,
    String? searchQuery,
  }) async {
    try {
      var query = _client.from('categories').select();

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$searchQuery%');
      }

      final response = await query.order('display_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al cargar categorías: $e');
    }
  }

  /// Get a single category by ID
  Future<Map<String, dynamic>> getCategoryById(String id) async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('id', id)
          .single();
      return response;
    } catch (e) {
      throw Exception('Error al cargar categoría: $e');
    }
  }

  /// Create a new category
  Future<Map<String, dynamic>> createCategory({
    required String name,
    String? description,
    String? icon,
    String? color,
    int displayOrder = 0,
    bool isActive = true,
  }) async {
    try {
      final data = {
        'name': name,
        'description': description,
        'icon': icon,
        'color': color,
        'display_order': displayOrder,
        'is_active': isActive,
      };

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

  /// Update an existing category
  Future<void> updateCategory(String id, Map<String, dynamic> updates) async {
    try {
      await _client.from('categories').update(updates).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar categoría: $e');
    }
  }

  /// Soft delete a category (set is_active to false)
  Future<void> deleteCategory(String id) async {
    try {
      await _client
          .from('categories')
          .update({'is_active': false})
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar categoría: $e');
    }
  }

  /// Reorder categories by updating display_order
  Future<void> reorderCategories(List<Map<String, dynamic>> categories) async {
    try {
      for (int i = 0; i < categories.length; i++) {
        await _client
            .from('categories')
            .update({'display_order': i})
            .eq('id', categories[i]['id']);
      }
    } catch (e) {
      throw Exception('Error al reordenar categorías: $e');
    }
  }

  // ============================================================================
  // PRODUCTS - Complete CRUD Operations
  // ============================================================================

  /// Retrieve all products with optional filtering and category join
  Future<List<Map<String, dynamic>>> getProducts({
    String? categoryId,
    bool activeOnly = true,
    bool availableOnly = false,
    String? searchQuery,
  }) async {
    try {
      var query = _client.from('products').select('*, categories(name, color)');

      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      if (availableOnly) {
        query = query.eq('is_available', true);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'name.ilike.%$searchQuery%,sku.ilike.%$searchQuery%,barcode.ilike.%$searchQuery%',
        );
      }

      final response = await query.order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al cargar productos: $e');
    }
  }

  /// Get a single product by ID with full details
  Future<Map<String, dynamic>> getProductById(String id) async {
    try {
      final response = await _client
          .from('products')
          .select('*, categories(name, color)')
          .eq('id', id)
          .single();
      return response;
    } catch (e) {
      throw Exception('Error al cargar producto: $e');
    }
  }

  /// Get products by barcode for quick scanning
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    try {
      final response = await _client
          .from('products')
          .select('*, categories(name, color)')
          .eq('barcode', barcode)
          .eq('is_active', true)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Error al buscar producto por código de barras: $e');
    }
  }

  /// Create a new product
  Future<Map<String, dynamic>> createProduct({
    required String name,
    required String categoryId,
    required double price,
    required double cost,
    String? description,
    String? sku,
    String? barcode,
    String? imageUrl,
    int? preparationTime,
    int? calories,
    String? allergens,
    bool isActive = true,
    bool isAvailable = true,
  }) async {
    try {
      final data = {
        'name': name,
        'category_id': categoryId,
        'price': price,
        'cost': cost,
        'description': description,
        'sku': sku,
        'barcode': barcode,
        'image_url': imageUrl,
        'preparation_time': preparationTime,
        'calories': calories,
        'allergens': allergens,
        'is_active': isActive,
        'is_available': isAvailable,
      };

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

  /// Update an existing product
  Future<void> updateProduct(String id, Map<String, dynamic> updates) async {
    try {
      await _client.from('products').update(updates).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  /// Toggle product availability (for quick enable/disable)
  Future<void> toggleProductAvailability(String id, bool isAvailable) async {
    try {
      await _client
          .from('products')
          .update({'is_available': isAvailable})
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al cambiar disponibilidad del producto: $e');
    }
  }

  /// Soft delete a product (set is_active to false)
  Future<void> deleteProduct(String id) async {
    try {
      await _client.from('products').update({'is_active': false}).eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }

  /// Update product image URL
  Future<void> updateProductImage(String id, String imageUrl) async {
    try {
      await _client
          .from('products')
          .update({'image_url': imageUrl})
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar imagen del producto: $e');
    }
  }

  /// Get products with low profit margin
  Future<List<Map<String, dynamic>>> getLowProfitProducts({
    double threshold = 0.2,
  }) async {
    try {
      final products = await getProducts(activeOnly: true);

      return products.where((product) {
        final price = (product['price'] as num).toDouble();
        final cost = (product['cost'] as num).toDouble();
        final margin = (price - cost) / price;
        return margin < threshold;
      }).toList();
    } catch (e) {
      throw Exception('Error al cargar productos con bajo margen: $e');
    }
  }

  /// Bulk update product prices
  Future<void> bulkUpdatePrices(List<Map<String, dynamic>> priceUpdates) async {
    try {
      for (final update in priceUpdates) {
        await _client
            .from('products')
            .update({'price': update['price']})
            .eq('id', update['id']);
      }
    } catch (e) {
      throw Exception('Error al actualizar precios masivamente: $e');
    }
  }

  /// Get product statistics
  Future<Map<String, dynamic>> getProductStatistics() async {
    try {
      final products = await _client.from('products').select();

      final activeCount = products.where((p) => p['is_active'] == true).length;
      final availableCount = products
          .where((p) => p['is_available'] == true)
          .length;
      final totalValue = products.fold<double>(
        0,
        (sum, p) => sum + ((p['cost'] as num).toDouble()),
      );

      return {
        'total_products': products.length,
        'active_products': activeCount,
        'available_products': availableCount,
        'total_inventory_value': totalValue,
      };
    } catch (e) {
      throw Exception('Error al cargar estadísticas de productos: $e');
    }
  }
}

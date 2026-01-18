import './supabase_service.dart';

/// Service for managing inventory, ingredients, recipes, and stock movements
class InventoryService {
  final _client = SupabaseService.client;

  // ============================================================================
  // INGREDIENTS - Complete CRUD Operations
  // ============================================================================

  /// Retrieve all ingredients with optional filtering
  Future<List<Map<String, dynamic>>> getIngredients({
    bool activeOnly = true,
    String? searchQuery,
  }) async {
    try {
      var query = _client.from('ingredients').select();

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'name.ilike.%$searchQuery%,supplier.ilike.%$searchQuery%',
        );
      }

      final response = await query.order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al cargar ingredientes: $e');
    }
  }

  /// Get a single ingredient by ID
  Future<Map<String, dynamic>> getIngredientById(String id) async {
    try {
      final response = await _client
          .from('ingredients')
          .select()
          .eq('id', id)
          .single();
      return response;
    } catch (e) {
      throw Exception('Error al cargar ingrediente: $e');
    }
  }

  /// Create a new ingredient
  Future<Map<String, dynamic>> createIngredient({
    required String name,
    required String unit,
    required double unitCost,
    required double minStock,
    required double maxStock,
    double currentStock = 0,
    String? supplier,
    bool isActive = true,
  }) async {
    try {
      final data = {
        'name': name,
        'unit': unit,
        'unit_cost': unitCost,
        'min_stock': minStock,
        'max_stock': maxStock,
        'current_stock': currentStock,
        'supplier': supplier,
        'is_active': isActive,
      };

      final response = await _client
          .from('ingredients')
          .insert(data)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Error al crear ingrediente: $e');
    }
  }

  /// Update an existing ingredient
  Future<void> updateIngredient(String id, Map<String, dynamic> updates) async {
    try {
      await _client.from('ingredients').update(updates).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar ingrediente: $e');
    }
  }

  /// Update ingredient stock level
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

  /// Soft delete an ingredient
  Future<void> deleteIngredient(String id) async {
    try {
      await _client
          .from('ingredients')
          .update({'is_active': false})
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar ingrediente: $e');
    }
  }

  /// Get ingredients with low stock (below min_stock)
  Future<List<Map<String, dynamic>>> getLowStockIngredients() async {
    try {
      final response = await _client
          .from('ingredients')
          .select()
          .filter('current_stock', 'lt', 'min_stock')
          .eq('is_active', true)
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al cargar alertas de stock: $e');
    }
  }

  /// Get ingredients that need reordering (below reorder point - 50% of max)
  Future<List<Map<String, dynamic>>> getIngredientsToReorder() async {
    try {
      final ingredients = await getIngredients(activeOnly: true);

      return ingredients.where((ingredient) {
        final currentStock = (ingredient['current_stock'] as num).toDouble();
        final maxStock = (ingredient['max_stock'] as num).toDouble();
        final reorderPoint = maxStock * 0.5;
        return currentStock <= reorderPoint;
      }).toList();
    } catch (e) {
      throw Exception('Error al cargar ingredientes a reordenar: $e');
    }
  }

  /// Get ingredients by supplier
  Future<List<Map<String, dynamic>>> getIngredientsBySupplier(
    String supplier,
  ) async {
    try {
      final response = await _client
          .from('ingredients')
          .select()
          .eq('supplier', supplier)
          .eq('is_active', true)
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al cargar ingredientes por proveedor: $e');
    }
  }

  // ============================================================================
  // INVENTORY MOVEMENTS - Complete CRUD Operations
  // ============================================================================

  /// Retrieve inventory movements with optional filtering
  Future<List<Map<String, dynamic>>> getInventoryMovements({
    String? ingredientId,
    String? movementType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client.from('inventory_movements').select('''
        *,
        ingredients(name, unit),
        user_profiles(full_name)
      ''');

      if (ingredientId != null) {
        query = query.eq('ingredient_id', ingredientId);
      }

      if (movementType != null) {
        query = query.eq('type', movementType);
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
      throw Exception('Error al cargar movimientos de inventario: $e');
    }
  }

  /// Create a new inventory movement and update stock
  Future<Map<String, dynamic>> createInventoryMovement({
    required String ingredientId,
    required String type,
    required double quantity,
    required double unitCost,
    String? referenceNumber,
    String? notes,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final totalCost = quantity * unitCost;

      final data = {
        'ingredient_id': ingredientId,
        'user_id': userId,
        'type': type,
        'quantity': quantity,
        'unit_cost': unitCost,
        'total_cost': totalCost,
        'reference_number': referenceNumber,
        'notes': notes,
      };

      final movement = await _client
          .from('inventory_movements')
          .insert(data)
          .select()
          .single();

      // Update ingredient stock based on movement type
      final ingredient = await getIngredientById(ingredientId);
      final currentStock = (ingredient['current_stock'] as num).toDouble();

      double newStock = currentStock;
      if (type == 'purchase' || type == 'adjustment') {
        newStock = currentStock + quantity;
      } else if (type == 'sale' || type == 'waste' || type == 'transfer') {
        newStock = currentStock - quantity;
      }

      await updateIngredientStock(ingredientId, newStock);

      return movement;
    } catch (e) {
      throw Exception('Error al crear movimiento de inventario: $e');
    }
  }

  /// Get movement statistics for a date range
  Future<Map<String, dynamic>> getMovementStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final movements = await getInventoryMovements(
        startDate: startDate,
        endDate: endDate,
      );

      final purchases = movements
          .where((m) => m['type'] == 'purchase')
          .toList();
      final sales = movements.where((m) => m['type'] == 'sale').toList();
      final waste = movements.where((m) => m['type'] == 'waste').toList();
      final adjustments = movements
          .where((m) => m['type'] == 'adjustment')
          .toList();

      final totalPurchases = purchases.fold<double>(
        0,
        (sum, m) => sum + ((m['total_cost'] as num).toDouble()),
      );

      final totalWaste = waste.fold<double>(
        0,
        (sum, m) => sum + ((m['total_cost'] as num).toDouble()),
      );

      return {
        'total_movements': movements.length,
        'purchases_count': purchases.length,
        'sales_count': sales.length,
        'waste_count': waste.length,
        'adjustments_count': adjustments.length,
        'total_purchases_value': totalPurchases,
        'total_waste_value': totalWaste,
      };
    } catch (e) {
      throw Exception('Error al cargar estadísticas de movimientos: $e');
    }
  }

  // ============================================================================
  // RECIPES - Complete CRUD Operations
  // ============================================================================

  /// Get recipes for a specific product
  Future<List<Map<String, dynamic>>> getRecipesByProduct(
    String productId,
  ) async {
    try {
      final response = await _client
          .from('recipes')
          .select('*, ingredients(name, unit, unit_cost)')
          .eq('product_id', productId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al cargar recetas: $e');
    }
  }

  /// Get all products using a specific ingredient
  Future<List<Map<String, dynamic>>> getProductsByIngredient(
    String ingredientId,
  ) async {
    try {
      final response = await _client
          .from('recipes')
          .select('*, products(name, price)')
          .eq('ingredient_id', ingredientId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al cargar productos por ingrediente: $e');
    }
  }

  /// Create a new recipe entry
  Future<Map<String, dynamic>> createRecipe({
    required String productId,
    required String ingredientId,
    required double quantity,
    required String unit,
  }) async {
    try {
      final data = {
        'product_id': productId,
        'ingredient_id': ingredientId,
        'quantity': quantity,
        'unit': unit,
      };

      final response = await _client
          .from('recipes')
          .insert(data)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Error al crear receta: $e');
    }
  }

  /// Update a recipe entry
  Future<void> updateRecipe(String id, Map<String, dynamic> updates) async {
    try {
      await _client.from('recipes').update(updates).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar receta: $e');
    }
  }

  /// Delete a recipe entry
  Future<void> deleteRecipe(String id) async {
    try {
      await _client.from('recipes').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar receta: $e');
    }
  }

  /// Calculate total cost of a product based on its recipe
  Future<double> calculateProductCost(String productId) async {
    try {
      final recipes = await getRecipesByProduct(productId);

      double totalCost = 0;
      for (final recipe in recipes) {
        final quantity = (recipe['quantity'] as num).toDouble();
        final unitCost = (recipe['ingredients']['unit_cost'] as num).toDouble();
        totalCost += quantity * unitCost;
      }

      return totalCost;
    } catch (e) {
      throw Exception('Error al calcular costo del producto: $e');
    }
  }

  /// Get inventory valuation report
  Future<Map<String, dynamic>> getInventoryValuation() async {
    try {
      final ingredients = await getIngredients(activeOnly: true);

      double totalValue = 0;
      for (final ingredient in ingredients) {
        final currentStock = (ingredient['current_stock'] as num).toDouble();
        final unitCost = (ingredient['unit_cost'] as num).toDouble();
        totalValue += currentStock * unitCost;
      }

      return {
        'total_ingredients': ingredients.length,
        'total_inventory_value': totalValue,
        'ingredients': ingredients,
      };
    } catch (e) {
      throw Exception('Error al calcular valoración de inventario: $e');
    }
  }
}

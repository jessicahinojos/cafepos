import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/add_product_dialog.dart';
import './widgets/category_management_dialog.dart';
import './widgets/product_card_widget.dart';
import './widgets/recipe_management_dialog.dart';

class ProductManagement extends StatefulWidget {
  const ProductManagement({super.key});

  @override
  State<ProductManagement> createState() => _ProductManagementState();
}

class _ProductManagementState extends State<ProductManagement> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  final Set<int> _selectedProducts = {};
  bool _isMultiSelectMode = false;

  // Mock product data
  final List<Map<String, dynamic>> _products = [
    {
      "id": 1,
      "name": "Café Americano",
      "description": "Café negro clásico preparado con granos premium",
      "sku": "CAF-001",
      "price": 2.50,
      "category": "Bebidas Calientes",
      "image":
          "https://images.unsplash.com/photo-1647707966898-c013e827d9d4",
      "semanticLabel":
          "Taza de café americano negro en taza blanca sobre platillo",
      "isActive": true,
      "hasRecipe": true,
      "salesCount": 245,
    },
    {
      "id": 2,
      "name": "Cappuccino",
      "description": "Espresso con leche vaporizada y espuma cremosa",
      "sku": "CAF-002",
      "price": 3.50,
      "category": "Bebidas Calientes",
      "image":
          "https://images.unsplash.com/photo-1491489061218-d7b8608e1642",
      "semanticLabel":
          "Cappuccino con arte latte en forma de corazón en taza blanca",
      "isActive": true,
      "hasRecipe": true,
      "salesCount": 312,
    },
    {
      "id": 3,
      "name": "Croissant de Mantequilla",
      "description": "Croissant francés hojaldrado recién horneado",
      "sku": "PAN-001",
      "price": 2.00,
      "category": "Panadería",
      "image":
          "https://images.unsplash.com/photo-1720705033886-ce38dd0d0765",
      "semanticLabel":
          "Croissant dorado y hojaldrado sobre superficie de madera",
      "isActive": true,
      "hasRecipe": true,
      "salesCount": 189,
    },
    {
      "id": 4,
      "name": "Sandwich Club",
      "description": "Triple sandwich con pollo, bacon, lechuga y tomate",
      "sku": "COM-001",
      "price": 6.50,
      "category": "Comida",
      "image":
          "https://images.unsplash.com/photo-1597205153357-61432f41f96f",
      "semanticLabel": "Sandwich club triple con papas fritas en plato blanco",
      "isActive": true,
      "hasRecipe": true,
      "salesCount": 156,
    },
    {
      "id": 5,
      "name": "Té Verde Matcha",
      "description": "Té matcha japonés premium con leche",
      "sku": "BEB-001",
      "price": 4.00,
      "category": "Bebidas Frías",
      "image":
          "https://images.unsplash.com/photo-1617892165107-76fb45f50f7c",
      "semanticLabel":
          "Bebida de té verde matcha con hielo en vaso transparente",
      "isActive": false,
      "hasRecipe": true,
      "salesCount": 98,
    },
    {
      "id": 6,
      "name": "Ensalada César",
      "description": "Lechuga romana, pollo, crutones y aderezo césar",
      "sku": "COM-002",
      "price": 5.50,
      "category": "Comida",
      "image":
          "https://images.unsplash.com/photo-1605100768121-cb7dce99dc81",
      "semanticLabel": "Ensalada césar con pollo a la parrilla en bowl blanco",
      "isActive": true,
      "hasRecipe": true,
      "salesCount": 134,
    },
    {
      "id": 7,
      "name": "Muffin de Arándanos",
      "description": "Muffin casero con arándanos frescos",
      "sku": "PAN-002",
      "price": 2.50,
      "category": "Panadería",
      "image":
          "https://images.unsplash.com/photo-1610557242288-1267a7dd4ccc",
      "semanticLabel":
          "Muffin de arándanos con azúcar espolvoreada en papel de hornear",
      "isActive": true,
      "hasRecipe": true,
      "salesCount": 167,
    },
    {
      "id": 8,
      "name": "Smoothie de Fresa",
      "description": "Batido natural de fresas con yogurt",
      "sku": "BEB-002",
      "price": 4.50,
      "category": "Bebidas Frías",
      "image":
          "https://images.unsplash.com/photo-1589733955941-5eeaf752f6dd",
      "semanticLabel": "Smoothie rosa de fresa en vaso alto con pajita",
      "isActive": true,
      "hasRecipe": true,
      "salesCount": 201,
    },
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products.where((product) {
      final name = (product["name"] as String).toLowerCase();
      final sku = (product["sku"] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || sku.contains(query);
    }).toList();
  }

  void _toggleProductStatus(int productId) {
    HapticFeedback.lightImpact();
    setState(() {
      final index = _products.indexWhere((p) => p["id"] == productId);
      if (index != -1) {
        _products[index]["isActive"] = !(_products[index]["isActive"] as bool);
      }
    });
  }

  void _deleteProduct(int productId) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar Producto',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          '¿Está seguro de que desea eliminar este producto? Esta acción no se puede deshacer.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _products.removeWhere((p) => p["id"] == productId);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Producto eliminado exitosamente'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _duplicateProduct(int productId) {
    HapticFeedback.lightImpact();
    final product = _products.firstWhere((p) => p["id"] == productId);
    final newProduct = Map<String, dynamic>.from(product);
    newProduct["id"] = _products.length + 1;
    newProduct["name"] = "${product["name"]} (Copia)";
    newProduct["sku"] = "${product["sku"]}-COPY";
    setState(() {
      _products.add(newProduct);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Producto duplicado exitosamente'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAddProductDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        onSave: (productData) {
          setState(() {
            _products.add(productData);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto agregado exitosamente'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        product: product,
        onSave: (productData) {
          setState(() {
            final index = _products.indexWhere((p) => p["id"] == product["id"]);
            if (index != -1) {
              _products[index] = productData;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto actualizado exitosamente'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _showRecipeManagement(Map<String, dynamic> product) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => RecipeManagementDialog(product: product),
    );
  }

  void _showCategoryManagement() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => const CategoryManagementDialog(),
    );
  }

  void _toggleMultiSelect(int productId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedProducts.contains(productId)) {
        _selectedProducts.remove(productId);
        if (_selectedProducts.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedProducts.add(productId);
        _isMultiSelectMode = true;
      }
    });
  }

  void _showBulkActionsDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Acciones Masivas',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'edit',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Actualizar Precios'),
              onTap: () {
                Navigator.pop(context);
                _showBulkPriceUpdate();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'category',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Cambiar Categoría'),
              onTap: () {
                Navigator.pop(context);
                _showBulkCategoryChange();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'toggle_on',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Activar/Desactivar'),
              onTap: () {
                Navigator.pop(context);
                _bulkToggleStatus();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkPriceUpdate() {
    final TextEditingController percentageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Actualizar Precios',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: TextField(
          controller: percentageController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Porcentaje de cambio (%)',
            hintText: 'Ej: 10 para aumentar 10%',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final percentage = double.tryParse(percentageController.text);
              if (percentage != null) {
                setState(() {
                  for (final id in _selectedProducts) {
                    final index = _products.indexWhere((p) => p["id"] == id);
                    if (index != -1) {
                      final currentPrice = _products[index]["price"] as double;
                      _products[index]["price"] =
                          currentPrice * (1 + percentage / 100);
                    }
                  }
                  _selectedProducts.clear();
                  _isMultiSelectMode = false;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Precios actualizados exitosamente'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _showBulkCategoryChange() {
    final categories = _products
        .map((p) => p["category"] as String)
        .toSet()
        .toList();
    String? selectedCategory;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Cambiar Categoría',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: DropdownButtonFormField<String>(
            initialValue: selectedCategory,
            decoration: const InputDecoration(labelText: 'Nueva Categoría'),
            items: categories.map((category) {
              return DropdownMenuItem(value: category, child: Text(category));
            }).toList(),
            onChanged: (value) {
              setDialogState(() {
                selectedCategory = value;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedCategory != null
                  ? () {
                      setState(() {
                        for (final id in _selectedProducts) {
                          final index = _products.indexWhere(
                            (p) => p["id"] == id,
                          );
                          if (index != -1) {
                            _products[index]["category"] = selectedCategory;
                          }
                        }
                        _selectedProducts.clear();
                        _isMultiSelectMode = false;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Categoría actualizada exitosamente'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  : null,
              child: const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );
  }

  void _bulkToggleStatus() {
    setState(() {
      for (final id in _selectedProducts) {
        final index = _products.indexWhere((p) => p["id"] == id);
        if (index != -1) {
          _products[index]["isActive"] =
              !(_products[index]["isActive"] as bool);
        }
      }
      _selectedProducts.clear();
      _isMultiSelectMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Estado actualizado exitosamente'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Productos sincronizados'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestión de Productos',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isMultiSelectMode)
            IconButton(
              icon: CustomIconWidget(
                iconName: 'more_vert',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: _showBulkActionsDialog,
              tooltip: 'Acciones masivas',
            ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'category',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _showCategoryManagement,
            tooltip: 'Gestionar categorías',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(8.h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o SKU...',
                prefixIcon: CustomIconWidget(
                  iconName: 'search',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: CustomIconWidget(
                          iconName: 'clear',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.brightness == Brightness.light
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFF1E293B),
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
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
            : _filteredProducts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'inventory_2',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 64,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _searchQuery.isEmpty
                          ? 'No hay productos disponibles'
                          : 'No se encontraron productos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      _searchQuery.isEmpty
                          ? 'Agregue su primer producto'
                          : 'Intente con otro término de búsqueda',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(4.w),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return ProductCardWidget(
                    product: product,
                    isSelected: _selectedProducts.contains(product["id"]),
                    isMultiSelectMode: _isMultiSelectMode,
                    onTap: () {
                      if (_isMultiSelectMode) {
                        _toggleMultiSelect(product["id"] as int);
                      }
                    },
                    onLongPress: () {
                      _toggleMultiSelect(product["id"] as int);
                    },
                    onToggleStatus: () =>
                        _toggleProductStatus(product["id"] as int),
                    onEdit: () => _showEditProductDialog(product),
                    onDuplicate: () => _duplicateProduct(product["id"] as int),
                    onDelete: () => _deleteProduct(product["id"] as int),
                    onManageRecipe: () => _showRecipeManagement(product),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        icon: CustomIconWidget(
          iconName: 'add',
          color: theme.colorScheme.onPrimary,
          size: 24,
        ),
        label: Text(
          'Agregar Producto',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

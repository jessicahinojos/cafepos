import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/product_service.dart';
import '../../services/order_service.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/cart_panel_widget.dart';
import './widgets/category_chip_widget.dart';
import './widgets/payment_bottom_sheet_widget.dart';
import './widgets/product_grid_item_widget.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();

  String _selectedCategoryId = 'all';
  String _selectedCategoryName = 'Todos';
  String _orderType = 'Mostrador';
  final List<Map<String, dynamic>> _cartItems = [];
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isLoading = true;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];

  final List<String> _orderTypes = [
    'Mostrador',
    'Mesa',
    'Para Llevar',
    'Delivery',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Load categories and products from Supabase
      final categories = await _productService.getCategories(activeOnly: true);
      final products = await _productService.getProducts(
        activeOnly: true,
        availableOnly: true,
      );

      setState(() {
        _categories = [
          {'id': 'all', 'name': 'Todos'},
          ...categories,
        ];
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
      }
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    List<Map<String, dynamic>> filtered = _products;

    // Filter by category
    if (_selectedCategoryId != 'all') {
      filtered = filtered
          .where((p) => p['category_id'] == _selectedCategoryId)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        final name = (p['name'] as String? ?? '').toLowerCase();
        final sku = (p['sku'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || sku.contains(query);
      }).toList();
    }

    return filtered;
  }

  double get _cartTotal {
    return _cartItems.fold(0.0, (sum, item) {
      final price = item["price"] as double;
      final quantity = item["quantity"] as int;
      final discount = item["discount"] as double? ?? 0.0;
      return sum + ((price * quantity) - discount);
    });
  }

  int get _cartItemCount {
    return _cartItems.fold(0, (sum, item) => sum + (item["quantity"] as int));
  }

  void _addToCart(Map<String, dynamic> product) {
    HapticFeedback.lightImpact();

    setState(() {
      final existingIndex = _cartItems.indexWhere(
        (item) => item["id"] == product["id"],
      );

      if (existingIndex != -1) {
        _cartItems[existingIndex]["quantity"] =
            (_cartItems[existingIndex]["quantity"] as int) + 1;
      } else {
        _cartItems.add({
          "id": product["id"],
          "name": product["name"],
          "price": (product["price"] as num).toDouble(),
          "quantity": 1,
          "note": "",
          "discount": 0.0,
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product["name"]} agregado al carrito'),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _updateCartItem(int index, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index]["quantity"] = quantity;
      }
    });
  }

  void _removeCartItem(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  void _updateCartItemNote(int index, String note) {
    setState(() {
      _cartItems[index]["note"] = note;
    });
  }

  void _updateCartItemDiscount(int index, double discount) {
    setState(() {
      _cartItems[index]["discount"] = discount;
    });
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
    });
  }

  Future<void> _showPaymentSheet() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El carrito está vacío')));
      return;
    }

    HapticFeedback.mediumImpact();
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentBottomSheetWidget(
        total: _cartTotal,
        orderType: _orderType,
        cartItems: _cartItems,
        onPaymentComplete: (paymentData) async {
          try {
            // Prepare order items for Supabase
            final orderItems = _cartItems.map((item) {
              return {
                'product_id': item['id'],
                'product_name': item['name'],
                'quantity': item['quantity'],
                'unit_price': item['price'],
                'notes': item['note'] ?? '',
              };
            }).toList();

            // Create order in Supabase
            final order = await _orderService.createOrder(
              items: orderItems,
              tableNumber: _orderType == 'Mesa' ? 'Mesa' : null,
              discount: _cartItems.fold(
                0.0,
                (sum, item) => sum + (item['discount'] as double? ?? 0.0),
              ),
              notes: 'Tipo: $_orderType',
            );

            // Create payment record
            await _orderService.createPayment(
              orderId: order['id'],
              method: (paymentData['method'] as String?) ?? 'cash',
              amount: (paymentData['amount'] as double?) ?? _cartTotal,
              referenceNumber: (paymentData['referenceNumber'] as String?),
            );

            return order;
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error al procesar orden: $e')),
              );
            }
            rethrow;
          }
        },
      ),
    );

    if (result != null && mounted) {
      _clearCart();
      Navigator.of(context).pop();
      _showSuccessDialog(result['paymentMethod'] ?? 'Efectivo');
    }
  }

  void _showSuccessDialog(String paymentMethod) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 15.w,
                  height: 15.w,
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light
                        ? const Color(0xFF059669).withValues(alpha: 0.1)
                        : const Color(0xFF10B981).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: 'check_circle',
                    color: theme.brightness == Brightness.light
                        ? const Color(0xFF059669)
                        : const Color(0xFF10B981),
                    size: 8.w,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '¡Pago Exitoso!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Método: $paymentMethod',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar'),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Imprimiendo recibo...'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Text('Imprimir'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Ventas',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ventas',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'qr_code_scanner',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Escáner QR próximamente'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Escanear código',
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _isSearching = value.isNotEmpty;
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o SKU...',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(2.w),
                  child: CustomIconWidget(
                    iconName: 'search',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: CustomIconWidget(
                          iconName: 'clear',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _isSearching = false;
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
          Container(
            height: 6.h,
            padding: EdgeInsets.symmetric(vertical: 1.h),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: _categories.length,
              separatorBuilder: (context, index) => SizedBox(width: 2.w),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return CategoryChipWidget(
                  label: category['name'] ?? '',
                  isSelected: _selectedCategoryId == category['id'],
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedCategoryId = category['id'];
                      _selectedCategoryName = category['name'] ?? 'Todos';
                    });
                  },
                );
              },
            ),
          ),
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'search_off',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 64,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'No se encontraron productos',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.all(4.w),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 3.w,
                      mainAxisSpacing: 2.h,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return ProductGridItemWidget(
                        product: product,
                        onTap: () => _addToCart(product),
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          _showProductOptions(product);
                        },
                      );
                    },
                  ),
          ),
          CartPanelWidget(
            cartItems: _cartItems,
            cartTotal: _cartTotal,
            cartItemCount: _cartItemCount,
            orderType: _orderType,
            orderTypes: _orderTypes,
            onOrderTypeChanged: (type) {
              setState(() {
                _orderType = type;
              });
            },
            onUpdateQuantity: _updateCartItem,
            onRemoveItem: _removeCartItem,
            onUpdateNote: _updateCartItemNote,
            onUpdateDiscount: _updateCartItemDiscount,
            onCheckout: _showPaymentSheet,
          ),
        ],
      ),
    );
  }

  void _showProductOptions(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                product["name"] as String,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3.h),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'info_outline',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: const Text('Ver detalles'),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Detalles del producto próximamente'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'note_add',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: const Text('Agregar nota'),
                onTap: () {
                  Navigator.of(context).pop();
                  _addToCart(product);
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'discount',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: const Text('Aplicar descuento'),
                onTap: () {
                  Navigator.of(context).pop();
                  _addToCart(product);
                },
              ),
              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }
}
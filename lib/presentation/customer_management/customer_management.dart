import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/customer_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/add_customer_dialog.dart';
import './widgets/add_points_dialog.dart';
import './widgets/customer_card_widget.dart';
import './widgets/customer_detail_sheet.dart';

class CustomerManagement extends StatefulWidget {
  const CustomerManagement({super.key});

  @override
  State<CustomerManagement> createState() => _CustomerManagementState();
}

class _CustomerManagementState extends State<CustomerManagement> {
  final TextEditingController _searchController = TextEditingController();
  final CustomerService _customerService = CustomerService();

  String _searchQuery = '';
  bool _isSearching = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _customers = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final customers = await _customerService.getCustomers(
        activeOnly: true,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );

      setState(() {
        _customers = customers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredCustomers {
    return _customers;
  }

  Map<String, List<Map<String, dynamic>>> get _groupedCustomers {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var customer in _filteredCustomers) {
      final firstLetter = (customer["name"] as String)[0].toUpperCase();
      grouped.putIfAbsent(firstLetter, () => []);
      grouped[firstLetter]!.add(customer);
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  void _showCustomerDetail(Map<String, dynamic> customer) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomerDetailSheet(
        customer: customer,
        onAddPoints: () => _showAddPointsDialog(customer),
        onNewOrder: () => _handleNewOrder(customer),
        onEdit: () => _handleEditCustomer(customer),
      ),
    );
  }

  void _showAddCustomerDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AddCustomerDialog(
        onCustomerAdded: (newCustomer) async {
          try {
            await _customerService.createCustomer(
              name: newCustomer["name"],
              phone: newCustomer["phone"],
              email: newCustomer["email"],
            );

            await _loadCustomers();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Cliente ${newCustomer["name"]} añadido correctamente',
                  ),
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF059669)
                      : const Color(0xFF10B981),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al crear cliente: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showAddPointsDialog(Map<String, dynamic> customer) {
    Navigator.pop(context);
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AddPointsDialog(
        customer: customer,
        onPointsAdded: (points, description) async {
          try {
            await _customerService.addLoyaltyPoints(customer["id"], points);

            await _loadCustomers();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$points puntos añadidos a ${customer["name"]}',
                  ),
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF059669)
                      : const Color(0xFF10B981),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al añadir puntos: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _handleNewOrder(Map<String, dynamic> customer) {
    Navigator.pop(context);
    HapticFeedback.lightImpact();
    Navigator.of(context, rootNavigator: true).pushNamed('/sales-screen');
  }

  void _handleEditCustomer(Map<String, dynamic> customer) {
    Navigator.pop(context);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de edición en desarrollo')),
    );
  }

  void _handleQuickAction(Map<String, dynamic> customer, String action) {
    HapticFeedback.lightImpact();
    switch (action) {
      case 'points':
        _showAddPointsDialog(customer);
        break;
      case 'order':
        _handleNewOrder(customer);
        break;
      case 'edit':
        _handleEditCustomer(customer);
        break;
    }
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 72),
        child: CustomAppBar(
          title: 'Gestión de Clientes',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'settings',
                color: theme.brightness == Brightness.light
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                size: 24,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamed('/settings-screen');
              },
              tooltip: 'Configuración del programa de fidelidad',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(72),
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _isSearching = value.isNotEmpty;
                  });
                  _loadCustomers();
                },
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o teléfono...',
                  prefixIcon: CustomIconWidget(
                    iconName: 'search',
                    color: theme.brightness == Brightness.light
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                    size: 24,
                  ),
                  suffixIcon: _isSearching
                      ? IconButton(
                          icon: CustomIconWidget(
                            iconName: 'clear',
                            color: theme.brightness == Brightness.light
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                            size: 20,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _isSearching = false;
                            });
                            _loadCustomers();
                          },
                          tooltip: 'Limpiar búsqueda',
                        )
                      : null,
                  filled: true,
                  fillColor: theme.brightness == Brightness.light
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF334155),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF334155),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
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
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'error_outline',
                    color: Colors.red,
                    size: 64,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Error al cargar clientes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFF475569)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.brightness == Brightness.light
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  ElevatedButton.icon(
                    onPressed: _loadCustomers,
                    icon: CustomIconWidget(
                      iconName: 'refresh',
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : _filteredCustomers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: _isSearching ? 'search_off' : 'people_outline',
                    color: theme.brightness == Brightness.light
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    size: 64,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _isSearching
                        ? 'No se encontraron clientes'
                        : 'No hay clientes registrados',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFF475569)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    _isSearching
                        ? 'Intenta con otro término de búsqueda'
                        : 'Añade tu primer cliente para comenzar',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              itemCount: _groupedCustomers.length,
              itemBuilder: (context, index) {
                final letter = _groupedCustomers.keys.elementAt(index);
                final customers = _groupedCustomers[letter]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                      child: Text(
                        letter,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    ...customers.map(
                      (customer) => CustomerCardWidget(
                        customer: customer,
                        onTap: () => _showCustomerDetail(customer),
                        onQuickAction: (action) =>
                            _handleQuickAction(customer, action),
                      ),
                    ),
                    SizedBox(height: 2.h),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCustomerDialog,
        icon: CustomIconWidget(
          iconName: 'person_add',
          color: theme.brightness == Brightness.light
              ? const Color(0xFFFFFFFF)
              : const Color(0xFFFFFFFF),
          size: 24,
        ),
        label: Text(
          'Nuevo Cliente',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.brightness == Brightness.light
                ? const Color(0xFFFFFFFF)
                : const Color(0xFFFFFFFF),
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        elevation: 4.0,
      ),
    );
  }
}
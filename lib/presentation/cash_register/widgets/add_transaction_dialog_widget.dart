import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class AddTransactionDialog extends StatefulWidget {
  final Function(String, double, String, String, String) onConfirm;

  const AddTransactionDialog({super.key, required this.onConfirm});

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _selectedType = 'income';
  String _selectedPaymentMethod = 'cash';
  String _selectedCategory = 'Ingresos';

  final List<Map<String, dynamic>> _incomeCategories = [
    {"label": "Ingresos", "icon": "add_circle"},
    {"label": "Propinas", "icon": "volunteer_activism"},
    {"label": "Otros Ingresos", "icon": "attach_money"},
  ];

  final List<Map<String, dynamic>> _expenseCategories = [
    {"label": "Gastos", "icon": "remove_circle"},
    {"label": "Compras", "icon": "shopping_cart"},
    {"label": "Mantenimiento", "icon": "build"},
    {"label": "Servicios", "icon": "receipt_long"},
    {"label": "Otros Gastos", "icon": "money_off"},
  ];

  List<Map<String, dynamic>> get _currentCategories =>
      _selectedType == 'income' ? _incomeCategories : _expenseCategories;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: 'add',
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nueva Transacción',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Tipo de Transacción',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(
                      context: context,
                      type: 'income',
                      label: 'Ingreso',
                      icon: 'add_circle',
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFF059669)
                          : const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeButton(
                      context: context,
                      type: 'expense',
                      label: 'Gasto',
                      icon: 'remove_circle',
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Categoría',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _currentCategories.map((category) {
                  final isSelected = _selectedCategory == category["label"];
                  return InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedCategory = category["label"] as String;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : theme.brightness == Brightness.light
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.brightness == Brightness.light
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFF334155),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: category["icon"] as String,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.brightness == Brightness.light
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            category["label"] as String,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.brightness == Brightness.light
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$ ',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Método de Pago',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildPaymentMethodButton(
                      context: context,
                      method: 'cash',
                      label: 'Efectivo',
                      icon: 'payments',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPaymentMethodButton(
                      context: context,
                      method: 'card',
                      label: 'Tarjeta',
                      icon: 'credit_card',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPaymentMethodButton(
                      context: context,
                      method: 'qr',
                      label: 'QR',
                      icon: 'qr_code_scanner',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Nota (opcional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        final amount = double.tryParse(_amountController.text);
                        if (amount != null && amount > 0) {
                          widget.onConfirm(
                            _selectedType,
                            amount,
                            _selectedPaymentMethod,
                            _selectedCategory,
                            _noteController.text.isEmpty
                                ? 'Sin nota'
                                : _noteController.text,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Por favor ingresa un monto válido',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text('Agregar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required BuildContext context,
    required String type,
    required String label,
    required String icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedType = type;
          _selectedCategory = type == 'income' ? 'Ingresos' : 'Gastos';
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : theme.brightness == Brightness.light
              ? const Color(0xFFF8FAFC)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : theme.brightness == Brightness.light
                ? const Color(0xFFE2E8F0)
                : const Color(0xFF334155),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: icon,
              color: isSelected
                  ? color
                  : theme.brightness == Brightness.light
                  ? const Color(0xFF64748B)
                  : const Color(0xFF94A3B8),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? color
                    : theme.brightness == Brightness.light
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodButton({
    required BuildContext context,
    required String method,
    required String label,
    required String icon,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedPaymentMethod == method;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.brightness == Brightness.light
              ? const Color(0xFFF8FAFC)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.brightness == Brightness.light
                ? const Color(0xFFE2E8F0)
                : const Color(0xFF334155),
          ),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.brightness == Brightness.light
                  ? const Color(0xFF64748B)
                  : const Color(0xFF94A3B8),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.brightness == Brightness.light
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
